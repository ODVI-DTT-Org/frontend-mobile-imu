import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../models/error_report_model.dart';
import 'sync/powersync_service.dart';

/// Error Reporter Service
///
/// Collects error reports from the mobile app and sends them to the backend.
/// Implements offline-first queue with deduplication and rate limiting.
/// Queue is stored in the PowerSync `error_logs` SQLite table.
class ErrorReporterService {
  static final ErrorReporterService _instance = ErrorReporterService._internal();
  factory ErrorReporterService() => _instance;
  ErrorReporterService._internal();

  static const int _maxQueueSize = 1000;

  late Dio _dio;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize the error reporter
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      _isInitialized = true;
      debugPrint('[ErrorReporter] Initialized');
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to initialize: $e');
    }
  }

  /// Report an error
  Future<void> reportError(ErrorReport report) async {
    if (!_isInitialized) {
      debugPrint('[ErrorReporter] Not initialized, skipping error report');
      return;
    }

    try {
      if (report.fingerprint == null || report.fingerprint!.isEmpty) {
        report = ErrorReport(
          code: report.code,
          message: report.message,
          statusCode: report.statusCode,
          platform: report.platform,
          stackTrace: report.stackTrace,
          userId: report.userId,
          requestId: report.requestId,
          fingerprint: _generateFingerprint(report.code, report.message, report.stackTrace),
          appVersion: report.appVersion,
          osVersion: report.osVersion,
          deviceInfo: report.deviceInfo,
          details: report.details,
          suggestions: report.suggestions,
          documentationUrl: report.documentationUrl,
          createdAt: report.createdAt,
        );
      }

      if (await _isDuplicate(report.fingerprint!)) {
        debugPrint('[ErrorReporter] Skipping duplicate error: ${report.fingerprint}');
        return;
      }

      await _addToQueue(report);
      debugPrint('[ErrorReporter] Error queued: ${report.code} (${report.id})');

      await syncErrors();
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to report error: $e');
    }
  }

  /// Sync queued errors to the backend
  Future<void> syncErrors() async {
    if (!_isInitialized || _isSyncing) return;

    _isSyncing = true;

    try {
      final db = await PowerSyncService.database;
      final rows = await db.getAll(
        'SELECT * FROM error_logs WHERE is_synced = 0 ORDER BY created_at ASC',
      );

      if (rows.isEmpty) {
        debugPrint('[ErrorReporter] No errors to sync');
        return;
      }

      debugPrint('[ErrorReporter] Syncing ${rows.length} errors...');
      int synced = 0, failed = 0;

      for (final row in rows) {
        try {
          final report = _reportFromRow(row);
          final response = await _sendError(report);

          if (response.logged || response.reason == 'duplicate') {
            await db.execute(
              'UPDATE error_logs SET is_synced = 1 WHERE id = ?',
              [row['id']],
            );
            synced++;
          } else {
            failed++;
          }
        } catch (e) {
          debugPrint('[ErrorReporter] Failed to sync error ${row['id']}: $e');
          failed++;
        }
      }

      debugPrint('[ErrorReporter] Sync complete: $synced synced, $failed failed');
    } catch (e) {
      debugPrint('[ErrorReporter] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get queue size (unsent errors)
  Future<int> getQueueSize() async {
    if (!_isInitialized) return 0;

    try {
      final db = await PowerSyncService.database;
      final result = await db.get(
        'SELECT COUNT(*) as count FROM error_logs WHERE is_synced = 0',
      );
      return (result['count'] as int? ?? 0);
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to get queue size: $e');
      return 0;
    }
  }

  /// Clear all unsent queued errors
  Future<void> clearQueue() async {
    if (!_isInitialized) return;

    try {
      final db = await PowerSyncService.database;
      await db.execute('DELETE FROM error_logs WHERE is_synced = 0');
      debugPrint('[ErrorReporter] Queue cleared');
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to clear queue: $e');
    }
  }

  String _generateFingerprint(String code, String message, String? stackTrace) {
    final content = stackTrace != null && stackTrace.isNotEmpty
        ? '$code:$message:$stackTrace'
        : '$code:$message';

    return sha256.convert(utf8.encode(content)).toString();
  }

  Future<bool> _isDuplicate(String fingerprint) async {
    try {
      final db = await PowerSyncService.database;
      final cutoff = DateTime.now()
          .subtract(const Duration(seconds: 60))
          .toIso8601String();
      final result = await db.getOptional(
        'SELECT id FROM error_logs WHERE fingerprint = ? AND created_at > ? LIMIT 1',
        [fingerprint, cutoff],
      );
      return result != null;
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to check duplicate: $e');
      return false;
    }
  }

  Future<void> _addToQueue(ErrorReport report) async {
    try {
      final db = await PowerSyncService.database;

      final countResult = await db.get(
        'SELECT COUNT(*) as c FROM error_logs WHERE is_synced = 0',
      );
      final count = (countResult['c'] as int? ?? 0);

      if (count >= _maxQueueSize) {
        final oldest = await db.getOptional(
          'SELECT id FROM error_logs WHERE is_synced = 0 ORDER BY created_at ASC LIMIT 1',
        );
        if (oldest != null) {
          await db.execute('DELETE FROM error_logs WHERE id = ?', [oldest['id']]);
          debugPrint('[ErrorReporter] Queue full, evicted oldest error');
        }
      }

      await db.execute(
        'INSERT INTO error_logs (id, code, message, platform, stack_trace, user_id, request_id, fingerprint, app_version, os_version, device_info, details, is_synced, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)',
        [
          report.id,
          report.code,
          report.message,
          report.platform.value,
          report.stackTrace,
          report.userId,
          report.requestId,
          report.fingerprint,
          report.appVersion,
          report.osVersion,
          report.deviceInfo != null ? jsonEncode(report.deviceInfo) : null,
          report.details != null ? jsonEncode(report.details) : null,
          report.createdAt.toIso8601String(),
        ],
      );
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to add to queue: $e');
    }
  }

  ErrorReport _reportFromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? deviceInfo;
    Map<String, dynamic>? details;

    try {
      final deviceInfoStr = row['device_info'] as String?;
      if (deviceInfoStr != null) {
        deviceInfo = jsonDecode(deviceInfoStr) as Map<String, dynamic>?;
      }
    } catch (_) {}

    try {
      final detailsStr = row['details'] as String?;
      if (detailsStr != null) {
        details = jsonDecode(detailsStr) as Map<String, dynamic>?;
      }
    } catch (_) {}

    return ErrorReport(
      code: row['code'] as String? ?? 'UNKNOWN',
      message: row['message'] as String? ?? '',
      platform: ErrorPlatform.fromString(row['platform'] as String? ?? 'mobile'),
      stackTrace: row['stack_trace'] as String?,
      userId: row['user_id'] as String?,
      requestId: row['request_id'] as String?,
      fingerprint: row['fingerprint'] as String?,
      appVersion: row['app_version'] as String?,
      osVersion: row['os_version'] as String?,
      deviceInfo: deviceInfo,
      details: details,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Future<ErrorReportResponse> _sendError(ErrorReport report) async {
    try {
      final response = await _dio.post(
        '${AppConfig.backendApiUrl}/errors',
        data: report.toJson(),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ErrorReportResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to send error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to send error: $e');
      rethrow;
    }
  }
}
