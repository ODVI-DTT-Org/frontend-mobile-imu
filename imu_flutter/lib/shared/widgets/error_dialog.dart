import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/error_handling_service.dart';

/// Error dialog widget for showing user-friendly error messages
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkError = error.severity == ErrorSeverity.error ||
        error.severity == ErrorSeverity.critical;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getIconColor(error.severity).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(error.severity),
                color: _getIconColor(error.severity),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getTitle(error.severity),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
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
                        icon: const Icon(LucideIcons.refreshCw),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getIconColor(error.severity),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
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
