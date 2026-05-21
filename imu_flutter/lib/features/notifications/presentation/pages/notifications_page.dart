import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/notification_provider.dart';
import '../../../../core/utils/app_notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsPageProvider);

    Future<void> handleRefresh() async {
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 1200)),
        ref.read(notificationsPageProvider.notifier).refresh(),
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
            data: (state) {
              if (state.notifications.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(LucideIcons.moreVertical, size: 20),
                onSelected: (value) {
                  switch (value) {
                    case 'mark_read':
                      _markAllRead(context, ref);
                      break;
                    case 'clear_read':
                      _clearRead(context, ref);
                      break;
                    case 'clear_all':
                      _clearAll(context, ref);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'mark_read',
                    enabled: state.hasUnread,
                    child: const Text('Mark all read'),
                  ),
                  PopupMenuItem(
                    value: 'clear_read',
                    enabled: state.hasRead,
                    child: const Text('Clear read'),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Text('Clear all'),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncNotifications.when(
        data: (state) {
          if (state.notifications.isEmpty) {
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
              itemCount: state.notifications.length + 2,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _NotificationSummary(
                    shown: state.notifications.length,
                    total: state.total,
                    unread: state.unread,
                    onClearRead: state.hasRead ? () => _clearRead(context, ref) : null,
                    onClearAll: () => _clearAll(context, ref),
                  );
                }
                final notificationIndex = index - 1;
                if (notificationIndex >= state.notifications.length) {
                  return _LoadMoreFooter(
                    state: state,
                    onLoadMore: () => ref.read(notificationsPageProvider.notifier).loadMore(),
                  );
                }
                return _NotificationTile(
                  notification: state.notifications[notificationIndex],
                  onTap: () => _handleTap(context, ref, state.notifications[notificationIndex]),
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
        await ref.read(notificationsPageProvider.notifier).markRead(n.id);
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
      await ref.read(notificationsPageProvider.notifier).markAllRead();
    } catch (e) {
      _logNotificationError('markAllRead', e);
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to mark notifications as read');
      }
    }
  }

  Future<void> _clearRead(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(notificationsPageProvider.notifier).clearRead();
      if (context.mounted) {
        AppNotification.showSuccess(context, 'Read notifications cleared');
      }
    } catch (e) {
      _logNotificationError('clearRead', e);
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to clear read notifications');
      }
    }
  }

  Future<void> _clearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await _confirmClearAll(context);
    if (!confirmed) return;

    try {
      await ref.read(notificationsPageProvider.notifier).clearAll();
      if (context.mounted) {
        AppNotification.showSuccess(context, 'Notifications cleared');
      }
    } catch (e) {
      _logNotificationError('clearAll', e);
      if (context.mounted) {
        AppNotification.showError(context, 'Failed to clear notifications');
      }
    }
  }

  void _logNotificationError(String action, Object e) {
    if (e is DioException) {
      debugPrint('[NOTIF][$action] DioException: status=${e.response?.statusCode} uri=${e.requestOptions.uri} data=${e.response?.data}');
    } else {
      debugPrint('[NOTIF][$action] ${e.runtimeType}: $e');
    }
  }

  Future<bool> _confirmClearAll(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This removes all notifications from your notification center.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _NotificationSummary extends StatelessWidget {
  final int shown;
  final int total;
  final int unread;
  final VoidCallback? onClearRead;
  final VoidCallback onClearAll;

  const _NotificationSummary({
    required this.shown,
    required this.total,
    required this.unread,
    required this.onClearRead,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$shown of $total shown${unread > 0 ? ' - $unread unread' : ''}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: onClearRead,
            child: const Text('Clear read', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: onClearAll,
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final NotificationsPageState state;
  final VoidCallback onLoadMore;

  const _LoadMoreFooter({required this.state, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    if (!state.hasMore && state.loadMoreError == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            'All notifications loaded',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          if (state.loadMoreError != null) ...[
            Text(
              state.loadMoreError!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: state.isLoadingMore ? null : onLoadMore,
              child: state.isLoadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load more'),
            ),
          ),
        ],
      ),
    );
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
