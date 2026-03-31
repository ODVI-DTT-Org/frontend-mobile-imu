import 'package:dio/dio.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../domain/services/token_manager.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementation of AuthRepository using remote data source.
///
/// This repository handles authentication operations by coordinating
/// between the API client (AuthRemoteDataSource) and token storage
/// (TokenManager).
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final TokenManager tokenManager;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.tokenManager,
  });

  @override
  Future<TokenData> login(String email, String password) async {
    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final response = await remoteDataSource.login(request);

      // Convert response to TokenData
      final tokenData = response.toTokenData();

      // Store tokens securely
      await tokenManager.storeTokens(tokenData);

      return tokenData;
    } on DioException catch (e) {
      // Handle API errors
      if (e.response?.statusCode == 401) {
        throw AuthException(
          type: AuthErrorType.invalidCredentials,
          message: 'Invalid email or password',
        );
      } else if (e.response?.statusCode == 429) {
        throw AuthException(
          type: AuthErrorType.tooManyAttempts,
          message: 'Too many login attempts. Please try again later.',
        );
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AuthException(
          type: AuthErrorType.networkError,
          message: 'Network timeout. Please check your connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw AuthException(
          type: AuthErrorType.networkError,
          message: 'No internet connection. Please check your network.',
        );
      } else {
        throw AuthException(
          type: AuthErrorType.unknown,
          message: e.message ?? 'An error occurred during login',
        );
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        type: AuthErrorType.unknown,
        message: 'An unexpected error occurred',
      );
    }
  }

  @override
  Future<TokenData> refreshToken(String refreshToken) async {
    try {
      final request = RefreshTokenRequest(refreshToken: refreshToken);
      final response = await remoteDataSource.refreshToken(request);

      final tokenData = response.toTokenData();
      await tokenManager.storeTokens(tokenData);

      return tokenData;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw AuthException(
          type: AuthErrorType.invalidToken,
          message: 'Session expired. Please login again.',
        );
      }
      throw AuthException(
        type: AuthErrorType.unknown,
        message: 'Failed to refresh token',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      // Continue with local logout even if API call fails
    } finally {
      await tokenManager.clearTokens();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return await tokenManager.hasRefreshToken() && !tokenManager.isTokenExpired();
  }

  @override
  Future<String?> getCurrentUserId() async {
    return await tokenManager.getUserId();
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final AuthErrorType type;
  final String message;

  AuthException({
    required this.type,
    required this.message,
  });

  @override
  String toString() => 'AuthException: $message ($type)';
}

/// Types of authentication errors.
enum AuthErrorType {
  invalidCredentials,
  invalidToken,
  tooManyAttempts,
  networkError,
  userNotFound,
  accountDisabled,
  unknown,
}
