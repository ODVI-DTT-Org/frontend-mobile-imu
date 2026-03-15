import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'token_manager.dart';
import 'api_logger.dart';

/// PocketBase client service for backend API communication
class PocketBaseClient {
  late PocketBase _pb;
  final TokenManager _tokenManager = TokenManager();
  final ApiLogger _logger = ApiLogger();
  bool _isInitialized = false;

  /// Get the underlying PocketBase instance
  PocketBase get instance {
    if (!_isInitialized) {
      _initializeSync();
    }
    return _pb;
  }

  /// Whether the client is initialized
  bool get isInitialized => _isInitialized;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => _pb.authStore.isValid;

  /// Get current auth token
  String? get authToken => _pb.authStore.token;

  /// Synchronous initialization - creates PocketBase instance without async token manager
  void _initializeSync() {
    if (_isInitialized) return;

    final baseUrl = AppConfig.pocketbaseUrl;
    debugPrint('PocketBaseClient: Sync init with URL: $baseUrl');

    _pb = PocketBase(baseUrl);
    _isInitialized = true;
  }

  /// Initialize the PocketBase client (async version with token manager)
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PocketBaseClient already initialized');
      return;
    }

    final baseUrl = AppConfig.pocketbaseUrl;
    debugPrint('Initializing PocketBase with URL: $baseUrl');

    _pb = PocketBase(baseUrl);

    // Initialize token manager (restores auth token from secure storage)
    await _tokenManager.initialize(_pb);

    _isInitialized = true;
    debugPrint('PocketBaseClient initialized successfully');
  }

  /// Check backend health
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _pb.health.check();
      return {'code': response.code, 'message': response.message};
    } catch (e) {
      debugPrint('Health check failed: $e');
      return {
        'healthy': false,
        'error': e.toString(),
      };
    }
  }

  /// Clear authentication
  void clearAuth() {
    _pb.authStore.clear();
    _tokenManager.clearToken();
    debugPrint('Auth cleared');
  }

  /// Persist current auth token to secure storage
  /// Call this after successful login to ensure auth persists across app restarts
  Future<void> persistAuth() async {
    if (_pb.authStore.isValid) {
      await _tokenManager.saveToken(
        _pb.authStore.token,
        _pb.authStore.model as RecordModel?,
      );
      debugPrint('✅ Auth token persisted to secure storage');
    } else {
      debugPrint('⚠️ Cannot persist auth: no valid auth token');
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenManager.dispose();
    _isInitialized = false;
    debugPrint('PocketBaseClient disposed');
  }
}

/// Singleton instance initialized in main.dart
PocketBaseClient? _pocketBaseClientInstance;

/// Initialize the global PocketBase client (called in main.dart)
Future<void> initializePocketBaseClient() async {
  _pocketBaseClientInstance = PocketBaseClient();
  await _pocketBaseClientInstance!.initialize();
}

/// Riverpod provider for PocketBase client
/// Uses the singleton instance initialized in main.dart
final pocketBaseClientProvider = Provider<PocketBaseClient>((ref) {
  if (_pocketBaseClientInstance == null) {
    debugPrint('⚠️ PocketBaseClient not initialized! Call initializePocketBaseClient() in main.dart');
    // Fallback: create and initialize synchronously (without token restoration)
    _pocketBaseClientInstance = PocketBaseClient();
    _pocketBaseClientInstance!._initializeSync();
  }

  ref.onDispose(() {
    // Don't dispose the singleton here - it's managed globally
  });

  return _pocketBaseClientInstance!;
});

/// Provider for PocketBase instance
final pocketBaseProvider = Provider<PocketBase>((ref) {
  final client = ref.watch(pocketBaseClientProvider);
  return client.instance;
});
