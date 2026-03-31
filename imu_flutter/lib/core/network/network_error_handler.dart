import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Network error types for better error handling.
enum NetworkErrorType {
  /// No internet connection
  noInternet,

  /// Request timeout
  timeout,

  /// Server error (5xx)
  serverError,

  /// Client error (4xx)
  clientError,

  /// Unauthorized (401)
  unauthorized,

  /// Forbidden (403)
  forbidden,

  /// Not found (404)
  notFound,

  /// Network error
  networkError,

  /// Unknown error
  unknown,
}

/// Custom exception for network errors.
class NetworkException implements Exception {
  final NetworkErrorType type;
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Create a user-friendly error message.
  String get userMessage {
    switch (type) {
      case NetworkErrorType.noInternet:
        return 'No internet connection. Please check your network and try again.';
      case NetworkErrorType.timeout:
        return 'Request timed out. Please try again.';
      case NetworkErrorType.serverError:
        return 'Server error. Please try again later.';
      case NetworkErrorType.clientError:
        return 'Invalid request. Please check your input and try again.';
      case NetworkErrorType.unauthorized:
        return 'Session expired. Please log in again.';
      case NetworkErrorType.forbidden:
        return 'You don\'t have permission to access this resource.';
      case NetworkErrorType.notFound:
        return 'The requested resource was not found.';
      case NetworkErrorType.networkError:
        return 'Network error. Please check your connection and try again.';
      case NetworkErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Handler for Dio exceptions.
///
/// Converts Dio exceptions into user-friendly error messages
/// and provides appropriate error types for handling.
class NetworkErrorHandler {
  /// Handle a Dio exception and return a [NetworkException].
  static NetworkException handle(DioException error) {
    if (kDebugMode) {
      debugPrint('🔴 Network Error: ${error.type}');
      debugPrint('🔴 Message: ${error.message}');
      debugPrint('🔴 Response: ${error.response}');
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          type: NetworkErrorType.timeout,
          message: 'Request timed out',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.cancel:
        return NetworkException(
          type: NetworkErrorType.unknown,
          message: 'Request was cancelled',
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return NetworkException(
          type: NetworkErrorType.noInternet,
          message: 'No internet connection',
          originalError: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkException(
          type: NetworkErrorType.networkError,
          message: 'Invalid SSL certificate',
          originalError: error,
        );

      case DioExceptionType.unknown:
        return _handleUnknownError(error);
    }
  }

  /// Handle bad response errors (4xx, 5xx).
  static NetworkException _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Extract error message from response if available
    String errorMessage = 'Request failed';
    if (data is Map<String, dynamic>) {
      errorMessage = data['message'] ??
                    data['error'] ??
                    data['detail'] ??
                    errorMessage;
    } else if (data is String) {
      errorMessage = data;
    }

    if (kDebugMode) {
      debugPrint('🔴 Status Code: $statusCode');
      debugPrint('🔴 Error Message: $errorMessage');
    }

    switch (statusCode) {
      case 400:
        return NetworkException(
          type: NetworkErrorType.clientError,
          message: errorMessage,
          statusCode: statusCode,
          originalError: error,
        );

      case 401:
        return NetworkException(
          type: NetworkErrorType.unauthorized,
          message: 'Unauthorized access',
          statusCode: statusCode,
          originalError: error,
        );

      case 403:
        return NetworkException(
          type: NetworkErrorType.forbidden,
          message: 'Access forbidden',
          statusCode: statusCode,
          originalError: error,
        );

      case 404:
        return NetworkException(
          type: NetworkErrorType.notFound,
          message: 'Resource not found',
          statusCode: statusCode,
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return NetworkException(
          type: NetworkErrorType.serverError,
          message: 'Server error',
          statusCode: statusCode,
          originalError: error,
        );

      default:
        return NetworkException(
          type: NetworkErrorType.clientError,
          message: errorMessage,
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  /// Handle unknown errors.
  static NetworkException _handleUnknownError(DioException error) {
    if (error.error is SocketException) {
      return NetworkException(
        type: NetworkErrorType.noInternet,
        message: 'No internet connection',
        originalError: error,
      );
    }

    return NetworkException(
      type: NetworkErrorType.unknown,
      message: error.message ?? 'An unknown error occurred',
      originalError: error,
    );
  }

  /// Check if an error is a network error.
  static bool isNetworkError(dynamic error) {
    return error is NetworkException || error is DioException;
  }

  /// Check if an error is an unauthorized error (401).
  static bool isUnauthorized(dynamic error) {
    if (error is NetworkException) {
      return error.type == NetworkErrorType.unauthorized;
    }
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }

  /// Check if an error is a no internet error.
  static bool isNoInternet(dynamic error) {
    if (error is NetworkException) {
      return error.type == NetworkErrorType.noInternet;
    }
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError;
    }
    return false;
  }

  /// Check if an error is a timeout error.
  static bool isTimeout(dynamic error) {
    if (error is NetworkException) {
      return error.type == NetworkErrorType.timeout;
    }
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    return false;
  }
}
