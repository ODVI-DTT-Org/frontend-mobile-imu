import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

/// Notification data for queued notifications
class QueuedNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final int retryCount;

  QueuedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'data': data,
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory QueuedNotification.fromJson(Map<String, dynamic> json) {
    return QueuedNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  QueuedNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? queuedAt,
    int? retryCount,
  }) {
    return QueuedNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Service for managing offline push notifications
/// Queues notifications while offline and sends them when connectivity is restored
class OfflineNotificationService {
  final List<QueuedNotification> _queue = [];
  final StreamController<List<QueuedNotification>> _queueController =
      StreamController<List<QueuedNotification>>.broadcast();
  bool _isOnline = true;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Stream of queue changes
  Stream<List<QueuedNotification>> get queueStream => _queueController.stream;

  /// Current queue
  List<QueuedNotification> get queue => List.unmodifiable(_queue);

  OfflineNotificationService();

  /// Initialize the service
  Future<void> initialize() async {
    // Request notification permissions
    final granted = await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    final androidGranted = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    if (granted != true && androidGranted != true) {
      logDebug('Notification permissions not granted');
      return;
    }

    // Initialize notification settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    logDebug('Offline notification service initialized');
  }

  /// Queue a notification to be sent
  Future<void> queueNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    if (_isOnline) {
      await _sendNotification(title, body, type, data);
    } else {
      // Queue for later
      final notification = QueuedNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        data: data ?? {},
        queuedAt: DateTime.now(),
        retryCount: 0,
      );

      _queue.add(notification);
      _queueController.add(List.from(_queue));
      logDebug('Notification queued: $title');
    }
  }

  /// Send a notification immediately
  Future<void> _sendNotification(
    String title,
    String body,
    String type,
    Map<String, dynamic>? data,
  ) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        type,
        type.replaceAll('_', ' ').toUpperCase(),
        importance: Importance.high,
        priority: Priority.high,
        payload: data?.toString(),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: data?.toString(),
      );

      logDebug('Notification sent: $title');
    } catch (e) {
      logError('Failed to send notification', e);
    }
  }

  /// Process queued notifications when online
  Future<void> processQueue() async {
    if (!_isOnline || _queue.isEmpty) return;

    final notifications = List<QueuedNotification>.from(_queue);
    _queue.clear();
    _queueController.add(List.from(_queue));

    for (final notification in notifications) {
      try {
        await _sendNotification(
          notification.title,
          notification.body,
          notification.type,
          notification.data,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        logError('Failed to send queued notification', e);
        // Re-add failed notification with incremented retry count
        if (notification.retryCount < 3) {
          _queue.add(notification.copyWith(retryCount: notification.retryCount + 1));
        }
      }
    }

    _queueController.add(List.from(_queue));
    logDebug('Processed ${notifications.length} queued notifications');
  }

  /// Set online status
  void setOnlineStatus(bool isOnline) {
    final wasOffline = !_isOnline;
    _isOnline = isOnline;

    if (wasOffline && isOnline) {
      // Just came online, process queue
      processQueue();
    }
  }

  /// Get pending notification count
  int get pendingCount => _queue.length;

  /// Clear all queued notifications
  void clearQueue() {
    _queue.clear();
    _queueController.add(List.from(_queue));
  }

  /// Dispose resources
  void dispose() {
    _queueController.close();
  }
}

/// Provider for offline notification service
final offlineNotificationServiceProvider =
    Provider<OfflineNotificationService>((ref) {
  final service = OfflineNotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});
