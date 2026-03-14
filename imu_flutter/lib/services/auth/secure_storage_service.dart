import 'dart:convert';
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

  /// Generate a random salt for PIN hashing
  String _generateSalt() {
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return sha256.convert(bytes).toString().substring(0, 32);
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
}
