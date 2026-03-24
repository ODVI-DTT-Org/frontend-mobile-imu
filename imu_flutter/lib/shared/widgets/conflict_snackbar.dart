import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';

/// Conflict notification data
class ConflictNotification {
  final String id;
  final String tableName;
  final String recordId;
  final String message;
  final DateTime timestamp;

  ConflictNotification({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service for managing conflict notifications
class ConflictNotificationService {
  final Stream<List<ConflictNotification>> Function() _notificationsStream;
  final void Function(ConflictNotification) _dismissNotification;

  ConflictNotificationService({
    required Stream<List<ConflictNotification>> Function() notificationsStream,
    required void Function(ConflictNotification) dismissNotification,
  })  : _notificationsStream = notificationsStream,
        _dismissNotification = dismissNotification;

  Stream<List<ConflictNotification>> get notifications => _notificationsStream();
  void dismiss(ConflictNotification notification) => _dismissNotification(notification);
}

/// Placeholder provider for conflict notification service
final conflictNotificationServiceProvider =
    Provider<AsyncValue<ConflictNotificationService>>((ref) {
  // This would be connected to the actual conflict resolution service
  return AsyncValue.data(ConflictNotificationService(
    notificationsStream: () => Stream.value([]),
    dismissNotification: (_) {},
  ));
});

/// SnackBar widget for displaying conflict notifications
class ConflictSnackbar {
  final ConflictNotification notification;

  const ConflictSnackbar({required this.notification});

  static SnackBar create(ConflictNotification notification) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.sync_problem,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sync Conflict',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.warning,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {},
      ),
    );
  }

  /// Show conflict snackbar
  static void show(BuildContext context, ConflictNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(create(notification));
  }
}

/// Widget that listens for conflict notifications and displays them
class ConflictNotificationListener extends ConsumerWidget {
  final Widget child;

  const ConflictNotificationListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(conflictNotificationServiceProvider);

    notificationService.whenData((service) {
      service.notifications.listen((notifications) {
        if (context.mounted && notifications.isNotEmpty) {
          ConflictSnackbar.show(context, notifications.first);
        }
      });
    });

    return child;
  }
}
