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

/// Notifications for the page. Pull-to-refresh invalidates this provider, which
/// fetches the backend immediately instead of waiting for the next PowerSync
/// download cycle. If the API is unavailable, fall back to local PowerSync rows.
final notificationsPageProvider =
    FutureProvider.autoDispose<List<NotificationItem>>((ref) async {
  try {
    final rows = await ref.watch(notificationsApiServiceProvider).fetchNotifications();
    return rows.map(NotificationItem.fromRow).toList();
  } catch (_) {
    return fetchLocalNotifications();
  }
});

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
