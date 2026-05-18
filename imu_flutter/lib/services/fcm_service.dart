import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/notifications_api_service.dart';

/// FCM integration service.
///
/// Activation checklist (one-time setup):
///   1. Add google-services.json  → android/app/google-services.json
///   2. Add GoogleService-Info.plist → ios/Runner/GoogleService-Info.plist
///   3. In pubspec.yaml, uncomment:
///        firebase_core: ^2.24.2
///        firebase_messaging: ^14.7.8
///   4. In android/settings.gradle, add to plugins {}:
///        id "com.google.gms.google-services" version "4.4.0" apply false
///   5. In android/app/build.gradle, add to plugins {}:
///        id "com.google.gms.google-services"
///   6. Run: flutter pub get
///   7. In this file, uncomment all [FCM_ACTIVE] lines and delete [FCM_STUB] lines.
///   8. Set FCM_SERVICE_ACCOUNT_JSON on the backend (base64 or raw JSON).
///
/// While Firebase is not configured, the service is a safe no-op.
/// PowerSync still delivers all notifications — only real-time wake-up is absent.

// [FCM_ACTIVE] import 'package:firebase_core/firebase_core.dart';
// [FCM_ACTIVE] import 'package:firebase_messaging/firebase_messaging.dart';

// [FCM_ACTIVE] @pragma('vm:entry-point')
// [FCM_ACTIVE] Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// [FCM_ACTIVE]   // The app is in background/terminated — trigger a PowerSync re-sync
// [FCM_ACTIVE]   // We cannot easily call Riverpod providers here, but PowerSync auto-syncs
// [FCM_ACTIVE]   // when the app resumes. The local notification is enough to wake the user.
// [FCM_ACTIVE]   debugPrint('[FCM] Background message received: ${message.messageId}');
// [FCM_ACTIVE] }

class FcmService {
  static bool _initialized = false;
  static String? _token;

  static String? get token => _token;

  /// Call once after Firebase is enabled and after auth succeeds.
  static Future<void> initialize(WidgetRef ref) async {
    if (_initialized || kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    try {
      // [FCM_STUB] FCM is not yet active — see activation checklist above.
      debugPrint('[FCM] Stub mode — activate Firebase to enable push wake-up');
      _initialized = true;

      // [FCM_ACTIVE] await Firebase.initializeApp();
      // [FCM_ACTIVE] FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      //
      // [FCM_ACTIVE] final messaging = FirebaseMessaging.instance;
      // [FCM_ACTIVE] await messaging.requestPermission(alert: false, badge: true, sound: false);
      //
      // [FCM_ACTIVE] _token = await messaging.getToken();
      // [FCM_ACTIVE] if (_token != null) await _registerToken(ref, _token!);
      //
      // [FCM_ACTIVE] messaging.onTokenRefresh.listen((newToken) {
      // [FCM_ACTIVE]   _token = newToken;
      // [FCM_ACTIVE]   _registerToken(ref, newToken);
      // [FCM_ACTIVE] });
      //
      // [FCM_ACTIVE] // Foreground messages → trigger PowerSync re-sync
      // [FCM_ACTIVE] FirebaseMessaging.onMessage.listen((_) {
      // [FCM_ACTIVE]   // PowerSync's live query already picks up new rows — no action needed.
      // [FCM_ACTIVE]   debugPrint('[FCM] Foreground message received — PowerSync will re-sync');
      // [FCM_ACTIVE] });
      //
      // [FCM_ACTIVE] _initialized = true;
      // [FCM_ACTIVE] debugPrint('[FCM] Initialized, token: $_token');
    } catch (e) {
      debugPrint('[FCM] Initialization failed (expected without google-services.json): $e');
    }
  }

  static Future<void> _registerToken(WidgetRef ref, String token) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await ref.read(notificationsApiServiceProvider).registerDeviceToken(
        token: token,
        platform: platform,
      );
      debugPrint('[FCM] Device token registered');
    } catch (e) {
      debugPrint('[FCM] Failed to register device token: $e');
    }
  }

  /// Unregister token on logout.
  static Future<void> unregisterToken(WidgetRef ref) async {
    if (_token == null) return;
    try {
      await ref.read(notificationsApiServiceProvider).unregisterDeviceToken(token: _token!);
      _token = null;
      debugPrint('[FCM] Device token unregistered');
    } catch (e) {
      debugPrint('[FCM] Failed to unregister device token: $e');
    }
  }
}

final fcmServiceProvider = Provider<FcmService>((_) => FcmService());
