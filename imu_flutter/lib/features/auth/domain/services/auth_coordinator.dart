library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../entities/auth_state.dart';
import '../repositories/auth_repository.dart';
import '../services/token_refresh_service.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/auth/jwt_auth_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/sync/powersync_connector.dart';
import '../../../../core/config/app_config.dart';

/// Exception thrown when an invalid state transition is attempted.
///
/// This exception is thrown by [AuthCoordinator.transitionTo] when
/// the transition from current state to target state is not allowed
/// by the state machine rules defined in [_validTransitions].
///
/// Example:
/// ```dart
/// try {
///   await coordinator.transitionTo(AuthenticatedState(userId: '123'));
/// } on InvalidTransitionException catch (e) {
///   print('Cannot transition: $e');
/// }
/// ```
class InvalidTransitionException implements Exception {
  /// The state we're transitioning from
  final AuthStateType fromState;

  /// The state we're attempting to transition to
  final AuthStateType toState;

  /// Human-readable error message
  final String message;

  /// Creates a new invalid transition exception
  InvalidTransitionException({
    required this.fromState,
    required this.toState,
    this.message = 'Invalid state transition',
  });

  @override
  String toString() =>
      'InvalidTransitionException: $message (from $fromState to $toState)';
}

/// Exception thrown when a transition guard fails.
///
/// This exception is thrown by [AuthCoordinator.transitionTo] when
/// a guard function returns false, preventing the state transition.
///
/// Example:
/// ```dart
/// try {
///   await coordinator.transitionTo(
///     AuthenticatedState(userId: '123'),
///     guard: () async => await hasNetworkConnection(),
///   );
/// } on GuardFailedException catch (e) {
///   print('Guard prevented transition: ${e.message}');
/// }
/// ```
class GuardFailedException implements Exception {
  /// The state we're transitioning from
  final AuthStateType fromState;

  /// The state we're attempting to transition to
  final AuthStateType toState;

  /// Human-readable error message describing why the guard failed
  final String message;

  /// Creates a new guard failed exception
  GuardFailedException({
    required this.fromState,
    required this.toState,
    this.message = 'Transition guard failed',
  });

  @override
  String toString() =>
      'GuardFailedException: $message (from $fromState to $toState)';
}

/// Async function that validates whether a state transition should proceed.
///
/// Transition guards are evaluated before the state machine validates
/// the transition. If a guard returns false, the transition is prevented
/// and a [GuardFailedException] is thrown.
///
/// Example guards:
/// ```dart
/// // Network connectivity check
/// TransitionGuard hasNetworkGuard = () async {
///   final connectivity = await Connectivity().checkConnectivity();
///   return connectivity != ConnectivityResult.none;
/// };
///
/// // User consent check
/// TransitionGuard hasConsentGuard = () async {
///   return await consentService.hasUserConsented();
/// };
///
/// // Biometric availability check
/// TransitionGuard biometricAvailableGuard = () async {
///   return await LocalAuthentication().canCheckBiometrics();
/// };
/// ```
typedef TransitionGuard = Future<bool> Function();

/// Event emitted when authentication state changes.
///
/// Contains information about the state transition including
/// the from/to states, timestamp, and optional metadata.
///
/// Example:
/// ```dart
/// coordinator.stateChangeStream.listen((event) {
///   print('Transition: ${event.fromState} → ${event.toState}');
///   print('At: ${event.timestamp}');
///   print('Metadata: ${event.metadata}');
/// });
/// ```
class StateChangeEvent {
  /// The state we're transitioning from
  final AuthStateType fromState;

  /// The state we're transitioning to
  final AuthStateType toState;

  /// When the transition occurred
  final DateTime timestamp;

  /// Optional metadata about the transition
  /// (e.g., user ID, error message, guard name)
  final Map<String, dynamic>? metadata;

  /// Creates a new state change event
  const StateChangeEvent({
    required this.fromState,
    required this.toState,
    required this.timestamp,
    this.metadata,
  });

  @override
  String toString() {
    final buffer = StringBuffer('StateChangeEvent: ');
    buffer.write('$fromState → $toState ');
    buffer.write('at ${timestamp.toIso8601String()}');
    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write(' (metadata: $metadata)');
    }
    return buffer.toString();
  }
}

/// Authentication State Coordinator
///
/// Singleton service that manages authentication state transitions.
/// Acts as the central authority for auth state changes, ensuring
/// atomic transitions and maintaining state history for debugging.
///
/// Features:
/// - Singleton pattern (single instance across app)
/// - ChangeNotifier integration for Riverpod providers
/// - State history tracking (max 50 entries)
/// - Atomic state transitions (exit old → enter new)
/// - Lifecycle hook management (onEnter, onExit)
/// - State machine validation (prevents invalid transitions)
/// - Transition guards (precondition checks before transitioning)
///
/// Example usage:
/// ```dart
/// // Get coordinator instance
/// final coordinator = AuthCoordinator();
///
/// // Transition to new state
/// await coordinator.transitionTo(
///   LoggingInState(email: 'user@example.com'),
/// );
///
/// // Transition with guard (network check)
/// await coordinator.transitionTo(
///   AuthenticatedState(userId: '123'),
///   guard: () async => await hasNetworkConnection(),
/// );
///
/// // Listen to state changes (via Riverpod)
/// ref.listen(authCoordinatorProvider, (previous, next) {
///   print('State changed: ${previous?.type} → ${next.currentState.type}');
/// });
/// ```
class AuthCoordinator extends ChangeNotifier {
  // ==========================================================================
  // State Machine Transition Rules
  // ==========================================================================

  /// Valid state transitions for the authentication state machine.
  ///
  /// Defines which states can transition to which other states.
  /// Attempting a transition not in this map will throw
  /// [InvalidTransitionException].
  ///
  /// Key = source state, Value = set of valid target states
  static const Map<AuthStateType, Set<AuthStateType>> _validTransitions = {
    // User can start login process, go to PIN entry (if has PIN), or encounter an error
    AuthStateType.notAuthenticated: {
      AuthStateType.loggingIn,
      AuthStateType.pinEntry,  // For returning users with existing PIN
      AuthStateType.error,
    },

    // After logging in, check PIN setup, authenticate, or fail
    AuthStateType.loggingIn: {
      AuthStateType.checkPinSetup,
      AuthStateType.authenticated,
      AuthStateType.error,
    },

    // After checking PIN setup, go to setup or entry or error
    AuthStateType.checkPinSetup: {
      AuthStateType.pinSetup,
      AuthStateType.pinEntry,
      AuthStateType.error,
    },

    // After PIN setup, authenticate or error
    AuthStateType.pinSetup: {
      AuthStateType.authenticated,
      AuthStateType.error,
    },

    // Authenticated state has many possible transitions
    AuthStateType.authenticated: {
      AuthStateType.pinEntry,
      AuthStateType.sessionLocked,
      AuthStateType.tokenExpired,
      AuthStateType.refreshingToken, // Auto-refresh before expiry
      AuthStateType.offlineAuth,
      AuthStateType.notAuthenticated, // Logout
    },

    // After PIN entry, authenticate, lock, expire, or error
    AuthStateType.pinEntry: {
      AuthStateType.authenticated,
      AuthStateType.sessionLocked,
      AuthStateType.tokenExpired,
      AuthStateType.error,
    },

    // Token expired requires re-login or error
    AuthStateType.tokenExpired: {
      AuthStateType.notAuthenticated,
      AuthStateType.error,
    },

    // Refreshing token can succeed or fail
    AuthStateType.refreshingToken: {
      AuthStateType.authenticated, // Success
      AuthStateType.tokenRefreshFailed, // Max retries reached
    },

    // Token refresh failed requires re-login or error
    AuthStateType.tokenRefreshFailed: {
      AuthStateType.notAuthenticated, // Re-login
      AuthStateType.error,
    },

    // Session locked can be unlocked, re-entered, expired, or logged out
    AuthStateType.sessionLocked: {
      AuthStateType.authenticated,
      AuthStateType.pinEntry,
      AuthStateType.notAuthenticated,
      AuthStateType.tokenExpired,
    },

    // Offline auth can become authenticated, logged out, or expired
    AuthStateType.offlineAuth: {
      AuthStateType.authenticated,
      AuthStateType.notAuthenticated,
      AuthStateType.tokenExpired,
    },

    // Error state can retry or give up
    AuthStateType.error: {
      AuthStateType.notAuthenticated,
      AuthStateType.loggingIn,
    },
  };
  // ==========================================================================
  // Singleton Pattern
  // ==========================================================================

  /// Private internal instance
  static final AuthCoordinator _instance = AuthCoordinator._internal();

  /// Factory constructor returns the singleton instance
  factory AuthCoordinator() => _instance;

  /// Private constructor - prevents external instantiation
  AuthCoordinator._internal();

  // ==========================================================================
  // Dependencies
  // ==========================================================================

  /// Optional auth repository for performing login operations
  ///
  /// Must be set via [initialize] before using login functionality.
  AuthRepository? _authRepository;

  /// Session service for managing session lifecycle
  ///
  /// Tracks session duration and user activity for auto-lock functionality.
  final SessionService _sessionService = SessionService();

  /// Token refresh service for automatic token renewal
  ///
  /// Monitors token expiry and refreshes tokens before they expire.
  TokenRefreshService? _tokenRefreshService;

  /// Connectivity service for network monitoring
  ///
  /// Detects network connectivity changes for offline authentication.
  /// Set to null for unit tests that don't have platform plugins.
  ConnectivityService? _connectivityService;

  /// Stream subscription for connectivity changes
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// Flag to prevent multiple simultaneous session checks
  bool _isCheckingSession = false;

  /// Timer for periodic session monitoring
  Timer? _sessionMonitorTimer;

  /// Initialize the coordinator with required dependencies
  ///
  /// Call this method once during app initialization to provide
  /// the auth repository. Can be called multiple times to update
  /// the repository (e.g., in tests).
  ///
  /// This method also checks for existing sessions and restores
  /// the authentication state if valid tokens are found.
  ///
  /// Example:
  /// ```dart
  /// final coordinator = AuthCoordinator();
  /// coordinator.initialize(authRepository);
  /// ```
  void initialize(AuthRepository repository) {
    _authRepository = repository;

    // Initialize token refresh service
    _tokenRefreshService = TokenRefreshService(
      tokenManager: repository.tokenManager,
      refreshCallback: (refreshToken) async {
        // Call the repository's refresh token method
        final tokenData = await repository.refreshToken(refreshToken);
        return TokenRefreshResult.success(
          accessToken: tokenData.accessToken,
          refreshToken: tokenData.refreshToken,
          expiresIn: tokenData.expiresIn,
        );
      },
    );

    // Listen to refresh results
    _tokenRefreshService!.refreshResults.listen((result) {
      _handleTokenRefreshResult(result);
    });

    // Initialize connectivity service and listen for changes (only if not null for tests)
    if (_connectivityService != null) {
      try {
        _connectivityService!.initialize();
        _connectivitySubscription = _connectivityService!.statusStream.listen((status) {
          _handleConnectivityChange(status);
        });
      } catch (e) {
        // ConnectivityService may fail in tests without platform plugins
        debugPrint('[AuthCoordinator] Failed to initialize connectivity service: $e');
      }
    }

    // Check for existing session on initialization
    checkExistingSession();
  }

  /// Check for existing authentication session and restore state
  ///
  /// This method checks if valid tokens exist in secure storage.
  /// If found, it transitions the coordinator to the appropriate state.
  ///
  /// Called automatically during [initialize], but can also be called
  /// manually if needed (e.g., after token refresh).
  ///
  /// Example:
  /// ```dart
  /// await coordinator.checkExistingSession();
  /// ```
  Future<void> checkExistingSession() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingSession) {
      debugPrint('[AuthCoordinator] Session check already in progress, skipping');
      return;
    }

    // Skip if already authenticated or in a transitional state
    if (_currentState.type != AuthStateType.notAuthenticated &&
        _currentState.type != AuthStateType.error) {
      debugPrint('[AuthCoordinator] Already in state: ${_currentState.type}, skipping session check');
      return;
    }

    // Additional safety check: skip if in LoggingInState (transitional)
    if (_currentState.type == AuthStateType.loggingIn) {
      debugPrint('[AuthCoordinator] In LoggingInState, skipping session check to avoid conflicts');
      return;
    }

    _isCheckingSession = true;

    try {
      debugPrint('[AuthCoordinator] ========== CHECKING EXISTING SESSION ==========');

      if (_authRepository == null) {
        debugPrint('[AuthCoordinator] AuthRepository not initialized, cannot check session');
        return;
      }

      // Check if valid tokens exist
      final hasValidSession = await _authRepository!.isAuthenticated();

      debugPrint('[AuthCoordinator] Has valid session: $hasValidSession');

      if (hasValidSession) {
        // Get the current user ID from the repository
        final userId = await _authRepository!.getCurrentUserId();

        if (userId != null) {
          debugPrint('[AuthCoordinator] Found valid session for user: $userId');

          // Check if user has PIN set
          // For now, we'll go to PIN entry state. The PIN pages will handle
          // the flow of checking if PIN exists and routing appropriately.
          await transitionTo(
            PinEntryState(
              userId: userId,
            ),
          );

          debugPrint('[AuthCoordinator] ✅ Session restored to PIN entry state');
        } else {
          debugPrint('[AuthCoordinator] ⚠️ Valid session but no user found, staying in NotAuthenticatedState');
        }
      } else {
        debugPrint('[AuthCoordinator] No valid session found, staying in NotAuthenticatedState');
      }
    } catch (e) {
      debugPrint('[AuthCoordinator] ❌ Error checking existing session: $e');
      // Stay in NotAuthenticatedState on error
    } finally {
      _isCheckingSession = false;
    }
  }

  // ==========================================================================
  // Session Monitoring
  // ==========================================================================

  /// Start periodic session monitoring
  ///
  /// Checks every second for:
  /// - Session lock (15 minutes of inactivity)
  /// - Session expiry (8 hours maximum duration)
  ///
  /// Automatically called when user authenticates.
  void _startSessionMonitoring() {
    _stopSessionMonitoring();

    _sessionMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Fire and forget - don't await the future
      _checkSessionStatus();
    });

    debugPrint('[AuthCoordinator] Session monitoring started');
  }

  /// Stop session monitoring timer
  ///
  /// Called when user logs out or coordinator is disposed.
  void _stopSessionMonitoring() {
    _sessionMonitorTimer?.cancel();
    _sessionMonitorTimer = null;
  }

  /// Check session status and transition if needed
  ///
  /// Called every second by the session monitor timer.
  /// Handles:
  /// - Session lock (15 min inactivity) → SessionLockedState
  /// - Session expiry (8 hours) → NotAuthenticatedState
  Future<void> _checkSessionStatus() async {
    // Only check if currently authenticated
    if (_currentState.type != AuthStateType.authenticated) {
      return;
    }

    // Check for session lock (15 minutes of inactivity)
    if (_sessionService.isLocked) {
      debugPrint('[AuthCoordinator] ⚠️ Session locked due to inactivity');
      _stopSessionMonitoring();

      // Get current user ID from repository if available
      String? userId;
      if (_authRepository != null) {
        userId = await _authRepository!.getCurrentUserId();
      }

      if (userId != null) {
        transitionTo(SessionLockedState(
          userId: userId,
          lockedAt: DateTime.now(),
        ));
      } else {
        // If we can't get user ID, just go to not authenticated
        transitionTo(NotAuthenticatedState());
      }
      return;
    }

    // Check for session expiry (8 hours)
    if (_sessionService.isSessionExpired()) {
      debugPrint('[AuthCoordinator] ⚠️ Session expired (8 hours)');
      _stopSessionMonitoring();
      transitionTo(NotAuthenticatedState());
      return;
    }
  }

  /// Record user activity
  ///
  /// Should be called whenever user interacts with the app.
  /// Resets the inactivity timer.
  ///
  /// Example:
  /// ```dart
  /// coordinator.recordActivity();
  /// ```
  void recordActivity() {
    _sessionService.recordActivity();
  }

  /// Get the session service for external access
  ///
  /// Allows widgets and services to record activity.
  SessionService get sessionService => _sessionService;

  // ==========================================================================
  // Token Refresh Management
  // ==========================================================================

  /// Handle token refresh results
  ///
  /// Called when TokenRefreshService completes a refresh operation.
  /// Transitions to appropriate state based on result.
  void _handleTokenRefreshResult(TokenRefreshResult result) {
    if (result.success) {
      debugPrint('[AuthCoordinator] ✅ Token refresh successful');
      // If we were in RefreshingTokenState, transition back to AuthenticatedState
      if (_currentState.type == AuthStateType.refreshingToken) {
        // Get current user ID
        final userId = _currentState.metadata['userId'] as String?;
        if (userId != null) {
          transitionTo(AuthenticatedState(userId: userId));
        }
      }
    } else {
      debugPrint('[AuthCoordinator] ❌ Token refresh failed: ${result.error} (attempt ${result.attempt})');

      // If max retries reached, transition to TokenRefreshFailedState
      if (result.attempt >= TokenRefreshService.maxRetryAttempts) {
        debugPrint('[AuthCoordinator] Max retry attempts reached, transitioning to TokenRefreshFailedState');

        final userId = _currentState.metadata['userId'] as String?;
        transitionTo(TokenRefreshFailedState(
          error: result.error ?? 'Token refresh failed',
          lastAttempt: result.attempt,
          metadata: userId != null ? {'userId': userId} : const {},
        ));
      }
    }
  }

  /// Manually trigger token refresh
  ///
  /// Call this when you receive a 401 error from the API.
  /// Transitions to RefreshingTokenState and triggers immediate refresh.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await apiCall();
  /// } on UnauthorizedException {
  ///   await coordinator.refreshToken();
  /// }
  /// ```
  Future<void> refreshToken() async {
    if (_tokenRefreshService == null) {
      debugPrint('[AuthCoordinator] TokenRefreshService not initialized');
      return;
    }

    // Get current user ID before transitioning
    final userId = await _authRepository?.getCurrentUserId();

    // Transition to RefreshingTokenState
    if (userId != null) {
      await transitionTo(RefreshingTokenState(
        metadata: {'userId': userId, 'reason': 'Manual token refresh requested'},
      ));
    }

    // Trigger immediate refresh
    final result = await _tokenRefreshService!.refreshNow();

    // Handle result
    _handleTokenRefreshResult(result);
  }

  // ==========================================================================
  // Offline Authentication Management
  // ==========================================================================

  /// Handle connectivity changes
  ///
  /// Called when network connectivity changes between online and offline.
  /// Manages transition to/from OfflineAuthState based on connectivity.
  void _handleConnectivityChange(ConnectivityStatus status) {
    debugPrint('[AuthCoordinator] Connectivity changed: $status');

    // Only handle connectivity changes when authenticated
    if (_currentState.type != AuthStateType.authenticated) {
      return;
    }

    if (status == ConnectivityStatus.offline) {
      debugPrint('[AuthCoordinator] Network lost, transitioning to OfflineAuthState');

      // Get current user ID and calculate grace period
      final userId = _currentState.metadata['userId'] as String?;
      if (userId != null) {
        // Calculate grace period (24 hours from last online login)
        final gracePeriod = Duration(hours: 24);

        transitionTo(OfflineAuthState(
          userId: userId,
          gracePeriodRemaining: gracePeriod,
        ));
      }
    } else if (status == ConnectivityStatus.online && _currentState.type == AuthStateType.offlineAuth) {
      debugPrint('[AuthCoordinator] Network restored, transitioning back to AuthenticatedState');

      // Get user ID from offline state
      if (_currentState is OfflineAuthState) {
        final offlineState = _currentState as OfflineAuthState;
        transitionTo(AuthenticatedState(userId: offlineState.userId));
      }
    }
  }

  /// Flag to prevent operations after disposal
  bool _mounted = true;

  /// Check if coordinator is still mounted
  ///
  /// Returns false after disposal, preventing timer callbacks
  /// from executing after the coordinator is cleaned up.
  bool get mounted => _mounted;

  // ==========================================================================
  // State Management
  // ==========================================================================

  /// Current active authentication state
  ///
  /// Starts as [NotAuthenticatedState] when app launches.
  /// Use [transitionTo] to change to a new state.
  AuthState _currentState = NotAuthenticatedState();

  /// History of all states the coordinator has transitioned through
  ///
  /// Maintains up to 50 previous states for debugging and audit trails.
  /// Returned as unmodifiable list to prevent external mutations.
  final List<AuthState> _stateHistory = [];

  /// Stream controller for state change events
  ///
  /// Broadcast stream allows multiple listeners to receive state change events.
  /// Events are emitted after every successful state transition.
  final StreamController<StateChangeEvent> _stateChangeController =
      StreamController<StateChangeEvent>.broadcast();

  // ==========================================================================
  // Getters
  // ==========================================================================

  /// Get the current authentication state
  ///
  /// This is the primary way to check what state the auth flow is in.
  /// For reactive updates, use [authCoordinatorProvider] with Riverpod.
  AuthState get currentState => _currentState;

  /// Get complete state history (unmodifiable)
  ///
  /// Returns a read-only list of all previous states in chronological order.
  /// Useful for debugging and understanding how the app reached its current state.
  List<AuthState> get stateHistory => List.unmodifiable(_stateHistory);

  /// Stream of state change events
  ///
  /// Broadcast stream that emits an event on every successful state transition.
  /// Multiple listeners can subscribe to this stream.
  ///
  /// Example:
  /// ```dart
  /// // Listen to all state changes
  /// coordinator.stateChangeStream.listen((event) {
  ///   print('State changed: ${event.fromState} → ${event.toState}');
  /// });
  ///
  /// // Listen in a widget
  /// StreamBuilder<StateChangeEvent>(
  ///   stream: coordinator.stateChangeStream,
  ///   builder: (context, snapshot) {
  ///     if (snapshot.hasData) {
  ///       return Text('State: ${snapshot.data!.toState}');
  ///     }
  ///     return CircularProgressIndicator();
  ///   },
  /// );
  /// ```
  Stream<StateChangeEvent> get stateChangeStream =>
      _stateChangeController.stream;

  // ==========================================================================
  // State Transitions
  // ==========================================================================

  /// Validates if a state transition is allowed by the state machine rules.
  ///
  /// Returns true if the transition from [from] to [to] is valid,
  /// false otherwise. Uses [_validTransitions] map to check allowed transitions.
  ///
  /// Example:
  /// ```dart
  /// final isValid = _isValidTransition(
  ///   AuthStateType.notAuthenticated,
  ///   AuthStateType.loggingIn,
  /// ); // true
  /// ```
  bool _isValidTransition(AuthStateType from, AuthStateType to) {
    final validTargets = _validTransitions[from];
    return validTargets?.contains(to) ?? false;
  }

  /// Transition to a new authentication state
  ///
  /// Performs an atomic state transition with proper lifecycle management:
  /// 1. Evaluates guard if provided (throws [GuardFailedException] if false)
  /// 2. Validates the transition is allowed (throws if not)
  /// 3. Calls onExit() on current state
  /// 4. Adds current state to history (max 50 entries)
  /// 5. Sets new state as current
  /// 6. Calls onEnter() on new state
  /// 7. Handles special state logic (e.g., login for LoggingInState)
  /// 8. Notifies all listeners (triggers Riverpod rebuilds)
  ///
  /// Example:
  /// ```dart
  /// // Simple transition
  /// await coordinator.transitionTo(
  ///   AuthenticatedState(userId: 'user-123'),
  /// );
  ///
  /// // Transition with guard (network check)
  /// await coordinator.transitionTo(
  ///   AuthenticatedState(userId: 'user-123'),
  ///   guard: () async {
  ///     final connectivity = await Connectivity().checkConnectivity();
  ///     return connectivity != ConnectivityResult.none;
  ///   },
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [newState] The state to transition to. Must be a concrete AuthState subclass.
  /// - [guard] Optional async function that returns true if transition should proceed.
  ///   If provided, evaluated before state machine validation. Returns false to prevent
  ///   transition and throw [GuardFailedException].
  ///
  /// Throws:
  /// - [GuardFailedException] if guard returns false
  /// - [InvalidTransitionException] if the transition is not allowed by state machine
  /// - StateError if transition fails (e.g., onEnter/onExit throws)
  ///
  /// See also:
  /// - [AuthState.onEnter] - Called when entering a state
  /// - [AuthState.onExit] - Called when exiting a state
  /// - [TransitionGuard] - Guard function signature
  /// - [canTransitionTo] - Check if transition is valid without executing
  /// - [_validTransitions] - State machine transition rules
  /// - [_isValidTransition] - Transition validation logic
  Future<void> transitionTo(
    AuthState newState, {
    TransitionGuard? guard,
  }) async {
    // Debug logging - show coordinator instance and current state
    debugPrint('[AuthCoordinator] ========== TRANSITION REQUEST ==========');
    debugPrint('[AuthCoordinator] Coordinator instance: ${hashCode}');
    debugPrint('[AuthCoordinator] Current state type: ${_currentState.type}');
    debugPrint('[AuthCoordinator] Current state runtime type: ${_currentState.runtimeType}');
    debugPrint('[AuthCoordinator] Requested transition to: ${newState.type}');
    debugPrint('[AuthCoordinator] New state runtime type: ${newState.runtimeType}');

    // Evaluate guard before state machine validation
    if (guard != null) {
      final guardPassed = await guard();
      if (!guardPassed) {
        throw GuardFailedException(
          fromState: _currentState.type,
          toState: newState.type,
          message: 'Transition guard prevented transition from ${_currentState.type} to ${newState.type}',
        );
      }
    }

    // Debug logging
    debugPrint('[AuthCoordinator] Attempting transition from ${_currentState.type} to ${newState.type}');
    debugPrint('[AuthCoordinator] Current state runtime type: ${_currentState.runtimeType}');
    debugPrint('[AuthCoordinator] New state runtime type: ${newState.runtimeType}');

    // Validate transition is allowed by state machine rules
    if (!_isValidTransition(_currentState.type, newState.type)) {
      debugPrint('[AuthCoordinator] ❌ Invalid transition! From: ${_currentState.type}, To: ${newState.type}');
      throw InvalidTransitionException(
        fromState: _currentState.type,
        toState: newState.type,
        message: 'Cannot transition from ${_currentState.type} to ${newState.type}',
      );
    }

    // Exit current state (cleanup timers, close streams, etc.)
    await _currentState.onExit();

    // Add current state to history before transitioning
    _stateHistory.add(_currentState);

    // Keep only the last 50 states to prevent unbounded memory growth
    if (_stateHistory.length > 50) {
      _stateHistory.removeAt(0);
    }

    // Set new state as current
    _currentState = newState;

    // Enter new state (start timers, load data, trigger side effects)
    await _currentState.onEnter();

    // Handle session lifecycle
    if (_stateHistory.last.type == AuthStateType.authenticated &&
        newState.type != AuthStateType.authenticated) {
      // Leaving authenticated state - stop session monitoring
      debugPrint('[AuthCoordinator] Leaving authenticated state, stopping session monitoring');
      _stopSessionMonitoring();
      _sessionService.endSession();

      // Stop token refresh monitoring
      if (_tokenRefreshService != null) {
        debugPrint('[AuthCoordinator] Stopping token refresh monitoring');
        _tokenRefreshService!.stopMonitoring();
      }
    } else if (_stateHistory.last.type != AuthStateType.authenticated &&
        newState.type == AuthStateType.authenticated) {
      // Entering authenticated state - start session
      debugPrint('[AuthCoordinator] Entering authenticated state, starting session');
      _sessionService.startSession();
      _startSessionMonitoring();

      // Start token refresh monitoring
      if (_tokenRefreshService != null) {
        debugPrint('[AuthCoordinator] Starting token refresh monitoring');
        _tokenRefreshService!.startMonitoring();
      }
    }

    // Handle special state logic
    if (newState is LoggingInState) {
      await _handleLoggingIn(newState);
    }

    // Emit state change event
    final event = StateChangeEvent(
      fromState: _stateHistory.last.type,
      toState: _currentState.type,
      timestamp: DateTime.now(),
    );
    _stateChangeController.add(event);

    // Notify all listeners (triggers Riverpod provider rebuilds)
    notifyListeners();
  }

  /// Handle the login process for LoggingInState
  ///
  /// This method is called automatically after transitioning to LoggingInState.
  /// It performs the actual login API call and transitions to the appropriate
  /// next state based on the result.
  Future<void> _handleLoggingIn(LoggingInState state) async {
    if (_authRepository == null) {
      debugPrint('AuthCoordinator: AuthRepository not initialized, cannot perform login');
      await transitionTo(
        ErrorState(
          errorMessage: 'Authentication service not available',
          errorType: 'AuthServiceNotAvailable',
        ),
      );
      return;
    }

    try {
      debugPrint('AuthCoordinator: Attempting login for ${state.email}');
      final tokenData = await _authRepository!.login(state.email, state.password);
      debugPrint('AuthCoordinator: Login successful, userId: ${tokenData.userId}');

      // CRITICAL: Update JwtAuthService with tokens for PowerSync compatibility
      // JwtAuthService is used by PowerSync connector and API services
      // TokenManager stores tokens in secure storage, but JwtAuthService needs them too
      try {
        final jwtAuth = JwtAuthService.instance;

        // Update cached tokens in JwtAuthService without making API calls
        await jwtAuth.updateCachedTokens(
          accessToken: tokenData.accessToken,
          refreshToken: tokenData.refreshToken,
        );

        // Re-initialize to parse user from JWT token
        await jwtAuth.initialize();
        debugPrint('AuthCoordinator: JwtAuthService updated with tokens, user: ${jwtAuth.currentUser?.email}');

        // Connect to PowerSync after successful login
        // NOTE: PowerSync connection failures should NOT affect login success
        try {
          debugPrint('AuthCoordinator: Connecting to PowerSync...');
          final connector = IMUPowerSyncConnector(
            authService: jwtAuth,
            powersyncUrl: AppConfig.powerSyncUrl,
            apiUrl: AppConfig.postgresApiUrl,
          );
          await PowerSyncService.connect(connector);
          debugPrint('AuthCoordinator: PowerSync connected successfully');
        } catch (e) {
          // Log the error but DON'T fail the login
          // PowerSync sync errors are non-critical - app can still function
          debugPrint('AuthCoordinator: PowerSync connection failed (app will continue without sync): $e');
        }
      } catch (e) {
        debugPrint('AuthCoordinator: Failed to update JwtAuthService: $e');
        // Continue anyway - login was successful
      }

      // DISABLED: PIN flow - going directly to AuthenticatedState
      // // Transition to check PIN setup state
      // await transitionTo(
      //   CheckPinSetupState(userId: tokenData.userId ?? 'unknown'),
      // );

      // Transition directly to AuthenticatedState (PIN flow disabled)
      await transitionTo(
        AuthenticatedState(
          userId: tokenData.userId ?? 'unknown',
        ),
      );
    } catch (e) {
      debugPrint('AuthCoordinator: Login failed: $e');
      await transitionTo(
        ErrorState(
          errorMessage: e.toString(),
          errorType: 'LoginFailed',
        ),
      );
    }
  }

  /// Check if a transition to the given state type is valid
  ///
  /// Returns true if the transition from current state to [targetState]
  /// is allowed by the state machine rules, false otherwise.
  ///
  /// This is a convenience method for checking transitions without
  /// attempting them. Does NOT evaluate guards - only checks state machine
  /// validation rules.
  ///
  /// Example:
  /// ```dart
  /// // Check before transitioning (UI-based conditional logic)
  /// if (coordinator.canTransitionTo(AuthStateType.authenticated)) {
  ///   // Show "Continue" button
  /// } else {
  ///   // Show disabled button
  /// }
  ///
  /// // Check with guard evaluation
  /// final canProceed = coordinator.canTransitionTo(AuthStateType.authenticated) &&
  ///     await hasNetworkConnection();
  /// ```
  ///
  /// Parameters:
  /// - [targetState] The state type to check if we can transition to
  ///
  /// Returns:
  /// - true if transition is valid per state machine rules
  /// - false if transition is not allowed
  ///
  /// See also:
  /// - [transitionTo] - Execute the transition
  /// - [_isValidTransition] - Internal validation logic
  bool canTransitionTo(AuthStateType targetState) {
    return _isValidTransition(_currentState.type, targetState);
  }

  // ==========================================================================
  // Utility Methods
  // ==========================================================================

  /// Check if current state matches the given type
  ///
  /// Convenience method to avoid type checking boilerplate.
  ///
  /// Example:
  /// ```dart
  /// if (coordinator.isState(AuthStateType.authenticated)) {
  ///   // User is logged in
  /// }
  /// ```
  bool isState(AuthStateType type) {
    return _currentState.type == type;
  }

  /// Get state history as a list of state types
  ///
  /// Returns a simplified view of state history containing only
  /// the state types (not full state objects). Useful for logging.
  ///
  /// Example:
  /// ```dart
  /// final types = coordinator.stateHistoryTypes;
  /// // [notAuthenticated, loggingIn, checkPinSetup, pinEntry, authenticated]
  /// ```
  List<AuthStateType> get stateHistoryTypes {
    return _stateHistory.map((state) => state.type).toList();
  }

  /// Clear state history
  ///
  /// Removes all historical state entries. Useful for testing or
  /// privacy cleanup. Does NOT affect the current state.
  void clearHistory() {
    _stateHistory.clear();
    notifyListeners();
  }

  /// Reset coordinator to initial state
  ///
  /// Transitions back to [NotAuthenticatedState] and clears history.
  /// Primarily useful for testing and logout scenarios.
  ///
  /// Example:
  /// ```dart
  /// await coordinator.reset();
  /// // Coordinator is now in NotAuthenticatedState with empty history
  /// ```
  Future<void> reset() async {
    // Bypass normal transition validation for reset
    await _currentState.onExit();
    _currentState = NotAuthenticatedState();
    _stateHistory.clear();
    await _currentState.onEnter();
    notifyListeners();
  }

  @override
  String toString() {
    final buffer = StringBuffer('AuthCoordinator\n');
    buffer.write('  Current State: ${_currentState.type}\n');
    buffer.write('  State History: ${_stateHistory.length} entries\n');
    if (_stateHistory.isNotEmpty) {
      buffer.write('  Last 5 states: ');
      final recentStates = _stateHistory.length > 5
          ? _stateHistory.skip(_stateHistory.length - 5)
          : _stateHistory;
      buffer.writeAll(
        recentStates.map((s) => s.type.toString()),
        ' → ',
      );
    }
    return buffer.toString();
  }

  /// Dispose of resources
  ///
  /// Closes the state change stream controller to prevent memory leaks.
  /// Call this when the coordinator is no longer needed (typically in
  /// ProviderContainer dispose or app dispose).
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   AuthCoordinator().dispose();
  ///   super.dispose();
  /// }
  /// ```
  ///
  /// Note: Since AuthCoordinator is a singleton, be careful about disposing
  /// it while it's still in use. Only dispose when the app is shutting down
  /// or the coordinator is explicitly no longer needed.
  @override
  void dispose() {
    _stopSessionMonitoring();
    _connectivitySubscription?.cancel();
    _tokenRefreshService?.stopMonitoring();
    _stateChangeController.close();
    _mounted = false;
    super.dispose();
  }
}
