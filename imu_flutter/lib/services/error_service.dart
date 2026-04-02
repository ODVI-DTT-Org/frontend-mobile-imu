import 'package:flutter/material.dart';
import '../models/error_model.dart';

/// Error Service for displaying standardized error messages
///
/// Provides methods to show errors in SnackBars with consistent formatting
class ErrorService {
  /// Show error as SnackBar
  static void showError(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? action,
  }) {
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Build error message with metadata
    final message = error.message;
    final code = error.code;
    final shortRequestId = error.shortRequestId;

    // Create content widget with error details
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Code: $code',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ID: $shortRequestId',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ],
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: Colors.red.shade700,
        duration: duration,
        action: action != null
            ? SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  scaffoldMessenger.hideCurrentSnackBar();
                  action();
                },
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error dialog with details
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    String? title,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main error message
              Text(
                error.message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Error code and request ID
              _buildDetailRow('Code', error.code),
              _buildDetailRow('Request ID', error.shortRequestId),
              _buildDetailRow('Timestamp', error.timestamp),

              // Suggestions if available
              if (error.suggestions != null && error.suggestions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Suggestions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...error.suggestions!.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      '• $suggestion',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show validation errors inline
  static void showValidationErrors(
    BuildContext context,
    List<FieldError> errors,
  ) {
    // This is meant to be used by form widgets to display inline errors
    // The actual display should be handled by the form UI
    debugPrint('Validation errors: ${errors.map((e) => e.toString()).join(', ')}');
  }

  /// Parse error from API response
  static AppError? parseError(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        // Check if this is our standardized error format
        if (data.containsKey('code') && data.containsKey('requestId')) {
          return AppError.fromJson(data);
        }

        // Check for legacy error format
        if (data.containsKey('error') || data.containsKey('message')) {
          return AppError(
            requestId: generateRequestId(),
            timestamp: DateTime.now().toIso8601String(),
            code: data['code'] as String? ?? 'UNKNOWN_ERROR',
            message: (data['message'] as String?) ?? (data['error'] as String?) ?? 'An error occurred',
            path: '',
            method: '',
          );
        }
      }

      // Handle string errors
      if (data is String) {
        return AppError(
          requestId: generateRequestId(),
          timestamp: DateTime.now().toIso8601String(),
          code: 'UNKNOWN_ERROR',
          message: data,
          path: '',
          method: '',
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing error response: $e');
      return null;
    }
  }

  /// Generate a random request ID for errors that don't have one
  static String generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'client-$random';
  }

  /// Build detail row for error dialog
  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extension on AppError to get user-friendly display name
extension AppErrorExtension on AppError {
  /// Get user-friendly title for the error
  String get title {
    switch (code) {
      case 'VALIDATION_ERROR':
        return 'Invalid Input';
      case 'UNAUTHORIZED':
      case 'INVALID_CREDENTIALS':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_INVALID':
        return 'Authentication Error';
      case 'FORBIDDEN':
      case 'INSUFFICIENT_PERMISSIONS':
        return 'Access Denied';
      case 'NOT_FOUND':
        return 'Not Found';
      case 'CONFLICT':
        return 'Conflict';
      case 'RATE_LIMIT_EXCEEDED':
        return 'Too Many Requests';
      case 'NETWORK_ERROR':
        return 'Network Error';
      default:
        return 'Error';
    }
  }

  /// Get user-friendly icon for the error
  IconData get icon {
    switch (code) {
      case 'VALIDATION_ERROR':
        return Icons.error_outline;
      case 'UNAUTHORIZED':
      case 'INVALID_CREDENTIALS':
      case 'TOKEN_EXPIRED':
      case 'TOKEN_INVALID':
        return Icons.lock_outline;
      case 'FORBIDDEN':
      case 'INSUFFICIENT_PERMISSIONS':
        return Icons.block;
      case 'NOT_FOUND':
        return Icons.search_off;
      case 'CONFLICT':
        return Icons.sync_problem;
      case 'RATE_LIMIT_EXCEEDED':
        return Icons.speed;
      case 'NETWORK_ERROR':
        return Icons.wifi_off;
      default:
        return Icons.error;
    }
  }
}
