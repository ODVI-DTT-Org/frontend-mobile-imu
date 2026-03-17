import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stub user model (will be replaced with JWT user)
class StubUser {
  final String id;
  final String email;
  final String name;

  const StubUser({
    required this.id,
    required this.email,
    required this.name,
  });
}

/// Stub auth service (placeholder until JWT auth is implemented)
class AuthService {
  StubUser? _currentUser;

  Future<void> initialize() async {
    // TODO: Implement JWT auth
  }

  Future<StubUser?> login(String email, String password) async {
    // TODO: Implement login
    throw UnimplementedError('JWT auth not yet implemented');
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  bool get isAuthenticated => _currentUser != null;
  StubUser? get currentUser => _currentUser;
  String? get currentUserId => _currentUser?.id;
}

/// Providers
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final StubUser? user;

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
    StubUser? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial());

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    final isAuth = _authService.isAuthenticated;
    state = state.copyWith(
      isAuthenticated: isAuth,
      user: _authService.currentUser,
      isLoading: false,
    );
  }

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

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState.initial();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  notifier.checkAuthStatus();
  return notifier;
});
