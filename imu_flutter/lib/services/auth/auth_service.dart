import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'jwt_auth_service.dart';
import '../sync/powersync_service.dart';
import '../sync/powersync_connector.dart';
import '../../core/utils/logger.dart';
import '../../core/config/app_config.dart';

// Re-export JwtUser for convenience
export 'jwt_auth_service.dart' show JwtUser;

/// Main authentication service wrapping JWT auth
class AuthService {
  final JwtAuthService _jwtAuth;

  AuthService({JwtAuthService? jwtAuth}) : _jwtAuth = jwtAuth ?? JwtAuthService();

  /// Initialize authentication service
  Future<void> initialize() => _jwtAuth.initialize();

  /// Login with email and password
  Future<JwtUser> login(String email, String password, {bool rememberMe = false}) =>
      _jwtAuth.login(email: email, password: password, rememberMe: rememberMe);

  /// Logout current user
  Future<void> logout() => _jwtAuth.logout();

  /// Refresh authentication tokens
  Future<void> refreshToken() => _jwtAuth.refreshTokens();

  /// Register new user
  Future<JwtUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'caravan',
  }) =>
      _jwtAuth.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      );

  /// Check if user is authenticated
  bool get isAuthenticated => _jwtAuth.isAuthenticated;

  /// Get current user
  JwtUser? get currentUser => _jwtAuth.currentUser;

  /// Get current user ID
  String? get currentUserId => _jwtAuth.currentUser?.id;

  /// Get current user email
  String? get currentUserEmail => _jwtAuth.currentUser?.email;

  /// Get current user name
  String? get currentUserName => _jwtAuth.currentUser?.fullName;

  /// Get current user role
  String? get currentUserRole => _jwtAuth.currentUser?.role.apiValue;

  /// Get authorization header
  String? get authHeader => _jwtAuth.authHeader;

  /// Check if token needs refresh
  bool get needsRefresh => _jwtAuth.needsRefresh;

  /// Check if token refresh should be attempted (expires within 5 minutes)
  bool get shouldAttemptRefresh => _jwtAuth.shouldAttemptRefresh;

  /// Get time until token expires
  Duration? get timeUntilExpiry => _jwtAuth.timeUntilExpiry;
}

/// Provider for JWT auth service
/// Provider for JWT auth service (singleton to maintain token state)
final jwtAuthProvider = Provider<JwtAuthService>((ref) {
  final service = JwtAuthService.instance;
  // Initialize to load stored tokens
  // Note: This runs asynchronously but should complete before PIN entry
  service.initialize().then((_) {
    debugPrint('[AUTH-PROVIDER] JwtAuthService initialized successfully');
  }).catchError((e) {
    debugPrint('[AUTH-PROVIDER] JwtAuthService initialization error: $e');
  });
  ref.onDispose(() {
    // Service will be disposed automatically
  });
  return service;
});

/// Provider for main auth service
final authServiceProvider = Provider<AuthService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return AuthService(jwtAuth: jwtAuth);
});

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final JwtUser? user;

  const AuthState({
    required this.isAuthenticated,
    required this.isLoading,
    this.error,
    this.user,
  });

  factory AuthState.initial() => const AuthState(
    isAuthenticated: false,
    isLoading: true,  // Start in loading state to prevent premature router redirect
  );

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    JwtUser? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }

  @override
  String toString() => 'AuthState(isAuthenticated: $isAuthenticated, isLoading: $isLoading, user: ${user?.email})';
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  IMUPowerSyncConnector? _powerSyncConnector;
  Future<void> Function()? _onLoginSuccess;
  bool _disposed = false;

  AuthNotifier(this._authService, {Future<void> Function()? onLoginSuccess})
      : _onLoginSuccess = onLoginSuccess,
        super(AuthState.initial());

  /// Check if the notifier is still mounted (not disposed)
  bool get mounted => !_disposed;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true);
    try {
      await _authService.initialize();

      // PIN FUNCTIONALITY DISABLED - Only check JWT token validity
      // Consider authenticated if JWT token is valid
      final isAuth = _authService.isAuthenticated;

      if (!mounted) return;
      state = state.copyWith(
        isAuthenticated: isAuth,
        user: _authService.currentUser,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    if (!mounted) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password, rememberMe: rememberMe);

      // Connect to PowerSync after successful login
      // NOTE: PowerSync connection failures should NOT affect login success
      // Users should be able to use the app even if PowerSync fails
      try {
        logDebug('Connecting to PowerSync...');
        // Use the shared JWT auth service from provider
        _powerSyncConnector = IMUPowerSyncConnector(
          authService: _authService._jwtAuth,
          powersyncUrl: AppConfig.powerSyncUrl,
          apiUrl: AppConfig.postgresApiUrl,
        );
        await PowerSyncService.connect(_powerSyncConnector!);
        logDebug('PowerSync connected successfully');
      } catch (e) {
        // Log the error but DON'T fail the login
        // PowerSync sync errors are non-critical - app can still function
        logError('PowerSync connection failed (app will continue without sync)', e);
        if (!mounted) return false;
        // Store the error for display but don't set loading to false yet
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
        // Still trigger initial sync callback even if PowerSync fails
        _onLoginSuccess?.call();
        return true; // Login succeeds even if PowerSync fails
      }

      if (!mounted) return false;
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );

      // Trigger initial sync after successful login and PowerSync connection
      _onLoginSuccess?.call();

      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    if (!mounted) return;

    state = state.copyWith(isLoading: true);

    // Disconnect from PowerSync
    try {
      await PowerSyncService.disconnect();
      logDebug('PowerSync disconnected');
    } catch (e) {
      logError('Failed to disconnect PowerSync', e);
    }

    await _authService.logout();
    if (!mounted) return;
    state = AuthState.initial();
  }

  /// Refresh authentication
  Future<void> refresh() async {
    if (!mounted) return;

    try {
      await _authService.refreshToken();
      if (!mounted) return;
      state = state.copyWith(
        isAuthenticated: _authService.isAuthenticated,
        user: _authService.currentUser,
      );
    } catch (e) {
      if (!mounted) return;
      state = AuthState.initial();
    }
  }

  /// Clear any error message
  void clearError() {
    if (!mounted) return;
    state = state.copyWith(error: null);
  }
}

// Note: authNotifierProvider is now defined in app_providers.dart
// to allow access to other providers for initial sync callback
