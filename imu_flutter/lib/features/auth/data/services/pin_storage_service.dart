import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for storing and retrieving PIN data securely.
///
/// Security model:
/// - Hashed PIN is stored encrypted in secure storage
/// - Salt is stored separately (also encrypted)
/// - Both are cleared on logout
class PinStorageService {
  final FlutterSecureStorage _secureStorage;

  // Storage keys
  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _failedAttemptsKey = 'pin_failed_attempts';
  static const String _lockoutUntilKey = 'pin_lockout_until';

  PinStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
          ),
        );

  /// Store the hashed PIN and salt.
  ///
  /// Called after successful PIN setup.
  Future<void> storePin(String hashedPin, String salt) async {
    await _secureStorage.write(key: _pinHashKey, value: hashedPin);
    await _secureStorage.write(key: _pinSaltKey, value: salt);
  }

  /// Retrieve the stored hashed PIN.
  ///
  /// Returns null if no PIN is set up.
  Future<String?> getPinHash() async {
    return await _secureStorage.read(key: _pinHashKey);
  }

  /// Retrieve the stored salt.
  ///
  /// Returns null if no PIN is set up.
  Future<String?> getPinSalt() async {
    return await _secureStorage.read(key: _pinSaltKey);
  }

  /// Check if a PIN has been set up.
  ///
  /// Returns true if a PIN hash exists in storage.
  Future<bool> isPinSetup() async {
    final hash = await getPinHash();
    return hash != null && hash.isNotEmpty;
  }

  /// Clear all PIN data.
  ///
  /// Called on logout or PIN reset.
  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await clearFailedAttempts();
    await clearLockout();
  }

  /// Store the number of failed PIN attempts.
  Future<void> storeFailedAttempts(int count) async {
    await _secureStorage.write(
      key: _failedAttemptsKey,
      value: count.toString(),
    );
  }

  /// Retrieve the number of failed PIN attempts.
  ///
  /// Returns 0 if no attempts have been recorded.
  Future<int> getFailedAttempts() async {
    final value = await _secureStorage.read(key: _failedAttemptsKey);
    return value != null ? int.tryParse(value) ?? 0 : 0;
  }

  /// Clear the failed attempts counter.
  ///
  /// Called after successful PIN entry or lockout period expires.
  Future<void> clearFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
  }

  /// Store the lockout expiration time.
  ///
  /// [lockoutUntil] is the Unix timestamp when lockout expires.
  Future<void> storeLockoutUntil(DateTime lockoutUntil) async {
    await _secureStorage.write(
      key: _lockoutUntilKey,
      value: lockoutUntil.toIso8601String(),
    );
  }

  /// Retrieve the lockout expiration time.
  ///
  /// Returns null if not locked out.
  Future<DateTime?> getLockoutUntil() async {
    final value = await _secureStorage.read(key: _lockoutUntilKey);
    if (value == null) return null;
    return DateTime.parse(value);
  }

  /// Clear the lockout.
  ///
  /// Called after lockout period expires.
  Future<void> clearLockout() async {
    await _secureStorage.delete(key: _lockoutUntilKey);
  }

  /// Check if the user is currently locked out.
  ///
  /// Returns true if locked out and lockout hasn't expired.
  Future<bool> isLockedOut() async {
    final lockoutUntil = await getLockoutUntil();
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil);
  }
}
