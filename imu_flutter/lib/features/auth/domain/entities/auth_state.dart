library;

import 'package:imu_flutter/services/auth/secure_storage_service.dart';
import '../services/auth_coordinator.dart';

/// Authentication State Machine Foundation
///
/// This file defines the core state machine architecture for IMU authentication.
/// It eliminates recurring authentication issues by providing a single source of truth
/// for auth state with explicit transitions and lifecycle management.
///
/// States follow a strict transition pattern and support:
/// - Timeout handling for security
/// - Metadata for context-specific data
/// - Lifecycle hooks (onEnter, onExit, onTimeout)
/// - Type-safe state transitions

/// Authentication state types representing all possible states in the auth flow
enum AuthStateType {
  /// User is not authenticated - initial state
  notAuthenticated,

  /// User is in the process of logging in with credentials
  loggingIn,

  /// Checking if user has PIN setup configured
  checkPinSetup,

  /// User is setting up their PIN for first time or reset
  pinSetup,

  /// User is fully authenticated and can access the app
  authenticated,

  /// User needs to enter PIN to verify their identity
  pinEntry,

  /// Authentication token has expired, needs refresh or re-login
  tokenExpired,

  /// Refreshing authentication token (silent operation)
  refreshingToken,

  /// Token refresh failed, needs retry or re-login
  tokenRefreshFailed,

  /// Session is locked due to inactivity or security reasons
  sessionLocked,

  /// User is authenticated in offline mode (cached credentials)
  offlineAuth,

  /// Error state - something went wrong during authentication
  error,
}

/// Base class for all authentication states
///
/// Provides common properties and lifecycle hooks for state management.
/// All concrete auth states should extend this class.
///
/// Example usage:
/// ```dart
/// class LoggingInState extends AuthState {
///   LoggingInState() : super(
///     type: AuthStateType.loggingIn,
///     timeout: Duration(seconds: 30),
///   );
///
///   @override
///   Future<void> onEnter() async {
///     // Start login process
///   }
///
///   @override
///   void onTimeout() {
///     // Handle login timeout
///   }
/// }
/// ```
abstract class AuthState {
  /// The type of this authentication state
  final AuthStateType type;

  /// Timestamp when this state was entered
  final DateTime? enteredAt;

  /// Optional timeout duration for this state
  ///
  /// Used for security (auto-lock) and UX (prevent infinite loading)
  final Duration? timeout;

  /// Context-specific data for this state instance.
  ///
  /// Each concrete AuthState implementation should document its expected
  /// metadata structure. Common metadata keys include:
  /// - 'userId': String - User ID for authenticated states
  /// - 'error': String - Error message for error states
  /// - 'reason': String - Transition reason for debugging
  /// - 'attempts': int - Retry attempt counter
  final Map<String, dynamic> metadata;

  /// Creates a new AuthState instance
  const AuthState({
    required this.type,
    this.enteredAt,
    this.timeout,
    this.metadata = const {},
  });

  /// Called when entering this state
  ///
  /// Override this method to perform initialization logic,
  /// such as starting timers, loading data, or triggering side effects.
  ///
  /// Lifecycle methods (onEnter, onExit, onTimeout) are guaranteed to be
  /// called sequentially by AuthCoordinator - never concurrently.
  /// State transitions are atomic: exit(old state) -> enter(new state).
  Future<void> onEnter() async {}

  /// Called when exiting this state
  ///
  /// Override this method to perform cleanup logic,
  /// such as canceling timers, closing streams, or saving state.
  ///
  /// Lifecycle methods (onEnter, onExit, onTimeout) are guaranteed to be
  /// called sequentially by AuthCoordinator - never concurrently.
  /// State transitions are atomic: exit(old state) -> enter(new state).
  Future<void> onExit() async {}

  /// Called when this state times out
  ///
  /// Only called if [timeout] is set and the duration elapses.
  /// Override this to handle timeout scenarios (e.g., transition to error state).
  ///
  /// Lifecycle methods (onEnter, onExit, onTimeout) are guaranteed to be
  /// called sequentially by AuthCoordinator - never concurrently.
  /// State transitions are atomic: exit(old state) -> enter(new state).
  void onTimeout() {}

  /// Check if this state has timed out
  ///
  /// Returns true if:
  /// - [timeout] is set
  /// - [enteredAt] is set
  /// - The elapsed time since [enteredAt] exceeds [timeout]
  bool get isTimedOut {
    if (timeout == null || enteredAt == null) return false;
    return DateTime.now().isAfter(enteredAt!.add(timeout!));
  }

  /// Get remaining time before timeout
  ///
  /// Returns null if no timeout is set or if already timed out.
  Duration? get remainingTime {
    if (timeout == null || enteredAt == null) return null;
    final timeoutTime = enteredAt!.add(timeout!);
    final remaining = timeoutTime.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  /// Create a copy of this state with modified properties
  ///
  /// Useful for state transitions while preserving metadata.
  AuthState copyWith({
    AuthStateType? type,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AuthState.$type');
    if (enteredAt != null) {
      buffer.write(', enteredAt: $enteredAt');
    }
    if (timeout != null) {
      buffer.write(', timeout: $timeout');
    }
    if (metadata.isNotEmpty) {
      buffer.write(', metadata: $metadata');
    }
    return buffer.toString();
  }

  /// Compares states for equality.
  ///
  /// Metadata is intentionally excluded from equality comparison because:
  /// - Metadata represents contextual data (timestamps, error messages, etc.)
  /// - State identity is determined by type + timing, not context
  /// - This allows state comparison even when metadata differs (e.g., retry attempts)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.type == type &&
        other.enteredAt == enteredAt &&
        other.timeout == timeout;
  }

  @override
  int get hashCode => Object.hash(type, enteredAt, timeout);
}

// =============================================================================
// CONCRETE AUTH STATE IMPLEMENTATIONS
// =============================================================================

/// Initial state when no user is logged in.
///
/// This is the starting state of the authentication state machine.
/// Transitions to [LoggingInState] when user initiates login.
///
/// Example:
/// ```dart
/// final state = NotAuthenticatedState();
/// coordinator.transitionTo(state);
/// ```
class NotAuthenticatedState extends AuthState {
  NotAuthenticatedState({
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.notAuthenticated,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: metadata,
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return NotAuthenticatedState(
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when user is in the process of logging in with credentials.
///
/// Transitions to [CheckPinSetupState] on successful credential validation,
/// or [ErrorState] on failure.
///
/// Example:
/// ```dart
/// final state = LoggingInState(email: 'user@example.com', password: 'password123');
/// coordinator.transitionTo(state);
/// ```
class LoggingInState extends AuthState {
  /// User's email address for login
  final String email;

  /// User's password for login
  final String password;

  LoggingInState({
    required this.email,
    required this.password,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.loggingIn,
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(seconds: 30), // Default 30s timeout
    metadata: _mergeMetadata(metadata, {'email': email}),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? email,
    String? password,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    final newEmail = email ?? this.email;
    final newPassword = password ?? this.password;
    return LoggingInState(
      email: newEmail,
      password: newPassword,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when checking if user has PIN setup configured.
///
/// This is an intermediate state during login flow that checks
/// whether the user needs to set up a PIN (first-time) or enter
/// existing PIN (returning user).
///
/// Transitions to:
/// - [PinSetupState] if user has no PIN (first-time)
/// - [PinEntryState] if user has PIN (returning user)
/// - [ErrorState] on check failure
///
/// Example:
/// ```dart
/// final state = CheckPinSetupState(userId: 'user-123');
/// coordinator.transitionTo(state);
/// ```
class CheckPinSetupState extends AuthState {
  /// User ID to check PIN setup status for
  final String userId;

  CheckPinSetupState({
    required this.userId,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.checkPinSetup,
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(seconds: 10), // Default 10s timeout
    metadata: _mergeMetadata(metadata, {'userId': userId}),
  );

  @override
  Future<void> onEnter() async {
    // Auto-transition to appropriate state based on PIN status
    // This must be done synchronously to prevent router from redirecting
    // while we're still in CheckPinSetupState
    try {
      // Import here to avoid circular dependency
      final secureStorageService = SecureStorageService();

      // Check if user has a PIN set up
      final hasPin = await secureStorageService.hasPin();

      // Get the coordinator to perform the transition
      final coordinator = AuthCoordinator();

      if (hasPin) {
        // User has PIN - go to PIN entry
        await coordinator.transitionTo(
          PinEntryState(userId: userId),
        );
      } else {
        // User doesn't have PIN - go to PIN setup
        await coordinator.transitionTo(
          PinSetupState(userId: userId),
        );
      }
    } catch (e) {
      // If check fails, transition to error state
      final coordinator = AuthCoordinator();
      await coordinator.transitionTo(
        ErrorState(
          errorMessage: 'Failed to check PIN setup status: $e',
          errorType: 'PinSetupCheckFailed',
        ),
      );
    }
  }

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return CheckPinSetupState(
      userId: userId ?? this.userId,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when user needs to create a PIN (first-time setup or reset).
///
/// User is prompted to create a 6-digit PIN for quick authentication.
/// After PIN creation, transitions to [AuthenticatedState].
///
/// Example:
/// ```dart
/// final state = PinSetupState(userId: 'user-123');
/// coordinator.transitionTo(state);
/// ```
class PinSetupState extends AuthState {
  /// User ID who is creating the PIN
  final String userId;

  PinSetupState({
    required this.userId,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.pinSetup,
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(minutes: 5), // Default 5min timeout
    metadata: _mergeMetadata(metadata, {'userId': userId}),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return PinSetupState(
      userId: userId ?? this.userId,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when user is fully authenticated and can access the app.
///
/// This is the active state when user is logged in and can use all features.
/// Can transition to [SessionLockedState] on inactivity or [TokenExpiredState]
/// when token expires.
///
/// Example:
/// ```dart
/// // Without PIN (first time setup)
/// final state = AuthenticatedState(userId: 'user-123');
///
/// // With PIN (during PIN setup)
/// final state = AuthenticatedState(userId: 'user-123', pin: '123456');
/// coordinator.transitionTo(state);
/// ```
class AuthenticatedState extends AuthState {
  /// Authenticated user's ID
  final String userId;

  /// Optional PIN (provided during setup, not stored for security)
  final String? pin;

  AuthenticatedState({
    required this.userId,
    this.pin,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.authenticated,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {
      'userId': userId,
      if (pin != null) 'hasPin': true,
    }),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    String? pin,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return AuthenticatedState(
      userId: userId ?? this.userId,
      pin: pin ?? this.pin,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when user needs to enter PIN to verify their identity.
///
/// Used for returning users who already have a PIN set up.
/// After successful PIN entry, transitions to [AuthenticatedState].
///
/// Example:
/// ```dart
/// final state = PinEntryState(
///   userId: 'user-123',
///   remainingAttempts: 3,
/// );
/// coordinator.transitionTo(state);
/// ```
class PinEntryState extends AuthState {
  /// User ID for PIN verification
  final String userId;

  /// Number of remaining attempts before lockout
  final int remainingAttempts;

  /// When the lockout expires (null if not locked out)
  final DateTime? lockoutUntil;

  PinEntryState({
    required this.userId,
    this.remainingAttempts = 5,
    this.lockoutUntil,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.pinEntry,
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(minutes: 5), // Default 5min timeout
    metadata: _mergeMetadata(metadata, {
      'userId': userId,
      'remainingAttempts': remainingAttempts,
      if (lockoutUntil != null) 'lockoutUntil': lockoutUntil,
    }),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    int? remainingAttempts,
    DateTime? lockoutUntil,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return PinEntryState(
      userId: userId ?? this.userId,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when authenticating with PIN (intermediate state).
///
/// This is a transient state while the PIN is being validated.
/// Transitions to [AuthenticatedState] on success or [PinEntryState] on failure.
///
/// Example:
/// ```dart
/// final state = AuthenticatingWithPinState(pin: '123456');
/// coordinator.transitionTo(state);
/// ```
class AuthenticatingWithPinState extends AuthState {
  /// The PIN being authenticated
  final String pin;

  AuthenticatingWithPinState({
    required this.pin,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.pinEntry, // Use pinEntry type since this is part of PIN flow
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(seconds: 10), // Default 10s timeout
    metadata: _mergeMetadata(metadata, {'authenticating': true}),
  );

  @override
  AuthState copyWith({
    String? pin,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return AuthenticatingWithPinState(
      pin: pin ?? this.pin,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when authentication token has expired.
///
/// User needs to re-login with password. Can occur due to:
/// - Token expiration (e.g., 8-hour session timeout)
/// - Security events requiring re-authentication
/// - Server-side token invalidation
///
/// Transitions to [LoggingInState] when user initiates re-login.
///
/// Example:
/// ```dart
/// final state = TokenExpiredState(
///   reason: 'Session expired after 8 hours of inactivity',
/// );
/// coordinator.transitionTo(state);
/// ```
class TokenExpiredState extends AuthState {
  /// Reason why the token expired
  final String reason;

  TokenExpiredState({
    required this.reason,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.tokenExpired,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {'reason': reason}),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? reason,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return TokenExpiredState(
      reason: reason ?? this.reason,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when refreshing authentication token (silent operation).
///
/// This is a transient state while the token is being refreshed.
/// User can continue using the app during refresh.
/// Transitions to [AuthenticatedState] on success or [TokenRefreshFailedState] on failure.
///
/// Example:
/// ```dart
/// final state = RefreshingTokenState(
///   attempt: 1,
/// );
/// coordinator.transitionTo(state);
/// ```
class RefreshingTokenState extends AuthState {
  /// Current retry attempt (0 for first attempt)
  final int attempt;

  RefreshingTokenState({
    this.attempt = 0,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.refreshingToken,
    enteredAt: enteredAt,
    timeout: timeout ?? const Duration(seconds: 30), // Default 30s timeout
    metadata: _mergeMetadata(metadata, {'attempt': attempt}),
  );

  @override
  AuthState copyWith({
    int? attempt,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return RefreshingTokenState(
      attempt: attempt ?? this.attempt,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when token refresh has failed.
///
/// Occurs when token refresh fails after max retry attempts.
/// User needs to re-login with credentials.
///
/// Example:
/// ```dart
/// final state = TokenRefreshFailedState(
///   error: 'Network error during token refresh',
///   lastAttempt: 3,
/// );
/// coordinator.transitionTo(state);
/// ```
class TokenRefreshFailedState extends AuthState {
  /// Error message describing why refresh failed
  final String error;

  /// Last retry attempt number
  final int lastAttempt;

  TokenRefreshFailedState({
    required this.error,
    this.lastAttempt = 0,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.tokenRefreshFailed,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {
      'error': error,
      'lastAttempt': lastAttempt,
    }),
  );

  @override
  AuthState copyWith({
    String? error,
    int? lastAttempt,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return TokenRefreshFailedState(
      error: error ?? this.error,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when session is locked due to inactivity or security reasons.
///
/// Occurs after 15 minutes of user inactivity (auto-lock feature).
/// User can unlock with PIN or biometrics. Does NOT require full re-login.
///
/// Differs from [TokenExpiredState] which requires password re-login.
///
/// Example:
/// ```dart
/// final state = SessionLockedState(
///   userId: 'user-123',
///   lockedAt: DateTime.now(),
/// );
/// coordinator.transitionTo(state);
/// ```
class SessionLockedState extends AuthState {
  /// User whose session is locked
  final String userId;

  /// Timestamp when session was locked
  final DateTime lockedAt;

  SessionLockedState({
    required this.userId,
    required this.lockedAt,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.sessionLocked,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {'userId': userId, 'lockedAt': lockedAt}),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    DateTime? lockedAt,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return SessionLockedState(
      userId: userId ?? this.userId,
      lockedAt: lockedAt ?? this.lockedAt,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// State when user is authenticated in offline mode with cached credentials.
///
/// Allows limited app access when network is unavailable.
/// Has a grace period before requiring online authentication.
///
/// Example:
/// ```dart
/// final state = OfflineAuthState(
///   userId: 'user-123',
///   gracePeriodRemaining: Duration(hours: 24),
/// );
/// coordinator.transitionTo(state);
/// ```
class OfflineAuthState extends AuthState {
  /// User ID authenticated offline
  final String userId;

  /// Time remaining until offline access expires
  final Duration gracePeriodRemaining;

  OfflineAuthState({
    required this.userId,
    required this.gracePeriodRemaining,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.offlineAuth,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {
      'userId': userId,
      'gracePeriodRemaining': gracePeriodRemaining,
    }),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? userId,
    Duration? gracePeriodRemaining,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineAuthState(
      userId: userId ?? this.userId,
      gracePeriodRemaining: gracePeriodRemaining ?? this.gracePeriodRemaining,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Error state when authentication fails or encounters an issue.
///
/// Used for all authentication-related errors including:
/// - Invalid credentials
/// - Network failures
/// - Server errors
/// - Validation failures
///
/// Example:
/// ```dart
/// final state = ErrorState(
///   errorMessage: 'Invalid email or password',
///   errorType: 'InvalidCredentialsError',
/// );
/// coordinator.transitionTo(state);
/// ```
class ErrorState extends AuthState {
  /// Human-readable error message
  final String errorMessage;

  /// Type/category of error for programmatic handling
  final String errorType;

  ErrorState({
    required this.errorMessage,
    required this.errorType,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic> metadata = const {},
  }) : super(
    type: AuthStateType.error,
    enteredAt: enteredAt,
    timeout: timeout,
    metadata: _mergeMetadata(metadata, {
      'errorMessage': errorMessage,
      'errorType': errorType,
    }),
  );

  @override
  AuthState copyWith({
    AuthStateType? type,
    String? errorMessage,
    String? errorType,
    DateTime? enteredAt,
    Duration? timeout,
    Map<String, dynamic>? metadata,
  }) {
    return ErrorState(
      errorMessage: errorMessage ?? this.errorMessage,
      errorType: errorType ?? this.errorType,
      enteredAt: enteredAt ?? this.enteredAt,
      timeout: timeout ?? this.timeout,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Helper function to merge metadata maps for const constructors.
///
/// This is needed because Dart doesn't allow spread operators in const expressions.
Map<String, dynamic> _mergeMetadata(
  Map<String, dynamic> base,
  Map<String, dynamic> additional,
) {
  if (base.isEmpty) return additional;
  if (additional.isEmpty) return base;
  return {...base, ...additional};
}
