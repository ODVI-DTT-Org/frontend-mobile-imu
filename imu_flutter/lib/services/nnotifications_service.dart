import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification types
enum NotificationType {
  reminder,
  syncComplete,
  syncFailed,
  newTouchpoint,
  scheduleChange,
  generic,
}

/// App notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name.toLowerCase() == (json['type']?.toString().toLowerCase() ?? ''),
        orElse: () => NotificationType.generic,
      ),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'],
      createdAt: json['created'] != null ? DateTime.parse(json['created']) : DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'data': data,
    'created': createdAt.toIso8601String(),
    'is_read': isRead,
  };
}

/// Notifications service
/// Note: This is a stub implementation. For full functionality,
/// configure flutter_local_notifications properly.
class NotificationsService extends ChangeNotifier {
  final List<AppNotification> _notifications = [];
  bool _isInitialized = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isInitialized => _isInitialized;

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      debugPrint('NotificationsService: Initialized (stub mode)');
    } catch (e) {
      debugPrint('NotificationsService: Initialization failed - $e');
    }
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.generic,
    String? id,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = AppNotification(
        id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        isRead: false,
      );

      _notifications.insert(0, notification);
      notifyListeners();

      debugPrint('NotificationsService: Show notification: $title - $body (stub)');
    } catch (e) {
      debugPrint('NotificationsService: Failed to show notification - $e');
    }
  }

  /// Show sync complete notification
  Future<void> showSyncComplete(int syncCount) async {
    await showNotification(
      title: 'Sync Complete',
      body: 'Successfully synced $syncCount items',
      type: NotificationType.syncComplete,
    );
  }

  /// Show sync failed notification
  Future<void> showSyncFailed(String error) async {
    await showNotification(
      title: 'Sync Failed',
      body: error,
      type: NotificationType.syncFailed,
    );
  }

  /// Show reminder notification
  Future<void> showReminder({
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      final notification = AppNotification(
        id: scheduledTime.millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: NotificationType.reminder,
        createdAt: DateTime.now(),
        isRead: false,
      );

      _notifications.insert(0, notification);
      notifyListeners();

      debugPrint('NotificationsService: Scheduled reminder for $scheduledTime (stub)');
    } catch (e) {
      debugPrint('NotificationsService: Failed to schedule reminder - $e');
    }
  }

  /// Mark notification as read
  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final existing = _notifications[index];
      _notifications[index] = AppNotification(
        id: existing.id,
        type: existing.type,
        title: existing.title,
        body: existing.body,
        data: existing.data,
        createdAt: existing.createdAt,
        isRead: true,
      );
      notifyListeners();
    }
  }

  /// Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      final existing = _notifications[i];
      if (!existing.isRead) {
        _notifications[i] = AppNotification(
          id: existing.id,
          type: existing.type,
          title: existing.title,
          body: existing.body,
          data: existing.data,
          createdAt: existing.createdAt,
          isRead: true,
        );
      }
    }
    notifyListeners();
  }

  /// Clear all notifications
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  /// Remove notification
  void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners();
  }
}

/// Provider for NotificationsService
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

/// Provider for unread notifications count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.unreadCount;
});

/// Provider for notifications list
final notificationsListProvider = Provider<List<AppNotification>>((ref) {
  final notificationsService = ref.watch(notificationsServiceProvider);
  return notificationsService.notifications;
});
