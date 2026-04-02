/// Application error model
///
/// Represents a standardized error response from the backend API
class AppError {
  /// Unique identifier for the request that generated this error
  final String requestId;

  /// ISO 8601 timestamp when the error occurred
  final String timestamp;

  /// Error code (e.g., VALIDATION_ERROR, NOT_FOUND, UNAUTHORIZED)
  final String code;

  /// User-friendly error message
  final String message;

  /// Request path that caused the error
  final String path;

  /// HTTP method that caused the error
  final String method;

  /// Additional error details
  final Map<String, dynamic>? details;

  /// Field-specific validation errors
  final List<FieldError>? errors;

  /// Suggestions for resolving the error
  final List<String>? suggestions;

  /// Documentation URL for this error
  final String? documentationUrl;

  /// Stack trace (only in development mode)
  final String? stack;

  /// Shortened request ID (first 8 characters)
  String get shortRequestId => requestId.substring(0, 8);

  AppError({
    required this.requestId,
    required this.timestamp,
    required this.code,
    required this.message,
    required this.path,
    required this.method,
    this.details,
    this.errors,
    this.suggestions,
    this.documentationUrl,
    this.stack,
  });

  /// Create AppError from JSON
  factory AppError.fromJson(Map<String, dynamic> json) {
    return AppError(
      requestId: json['requestId'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      code: json['code'] as String? ?? 'INTERNAL_SERVER_ERROR',
      message: json['message'] as String? ?? 'An error occurred',
      path: json['path'] as String? ?? '',
      method: json['method'] as String? ?? '',
      details: json['details'] as Map<String, dynamic>?,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => FieldError.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList(),
      documentationUrl: json['documentationUrl'] as String?,
      stack: json['stack'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'timestamp': timestamp,
      'code': code,
      'message': message,
      'path': path,
      'method': method,
      if (details != null) 'details': details,
      if (errors != null) 'errors': errors?.map((e) => e.toJson()).toList(),
      if (suggestions != null) 'suggestions': suggestions,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
      if (stack != null) 'stack': stack,
    };
  }

  @override
  String toString() {
    return 'AppError(requestId: $requestId, code: $code, message: $message)';
  }
}

/// Field-specific validation error
class FieldError {
  /// Field name that has the error
  final String field;

  /// Error message
  final String message;

  /// Field value that caused the error
  final dynamic value;

  FieldError({
    required this.field,
    required this.message,
    this.value,
  });

  /// Create FieldError from JSON
  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      field: json['field'] as String? ?? '',
      message: json['message'] as String? ?? '',
      value: json['value'],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      if (value != null) 'value': value,
    };
  }

  @override
  String toString() => 'FieldError(field: $field, message: $message)';
}
