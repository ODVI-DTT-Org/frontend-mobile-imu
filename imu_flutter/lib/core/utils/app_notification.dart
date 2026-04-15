import 'package:flutter/material.dart';
import 'dart:async';

/// Unified notification system for IMU app
/// All notifications appear at the TOP of the screen with consistent styling
///
/// Color scheme:
/// - Success: Green
/// - Warning: Orange
/// - Error: Red
/// - Neutral: Gray
class AppNotification {
  AppNotification._();

  static OverlayEntry? _currentNotification;
  static Timer? _dismissTimer;

  /// Show success notification (green)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      type: _NotificationType.success,
      duration: duration,
    );
  }

  /// Show error notification (red)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      message: message,
      type: _NotificationType.error,
      duration: duration,
    );
  }

  /// Show warning notification (orange)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      type: _NotificationType.warning,
      duration: duration,
    );
  }

  /// Show neutral/info notification (gray)
  static void showNeutral(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showNotification(
      context,
      message: message,
      type: _NotificationType.neutral,
      duration: duration,
    );
  }

  /// Show success notification with action button
  static void showSuccessWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _dismissCurrent();
    _showNotification(
      context,
      message: message,
      type: _NotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show error notification with action button
  static void showErrorWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _dismissCurrent();
    _showNotification(
      context,
      message: message,
      type: _NotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show warning notification with action button
  static void showWarningWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _dismissCurrent();
    _showNotification(
      context,
      message: message,
      type: _NotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Show neutral notification with action button
  static void showNeutralWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    _dismissCurrent();
    _showNotification(
      context,
      message: message,
      type: _NotificationType.neutral,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Dismiss current notification
  static void dismiss() {
    _dismissCurrent();
  }

  static void _showNotification(
    BuildContext context, {
    required String message,
    required _NotificationType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _dismissCurrent();

    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    _currentNotification = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: _dismissCurrent,
        theme: theme,
      ),
    );

    overlay.insert(_currentNotification!);

    if (duration != Duration.zero) {
      _dismissTimer = Timer(duration, _dismissCurrent);
    }
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentNotification?.remove();
    _currentNotification = null;
  }
}

enum _NotificationType { success, error, warning, neutral }

class _TopNotificationWidget extends StatelessWidget {
  final String message;
  final _NotificationType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final ThemeData theme;

  const _TopNotificationWidget({
    required this.message,
    required this.type,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        elevation: 6,
        shadowColor: colors.shadow,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _buildIcon(colors.iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  TextButton(
                    onPressed: () {
                      onAction!();
                      onDismiss();
                    },
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: colors.iconColor,
                    size: 18,
                  ),
                  onPressed: onDismiss,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(Color color) {
    switch (type) {
      case _NotificationType.success:
        return Icon(Icons.check_circle, color: color, size: 20);
      case _NotificationType.error:
        return Icon(Icons.error, color: color, size: 20);
      case _NotificationType.warning:
        return Icon(Icons.warning, color: color, size: 20);
      case _NotificationType.neutral:
        return Icon(Icons.info, color: color, size: 20);
    }
  }

  _NotificationColors _getColors() {
    switch (type) {
      case _NotificationType.success:
        return _NotificationColors(
          background: const Color(0xFF10B981), // Green
          iconColor: Colors.white,
          text: Colors.white,
          border: const Color(0xFF059669),
          shadow: const Color(0x3D10B981),
        );
      case _NotificationType.error:
        return _NotificationColors(
          background: const Color(0xFFEF4444), // Red
          iconColor: Colors.white,
          text: Colors.white,
          border: const Color(0xFFDC2626),
          shadow: const Color(0x3DEF4444),
        );
      case _NotificationType.warning:
        return _NotificationColors(
          background: const Color(0xFFF59E0B), // Orange
          iconColor: Colors.white,
          text: Colors.white,
          border: const Color(0xFFD97706),
          shadow: const Color(0x3DF59E0B),
        );
      case _NotificationType.neutral:
        return _NotificationColors(
          background: const Color(0xFF6B7280), // Gray
          iconColor: Colors.white,
          text: Colors.white,
          border: const Color(0xFF4B5563),
          shadow: const Color(0x3D6B7280),
        );
    }
  }
}

class _NotificationColors {
  final Color background;
  final Color iconColor;
  final Color text;
  final Color border;
  final Color shadow;

  _NotificationColors({
    required this.background,
    required this.iconColor,
    required this.text,
    required this.border,
    required this.shadow,
  });
}
