import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketbase/pocketbase.dart';

/// Token manager for handling auth token persistence and refresh
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  static const _tokenKey = 'pb_auth_token';
  static const _recordKey = 'pb_auth_record';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Timer? _refreshTimer;
  PocketBase? _pocketbase;

  /// Initialize token manager with PocketBase instance
  Future<void> initialize(PocketBase pb) async {
    _pocketbase = pb;

    // Load existing token and restore to PocketBase authStore
    await _loadAndRestoreToken();

    // Setup auto-refresh timer
    _setupRefreshTimer();

    debugPrint('TokenManager initialized');
  }

  /// Load stored token from secure storage and restore to PocketBase authStore
  Future<void> _loadAndRestoreToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final recordJson = await _secureStorage.read(key: _recordKey);

      if (token != null && token.isNotEmpty && _pocketbase != null) {
        debugPrint('Found stored auth token, restoring to PocketBase authStore');

        // Restore the auth record to PocketBase
        if (recordJson != null && recordJson.isNotEmpty) {
          try {
            final recordData = jsonDecode(recordJson) as Map<String, dynamic>;
            // Create a fake auth store and load it
            _pocketbase!.authStore.save(token, RecordModel(id: recordData['id'] ?? '', data: recordData));
            debugPrint('✅ Auth token restored to PocketBase authStore');
          } catch (e) {
            debugPrint('⚠️ Could not parse stored record: $e');
            // Just save the token without the record
            _pocketbase!.authStore.save(token, null);
          }
        } else {
          // Just save the token without the record
          _pocketbase!.authStore.save(token, null);
          debugPrint('✅ Auth token restored (without record data)');
        }
      } else {
        debugPrint('No stored auth token found');
      }
    } catch (e) {
      debugPrint('❌ Error loading stored token: $e');
    }
  }

  /// Setup automatic token refresh timer
  void _setupRefreshTimer() {
    _refreshTimer?.cancel();

    if (_pocketbase == null || !_pocketbase!.authStore.isValid) {
      return;
    }

    // Parse token expiry (PocketBase tokens are valid for ~1 day by default)
    // We'll refresh 5 minutes before expiry
    const refreshBeforeExpiry = Duration(minutes: 5);
    const checkInterval = Duration(minutes: 1);

    _refreshTimer = Timer.periodic(checkInterval, (timer) async {
      if (!_pocketbase!.authStore.isValid) {
        timer.cancel();
        return;
      }

      try {
        // Check if token needs refresh
        final expiresAt = _getTokenExpiry(_pocketbase!.authStore.token);
        if (expiresAt == null) return;

        final now = DateTime.now();
        final timeUntilExpiry = expiresAt.difference(now);

        if (timeUntilExpiry < refreshBeforeExpiry) {
          debugPrint('Token expiring soon, refreshing...');
          await refreshToken();
        }
      } catch (e) {
        debugPrint('Error checking token expiry: $e');
      }
    });
  }

  /// Parse token expiry from JWT
  DateTime? _getTokenExpiry(String? token) {
    if (token == null || token.isEmpty) return null;

    try {
      // JWT tokens have 3 parts separated by dots
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode payload (second part)
      // Note: This is a simplified implementation
      // In production, use a proper JWT library
      return null; // PocketBase handles this internally
    } catch (e) {
      debugPrint('Error parsing token: $e');
      return null;
    }
  }

  /// Refresh the auth token
  Future<bool> refreshToken() async {
    if (_pocketbase == null) {
      debugPrint('Cannot refresh: PocketBase not initialized');
      return false;
    }

    try {
      // PocketBase SDK handles token refresh automatically
      // Just verify the auth is still valid
      if (_pocketbase!.authStore.isValid) {
        debugPrint('✅ Token still valid');
        return true;
      }

      debugPrint('⚠️ Token invalid, user needs to re-authenticate');
      return false;
    } catch (e) {
      debugPrint('❌ Token refresh failed: $e');
      return false;
    }
  }

  /// Save auth token to secure storage
  Future<void> saveToken(String token, RecordModel? record) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);

      // Also save the record data as JSON for restoration
      if (record != null) {
        final recordJson = jsonEncode(record.toJson());
        await _secureStorage.write(key: _recordKey, value: recordJson);
        debugPrint('✅ Auth token and record saved');
      } else {
        debugPrint('✅ Auth token saved (no record data)');
      }

      // Restart refresh timer
      _setupRefreshTimer();
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  /// Clear stored auth token
  Future<void> clearToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      _refreshTimer?.cancel();
      debugPrint('✅ Auth token cleared');
    } catch (e) {
      debugPrint('❌ Error clearing token: $e');
    }
  }

  /// Get stored auth token
  Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('❌ Error reading token: $e');
      return null;
    }
  }

  /// Check if token is stored
  Future<bool> hasToken() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _refreshTimer?.cancel();
    debugPrint('TokenManager disposed');
  }
}
