import 'package:dio/dio.dart';
// import 'package:retrofit/retrofit.dart'; // DISABLED: Package not available
import '../../domain/services/token_manager.dart';
import '../../../../core/config/app_config.dart';

// part 'auth_remote_datasource.g.dart'; // DISABLED: Code generation not available

/// Remote data source for authentication API calls.
///
/// Handles all authentication-related network operations including
/// login, token refresh, and logout.
///
/// NOTE: Retrofit temporarily disabled - package not installed.
/// TODO: Install retrofit package or migrate to pure Dio implementation.
abstract class AuthRemoteDataSource {
  /// Authenticate user with email and password.
  ///
  /// Returns token data on success.
  /// Throws [DioException] on network or server errors.
  Future<LoginResponse> login(LoginRequest request);

  /// Refresh access token using refresh token.
  ///
  /// Returns new token data on success.
  Future<LoginResponse> refreshToken(RefreshTokenRequest request);

  /// Logout current user (invalidate refresh token).
  Future<void> logout();
}

/// Temporary implementation using Dio directly
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  AuthRemoteDataSourceImpl(this.dio, {this.baseUrl = ''});

  /// Authenticate user with email and password.
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await dio.post(
      '$baseUrl/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data);
  }

  /// Refresh access token using refresh token.
  Future<LoginResponse> refreshToken(RefreshTokenRequest request) async {
    final response = await dio.post(
      '$baseUrl/auth/refresh',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data);
  }

  /// Logout current user.
  Future<void> logout() async {
    await dio.post('$baseUrl/auth/logout');
  }
}

/// Request body for login endpoint.
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Request body for token refresh endpoint.
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}

/// Response from login or token refresh endpoint.
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String? userId;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.userId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Handle backend response format with nested user object
    String? userId;
    if (json.containsKey('user_id')) {
      userId = json['user_id'] as String?;
    } else if (json.containsKey('user') && json['user'] is Map) {
      final user = json['user'] as Map<String, dynamic>;
      userId = user['id'] as String?;
    }

    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int? ?? 3600,
      userId: userId,
    );
  }

  /// Convert to TokenData for use with TokenManager.
  TokenData toTokenData() {
    return TokenData(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: Duration(seconds: expiresIn),
      userId: userId,
    );
  }
}

/// Factory for creating AuthRemoteDataSource instances.
class AuthRemoteDataSourceFactory {
  /// Create an AuthRemoteDataSource instance with the configured base URL.
  static AuthRemoteDataSourceImpl create(Dio dio) {
    return AuthRemoteDataSourceImpl(dio, baseUrl: AppConfig.apiBaseUrl);
  }
}
