import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/config/app_config.dart';
import '../models/error_report_model.dart';

/// Error Reporter Service
///
/// Collects error reports from the mobile app and sends them to the backend.
/// Implements offline-first queue with deduplication and rate limiting.
class ErrorReporterService {
  static final ErrorReporterService _instance = ErrorReporterService._internal();
  factory ErrorReporterService() => _instance;
  ErrorReporterService._internal();

  static const String _errorQueueBox = 'error_queue';
  static const int _maxQueueSize = 1000;
  static const String _lastFingerprintKey = 'last_fingerprints';

  late Dio _dio;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// Initialize the error reporter
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Open error queue box
      if (!Hive.isBoxOpen(_errorQueueBox)) {
        await Hive.openBox<String>(_errorQueueBox);
      }

      // Initialize Dio with timeout
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
  ///
  /// This will queue the error locally and sync it to the backend when online.
  /// Duplicate errors (within 1 minute) are automatically skipped.
  Future<void> reportError(ErrorReport report) async {
    if (!_isInitialized) {
      debugPrint('[ErrorReporter] Not initialized, skipping error report');
      return;
    }

    try {
      // Generate fingerprint if not provided
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

      // Check for duplicate in recent fingerprints
      if (_isDuplicate(report.fingerprint!)) {
        debugPrint('[ErrorReporter] Skipping duplicate error: ${report.fingerprint}');
        return;
      }

      // Add to queue
      await _addToQueue(report);

      // Store fingerprint for deduplication
      await _storeFingerprint(report.fingerprint!);

      debugPrint('[ErrorReporter] Error queued: ${report.code} (${report.id})');

      // Try to sync immediately if online
      await syncErrors();
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to report error: $e');
    }
  }

  /// Sync queued errors to the backend
  Future<void> syncErrors() async {
    if (!_isInitialized || _isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      final box = Hive.box<String>(_errorQueueBox);
      final errors = box.keys.toList();

      if (errors.isEmpty) {
        debugPrint('[ErrorReporter] No errors to sync');
        return;
      }

      debugPrint('[ErrorReporter] Syncing ${errors.length} errors...');

      // Sync errors in batches of 10
      const batchSize = 10;
      int synced = 0;
      int failed = 0;

      for (int i = 0; i < errors.length; i += batchSize) {
        final batch = errors.skip(i).take(batchSize).toList();

        for (final errorId in batch) {
          try {
            final errorJson = box.get(errorId);
            if (errorJson == null) continue;

            final report = ErrorReport.fromJsonString(errorJson);
            final response = await _sendError(report);

            if (response.logged || response.reason == 'duplicate') {
              // Remove from queue on success or duplicate
              await box.delete(errorId);
              synced++;
            } else {
              failed++;
            }
          } catch (e) {
            debugPrint('[ErrorReporter] Failed to sync error $errorId: $e');
            failed++;
          }
        }
      }

      debugPrint('[ErrorReporter] Sync complete: $synced synced, $failed failed');
    } catch (e) {
      debugPrint('[ErrorReporter] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Get queue size
  Future<int> getQueueSize() async {
    if (!_isInitialized) return 0;

    try {
      final box = Hive.box<String>(_errorQueueBox);
      return box.length;
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to get queue size: $e');
      return 0;
    }
  }

  /// Clear all queued errors
  Future<void> clearQueue() async {
    if (!_isInitialized) return;

    try {
      final box = Hive.box<String>(_errorQueueBox);
      await box.clear();
      debugPrint('[ErrorReporter] Queue cleared');
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to clear queue: $e');
    }
  }

  /// Generate SHA-256 fingerprint for deduplication
  String _generateFingerprint(String code, String message, String? stackTrace) {
    final content = stackTrace != null && stackTrace.isNotEmpty
        ? '$code:$message:$stackTrace'
        : '$code:$message';

    final bytes = utf8.encode(content);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Check if fingerprint is a recent duplicate
  bool _isDuplicate(String fingerprint) {
    try {
      final box = Hive.box<String>(_errorQueueBox);
      final lastFingerprintsJson = box.get(_lastFingerprintKey, defaultValue: '{}');

      if (lastFingerprintsJson == null || lastFingerprintsJson.isEmpty) {
        return false;
      }

      final lastFingerprints = jsonDecode(lastFingerprintsJson) as Map<String, dynamic>;
      final lastSeen = lastFingerprints[fingerprint] as String?;

      if (lastSeen == null || lastSeen.isEmpty) {
        return false;
      }

      // Check if seen within last 60 seconds
      final lastSeenTime = DateTime.parse(lastSeen);
      final diff = DateTime.now().difference(lastSeenTime);

      return diff.inSeconds < 60;
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to check duplicate: $e');
      return false;
    }
  }

  /// Store fingerprint for deduplication
  Future<void> _storeFingerprint(String fingerprint) async {
    try {
      final box = Hive.box<String>(_errorQueueBox);
      final lastFingerprintsJson = box.get(_lastFingerprintKey, defaultValue: '{}');

      Map<String, dynamic> lastFingerprints = {};
      if (lastFingerprintsJson != null && lastFingerprintsJson.isNotEmpty) {
        try {
          lastFingerprints = jsonDecode(lastFingerprintsJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('[ErrorReporter] Failed to parse last fingerprints: $e');
        }
      }

      // Add current fingerprint
      lastFingerprints[fingerprint] = DateTime.now().toIso8601String();

      // Clean up old fingerprints (older than 60 seconds)
      final now = DateTime.now();
      lastFingerprints.removeWhere((key, value) {
        try {
          final valueStr = value as String?;
          if (valueStr == null) return true; // Remove null entries
          final timestamp = DateTime.parse(valueStr);
          return now.difference(timestamp).inSeconds > 60;
        } catch (e) {
          return true; // Remove invalid entries
        }
      });

      // Keep only last 100 fingerprints to prevent memory bloat
      if (lastFingerprints.length > 100) {
        final entries = lastFingerprints.entries.toList()
          ..sort((a, b) {
            final aValue = a.value as String?;
            final bValue = b.value as String?;
            if (aValue == null) return 1;
            if (bValue == null) return -1;
            return aValue.compareTo(bValue);
          });
        final toRemove = entries.take(lastFingerprints.length - 100);
        for (final entry in toRemove) {
          lastFingerprints.remove(entry.key);
        }
      }

      await box.put(_lastFingerprintKey, jsonEncode(lastFingerprints));
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to store fingerprint: $e');
    }
  }

  /// Add error to queue with FIFO eviction
  Future<void> _addToQueue(ErrorReport report) async {
    try {
      final box = Hive.box<String>(_errorQueueBox);

      // Check queue size and evict oldest if necessary
      if (box.length >= _maxQueueSize) {
        final oldestKey = box.keys.first;
        await box.delete(oldestKey);
        debugPrint('[ErrorReporter] Queue full, evicted oldest error: $oldestKey');
      }

      // Add new error
      await box.put(report.id, report.toJsonString());
    } catch (e) {
      debugPrint('[ErrorReporter] Failed to add to queue: $e');
    }
  }

  /// Send error to backend
  Future<ErrorReportResponse> _sendError(ErrorReport report) async {
    try {
      final response = await _dio.post(
        '${AppConfig.backendApiUrl}/errors',
        data: report.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
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
