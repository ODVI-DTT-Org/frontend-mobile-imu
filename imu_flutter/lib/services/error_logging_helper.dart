import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'package:package_info_plus/package_info_plus.dart'; // Temporarily disabled for build
import 'package:uuid/uuid.dart';
import '../models/error_report_model.dart';
import 'error_reporter_service.dart';
import 'sync/powersync_service.dart';
import 'auth/jwt_auth_service.dart';

/// Centralized error logging helper
/// Routes errors based on workflow impact: critical → direct API, non-critical → PowerSync
class ErrorLoggingHelper {
  /// Log critical error (blocks workflow) - direct to API
  static Future<void> logCriticalError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      final report = ErrorReport(
        code: _extractErrorCode(error),
        message: 'Failed to $operation: ${error.toString()}',
        platform: ErrorPlatform.mobile,
        stackTrace: stackTrace?.toString(),
        userId: await _getCurrentUserId(),
        appVersion: await _getAppVersion(),
        osVersion: await _getOsVersion(),
        deviceInfo: await _getDeviceInfo(),
        details: {'operation': operation, ...?context},
      );

      // Direct API call via ErrorReporterService
      await ErrorReporterService().reportError(report);

      debugPrint('[ErrorLogging] Critical error logged: $operation');
    } catch (e) {
      // Silently fail - don't let error logging break the app
      debugPrint('[ErrorLogging] Failed to log critical error: $e');
    }
  }

  /// Log non-critical error (user can continue) - PowerSync batch
  static Future<void> logNonCriticalError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      final report = ErrorReport(
        code: _extractErrorCode(error),
        message: 'Warning during $operation: ${error.toString()}',
        platform: ErrorPlatform.mobile,
        stackTrace: stackTrace?.toString(),
        userId: await _getCurrentUserId(),
        appVersion: await _getAppVersion(),
        osVersion: await _getOsVersion(),
        deviceInfo: await _getDeviceInfo(),
        details: {'operation': operation, ...?context},
      );

      // Queue to PowerSync
      await _queueForPowerSync(report);

      debugPrint('[ErrorLogging] Non-critical error queued: $operation');
    } catch (e) {
      // Silently fail
      debugPrint('[ErrorLogging] Failed to queue non-critical error: $e');
    }
  }

  /// Extract error code from exception
  static String _extractErrorCode(Object error) {
    final errorString = error.toString();

    if (errorString.contains('SocketException')) {
      return 'CONNECTION_ERROR';
    }
    if (errorString.contains('TimeoutException')) {
      return 'TIMEOUT_ERROR';
    }
    if (errorString.contains('HttpException')) {
      return 'HTTP_ERROR';
    }
    if (errorString.contains('DioException')) {
      return 'DIO_ERROR';
    }
    if (errorString.contains('DatabaseException')) {
      return 'DATABASE_ERROR';
    }
    if (errorString.contains('FormatException')) {
      return 'FORMAT_ERROR';
    }

    // Fallback: use runtime type
    return error.runtimeType.toString()
        .toUpperCase()
        .replaceAll('EXCEPTION', '_ERROR');
  }

  /// Get current user ID from JWT auth
  static Future<String?> _getCurrentUserId() async {
    try {
      final jwtAuth = JwtAuthService();
      return jwtAuth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  /// Get app version from package_info_plus
  static Future<String> _getAppVersion() async {
    // Temporarily disabled package_info_plus due to Kotlin compilation issues
    // TODO: Re-enable after updating to compatible package_info_plus version
    try {
      // final info = await PackageInfo.fromPlatform();
      // return info.version;
      return '1.3.2'; // Fallback to known version from pubspec.yaml
    } catch (e) {
      debugPrint('[ErrorLogging] Failed to get app version: $e');
      return '1.3.2'; // Fallback to known version
    }
  }

  /// Get OS version
  static Future<String> _getOsVersion() async {
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  /// Get device information
  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
    };
  }

  /// Queue non-critical error to PowerSync
  static Future<void> _queueForPowerSync(ErrorReport report) async {
    try {
      await PowerSyncService.execute(
        'INSERT INTO error_logs (code, message, platform, stack_trace, user_id, '
        'request_id, fingerprint, app_version, os_version, device_info, details, '
        'is_synced, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)',
        [
          report.code,
          report.message,
          report.platform.value,
          report.stackTrace ?? '',
          report.userId ?? '',
          report.requestId ?? '',
          report.fingerprint ?? '',
          report.appVersion ?? '',
          report.osVersion ?? '',
          jsonEncode(report.deviceInfo ?? {}),
          jsonEncode(report.details ?? {}),
          report.createdAt.toIso8601String(),
        ],
      );
    } catch (e) {
      debugPrint('[ErrorLogging] Failed to queue error for PowerSync: $e');
    }
  }
}
