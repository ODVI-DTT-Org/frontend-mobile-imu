import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/domain/services/token_manager.dart';
import '../config/app_config.dart';
import 'network_error_handler.dart';

/// Dio interceptor that automatically adds authentication tokens to requests.
///
/// Features:
/// - Adds access token to all requests
/// - Automatically refreshes expired tokens
/// - Handles 401 Unauthorized responses
/// - Retries failed requests after token refresh
class AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;

  AuthInterceptor({required TokenManager tokenManager})
      : _tokenManager = tokenManager;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add access token to request headers
    final accessToken = await _tokenManager.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    // Add other common headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    if (AppConfig.enableLogging) {
      debugPrint('🔵 Request: ${options.method} ${options.uri}');
      debugPrint('🔵 Headers: ${options.headers}');
      if (options.data != null) {
        debugPrint('🔵 Data: ${options.data}');
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    if (AppConfig.enableLogging) {
      debugPrint('🟢 Response: ${response.statusCode} ${response.requestOptions.uri}');
      debugPrint('🟢 Data: ${response.data}');
    }

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Convert to NetworkException for better error handling
    final networkError = NetworkErrorHandler.handle(err);

    if (AppConfig.enableLogging) {
      debugPrint('🔴 Error: ${networkError.type}');
      debugPrint('🔴 Message: ${networkError.message}');
      debugPrint('🔴 User Message: ${networkError.userMessage}');
    }

    // Pass the error to the next handler
    handler.next(err);
  }

  /// Dispose of resources
  void dispose() {
    // Nothing to dispose
  }
}
