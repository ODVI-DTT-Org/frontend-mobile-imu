import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/notification_provider.dart';
import '../../../../services/api/notifications_api_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../core/utils/app_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsStreamProvider);

    Future<void> handleRefresh() async {
      // Always show the spinner for at least 1.2s so the user sees feedback.
      // waitForInitialSync waits for any in-progress sync to finish; PowerSync
      // is reactive so new server data arrives automatically via the stream.
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1200)),
        PowerSyncService.waitForInitialSync(timeout: const Duration(seconds: 8))
            .catchError((_) {}),
      ]);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          asyncNotifications.when(
            data: (list) {
              final hasUnread = list.any((n) => n.isUnread);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => _markAllRead(context, ref),
                child: const Text(
                  'Mark all read',
                  style: TextStyle(fontSize: 13, color: Color(0xFF2563EB)),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncNotifications.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.bellOff, size: 48, color: Color(0xFFCBD5E1)),
                        SizedBox(height: 12),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                return _NotificationTile(
                  notification: notifications[index],
                  onTap: () => _handleTap(context, ref, notifications[index]),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, NotificationItem n) async {
    if (n.isUnread) {
      try {
        await ref.read(notificationsApiServiceProvider).markRead(n.id);
      } catch (_) {}
    }

    if (!context.mounted) return;
    final clientId = n.clientId;
    if (clientId != null && clientId.isNotEmpty) {
      context.push('/clients/$clientId');
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsApiServiceProvider).markAllRead();
    } catch (e) {
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to mark notifications as read');
      }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: notification.isUnread ? const Color(0xFFEFF6FF) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBgColor(notification.type),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _iconFor(notification.type),
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notification.isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (notification.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6, top: 3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'approval_approved':
        return LucideIcons.checkCircle;
      case 'approval_rejected':
        return LucideIcons.xCircle;
      case 'loan_released':
        return LucideIcons.banknote;
      case 'missed_visit':
        return LucideIcons.mapPin;
      case 'announcement':
        return LucideIcons.megaphone;
      case 'touchpoint_recorded':
        return LucideIcons.clipboardCheck;
      default:
        return LucideIcons.bell;
    }
  }

  Color _iconBgColor(String type) {
    switch (type) {
      case 'approval_approved':
      case 'loan_released':
        return const Color(0xFF16A34A);
      case 'approval_rejected':
        return const Color(0xFFDC2626);
      case 'missed_visit':
        return const Color(0xFFD97706);
      case 'announcement':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
