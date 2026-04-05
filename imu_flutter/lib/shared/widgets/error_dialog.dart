import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/error_model.dart' as backend_models;
import '../../services/error_handling_service.dart';
import '../../services/error_message_mapper.dart';

/// Error dialog widget for showing user-friendly error messages
///
/// Supports both backend AppError (from API) and local AppError (from error_handling_service)
class ErrorDialog extends StatelessWidget {
  final dynamic error; // Can be backend_models.AppError or AppError
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? userAction; // Optional: for context-aware messages

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.userAction,
  });

  @override
  Widget build(BuildContext context) {
    // Detect error type and extract information
    final isBackendError = error is backend_models.AppError;

    String title;
    String message;
    List<String> suggestions;
    IconData icon;
    Color color;

    if (isBackendError) {
      // Use ErrorMessageMapper for backend errors
      final backendError = error as backend_models.AppError;
      title = ErrorMessageMapper.getTitle(backendError.code);
      message = ErrorMessageMapper.getMessage(backendError.code, details: backendError.details);
      suggestions = ErrorMessageMapper.getSuggestions(backendError.code);
      icon = ErrorMessageMapper.getIcon(backendError.code);
      color = ErrorMessageMapper.getColor(backendError.code);
    } else {
      // Use local error properties (backward compatibility)
      final localError = error as AppError;
      title = _getTitle(localError.severity);
      message = localError.message;
      suggestions = [];
      icon = _getIcon(localError.severity);
      color = _getIconColor(localError.severity);
    }

    // Apply contextualization if userAction is provided
    if (userAction != null && isBackendError) {
      final backendError = error as backend_models.AppError;
      final contextualMessage = _ErrorContextualizer.getContextualMessage(
        backendError.code,
        userAction!,
      );
      if (contextualMessage != null) {
        message = contextualMessage;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with colored background
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),

            // User-friendly title
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Clear error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),

            // Actionable suggestions
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'What you can do:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              ...suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons
            const SizedBox(height: 24),
            if (onRetry != null || onDismiss != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onRetry != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onRetry!();
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  if (onRetry != null && onDismiss != null)
                    const SizedBox(width: 12),
                  if (onDismiss != null)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismiss!();
                        },
                        child: const Text('Dismiss'),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Legacy methods for local AppError (backward compatibility)
  IconData _getIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return LucideIcons.info;
      case ErrorSeverity.warning:
        return LucideIcons.alertTriangle;
      case ErrorSeverity.error:
        return LucideIcons.alertCircle;
      case ErrorSeverity.critical:
        return LucideIcons.alertOctagon;
      default:
        return LucideIcons.alertCircle;
    }
  }

  String _getTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
      default:
        return 'Error';
    }
  }

  Color _getIconColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red[700]!;
      default:
        return Colors.grey;
    }
  }
}

/// Private contextualizer for error dialog
class _ErrorContextualizer {
  static String? getContextualMessage(String errorCode, String userAction) {
    final key = '${userAction}_$errorCode';
    return _contextualMessages[key];
  }

  static const Map<String, String> _contextualMessages = {
    // Login action
    'login_INVALID_CREDENTIALS': 'Invalid email or password. Please try again.',
    'login_NETWORK_ERROR': 'Unable to sign in. Please check your internet connection.',

    // Save client action
    'save_client_VALIDATION_ERROR': 'Please check the client information.',
    'save_client_NETWORK_ERROR': 'Unable to save client. Please check your connection.',

    // Submit touchpoint action
    'submit_touchpoint_VALIDATION_ERROR': 'Please check the touchpoint information.',
    'submit_touchpoint_INVALID_TOUCHPOINT_TYPE': 'You can only create visit touchpoints.',

    // Sync data action
    'sync_data_NETWORK_ERROR': 'Unable to sync. Please check your internet connection.',
  };
}
