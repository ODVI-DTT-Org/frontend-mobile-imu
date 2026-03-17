/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;
  final Map<String, dynamic>? data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.originalError,
    this.data,
  });

  /// Create from API error
  factory ApiException.fromError(dynamic error) {
    String message = 'An unexpected error occurred';
    int? statusCode;
    String? errorCode;
    Map<String, dynamic>? data;

    if (error.toString().contains('ClientException') ||
        error.toString().contains('HttpException')) {
      // Parse HTTP exception
      final errorStr = error.toString();

      // Extract status code
      final statusCodeMatch = RegExp(r'statusCode:\s*(\d+)').firstMatch(errorStr);
      if (statusCodeMatch != null) {
        statusCode = int.tryParse(statusCodeMatch.group(1) ?? '');
      }

      // Extract response message
      final responseMatch = RegExp(r'response:\s*([^\]]+)\]').firstMatch(errorStr);
      if (responseMatch != null) {
        message = responseMatch.group(1)?.trim() ?? message;
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
    );
  }

  /// Network error (no internet)
  factory ApiException.networkError([dynamic originalError]) {
    return ApiException(
      message: 'No internet connection. Please check your network settings.',
      statusCode: 0,
      errorCode: 'NETWORK_ERROR',
      originalError: originalError,
    );
  }

  /// Timeout error
  factory ApiException.timeoutError([dynamic originalError]) {
    return ApiException(
      message: 'Request timed out. Please try again.',
      statusCode: 408,
      errorCode: 'TIMEOUT',
      originalError: originalError,
    );
  }

  /// Unauthorized error (401)
  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      message: message ?? 'Your session has expired. Please log in again.',
      statusCode: 401,
      errorCode: 'UNAUTHORIZED',
    );
  }

  /// Forbidden error (403)
  factory ApiException.forbidden([String? message]) {
    return ApiException(
      message: message ?? 'You do not have permission to perform this action.',
      statusCode: 403,
      errorCode: 'FORBIDDEN',
    );
  }

  /// Not found error (404)
  factory ApiException.notFound([String? message]) {
    return ApiException(
      message: message ?? 'The requested resource was not found.',
      statusCode: 404,
      errorCode: 'NOT_FOUND',
    );
  }

  /// Server error (500)
  factory ApiException.serverError([String? message]) {
    return ApiException(
      message: message ?? 'A server error occurred. Please try again later.',
      statusCode: 500,
      errorCode: 'SERVER_ERROR',
    );
  }

  /// Validation error (400)
  factory ApiException.validationError(Map<String, dynamic> errors) {
    return ApiException(
      message: 'Validation failed. Please check your input.',
      statusCode: 400,
      errorCode: 'VALIDATION_ERROR',
      data: errors,
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
