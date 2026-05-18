import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/notifications_api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // App is in background/terminated — PowerSync auto-syncs on resume.
  // The OS delivers a heads-up notification if the message has a notification
  // payload; for data-only messages (our case) the app wakes silently.
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class FcmService {
  static bool _initialized = false;
  static String? _token;

  static String? get token => _token;

  /// Call once after auth succeeds (wired in app.dart via authNotifierProvider listener).
  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // Request permission (badge only — no alert/sound; PowerSync delivers content)
      await messaging.requestPermission(alert: false, badge: true, sound: false);

      _token = await messaging.getToken();
      if (_token != null) await _registerToken(ref, _token!);

      // Refresh token whenever FCM rotates it
      messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        _registerToken(ref, newToken);
      });

      // Foreground data-only messages — PowerSync live query handles the update.
      FirebaseMessaging.onMessage.listen((_) {
        debugPrint('[FCM] Foreground sync trigger received — PowerSync will re-query');
      });

      _initialized = true;
      debugPrint('[FCM] Initialized. Token: $_token');
    } catch (e) {
      debugPrint('[FCM] Initialization failed: $e');
    }
  }

  static Future<void> _registerToken(WidgetRef ref, String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ref.read(notificationsApiServiceProvider).registerDeviceToken(
        token: token,
        platform: platform,
      );
      debugPrint('[FCM] Device token registered ($platform)');
    } catch (e) {
      debugPrint('[FCM] Failed to register device token: $e');
    }
  }

  /// Call on logout to remove the token from the backend.
  static Future<void> unregisterToken(WidgetRef ref) async {
    if (_token == null) return;
    try {
      await ref.read(notificationsApiServiceProvider).unregisterDeviceToken(token: _token!);
      _token = null;
      _initialized = false;
      debugPrint('[FCM] Device token unregistered');
    } catch (e) {
      debugPrint('[FCM] Failed to unregister device token: $e');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((_) => FcmService());
