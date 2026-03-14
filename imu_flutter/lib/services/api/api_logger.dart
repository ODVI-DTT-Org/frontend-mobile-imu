import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:imu_flutter/core/config/app_config.dart';

/// Log level for API logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// API Logger for debugging and monitoring API calls
class ApiLogger {
  static final ApiLogger _instance = ApiLogger._internal();
  factory ApiLogger() => _instance;
  ApiLogger._internal();

  static const int _maxLogLength = 1000;
  static const int _maxBodyLength = 500;

  final List<ApiLogEntry> _logs = [];
  final int _maxLogs = 100;

  /// Log an API request
  void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!AppConfig.debugMode) return;

    final entry = ApiLogEntry(
      type: LogType.request,
      method: method,
      url: url,
      timestamp: DateTime.now(),
      headers: _redactHeaders(headers),
      body: _truncateBody(body),
    );

    _addLog(entry);
    _printRequest(entry);
  }

  /// Log an API response
  void logResponse({
    required String method,
    required String url,
    required int statusCode,
    Map<String, dynamic>? headers,
    dynamic body,
    required Duration duration,
  }) {
    final entry = ApiLogEntry(
      type: LogType.response,
      method: method,
      url: url,
      timestamp: DateTime.now(),
      statusCode: statusCode,
      headers: _redactHeaders(headers),
      body: _truncateBody(body),
      duration: duration,
    );

    _addLog(entry);
    _printResponse(entry);
  }

  /// Log an API error
  void logError({
    required String method,
    required String url,
    required dynamic error,
    StackTrace? stackTrace,
    required Duration duration,
  }) {
    final entry = ApiLogEntry(
      type: LogType.error,
      method: method,
      url: url,
      timestamp: DateTime.now(),
      error: error.toString(),
      stackTrace: stackTrace?.toString(),
      duration: duration,
    );

    _addLog(entry);
    _printError(entry);
  }

  /// Add log entry to buffer
  void _addLog(ApiLogEntry entry) {
    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }
  }

  /// Print request log
  void _printRequest(ApiLogEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────');
    buffer.writeln('│ 📤 REQUEST: ${entry.method} ${entry.url}');
    if (entry.headers != null && entry.headers!.isNotEmpty) {
      buffer.writeln('│ Headers: ${_formatJson(entry.headers)}');
    }
    if (entry.body != null) {
      buffer.writeln('│ Body: ${_formatJson(entry.body)}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────');

    debugPrint(buffer.toString());
  }

  /// Print response log
  void _printResponse(ApiLogEntry entry) {
    final statusEmoji = entry.statusCode! < 400 ? '✅' : '⚠️';
    final duration = '${entry.duration!.inMilliseconds}ms';

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────');
    buffer.writeln('│ $statusEmoji RESPONSE: ${entry.method} ${entry.url}');
    buffer.writeln('│ Status: ${entry.statusCode} | Duration: $duration');
    if (entry.body != null) {
      buffer.writeln('│ Body: ${_formatJson(entry.body)}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────');

    debugPrint(buffer.toString());
  }

  /// Print error log
  void _printError(ApiLogEntry entry) {
    final duration = '${entry.duration!.inMilliseconds}ms';

    final buffer = StringBuffer();
    buffer.writeln('┌─────────────────────────────────────────────────────────');
    buffer.writeln('│ ❌ ERROR: ${entry.method} ${entry.url}');
    buffer.writeln('│ Duration: $duration');
    buffer.writeln('│ Error: ${entry.error}');
    if (AppConfig.debugMode && entry.stackTrace != null) {
      buffer.writeln('│ Stack: ${entry.stackTrace}');
    }
    buffer.writeln('└─────────────────────────────────────────────────────────');

    debugPrint(buffer.toString());
  }

  /// Format JSON for logging
  String _formatJson(dynamic data) {
    if (data == null) return 'null';

    try {
      final encoded = jsonEncode(data);
      if (encoded.length > _maxBodyLength) {
        return '${encoded.substring(0, _maxBodyLength)}... (truncated)';
      }
      return encoded;
    } catch (e) {
      return data.toString();
    }
  }

  /// Truncate body for logging
  dynamic _truncateBody(dynamic body) {
    if (body == null) return null;

    if (body is String && body.length > _maxBodyLength) {
      return '${body.substring(0, _maxBodyLength)}... (truncated)';
    }

    return body;
  }

  /// Redact sensitive headers
  Map<String, dynamic>? _redactHeaders(Map<String, dynamic>? headers) {
    if (headers == null) return null;

    final redacted = <String, dynamic>{};
    final sensitiveKeys = ['authorization', 'token', 'api-key', 'password'];

    for (final entry in headers.entries) {
      final key = entry.key.toLowerCase();
      if (sensitiveKeys.any((s) => key.contains(s))) {
        redacted[entry.key] = '***REDACTED***';
      } else {
        redacted[entry.key] = entry.value;
      }
    }

    return redacted;
  }

  /// Get all logs
  List<ApiLogEntry> get logs => List.unmodifiable(_logs);

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
    debugPrint('API logs cleared');
  }

  /// Export logs as string
  String exportLogs() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(log.toString());
      buffer.writeln('---');
    }
    return buffer.toString();
  }
}

/// Log entry type
enum LogType {
  request,
  response,
  error,
}

/// API log entry
class ApiLogEntry {
  final LogType type;
  final String method;
  final String url;
  final DateTime timestamp;
  final int? statusCode;
  final Map<String, dynamic>? headers;
  final dynamic body;
  final String? error;
  final String? stackTrace;
  final Duration? duration;

  ApiLogEntry({
    required this.type,
    required this.method,
    required this.url,
    required this.timestamp,
    this.statusCode,
    this.headers,
    this.body,
    this.error,
    this.stackTrace,
    this.duration,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('${type.name.toUpperCase()}: ');
    buffer.write('$method $url');

    if (statusCode != null) {
      buffer.write(' ($statusCode)');
    }

    if (duration != null) {
      buffer.write(' - ${duration!.inMilliseconds}ms');
    }

    if (error != null) {
      buffer.write('\nError: $error');
    }

    return buffer.toString();
  }
}

/// Global API logger instance
final apiLogger = ApiLogger();
