import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/utils/logger.dart';
import 'secure_storage_service.dart';

/// Service for handling offline authentication with PIN/biometric
class OfflineAuthService {
  static final OfflineAuthService _instance = OfflineAuthService._internal();
  factory OfflineAuthService() => _instance;
  OfflineAuthService._internal();

  final SecureStorageService _secureStorage = SecureStorageService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Check if offline login is possible using stored credentials.
  /// Returns false if no credentials exist or if the cached JWT has expired.
  Future<bool> canLoginOffline() async {
    final hasCredentials = await _secureStorage.hasOfflineCredentials();
    if (!hasCredentials) return false;

    final token = await _secureStorage.getOfflineToken();
    if (token == null) return false;

    try {
      final decoded = JwtDecoder.decode(token);
      final exp = decoded['exp'] as int?;
      if (exp != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiryTime)) return false;
      }
    } catch (_) {
      return false;
    }

    return true;
  }

  /// Authenticate with email + password offline (validates against stored hash)
  Future<OfflineAuthResult> authenticateWithCredentials(String email, String password) async {
    try {
      final isValid = await _secureStorage.verifyOfflineCredentials(email, password);
      if (!isValid) {
        return OfflineAuthResult(
          success: false,
          error: 'Incorrect email or password',
          requiresReauth: true,
        );
      }

      final token = await _secureStorage.getOfflineToken();
      if (token == null) {
        return OfflineAuthResult(
          success: false,
          error: 'No cached session. Please login online.',
          requiresReauth: true,
        );
      }

      // Check token expiry
      try {
        final decoded = JwtDecoder.decode(token);
        final exp = decoded['exp'] as int?;
        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (DateTime.now().isAfter(expiryTime)) {
            return OfflineAuthResult(
              success: false,
              error: 'Session expired. Please login online to continue.',
              requiresReauth: true,
            );
          }
        }
      } catch (e) {
        return OfflineAuthResult(
          success: false,
          error: 'Invalid cached session. Please login online.',
          requiresReauth: true,
        );
      }

      final user = _getUserFromToken(token);
      await _secureStorage.saveLastLoginTime();

      logDebug('Offline credential auth successful for ${user.email}');
      return OfflineAuthResult(
        success: true,
        user: user,
        token: token,
      );
    } catch (e) {
      logError('Offline credential authentication failed', e);
      return OfflineAuthResult(
        success: false,
        error: 'Authentication failed: $e',
        requiresReauth: true,
      );
    }
  }

  /// Authenticate with PIN (works offline)
  Future<OfflineAuthResult> authenticateWithPin(String pin) async {
    try {
      // Verify PIN
      final isPinValid = await _secureStorage.verifyPin(pin);
      if (!isPinValid) {
        logDebug('PIN verification failed');
        return OfflineAuthResult(
          success: false,
          error: 'Invalid PIN',
          requiresReauth: true,
        );
      }

      // Get cached token
      final token = await _secureStorage.getToken();
      if (token == null) {
        logDebug('No cached token found');
        return OfflineAuthResult(
          success: false,
          error: 'No cached credentials. Please login online.',
          requiresReauth: true,
        );
      }

      // Check if token is still valid
      try {
        final decoded = JwtDecoder.decode(token);
        final exp = decoded['exp'] as int?;
        if (exp != null) {
          final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
          if (DateTime.now().isAfter(expiryTime)) {
            logDebug('Cached token is expired');
            return OfflineAuthResult(
              success: false,
              error: 'Session expired. Please login online.',
              requiresReauth: true,
            );
          }
        }
      } catch (e) {
        logError('Failed to decode token', e);
        return OfflineAuthResult(
          success: false,
          error: 'Invalid cached credentials. Please login online.',
          requiresReauth: true,
        );
      }

      // Get user info from token
      final user = _getUserFromToken(token);

      // Update last login time
      await _secureStorage.saveLastLoginTime();

      logDebug('Offline authentication successful for ${user.id}');
      return OfflineAuthResult(
        success: true,
        user: user,
        token: token,
      );
    } catch (e) {
      logError('Offline authentication failed', e);
      return OfflineAuthResult(
        success: false,
        error: 'Authentication failed: $e',
        requiresReauth: true,
      );
    }
  }

  /// Authenticate with biometric (works offline)
  Future<OfflineAuthResult> authenticateWithBiometric() async {
    try {
      // Check if biometric is set up
      final hasPin = await _secureStorage.hasPin();
      if (!hasPin) {
        return OfflineAuthResult(
          success: false,
          error: 'Biometric not set up',
          requiresReauth: true,
        );
      }

      // Get cached token
      final token = await _secureStorage.getToken();
      if (token == null) {
        return OfflineAuthResult(
          success: false,
          error: 'No cached credentials. Please login online.',
          requiresReauth: true,
        );
      }

      // Get user info from token
      final user = _getUserFromToken(token);

      // Update last login time
      await _secureStorage.saveLastLoginTime();

      logDebug('Biometric authentication successful for ${user.id}');
      return OfflineAuthResult(
        success: true,
        user: user,
        token: token,
        usedBiometric: true,
      );
    } catch (e) {
      logError('Biometric authentication failed', e);
      return OfflineAuthResult(
        success: false,
        error: 'Biometric authentication failed: $e',
        requiresReauth: true,
      );
    }
  }

  /// Get remaining grace period for offline access
  Future<Duration?> getGracePeriodRemaining() async {
    return await _secureStorage.getOfflineGracePeriodRemaining();
  }

  /// Check if re-authentication is needed
  Future<bool> needsReauthentication() async {
    return await _secureStorage.needsOnlineReauth();
  }

  /// Get user info from JWT token
  OfflineAuthUser _getUserFromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return OfflineAuthUser(
      id: decoded['sub']?.toString() ?? '',
      email: decoded['email']?.toString() ?? '',
      firstName: decoded['first_name']?.toString() ?? '',
      lastName: decoded['last_name']?.toString() ?? '',
      role: decoded['role']?.toString() ?? 'caravan',
    );
  }
}

/// Result of offline authentication attempt
class OfflineAuthResult {
  final bool success;
  final OfflineAuthUser? user;
  final String? token;
  final String? error;
  final bool requiresReauth;
  final bool usedBiometric;

  OfflineAuthResult({
    required this.success,
    this.user,
    this.token,
    this.error,
    this.requiresReauth = false,
    this.usedBiometric = false,
  });

  @override
  String toString() {
    if (success) {
      return 'OfflineAuthResult(success: true, user: ${user?.email})';
    } else {
      return 'OfflineAuthResult(success: false, error: $error, requiresReauth: $requiresReauth)';
    }
  }
}

/// User info from offline authentication
class OfflineAuthUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  OfflineAuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  /// Get user's full name
  String get fullName => '$firstName $lastName'.trim();

  @override
  String toString() => 'OfflineAuthUser(id: $id, email: $email, role: $role)';
}
