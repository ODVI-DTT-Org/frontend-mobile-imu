import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/auth_state.dart';

/// Storage keys for offline credentials
class _StorageKeys {
  static const String lastValidToken = 'offline_last_valid_token';
  static const String lastValidRefreshToken = 'offline_last_valid_refresh_token';
  static const String lastValidUserId = 'offline_last_valid_user_id';
  static const String offlineAuthTimestamp = 'offline_auth_timestamp';
  static const String gracePeriodExpiry = 'grace_period_expiry';
  static const String credentialsHash = 'credentials_hash'; // For integrity validation
}

/// Service for storing and managing offline authentication credentials.
///
/// Features:
/// - Encrypted storage of last-known valid credentials
/// - Grace period tracking (24-hour offline access)
/// - Credential integrity validation
/// - Automatic cleanup of expired credentials
///
/// Security considerations:
/// - All credentials stored encrypted using flutter_secure_storage
/// - Credentials only used for offline mode, not for API calls
/// - Grace period limits offline access to 24 hours
/// - Automatic credential cleanup when grace period expires
class OfflineCredentialStorageService {
  /// Default grace period for offline access (24 hours)
  static const Duration defaultGracePeriod = Duration(hours: 24);

  final FlutterSecureStorage _secureStorage;

  OfflineCredentialStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Store credentials for offline authentication.
  ///
  /// Should be called after successful online authentication.
  /// Stores access token, refresh token, user ID, and grace period expiry.
  Future<void> storeOfflineCredentials({
    required String accessToken,
    required String refreshToken,
    required String userId,
    Duration gracePeriod = defaultGracePeriod,
  }) async {
    final now = DateTime.now();
    final gracePeriodExpiry = now.add(gracePeriod);

    await _secureStorage.write(
      key: _StorageKeys.lastValidToken,
      value: accessToken,
    );

    await _secureStorage.write(
      key: _StorageKeys.lastValidRefreshToken,
      value: refreshToken,
    );

    await _secureStorage.write(
      key: _StorageKeys.lastValidUserId,
      value: userId,
    );

    await _secureStorage.write(
      key: _StorageKeys.offlineAuthTimestamp,
      value: now.toIso8601String(),
    );

    await _secureStorage.write(
      key: _StorageKeys.gracePeriodExpiry,
      value: gracePeriodExpiry.toIso8601String(),
    );

    // Store hash for integrity validation
    final hash = _generateCredentialsHash(
      accessToken,
      refreshToken,
      userId,
    );
    await _secureStorage.write(
      key: _StorageKeys.credentialsHash,
      value: hash,
    );
  }

  /// Get stored offline credentials.
  ///
  /// Returns null if no credentials are stored or if grace period has expired.
  Future<OfflineCredentials?> getOfflineCredentials() async {
    // Check if credentials exist
    final accessToken = await _secureStorage.read(key: _StorageKeys.lastValidToken);
    final refreshToken = await _secureStorage.read(key: _StorageKeys.lastValidRefreshToken);
    final userId = await _secureStorage.read(key: _StorageKeys.lastValidUserId);
    final gracePeriodExpiryStr = await _secureStorage.read(key: _StorageKeys.gracePeriodExpiry);
    final storedHash = await _secureStorage.read(key: _StorageKeys.credentialsHash);

    if (accessToken == null ||
        refreshToken == null ||
        userId == null ||
        gracePeriodExpiryStr == null ||
        storedHash == null) {
      return null;
    }

    // Validate grace period
    final gracePeriodExpiry = DateTime.parse(gracePeriodExpiryStr);
    if (DateTime.now().isAfter(gracePeriodExpiry)) {
      // Grace period expired, clear credentials
      await clearOfflineCredentials();
      return null;
    }

    // Validate integrity
    final computedHash = _generateCredentialsHash(accessToken, refreshToken, userId);
    if (computedHash != storedHash) {
      // Integrity check failed, clear credentials
      await clearOfflineCredentials();
      return null;
    }

    return OfflineCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      gracePeriodExpiry: gracePeriodExpiry,
    );
  }

  /// Check if offline authentication is available.
  ///
  /// Returns true if valid credentials exist and grace period hasn't expired.
  Future<bool> isOfflineAuthAvailable() async {
    final credentials = await getOfflineCredentials();
    return credentials != null;
  }

  /// Get remaining grace period duration.
  ///
  /// Returns null if no credentials are stored.
  Future<Duration?> getRemainingGracePeriod() async {
    final gracePeriodExpiryStr = await _secureStorage.read(key: _StorageKeys.gracePeriodExpiry);
    if (gracePeriodExpiryStr == null) return null;

    final gracePeriodExpiry = DateTime.parse(gracePeriodExpiryStr);
    final remaining = gracePeriodExpiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Clear stored offline credentials.
  ///
  /// Should be called when:
  /// - User logs out
  /// - Grace period expires
  /// - Integrity validation fails
  /// - User successfully authenticates online
  Future<void> clearOfflineCredentials() async {
    await _secureStorage.delete(key: _StorageKeys.lastValidToken);
    await _secureStorage.delete(key: _StorageKeys.lastValidRefreshToken);
    await _secureStorage.delete(key: _StorageKeys.lastValidUserId);
    await _secureStorage.delete(key: _StorageKeys.offlineAuthTimestamp);
    await _secureStorage.delete(key: _StorageKeys.gracePeriodExpiry);
    await _secureStorage.delete(key: _StorageKeys.credentialsHash);
  }

  /// Validate stored credentials for integrity.
  ///
  /// Returns true if credentials are valid and haven't been tampered with.
  Future<bool> validateCredentialsIntegrity() async {
    final credentials = await getOfflineCredentials();
    return credentials != null;
  }

  /// Get the timestamp when offline credentials were stored.
  Future<DateTime?> getOfflineAuthTimestamp() async {
    final timestampStr = await _secureStorage.read(key: _StorageKeys.offlineAuthTimestamp);
    if (timestampStr == null) return null;
    return DateTime.parse(timestampStr);
  }

  /// Generate hash for credential integrity validation.
  ///
  /// Uses a simple hash of the credentials to detect tampering.
  String _generateCredentialsHash(String accessToken, String refreshToken, String userId) {
    // Simple hash implementation (in production, use proper cryptographic hash)
    final combined = '$accessToken|$refreshToken|$userId';
    final bytes = combined.codeUnits;
    var hash = 0;
    for (var i = 0; i < bytes.length; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return hash.toRadixString(16);
  }

  /// Dispose of resources.
  void dispose() {
    // No resources to dispose
  }
}

/// Data class for offline credentials.
class OfflineCredentials {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final DateTime gracePeriodExpiry;

  OfflineCredentials({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.gracePeriodExpiry,
  });

  /// Check if grace period has expired.
  bool get isGracePeriodExpired {
    return DateTime.now().isAfter(gracePeriodExpiry);
  }

  /// Get remaining grace period.
  Duration get remainingGracePeriod {
    final remaining = gracePeriodExpiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  String toString() {
    return 'OfflineCredentials(userId: $userId, gracePeriodExpiry: $gracePeriodExpiry)';
  }
}
