import 'package:flutter/material.dart';

class ProgressDialog {
  static OverlayEntry? _overlayEntry;
  static String? _currentMessage;
  static double? _currentProgress;

  /// Show a progress dialog overlay.
  ///
  /// [message] Optional message to display below the spinner.
  /// [progress] Optional progress value (0.0 to 1.0) for determinate progress.
  /// [dismissible] Whether the dialog can be dismissed by tapping outside (default: false).
  static void show(
    BuildContext context, {
    String? message,
    double? progress,
    bool dismissible = false,
  }) {
    _dismiss(); // Dismiss any existing dialog

    _currentMessage = message;
    _currentProgress = progress;

    _overlayEntry = OverlayEntry(
      builder: (context) => _ProgressDialog(
        message: _currentMessage,
        progress: _currentProgress,
        dismissible: dismissible,
        onDismiss: _dismiss,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Update the current progress dialog.
  ///
  /// [message] New message to display (optional).
  /// [progress] New progress value from 0.0 to 1.0 (optional).
  static void update({String? message, double? progress}) {
    if (message != null) _currentMessage = message;
    if (progress != null) _currentProgress = progress;

    _overlayEntry?.markNeedsBuild();
  }

  /// Dismiss the current progress dialog.
  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentMessage = null;
    _currentProgress = null;
  }

  /// Check if a progress dialog is currently visible.
  static bool get isVisible => _overlayEntry != null;
}

class _ProgressDialog extends StatelessWidget {
  final String? message;
  final double? progress;
  final bool dismissible;
  final VoidCallback? onDismiss;

  const _ProgressDialog({
    this.message,
    this.progress,
    this.dismissible = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: dismissible ? onDismiss : null,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message != null)
                  Text(
                    message!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (progress != null) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
                if (progress == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
