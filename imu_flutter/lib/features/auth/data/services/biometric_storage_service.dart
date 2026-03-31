import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage keys for biometric settings.
class _BiometricStorageKeys {
  static const String isEnabled = 'biometric_is_enabled';
  static const String lastUsedTime = 'biometric_last_used';
  static const String promptCount = 'biometric_prompt_count';
  static const String failedAttemptCount = 'biometric_failed_attempts';
  static const String enrollmentPromptShown = 'biometric_enrollment_prompt_shown';
  static const String userPreference = 'biometric_user_preference';
}

/// User preference for biometric authentication.
enum BiometricPreference {
  /// User prefers biometric authentication
  enabled,

  /// User prefers PIN authentication
  disabled,

  /// User has not set a preference
  notSet,
}

/// Service for storing biometric authentication settings and preferences.
///
/// Features:
/// - Store user's biometric preference
/// - Track biometric usage statistics
/// - Track failed attempts
/// - Remember if enrollment prompt was shown
///
/// Security considerations:
/// - All settings stored encrypted using flutter_secure_storage
/// - Preference is stored per device
/// - Failed attempts reset on successful authentication
class BiometricStorageService {
  final FlutterSecureStorage _secureStorage;

  BiometricStorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Check if biometric authentication is enabled.
  Future<bool> isEnabled() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.isEnabled);
    return value == 'true';
  }

  /// Set biometric authentication enabled/disabled.
  Future<void> setEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _BiometricStorageKeys.isEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Get user's biometric preference.
  Future<BiometricPreference> getUserPreference() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.userPreference);
    if (value == null) return BiometricPreference.notSet;

    switch (value) {
      case 'enabled':
        return BiometricPreference.enabled;
      case 'disabled':
        return BiometricPreference.disabled;
      default:
        return BiometricPreference.notSet;
    }
  }

  /// Set user's biometric preference.
  Future<void> setUserPreference(BiometricPreference preference) async {
    final value = switch (preference) {
      BiometricPreference.enabled => 'enabled',
      BiometricPreference.disabled => 'disabled',
      BiometricPreference.notSet => null,
    };

    if (value != null) {
      await _secureStorage.write(
        key: _BiometricStorageKeys.userPreference,
        value: value,
      );
    } else {
      await _secureStorage.delete(key: _BiometricStorageKeys.userPreference);
    }
  }

  /// Get timestamp of last successful biometric authentication.
  Future<DateTime?> getLastUsedTime() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.lastUsedTime);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  /// Set timestamp of last successful biometric authentication.
  Future<void> setLastUsedTime(DateTime time) async {
    await _secureStorage.write(
      key: _BiometricStorageKeys.lastUsedTime,
      value: time.toIso8601String(),
    );
  }

  /// Get number of times biometric authentication was prompted.
  Future<int> getPromptCount() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.promptCount);
    return int.tryParse(value ?? '') ?? 0;
  }

  /// Increment prompt count.
  Future<void> incrementPromptCount() async {
    final current = await getPromptCount();
    await _secureStorage.write(
      key: _BiometricStorageKeys.promptCount,
      value: (current + 1).toString(),
    );
  }

  /// Reset prompt count.
  Future<void> resetPromptCount() async {
    await _secureStorage.write(
      key: _BiometricStorageKeys.promptCount,
      value: '0',
    );
  }

  /// Get number of failed biometric attempts.
  Future<int> getFailedAttemptCount() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.failedAttemptCount);
    return int.tryParse(value ?? '') ?? 0;
  }

  /// Increment failed attempt count.
  Future<void> incrementFailedAttempts() async {
    final current = await getFailedAttemptCount();
    await _secureStorage.write(
      key: _BiometricStorageKeys.failedAttemptCount,
      value: (current + 1).toString(),
    );
  }

  /// Reset failed attempt count (called on successful authentication).
  Future<void> resetFailedAttempts() async {
    await _secureStorage.write(
      key: _BiometricStorageKeys.failedAttemptCount,
      value: '0',
    );
  }

  /// Check if enrollment prompt has been shown.
  Future<bool> hasEnrollmentPromptBeenShown() async {
    final value = await _secureStorage.read(key: _BiometricStorageKeys.enrollmentPromptShown);
    return value == 'true';
  }

  /// Mark that enrollment prompt has been shown.
  Future<void> setEnrollmentPromptShown() async {
    await _secureStorage.write(
      key: _BiometricStorageKeys.enrollmentPromptShown,
      value: 'true',
    );
  }

  /// Clear all biometric settings.
  ///
  /// Should be called when user logs out or switches accounts.
  Future<void> clearAll() async {
    await _secureStorage.delete(key: _BiometricStorageKeys.isEnabled);
    await _secureStorage.delete(key: _BiometricStorageKeys.lastUsedTime);
    await _secureStorage.delete(key: _BiometricStorageKeys.promptCount);
    await _secureStorage.delete(key: _BiometricStorageKeys.failedAttemptCount);
    await _secureStorage.delete(key: _BiometricStorageKeys.enrollmentPromptShown);
    await _secureStorage.delete(key: _BiometricStorageKeys.userPreference);
  }

  /// Get biometric usage statistics.
  Future<Map<String, dynamic>> getUsageStats() async {
    return {
      'isEnabled': await isEnabled(),
      'lastUsedTime': await getLastUsedTime(),
      'promptCount': await getPromptCount(),
      'failedAttempts': await getFailedAttemptCount(),
      'enrollmentPromptShown': await hasEnrollmentPromptBeenShown(),
      'userPreference': await getUserPreference(),
    };
  }

  /// Dispose of resources.
  void dispose() {
    // No resources to dispose
  }
}
