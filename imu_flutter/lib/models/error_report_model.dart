import 'dart:convert';

/// Error report model for sending errors to backend
///
/// Captures platform-specific context (app version, OS version, device info)
/// and generates fingerprints for deduplication.
class ErrorReport {
  /// Error code (e.g., "DATABASE_ERROR", "NETWORK_ERROR")
  final String code;

  /// Human-readable error message
  final String message;

  /// HTTP status code (if applicable)
  final int? statusCode;

  /// Platform that generated the error
  final ErrorPlatform platform;

  /// Stack trace for debugging
  final String? stackTrace;

  /// User ID who experienced the error (if available)
  final String? userId;

  /// Unique request ID for tracing
  final String? requestId;

  /// SHA-256 fingerprint for deduplication
  final String? fingerprint;

  /// Mobile app version (e.g., "1.0.0")
  final String? appVersion;

  /// Mobile OS version (e.g., "iOS 15.0")
  final String? osVersion;

  /// Mobile device information (model, manufacturer, etc.)
  final Map<String, dynamic>? deviceInfo;

  /// Additional error context
  final Map<String, dynamic>? details;

  /// Suggested fixes for the error
  final List<String>? suggestions;

  /// Link to documentation
  final String? documentationUrl;

  /// When the error was created
  final DateTime createdAt;

  ErrorReport({
    required this.code,
    required this.message,
    this.statusCode,
    required this.platform,
    this.stackTrace,
    this.userId,
    this.requestId,
    this.fingerprint,
    this.appVersion,
    this.osVersion,
    this.deviceInfo,
    this.details,
    this.suggestions,
    this.documentationUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create ErrorReport from JSON
  factory ErrorReport.fromJson(Map<String, dynamic> json) {
    return ErrorReport(
      code: json['code'] as String,
      message: json['message'] as String,
      statusCode: json['statusCode'] as int?,
      platform: ErrorPlatform.fromString(json['platform'] as String? ?? 'mobile'),
      stackTrace: json['stackTrace'] as String?,
      userId: json['userId'] as String?,
      requestId: json['requestId'] as String?,
      fingerprint: json['fingerprint'] as String?,
      appVersion: json['appVersion'] as String?,
      osVersion: json['osVersion'] as String?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
      details: json['details'] as Map<String, dynamic>?,
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map((s) => s as String)
          .toList(),
      documentationUrl: json['documentationUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (statusCode != null) 'statusCode': statusCode,
      'platform': platform.value,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (userId != null) 'userId': userId,
      if (requestId != null) 'requestId': requestId,
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (appVersion != null) 'appVersion': appVersion,
      if (osVersion != null) 'osVersion': osVersion,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (details != null) 'details': details,
      if (suggestions != null) 'suggestions': suggestions,
      if (documentationUrl != null) 'documentationUrl': documentationUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert to JSON string for storage
  String toJsonString() => jsonEncode(toJson());

  /// Create ErrorReport from JSON string
  factory ErrorReport.fromJsonString(String jsonString) {
    return ErrorReport.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Generate unique ID for this error report
  String get id => '${code}_${createdAt.millisecondsSinceEpoch}';

  @override
  String toString() {
    return 'ErrorReport(code: $code, message: $message, platform: ${platform.value})';
  }
}

/// Platform that generated the error
enum ErrorPlatform {
  mobile('mobile'),
  web('web'),
  backend('backend');

  final String value;
  const ErrorPlatform(this.value);

  /// Create ErrorPlatform from string
  static ErrorPlatform fromString(String value) {
    return ErrorPlatform.values.firstWhere(
      (platform) => platform.value == value,
      orElse: () => ErrorPlatform.mobile,
    );
  }
}

/// Error report response from backend
class ErrorReportResponse {
  /// Whether the request was successful
  final bool success;

  /// Whether the error was logged (false for duplicates)
  final bool logged;

  /// Unique ID of the error log entry
  final String errorId;

  /// Reason why error was not logged (duplicate or rate_limited)
  final String? reason;

  ErrorReportResponse({
    required this.success,
    required this.logged,
    required this.errorId,
    this.reason,
  });

  /// Create ErrorReportResponse from JSON
  factory ErrorReportResponse.fromJson(Map<String, dynamic> json) {
    return ErrorReportResponse(
      success: json['success'] as bool? ?? false,
      logged: json['logged'] as bool? ?? false,
      errorId: json['errorId'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }

  @override
  String toString() {
    return 'ErrorReportResponse(success: $success, logged: $logged, errorId: $errorId${reason != null ? ', reason: $reason' : ''})';
  }
}
