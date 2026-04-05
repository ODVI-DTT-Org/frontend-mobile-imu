import 'package:flutter/material.dart';
import '../models/error_model.dart';
import 'error_message_mapper.dart';

/// Error Service for displaying standardized error messages
///
/// Provides methods to show errors in SnackBars with consistent formatting
/// Uses ErrorMessageMapper to convert technical errors to user-friendly messages
class ErrorService {
  /// Show error as SnackBar with human-readable message
  static void showError(
    BuildContext context,
    AppError error, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? action,
  }) {
    if (!context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Get human-readable message and color from mapper
    final message = ErrorMessageMapper.getMessage(error.code, details: error.details);
    final color = ErrorMessageMapper.getColor(error.code);

    // Create content widget with error details
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: color,
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

  /// Show error dialog with details and suggestions
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    String? title,
  }) {
    if (!context.mounted) return;

    // Get human-readable content from mapper
    final displayTitle = title ?? ErrorMessageMapper.getTitle(error.code);
    final message = ErrorMessageMapper.getMessage(error.code, details: error.details);
    final suggestions = ErrorMessageMapper.getSuggestions(error.code);
    final icon = ErrorMessageMapper.getIcon(error.code);
    final color = ErrorMessageMapper.getColor(error.code);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: color, size: 32),
        title: Text(displayTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main error message
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Show suggestions from mapper (not from backend response)
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'What you can do:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...suggestions.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 14)),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Show request ID for debugging (in small text)
              const SizedBox(height: 16),
              Text(
                'Reference: ${error.shortRequestId}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
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

  /// Get human-readable error from AppError
  ///
  /// Returns a formatted human-readable error with title, message, and suggestions
  static HumanReadableError getHumanReadableError(AppError error) {
    return HumanReadableError(
      title: ErrorMessageMapper.getTitle(error.code),
      message: ErrorMessageMapper.getMessage(error.code, details: error.details),
      suggestions: ErrorMessageMapper.getSuggestions(error.code),
      icon: ErrorMessageMapper.getIcon(error.code),
      color: ErrorMessageMapper.getColor(error.code),
      requestId: error.shortRequestId,
    );
  }
}

/// Human-readable error data class
///
/// Contains user-friendly error information for display
class HumanReadableError {
  final String title;
  final String message;
  final List<String> suggestions;
  final IconData icon;
  final Color color;
  final String requestId;

  const HumanReadableError({
    required this.title,
    required this.message,
    required this.suggestions,
    required this.icon,
    required this.color,
    required this.requestId,
  });

  @override
  String toString() {
    return 'HumanReadableError(title: $title, message: $message, requestId: $requestId)';
  }
}
