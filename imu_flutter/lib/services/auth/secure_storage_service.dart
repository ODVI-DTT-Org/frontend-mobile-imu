import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Secure storage service for sensitive data like PIN, tokens
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys
  static const String _pinHashKey = 'user_pin_hash';
  static const String _pinSaltKey = 'user_pin_salt';
  static const String _pinSetupKey = 'pin_setup_complete';
  static const String _pinUserIdKey = 'pin_user_id';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _deviceIdKey = 'device_id';
  static const String _lastLoginTimeKey = 'last_login_time';
  static const String _lastOnlineLoginKey = 'last_online_login_time';
  // Offline credential keys — persist across logout (not deleted by clearSession)
  static const String _offlineCredHashKey = 'offline_cred_hash';
  static const String _offlineCredSaltKey = 'offline_cred_salt';
  static const String _offlineJwtKey = 'offline_jwt';

  // Offline grace period: 8 hours
  static const Duration offlineGracePeriod = Duration(hours: 8);

  /// Generate a random salt for PIN hashing
  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Hash PIN with salt using SHA-256
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  /// Save PIN securely (hashed, not plain text)
  Future<void> savePin(String pin, {String? userId}) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _storage.write(key: _pinHashKey, value: hash);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinSetupKey, value: 'true');

    if (userId != null) {
      await _storage.write(key: _pinUserIdKey, value: userId);
    }

    debugPrint('SecureStorageService: PIN saved securely');
  }

  /// Check if PIN exists
  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Verify PIN against stored hash
  Future<bool> verifyPin(String inputPin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final salt = await _storage.read(key: _pinSaltKey);

    if (storedHash == null || salt == null) return false;

    final inputHash = _hashPin(inputPin, salt);
    return inputHash == storedHash;
  }

  /// Get the user ID associated with the PIN
  Future<String?> getPinUserId() async {
    return await _storage.read(key: _pinUserIdKey);
  }

  /// Delete PIN
  Future<void> deletePin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _pinSetupKey);
    await _storage.delete(key: _pinUserIdKey);
    debugPrint('SecureStorageService: PIN deleted');
  }

  /// Check if PIN setup is complete
  Future<bool> isPinSetupComplete() async {
    final value = await _storage.read(key: _pinSetupKey);
    return value == 'true';
  }

  /// Save auth token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  /// Save device ID
  Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  /// Clear all secure data (on logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
    debugPrint('SecureStorageService: All data cleared');
  }

  /// Clear only session data (keep PIN)
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    debugPrint('SecureStorageService: Session cleared');
  }

  /// Clear session but keep PIN (for logout with PIN retention)
  Future<void> logout({bool keepPin = true}) async {
    if (keepPin) {
      await clearSession();
    } else {
      await clearAll();
    }
  }

  // ===== OFFLINE CREDENTIALS (survive logout) =====

  /// Save credential hash and offline JWT after successful online login.
  /// These keys are intentionally excluded from clearSession() so offline
  /// re-login works after logout.
  Future<void> saveOfflineCredentials(String email, String password, String token) async {
    final salt = _generateSalt();
    final hash = _hashPin(email + password, salt);
    await _storage.write(key: _offlineCredHashKey, value: hash);
    await _storage.write(key: _offlineCredSaltKey, value: salt);
    await _storage.write(key: _offlineJwtKey, value: token);
    debugPrint('SecureStorageService: Offline credentials saved');
  }

  Future<bool> verifyOfflineCredentials(String email, String password) async {
    final hash = await _storage.read(key: _offlineCredHashKey);
    final salt = await _storage.read(key: _offlineCredSaltKey);
    if (hash == null || salt == null) return false;
    return _hashPin(email + password, salt) == hash;
  }

  Future<String?> getOfflineToken() async {
    return await _storage.read(key: _offlineJwtKey);
  }

  Future<bool> hasOfflineCredentials() async {
    final hash = await _storage.read(key: _offlineCredHashKey);
    final token = await _storage.read(key: _offlineJwtKey);
    return hash != null && token != null;
  }

  // ===== OFFLINE AUTHENTICATION =====

  /// Save last login time (both online and PIN-based logins)
  Future<void> saveLastLoginTime() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _lastLoginTimeKey, value: now);
    debugPrint('SecureStorageService: Last login time saved: $now');
  }

  /// Save last ONLINE login time (for grace period calculation)
  Future<void> saveLastOnlineLoginTime() async {
    final now = DateTime.now().toIso8601String();
    await _storage.write(key: _lastOnlineLoginKey, value: now);
    debugPrint('SecureStorageService: Last online login time saved: $now');
  }

  /// Get last login time
  Future<DateTime?> getLastLoginTime() async {
    final timeStr = await _storage.read(key: _lastLoginTimeKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// Get last online login time
  Future<DateTime?> getLastOnlineLoginTime() async {
    final timeStr = await _storage.read(key: _lastOnlineLoginKey);
    if (timeStr == null) return null;
    return DateTime.tryParse(timeStr);
  }

  /// Check if offline login is possible using stored credentials.
  Future<bool> canLoginOffline() async {
    return await hasOfflineCredentials();
  }

  /// Get remaining offline grace period
  Future<Duration?> getOfflineGracePeriodRemaining() async {
    final lastOnlineLogin = await getLastOnlineLoginTime();
    if (lastOnlineLogin == null) return null;

    final now = DateTime.now();
    final timeSinceLastOnline = now.difference(lastOnlineLogin);
    final remaining = offlineGracePeriod - timeSinceLastOnline;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if user needs online re-authentication
  Future<bool> needsOnlineReauth() async {
    return !(await canLoginOffline());
  }
}
