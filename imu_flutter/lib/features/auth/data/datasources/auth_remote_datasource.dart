import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../domain/services/token_manager.dart';
import '../../../../core/config/app_config.dart';

part 'auth_remote_datasource.g.dart';

/// Remote data source for authentication API calls.
///
/// Handles all authentication-related network operations including
/// login, token refresh, and logout.
@RestApi(baseUrl: '')
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio, {String baseUrl}) = _AuthRemoteDataSource;

  /// Authenticate user with email and password.
  ///
  /// Returns token data on success.
  /// Throws [DioException] on network or server errors.
  @POST('/auth/login')
  Future<LoginResponse> login(
    @Body() LoginRequest request,
  );

  /// Refresh access token using refresh token.
  ///
  /// Returns new token data on success.
  @POST('/auth/refresh')
  Future<LoginResponse> refreshToken(@Body() RefreshTokenRequest request);

  /// Logout current user (invalidate refresh token).
  @POST('/auth/logout')
  Future<void> logout();
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
  static AuthRemoteDataSource create(Dio dio) {
    return AuthRemoteDataSource(dio, baseUrl: AppConfig.apiBaseUrl);
  }
}
