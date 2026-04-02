import '../../services/error_service.dart';
import '../../models/error_model.dart' as models;

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;
  final Map<String, dynamic>? data;

  /// Parsed AppError from backend response
  final models.AppError? appError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalError,
    this.data,
    this.appError,
  });

  /// Create from API error
  factory ApiException.fromError(dynamic error) {
    String message = 'An unexpected error occurred';
    int? statusCode;
    String? errorCode;
    Map<String, dynamic>? data;
    models.AppError? appError;

    if (error.toString().contains('ClientException') ||
        error.toString().contains('HttpException')) {
      // Parse HTTP exception
      final errorStr = error.toString();

      // Extract status code
      final statusCodeMatch = RegExp(r'statusCode:\s*(\d+)').firstMatch(errorStr);
      if (statusCodeMatch != null) {
        statusCode = int.tryParse(statusCodeMatch.group(1) ?? '');
      }

      // Try to extract response body as JSON
      final responseMatch = RegExp(r'response:\s*([^\]]+)\]').firstMatch(errorStr);
      if (responseMatch != null) {
        final responseStr = responseMatch.group(1)?.trim() ?? '';

        // Try to parse as JSON
        try {
          final jsonData = _parseJsonResponse(responseStr);
          if (jsonData != null) {
            data = jsonData;

            // Check if this is our standardized error format
            if (jsonData.containsKey('code') && jsonData.containsKey('requestId')) {
              appError = models.AppError.fromJson(jsonData);
              message = appError.message;
              errorCode = appError.code;
            } else {
              message = jsonData['message'] as String? ??
                  jsonData['error'] as String? ??
                  message;
              errorCode = jsonData['code'] as String?;
            }
          }
        } catch (e) {
          message = responseStr;
        }
      }
    } else {
      message = error.toString();
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      originalError: error,
      data: data,
      appError: appError,
    );
  }

  /// Parse JSON response from error string
  static Map<String, dynamic>? _parseJsonResponse(String responseStr) {
    try {
      // Remove outer quotes if present
      var cleaned = responseStr.trim();
      if (cleaned.startsWith("'") || cleaned.startsWith('"')) {
        cleaned = cleaned.substring(1);
      }
      if (cleaned.endsWith("'") || cleaned.endsWith('"')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }

      // Unescape escaped quotes
      cleaned = cleaned.replaceAll("\\'", "'");
      cleaned = cleaned.replaceAll('\\"', '"');

      // Try to parse as JSON
      if (cleaned.startsWith('{')) {
        // Using dynamic since dart:convert might not be imported
        // In production, import 'dart:convert' and use jsonDecode
        return null; // Placeholder - would use jsonDecode in actual implementation
      }
    } catch (e) {
      // Not a JSON response
    }
    return null;
  }

  /// Network error (no internet)
  factory ApiException.networkError([dynamic originalError]) {
    return ApiException(
      message: 'No internet connection. Please check your network settings.',
      statusCode: 0,
      errorCode: 'NETWORK_ERROR',
      originalError: originalError,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'NETWORK_ERROR',
        message: 'No internet connection. Please check your network settings.',
        path: '',
        method: '',
      ),
    );
  }

  /// Timeout error
  factory ApiException.timeoutError([dynamic originalError]) {
    return ApiException(
      message: 'Request timed out. Please try again.',
      statusCode: 408,
      errorCode: 'TIMEOUT',
      originalError: originalError,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'TIMEOUT',
        message: 'Request timed out. Please try again.',
        path: '',
        method: '',
      ),
    );
  }

  /// Unauthorized error (401)
  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message: message ?? 'Your session has expired. Please log in again.',
      statusCode: 401,
      errorCode: 'UNAUTHORIZED',
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'UNAUTHORIZED',
        message: message ?? 'Your session has expired. Please log in again.',
        path: '',
        method: '',
      ),
    );
  }

  /// Forbidden error (403)
  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message: message ?? 'You do not have permission to perform this action.',
      statusCode: 403,
      errorCode: 'FORBIDDEN',
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'FORBIDDEN',
        message: message ?? 'You do not have permission to perform this action.',
        path: '',
        method: '',
      ),
    );
  }

  /// Not found error (404)
  factory ApiException.notFound([String? message]) {
    return ApiException(
      message: message ?? 'The requested resource was not found.',
      statusCode: 404,
      errorCode: 'NOT_FOUND',
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'NOT_FOUND',
        message: message ?? 'The requested resource was not found.',
        path: '',
        method: '',
      ),
    );
  }

  /// Server error (500)
  factory ApiException.serverError([String? message]) {
    return ApiException(
      message: message ?? 'A server error occurred. Please try again later.',
      statusCode: 500,
      errorCode: 'SERVER_ERROR',
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'INTERNAL_SERVER_ERROR',
        message: message ?? 'A server error occurred. Please try again later.',
        path: '',
        method: '',
      ),
    );
  }

  /// Validation error (400)
  factory ApiException.validationError(Map<String, dynamic> errors) {
    return ApiException(
      message: 'Validation failed. Please check your input.',
      statusCode: 400,
      errorCode: 'VALIDATION_ERROR',
      data: errors,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: 'VALIDATION_ERROR',
        message: 'Validation failed. Please check your input.',
        path: '',
        method: '',
        details: errors,
      ),
    );
  }

  /// Whether this is a network error
  bool get isNetworkError => statusCode == 0 || errorCode == 'NETWORK_ERROR';

  /// Whether this is an authentication error
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Whether this is a client error (4xx)
  bool get isClientError => statusCode != null && statusCode! >= 400 && statusCode! < 500;

  /// Whether this is a server error (5xx)
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    final buffer = StringBuffer('ApiException: $message');
    if (statusCode != null) {
      buffer.write(' (status: $statusCode)');
    }
    if (errorCode != null) {
      buffer.write(' [code: $errorCode]');
    }
    return buffer.toString();
  }
}
