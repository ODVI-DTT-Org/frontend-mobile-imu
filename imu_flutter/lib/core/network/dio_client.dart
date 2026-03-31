import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';
import 'certificate_pinning.dart';
import '../../features/auth/domain/services/token_manager.dart';

/// Factory for creating configured Dio HTTP clients.
///
/// Features:
/// - Automatic authentication token injection
/// - Token refresh on 401 responses
/// - SSL certificate pinning (optional)
/// - Request/response logging
/// - Configurable timeouts
class DioClient {
  /// Create a new Dio instance with default configuration.
  ///
  /// If [tokenManager] is provided, an [AuthInterceptor] will be added
  /// to automatically handle authentication.
  static Dio create({
    required TokenManager? tokenManager,
    String? baseUrl,
  }) {
    final dio = Dio();

    // Base configuration
    dio.options.baseUrl = baseUrl ?? AppConfig.apiBaseUrl;
    dio.options.connectTimeout = AppConfig.apiConnectTimeout;
    dio.options.receiveTimeout = AppConfig.apiReceiveTimeout;
    dio.options.sendTimeout = AppConfig.apiTimeout;
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Add authentication interceptor if token manager is provided
    if (tokenManager != null) {
      dio.interceptors.add(AuthInterceptor(tokenManager: tokenManager));
    }

    // Add logging interceptor for development
    if (AppConfig.enableLogging && kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint('🌐 $obj'),
        ),
      );
    }

    // Configure SSL certificate pinning
    CertificatePinning.configure(dio);

    return dio;
  }

  /// Create a Dio instance for testing without authentication.
  static Dio createForTesting() {
    return Dio(
      BaseOptions(
        baseUrl: 'https://httpbin.org',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }
}
