import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';

/// Error boundary widget that provides structured error UI for Flutter apps.
///
/// **IMPORTANT LIMITATION:** Flutter doesn't support try-catch for widget errors.
/// This widget provides a structured UI for displaying errors, but doesn't
/// automatically catch build errors. To catch errors globally, use:
///
/// ```dart
/// // In main.dart:
/// ErrorWidget.builder = (details) {
///   return CustomErrorWidget(details);
/// };
/// ```
///
/// Alternatively, use packages like `catcher` or `flutter_error_handler`.
///
/// **Usage:**
/// ```dart
/// ErrorBoundary(
///   child: MyWidget(),
///   onError: (error, stackTrace) {
///     logError('Widget error', error, stackTrace);
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

/// Internal wrapper widget for future error catching implementation.
///
/// Note: This is currently a placeholder wrapper. Flutter doesn't provide
/// a direct way to catch errors in widget subtrees without using ErrorWidget.builder
/// globally. This wrapper exists for future implementation when Flutter adds
/// fine-grained error boundary support.
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
    // Placeholder: returns child directly without error catching
    // Error catching would require ErrorWidget.builder at app level
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
