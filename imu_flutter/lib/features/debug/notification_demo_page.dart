import 'package:flutter/material.dart';
import '../../core/utils/app_notification.dart';

/// Demo page to showcase the unified notification system
///
/// This page demonstrates all notification types:
/// - Success (green)
/// - Error (red)
/// - Warning (orange)
/// - Neutral (gray)
///
/// All notifications appear at the TOP of the screen.
class NotificationDemoPage extends StatelessWidget {
  const NotificationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Unified Notification System',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All notifications appear at the TOP of the screen.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Success Section
          _buildSection(
            context,
            title: 'Success',
            color: Colors.green,
            buttons: [
              _ButtonData(
                label: 'Show Success',
                onPressed: () => AppNotification.showSuccess(
                  context,
                  'Operation completed successfully!',
                ),
              ),
              _ButtonData(
                label: 'With Action',
                onPressed: () => AppNotification.showSuccessWithAction(
                  context,
                  message: 'Changes saved successfully!',
                  actionLabel: 'View',
                  onAction: () {
                    // Handle view action
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Error Section
          _buildSection(
            context,
            title: 'Error',
            color: Colors.red,
            buttons: [
              _ButtonData(
                label: 'Show Error',
                onPressed: () => AppNotification.showError(
                  context,
                  'Failed to complete operation.',
                ),
              ),
              _ButtonData(
                label: 'With Action',
                onPressed: () => AppNotification.showErrorWithAction(
                  context,
                  message: 'Connection failed.',
                  actionLabel: 'Retry',
                  onAction: () {
                    // Handle retry action
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Warning Section
          _buildSection(
            context,
            title: 'Warning',
            color: Colors.orange,
            buttons: [
              _ButtonData(
                label: 'Show Warning',
                onPressed: () => AppNotification.showWarning(
                  context,
                  'Please review before continuing.',
                ),
              ),
              _ButtonData(
                label: 'With Action',
                onPressed: () => AppNotification.showWarningWithAction(
                  context,
                  message: 'Unsaved changes detected.',
                  actionLabel: 'Save',
                  onAction: () {
                    // Handle save action
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Neutral Section
          _buildSection(
            context,
            title: 'Neutral',
            color: Colors.grey,
            buttons: [
              _ButtonData(
                label: 'Show Neutral',
                onPressed: () => AppNotification.showNeutral(
                  context,
                  'Syncing data...',
                ),
              ),
              _ButtonData(
                label: 'With Action',
                onPressed: () => AppNotification.showNeutralWithAction(
                  context,
                  message: 'Item deleted.',
                  actionLabel: 'Undo',
                  onAction: () {
                    // Handle undo action
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Manual Controls
          const Text(
            'Manual Controls',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => AppNotification.dismiss(),
            child: const Text('Dismiss Current Notification'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Color color,
    required List<_ButtonData> buttons,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...buttons.map(
            (button) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: button.onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(button.label),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonData {
  final String label;
  final VoidCallback onPressed;

  _ButtonData({
    required this.label,
    required this.onPressed,
  });
}
