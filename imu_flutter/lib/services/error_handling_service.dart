import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Error severity level
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// App error model
class AppError {
  final String message;
  final String? code;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? stackTrace;
  final dynamic originalError;

  AppError({
    required this.message,
    this.code,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
    this.originalError,
  });

  factory AppError.fromException(dynamic error) {
    if (error is ApiException) {
      return AppError(
        message: error.message,
        code: error.errorCode,
        severity: error.statusCode != null && error.statusCode! >= 500
            ? ErrorSeverity.critical
            : ErrorSeverity.error,
        timestamp: DateTime.now(),
        originalError: error,
      );
    }

    return AppError(
      message: error.toString(),
      severity: ErrorSeverity.error,
      timestamp: DateTime.now(),
      originalError: error,
    );
  }
}

/// Error handling service
class ErrorHandlingService extends StateNotifier<AppError?> {
  ErrorHandlingService() : super(null);

  /// Handle and report error
  void handleError(dynamic error, {String? context, bool reportToAnalytics = true}) {
    final appError = AppError.fromException(error);

    debugPrint('ErrorHandlingService: ${appError.severity.name.toUpperCase()} - ${appError.message}');

    // Update state
    state = appError;

    // Report to analytics in production
    if (reportToAnalytics && kReleaseMode) {
      _reportToAnalytics(appError, context);
    }
  }

  /// Clear current error
  void clearError() {
    state = null;
  }

  void _reportToAnalytics(AppError error, String? context) {
    // In production, integrate with Firebase Crashlytics or similar
    debugPrint('ErrorHandlingService: Would report to analytics - ${error.message}');
  }

  /// Get user-friendly error message
  String getUserMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.errorCode) {
        case 'INVALID_CREDENTIALS':
          return 'Invalid email or password. Please try again.';
        case 'RATE_LIMITED':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'NETWORK_ERROR':
          return 'No internet connection. Please check your network.';
        case 'UNAUTHORIZED':
          return 'Your session has expired. Please log in again.';
        default:
          return error.message;
      }
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Provider for ErrorHandlingService
final errorHandlingServiceProvider =
    StateNotifierProvider<ErrorHandlingService, AppError?>((ref) {
  return ErrorHandlingService();
});

/// Provider for current error
final currentErrorProvider = Provider<AppError?>((ref) {
  return ref.watch(errorHandlingServiceProvider);
});
