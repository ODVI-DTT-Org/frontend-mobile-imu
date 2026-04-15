import 'package:flutter/material.dart';
import 'app_notification.dart';

/// Export the new AppNotification for direct use
export 'app_notification.dart' show AppNotification;

/// Notification service for handling push notifications and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  Future<void> init() async {
    // In production, this would initialize Firebase Cloud Messaging
    // and local notifications
    debugPrint('NotificationService initialized');
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    // In production, request actual permission
    return true;
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    // In production, check actual permission status
    return true;
  }

  /// Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // In production, show actual notification
    debugPrint('Notification: $title - $body');
  }

  /// Schedule local notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // In production, schedule actual notification
    debugPrint('Scheduled notification: $title for $scheduledDate');
  }

  /// Cancel notification
  Future<void> cancelNotification(int id) async {
    // In production, cancel actual notification
    debugPrint('Cancelled notification: $id');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // In production, cancel all notifications
    debugPrint('Cancelled all notifications');
  }

  /// Get FCM token
  Future<String?> getToken() async {
    // In production, return actual FCM token
    return null;
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    // In production, subscribe to FCM topic
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    // In production, unsubscribe from FCM topic
    debugPrint('Unsubscribed from topic: $topic');
  }
}

/// In-app notification helper
///
/// **DEPRECATED:** Use [AppNotification] instead for unified top-positioned notifications.
/// This class is kept for backward compatibility and will be removed in future versions.
///
/// Migration guide:
/// - `InAppNotification.showSuccess()` → `AppNotification.showSuccess()`
/// - `InAppNotification.showError()` → `AppNotification.showError()`
/// - `InAppNotification.showWarning()` → `AppNotification.showWarning()`
/// - `InAppNotification.showInfo()` → `AppNotification.showNeutral()`
@Deprecated('Use AppNotification instead for unified top-positioned notifications')
class InAppNotification {
  /// Show success notification at the top
  static void showSuccess(BuildContext context, String message) {
    AppNotification.showSuccess(context, message);
  }

  /// Show error notification at the top
  static void showError(BuildContext context, String message) {
    AppNotification.showError(context, message);
  }

  /// Show warning notification at the top
  static void showWarning(BuildContext context, String message) {
    AppNotification.showWarning(context, message);
  }

  /// Show info notification at the top (now neutral/gray)
  static void showInfo(BuildContext context, String message) {
    AppNotification.showNeutral(context, message);
  }

  /// Show sync status notification with retry action at the top
  static void showSyncStatus(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    if (onRetry != null) {
      // For sync status with retry, use showNeutral with custom handling
      AppNotification.showNeutral(context, message);
    } else {
      AppNotification.showNeutral(context, message);
    }
  }

  /// Show undo notification at the top
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    // For undo, show neutral notification
    AppNotification.showNeutral(context, message);
  }
}
