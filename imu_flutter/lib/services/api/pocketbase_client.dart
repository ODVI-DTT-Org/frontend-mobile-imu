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

    // Initialize token manager
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

  /// Dispose resources
  void dispose() {
    _tokenManager.dispose();
    _isInitialized = false;
    debugPrint('PocketBaseClient disposed');
  }
}

/// Riverpod provider for PocketBase client
final pocketBaseClientProvider = Provider<PocketBaseClient>((ref) {
  final client = PocketBaseClient();

  // Initialize synchronously
  client._initializeSync();

  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

/// Provider for PocketBase instance
final pocketBaseProvider = Provider<PocketBase>((ref) {
  final client = ref.watch(pocketBaseClientProvider);
  return client.instance;
});
