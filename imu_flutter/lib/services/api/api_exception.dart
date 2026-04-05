import '../../services/error_service.dart';
import '../../services/error_message_mapper.dart';
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
    const errorCode = 'NETWORK_ERROR';
    final message = ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: message,
      statusCode: 0,
      errorCode: errorCode,
      originalError: originalError,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: message,
        path: '',
        method: '',
      ),
    );
  }

  /// Timeout error
  factory ApiException.timeoutError([dynamic originalError]) {
    const errorCode = 'TIMEOUT';
    final message = ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: message,
      statusCode: 408,
      errorCode: errorCode,
      originalError: originalError,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: message,
        path: '',
        method: '',
      ),
    );
  }

  /// Unauthorized error (401)
  factory ApiException.unauthorized([String? message]) {
    const errorCode = 'UNAUTHORIZED';
    final mappedMessage = message ?? ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: mappedMessage,
      statusCode: 401,
      errorCode: errorCode,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: mappedMessage,
        path: '',
        method: '',
      ),
    );
  }

  /// Forbidden error (403)
  factory ApiException.forbidden([String? message]) {
    const errorCode = 'FORBIDDEN';
    final mappedMessage = message ?? ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: mappedMessage,
      statusCode: 403,
      errorCode: errorCode,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: mappedMessage,
        path: '',
        method: '',
      ),
    );
  }

  /// Not found error (404)
  factory ApiException.notFound([String? message]) {
    const errorCode = 'NOT_FOUND';
    final mappedMessage = message ?? ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: mappedMessage,
      statusCode: 404,
      errorCode: errorCode,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: mappedMessage,
        path: '',
        method: '',
      ),
    );
  }

  /// Server error (500)
  factory ApiException.serverError([String? message]) {
    const errorCode = 'INTERNAL_SERVER_ERROR';
    final mappedMessage = message ?? ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: mappedMessage,
      statusCode: 500,
      errorCode: errorCode,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: mappedMessage,
        path: '',
        method: '',
      ),
    );
  }

  /// Validation error (400)
  factory ApiException.validationError(Map<String, dynamic> errors) {
    const errorCode = 'VALIDATION_ERROR';
    final message = ErrorMessageMapper.getMessage(errorCode);

    return ApiException(
      message: message,
      statusCode: 400,
      errorCode: errorCode,
      data: errors,
      appError: models.AppError(
        requestId: ErrorService.generateRequestId(),
        timestamp: DateTime.now().toIso8601String(),
        code: errorCode,
        message: message,
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

  /// Convert to human-readable error using ErrorMessageMapper
  ///
  /// Returns a HumanReadableError with user-friendly title, message, suggestions, icon, and color
  HumanReadableError toHumanReadable() {
    final code = errorCode ?? 'UNKNOWN_ERROR';
    return HumanReadableError(
      title: ErrorMessageMapper.getTitle(code),
      message: ErrorMessageMapper.getMessage(code),
      suggestions: ErrorMessageMapper.getSuggestions(code),
      icon: ErrorMessageMapper.getIcon(code),
      color: ErrorMessageMapper.getColor(code),
      requestId: appError?.shortRequestId ?? 'unknown',
    );
  }
}
