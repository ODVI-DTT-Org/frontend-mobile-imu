import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/api_exception.dart';
import 'error_message_mapper.dart';
import 'error_contextualizer.dart';

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

  /// Get user-friendly error message using ErrorMessageMapper
  String getUserMessage(dynamic error, {String? userAction}) {
    if (error is ApiException) {
      final errorCode = error.errorCode ?? 'UNKNOWN_ERROR';

      // Use contextualizer if userAction is provided
      if (userAction != null) {
        final contextualMessage = ErrorContextualizer.getContextualMessage(
          errorCode,
          userAction,
        );
        if (contextualMessage != null) {
          return contextualMessage;
        }
      }

      // Fall back to ErrorMessageMapper
      return ErrorMessageMapper.getMessage(errorCode);
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get error suggestions using ErrorMessageMapper
  List<String> getErrorSuggestions(dynamic error) {
    if (error is ApiException) {
      final errorCode = error.errorCode ?? 'UNKNOWN_ERROR';
      return ErrorMessageMapper.getSuggestions(errorCode);
    }
    return [];
  }

  /// Get error severity from status code
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (error is ApiException) {
      final statusCode = error.statusCode;

      if (statusCode != null) {
        if (statusCode! >= 500) {
          return ErrorSeverity.critical;
        } else if (statusCode! >= 400) {
          return ErrorSeverity.error;
        }
      }

      // Network errors (status code 0)
      if (statusCode == 0) {
        return ErrorSeverity.error;
      }
    }

    return ErrorSeverity.error;
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
