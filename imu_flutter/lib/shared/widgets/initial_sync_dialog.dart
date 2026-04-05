import 'package:flutter/material.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Dialog showing initial sync progress
///
/// Displays a loading indicator with progress text showing
/// current/total counts during the initial clients sync.
class InitialSyncDialog extends StatefulWidget {
  /// Function to execute the sync operation
  final Future<void> Function() onSync;

  /// Callback when sync completes successfully
  final VoidCallback? onComplete;

  /// Callback when sync fails
  final VoidCallback? onError;

  /// Callback when user cancels (optional)
  final VoidCallback? onCancel;

  const InitialSyncDialog({
    super.key,
    required this.onSync,
    this.onComplete,
    this.onError,
    this.onCancel,
  });

  @override
  State<InitialSyncDialog> createState() => _InitialSyncDialogState();
}

class _InitialSyncDialogState extends State<InitialSyncDialog> {
  bool _isSyncing = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      await widget.onSync();
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        // Auto-close after a short delay on success
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onComplete?.call();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        widget.onError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isSyncing ? false : true,
      child: AlertDialog(
        title: Text(_isSyncing ? 'Preparing Your Account' : (_hasError ? 'Sync Failed' : 'Setup Complete')),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSyncing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  'Syncing your clients...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (_total > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '$_current of $_total clients',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Please wait while we download your assigned clients. This may take a moment.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_hasError) ...[
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to sync your clients',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage.isNotEmpty ? _errorMessage : 'Please check your internet connection and try again.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '$_total clients synced successfully!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        actions: _isSyncing
            ? []
            : [
                if (_hasError)
                  TextButton.icon(
                    onPressed: () {
                      HapticUtils.lightImpact();
                      Navigator.of(context).pop();
                      // Retry by closing and letting caller handle retry
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                  )
                else
                  TextButton.icon(
                    onPressed: () {
                      HapticUtils.lightImpact();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('Continue'),
                  ),
              ],
      ),
    );
  }

  /// Update progress from parent widget
  void updateProgress(int current, int total) {
    if (mounted) {
      setState(() {
        _current = current;
        _total = total;
      });
    }
  }
}

/// Show initial sync dialog
///
/// Returns a Future that completes when the dialog is closed.
/// Use this to show the sync dialog and handle completion.
Future<T?> showInitialSyncDialog<T>({
  required BuildContext context,
  required Future<void> Function(int current, int total) onSync,
  VoidCallback? onComplete,
  VoidCallback? onError,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _InitialSyncDialogContent(
      onSync: onSync,
      onComplete: onComplete,
      onError: onError,
    ),
  );
}

/// Internal content widget for sync dialog
class _InitialSyncDialogContent extends StatefulWidget {
  final Future<void> Function(int current, int total) onSync;
  final VoidCallback? onComplete;
  final VoidCallback? onError;

  const _InitialSyncDialogContent({
    required this.onSync,
    this.onComplete,
    this.onError,
  });

  @override
  State<_InitialSyncDialogContent> createState() => _InitialSyncDialogContentState();
}

class _InitialSyncDialogContentState extends State<_InitialSyncDialogContent> {
  bool _isSyncing = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _startSync();
  }

  Future<void> _startSync() async {
    try {
      await widget.onSync(_current, _total);
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        // Auto-close after a short delay on success
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
            widget.onComplete?.call();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
        widget.onError?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _isSyncing ? false : true,
      child: InitialSyncDialog(
        onSync: () => widget.onSync(_current, _total),
        onComplete: widget.onComplete,
        onError: widget.onError,
      ),
    );
  }
}
