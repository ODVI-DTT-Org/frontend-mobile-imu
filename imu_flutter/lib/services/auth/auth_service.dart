import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'jwt_auth_service.dart';

// Re-export JwtUser for convenience
export 'jwt_auth_service.dart' show JwtUser;

/// Main authentication service wrapping JWT auth
class AuthService {
  final JwtAuthService _jwtAuth;

  AuthService({JwtAuthService? jwtAuth}) : _jwtAuth = jwtAuth ?? JwtAuthService();

  /// Initialize authentication service
  Future<void> initialize() => _jwtAuth.initialize();

  /// Login with email and password
  Future<JwtUser> login(String email, String password) =>
      _jwtAuth.login(email: email, password: password);

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
    String role = 'field_agent',
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
  String? get currentUserRole => _jwtAuth.currentUser?.role;

  /// Get authorization header
  String? get authHeader => _jwtAuth.authHeader;

  /// Check if token needs refresh
  bool get needsRefresh => _jwtAuth.needsRefresh;
}

/// Provider for JWT auth service
final jwtAuthProvider = Provider<JwtAuthService>((ref) => JwtAuthService());

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
    isLoading: false,
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

  AuthNotifier(this._authService) : super(AuthState.initial());

  /// Check current authentication status
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.initialize();
      state = state.copyWith(
        isAuthenticated: _authService.isAuthenticated,
        user: _authService.currentUser,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = AuthState.initial();
  }

  /// Refresh authentication
  Future<void> refresh() async {
    try {
      await _authService.refreshToken();
      state = state.copyWith(
        isAuthenticated: _authService.isAuthenticated,
        user: _authService.currentUser,
      );
    } catch (e) {
      state = AuthState.initial();
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for authentication state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  // Check auth status on initialization
  notifier.checkAuthStatus();
  return notifier;
});
