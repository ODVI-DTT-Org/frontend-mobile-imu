import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api/notifications_api_service.dart';
import '../../../services/sync/powersync_service.dart';

class NotificationItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  factory NotificationItem.fromRow(Map<String, dynamic> row) {
    Map<String, dynamic> data = {};
    final rawData = row['data'];
    if (rawData is String && rawData.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) data = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    }

    return NotificationItem(
      id: row['id'] as String,
      type: row['type'] as String? ?? '',
      title: row['title'] as String? ?? '',
      body: row['body'] as String? ?? '',
      data: data,
      readAt: row['read_at'] != null ? DateTime.tryParse(row['read_at'] as String) : null,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String? get clientId => data['client_id'] as String?;
}

Future<List<NotificationItem>> fetchLocalNotifications() async {
  final db = await PowerSyncService.database;
  final rows = await db.getAll(
    'SELECT id, type, title, body, data, read_at, created_at '
    'FROM notifications '
    'ORDER BY created_at DESC '
    'LIMIT 100',
  );
  return rows.map(NotificationItem.fromRow).toList();
}

class NotificationsPageState {
  final List<NotificationItem> notifications;
  final int total;
  final int unread;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get hasMore => notifications.length < total;
  bool get hasUnread => unread > 0 || notifications.any((n) => n.isUnread);
  bool get hasRead => notifications.any((n) => !n.isUnread);

  const NotificationsPageState({
    required this.notifications,
    required this.total,
    required this.unread,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  NotificationsPageState copyWith({
    List<NotificationItem>? notifications,
    int? total,
    int? unread,
    bool? isLoadingMore,
    String? loadMoreError,
  }) {
    return NotificationsPageState(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      unread: unread ?? this.unread,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

/// Notifications for the page. It fetches from the backend immediately so pull
/// refresh and pagination are not blocked by the next PowerSync download cycle.
/// If the first API page is unavailable, fall back to local PowerSync rows.
final notificationsPageProvider = StateNotifierProvider.autoDispose<
    NotificationsPageNotifier, AsyncValue<NotificationsPageState>>((ref) {
  return NotificationsPageNotifier(ref.watch(notificationsApiServiceProvider));
});

class NotificationsPageNotifier extends StateNotifier<AsyncValue<NotificationsPageState>> {
  static const int pageSize = 20;
  final NotificationsApiService _api;

  NotificationsPageNotifier(this._api) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final page = await _api.fetchNotificationsPage(limit: pageSize, offset: 0);
      state = AsyncValue.data(NotificationsPageState(
        notifications: page.notifications.map(NotificationItem.fromRow).toList(),
        total: page.total,
        unread: page.unread,
      ));
    } catch (error, stackTrace) {
      try {
        final local = await fetchLocalNotifications();
        state = AsyncValue.data(NotificationsPageState(
          notifications: local.take(pageSize).toList(),
          total: local.length,
          unread: local.where((n) => n.isUnread).length,
        ));
      } catch (_) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(
      isLoadingMore: true,
      loadMoreError: null,
    ));

    try {
      final page = await _api.fetchNotificationsPage(
        limit: pageSize,
        offset: current.notifications.length,
      );
      final next = page.notifications.map(NotificationItem.fromRow).toList();
      state = AsyncValue.data(current.copyWith(
        notifications: [...current.notifications, ...next],
        total: page.total,
        unread: page.unread,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncValue.data(current.copyWith(
        isLoadingMore: false,
        loadMoreError: 'Failed to load more notifications',
      ));
    }
  }

  Future<void> markRead(String notificationId) async {
    await _api.markRead(notificationId);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _api.markAllRead();
    await refresh();
  }

  Future<void> clearAll() async {
    await _api.clearAll();
    await refresh();
  }

  Future<void> clearRead() async {
    await _api.clearRead();
    await refresh();
  }
}

/// Reactive stream of all notifications for the current user, newest first.
final notificationsStreamProvider = StreamProvider<List<NotificationItem>>((ref) async* {
  final db = await PowerSyncService.database;
  yield* db.watch(
    'SELECT id, type, title, body, data, read_at, created_at '
    'FROM notifications '
    'ORDER BY created_at DESC '
    'LIMIT 100',
  ).map((rows) => rows.map(NotificationItem.fromRow).toList());
});

/// Reactive unread count — drives the badge on the bell icon.
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsStreamProvider).when(
    data: (list) => list.where((n) => n.isUnread).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
