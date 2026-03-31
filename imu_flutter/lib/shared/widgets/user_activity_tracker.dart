import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/session_service.dart';

/// Widget that tracks user activity for session management.
///
/// Wraps a child widget and detects:
/// - Tap events
/// - Scroll events
/// - Keyboard events
///
/// All activity is reported to SessionService for auto-lock functionality.
class UserActivityTracker extends StatefulWidget {
  final Widget child;
  final SessionService sessionService;

  const UserActivityTracker({
    super.key,
    required this.child,
    required this.sessionService,
  });

  @override
  State<UserActivityTracker> createState() => _UserActivityTrackerState();
}

class _UserActivityTrackerState extends State<UserActivityTracker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleActivity,
      onScaleStart: (_) => _handleActivity(),
      onLongPressStart: (_) => _handleActivity(),
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth == 0) {
            // Only track top-level scroll events
            _handleActivity();
          }
          return false;
        },
        child: KeyboardListener(
          focusOn: true,
          onKeyEvent: (event, _) {
            if (event is! KeyUpEvent) {
              // Track key down events (ignore key up)
              _handleActivity();
            }
            return KeyEventResult.ignored;
          },
          child: widget.child,
        ),
      ),
    );
  }

  void _handleActivity() {
    widget.sessionService.recordActivity();
  }
}
