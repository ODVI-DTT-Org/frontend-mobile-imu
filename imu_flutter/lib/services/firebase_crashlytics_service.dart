import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firebase Crashlytics service for error tracking and analytics
/// Note: This is a stub implementation. Enable Firebase in pubspec.yaml
/// and configure google-services.json/GoogleService-Info.plist for full functionality.
class FirebaseCrashlyticsService extends ChangeNotifier {
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize Firebase Crashlytics
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      debugPrint('FirebaseCrashlyticsService: Initialized (stub mode)');
    } catch (e) {
      debugPrint('FirebaseCrashlyticsService: Initialization failed: $e');
    }
  }

  /// Log custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    debugPrint('FirebaseCrashlyticsService: Logged event $name (stub)');
  }

  /// Log custom key
  Future<void> logCustomKey(String key, dynamic value) async {
    debugPrint('FirebaseCrashlyticsService: Set custom key $key (stub)');
  }

  /// Record error
  Future<void> recordError(dynamic error, {StackTrace? stackTrace}) async {
    debugPrint('FirebaseCrashlyticsService: Recorded error: $error (stub)');
  }

  /// Record flutter error
  void recordFlutterError(FlutterErrorDetails details) {
    debugPrint('FirebaseCrashlyticsService: Recorded flutter error (stub)');
  }

  /// Set user identifier
  Future<void> setUserIdentifier(String userId) async {
    debugPrint('FirebaseCrashlyticsService: Set user identifier: $userId (stub)');
  }

  /// Log button click
  Future<void> logButtonTap(String buttonName) async {
    await logEvent('button_tap', params: {'button': buttonName});
  }

  /// Log screen view
  Future<void> logScreenView(String screenName) async {
    await logEvent('screen_view', params: {'screen': screenName});
  }

  /// Log error with message
  Future<void> logError(String code, String message) async {
    await recordError(Exception('$code: $message'));
  }
}

/// Provider for FirebaseCrashlyticsService
final firebaseCrashlyticsServiceProvider = Provider<FirebaseCrashlyticsService>((ref) {
  return FirebaseCrashlyticsService();
});
