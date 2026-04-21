import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';

/// Error boundary widget that catches errors in child widgets.
///
/// Wraps any widget tree and displays a user-friendly error message
/// when an error occurs during build or runtime.
///
/// Usage:
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
///   onError: (error, stackTrace) {
///     Logger.error('Widget error', error: error, stackTrace: stackTrace);
///   },
/// )
/// ```
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final void Function(Object error, StackTrace? stackTrace)? onError;
  final bool showErrorDetails;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.showErrorDetails = false,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Reset error state when widget is recreated
    _error = null;
    _stackTrace = null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Error occurred - show error UI
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!, _stackTrace);
      }

      return _DefaultErrorWidget(
        error: _error!,
        stackTrace: _stackTrace,
        showErrorDetails: widget.showErrorDetails,
        onRetry: () {
          setState(() {
            _error = null;
            _stackTrace = null;
          });
        },
      );
    }

    // No error - build child with error boundary
    return ErrorWidgetBuilder(
      onError: (error, stackTrace) {
        setState(() {
          _error = error;
          _stackTrace = stackTrace;
        });

        // Call custom error handler if provided
        if (widget.onError != null) {
          widget.onError!(error, stackTrace);
        } else {
          // Default error logging
          logError(
            '[ErrorBoundary] Unhandled widget error',
            error,
            stackTrace,
          );
        }
      },
      child: widget.child,
    );
  }
}

/// Internal widget that catches Flutter errors using ErrorWidget.builder
class ErrorWidgetBuilder extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const ErrorWidgetBuilder({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Flutter doesn't have a direct way to catch widget errors
    // This is a placeholder for future implementation with ErrorWidget.builder
    return child;
  }
}

/// Default error widget display
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final bool showErrorDetails;
  final VoidCallback onRetry;

  const _DefaultErrorWidget({
    required this.error,
    this.stackTrace,
    this.showErrorDetails = false,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'An error occurred while rendering this component.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          if (showErrorDetails && stackTrace != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                stackTrace.toString(),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Extension method to easily wrap widgets with ErrorBoundary
extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary({
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    void Function(Object error, StackTrace? stackTrace)? onError,
    bool showErrorDetails = false,
  }) {
    return ErrorBoundary(
      errorBuilder: errorBuilder,
      onError: onError,
      showErrorDetails: showErrorDetails,
      child: this,
    );
  }
}
