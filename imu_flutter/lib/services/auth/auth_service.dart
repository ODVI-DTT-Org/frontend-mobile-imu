import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Authentication service for PocketBase backend
class AuthService {
  final PocketBase _pb;
  final FlutterSecureStorage _secureStorage;

  AuthService({
    required PocketBase pb,
    FlutterSecureStorage? secureStorage,
  })  : _pb = pb,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  /// Login with email and password
  Future<RecordModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting login for $email');

      final authRecord = await _pb.collection('users').authWithPassword(
        email,
        password,
      );

      debugPrint('AuthService: Login successful for user ${authRecord.record?.id}');
      return authRecord.record!;
    } on ClientException catch (e) {
      debugPrint('AuthService: Login failed - ${e.toString()}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('AuthService: Unexpected error - $e');
      throw ApiException(
        message: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  /// Login as superuser (admin)
  Future<RecordModel> loginAsSuperuser({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting superuser login for $email');

      final authRecord = await _pb.collection('_superusers').authWithPassword(
        email,
        password,
      );

      debugPrint('AuthService: Superuser login successful');
      return authRecord.record!;
    } on ClientException catch (e) {
      debugPrint('AuthService: Superuser login failed - ${e.toString()}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('AuthService: Unexpected error - $e');
      throw ApiException(
        message: 'An unexpected error occurred. Please try again.',
        originalError: e,
      );
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      _pb.authStore.clear();
      await _secureStorage.delete(key: 'pb_auth');
      debugPrint('AuthService: Logout successful');
    } catch (e) {
      debugPrint('AuthService: Logout error - $e');
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      debugPrint('AuthService: Requesting password reset for $email');

      await _pb.collection('users').requestPasswordReset(email);

      debugPrint('AuthService: Password reset email sent');
    } on ClientException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to request password reset.',
        originalError: e,
      );
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;

  /// Get current user record
  RecordModel? get currentUser => _pb.authStore.model as RecordModel?;

  /// Get current user ID
  String? get currentUserId => (_pb.authStore.model as RecordModel?)?.id;

  /// Get current user email
  String? get currentUserEmail => (_pb.authStore.model as RecordModel?)?.data['email'] as String?;

  /// Get current user name
  String? get currentUserName {
    final record = _pb.authStore.model as RecordModel?;
    if (record == null) return null;

    final firstName = record.data['first_name'] as String? ?? '';
    final lastName = record.data['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    return fullName.isNotEmpty ? fullName : record.data['email'] as String?;
  }

  /// Refresh auth token
  Future<void> refreshToken() async {
    try {
      await _pb.collection('users').authRefresh();
      debugPrint('AuthService: Token refreshed');
    } catch (e) {
      debugPrint('AuthService: Token refresh failed - $e');
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      throw const ApiException(
        message: 'Passwords do not match',
        errorCode: 'PASSWORD_MISMATCH',
      );
    }

    if (newPassword.length < 8) {
      throw const ApiException(
        message: 'Password must be at least 8 characters',
        errorCode: 'PASSWORD_TOO_SHORT',
      );
    }

    try {
      final userId = currentUserId;
      if (userId == null) {
        throw const ApiException(
          message: 'Not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        );
      }

      await _pb.collection('users').update(userId, body: {
        'oldPassword': oldPassword,
        'password': newPassword,
        'passwordConfirm': confirmPassword,
      });

      debugPrint('AuthService: Password updated');
    } on ClientException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw ApiException(
        message: 'Failed to update password',
        originalError: e,
      );
    }
  }

  /// Handle PocketBase auth errors
  ApiException _handleAuthError(ClientException e) {
    final response = e.response;

    if (response != null) {
      final data = response['data'] as Map<String, dynamic>?;
      final message = response['message'] as String?;

      // Check for specific error codes
      if (data != null) {
        // Validation errors
        if (data.containsKey('email')) {
          final emailError = data['email'];
          if (emailError is Map && emailError.containsKey('code')) {
            final code = emailError['code'] as String;
            if (code == 'validation_invalid_email') {
              return ApiException.validationError(
                {'email': 'Please enter a valid email address'},
              );
            }
          }
        }

        if (data.containsKey('password')) {
          final passwordError = data['password'];
          if (passwordError is Map && passwordError.containsKey('code')) {
            final code = passwordError['code'] as String;
            if (code == 'validation_required') {
              return ApiException.validationError(
                {'password': 'Password is required'},
              );
            }
          }
        }
      }

      // Auth failed
      if (message?.contains('Invalid email or password') == true ||
          message?.contains('Failed to authenticate') == true) {
        return const ApiException(
          message: 'Invalid email or password. Please try again.',
          errorCode: 'INVALID_CREDENTIALS',
        );
      }

      // Rate limited
      if (message?.contains('Too many requests') == true ||
          message?.contains('rate limit') == true) {
        return const ApiException(
          message: 'Too many login attempts. Please wait and try again.',
          errorCode: 'RATE_LIMITED',
          statusCode: 429,
        );
      }
    }

    // Default error
    return ApiException(
      message: 'Authentication failed. Please try again.',
      statusCode: e.statusCode,
      originalError: e,
    );
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return AuthService(pb: pb);
});

/// State notifier for auth state
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState.initial());

  /// Check current auth status
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final isAuthenticated = _authService.isAuthenticated;
      final user = _authService.currentUser;

      state = state.copyWith(
        isAuthenticated: isAuthenticated,
        user: user,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.loginWithEmailPassword(
        email: email,
        password: password,
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );

      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authService.logout();

      state = AuthState.initial();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to logout',
      );
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final RecordModel? user;

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
    RecordModel? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

/// Provider for AuthNotifier
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final notifier = AuthNotifier(authService);
  // Check auth status on initialization to detect persisted PocketBase sessions
  notifier.checkAuthStatus();
  return notifier;
});
