import '../../data/services/pin_storage_service.dart';
import 'pin_hash_service.dart';

/// Result of PIN validation.
enum PinValidationResult {
  /// PIN is correct
  success,

  /// PIN is incorrect
  incorrect,

  /// Too many failed attempts, account locked
  lockedOut,

  /// Account is locked out and lockout hasn't expired
  lockoutNotExpired,
}

/// Service for validating PINs and managing retry logic.
///
/// Features:
/// - Validates 6-digit PIN format
/// - Verifies PIN against stored hash
/// - Tracks failed attempts
/// - Locks after 5 failed attempts for 30 minutes
/// - Resets attempt counter on success
class PinValidationService {
  final PinStorageService _storageService;
  final PinHashService _hashService;

  /// Maximum number of failed attempts before lockout
  static const int maxFailedAttempts = 5;

  /// Duration of lockout after max attempts
  static const Duration lockoutDuration = Duration(minutes: 30);

  /// Required PIN length
  static const int requiredPinLength = 6;

  PinValidationService({
    required PinStorageService storageService,
    required PinHashService hashService,
  })  : _storageService = storageService,
        _hashService = hashService;

  /// Validate a PIN format.
  ///
  /// Returns true if the PIN is exactly 6 digits.
  bool isValidPinFormat(String pin) {
    if (pin.length != requiredPinLength) return false;
    // Check if all characters are digits
    return RegExp(r'^\d{6}$').hasMatch(pin);
  }

  /// Validate a PIN against the stored hash.
  ///
  /// Returns [PinValidationResult.success] if PIN is correct.
  /// Returns [PinValidationResult.incorrect] if PIN is wrong.
  /// Returns [PinValidationResult.lockedOut] if locked out.
  /// Returns [PinValidationResult.lockoutNotExpired] if still in lockout period.
  ///
  /// On success, resets the failed attempts counter.
  /// On failure, increments the counter and locks if needed.
  Future<PinValidationResult> validatePin(String pin) async {
    // Check if locked out
    final isLockedOut = await _storageService.isLockedOut();
    if (isLockedOut) {
      return PinValidationResult.lockoutNotExpired;
    }

    // Get stored hash and salt
    final storedHash = await _storageService.getPinHash();
    final salt = await _storageService.getPinSalt();

    if (storedHash == null || salt == null) {
      // No PIN set up
      return PinValidationResult.incorrect;
    }

    // Verify PIN
    final isValid = _hashService.verifyPin(pin, storedHash, salt);

    if (isValid) {
      // Reset failed attempts on success
      await _storageService.clearFailedAttempts();
      return PinValidationResult.success;
    } else {
      // Increment failed attempts
      await _incrementFailedAttempts();
      return PinValidationResult.incorrect;
    }
  }

  /// Increment the failed attempts counter and lock if needed.
  Future<void> _incrementFailedAttempts() async {
    final currentAttempts = await _storageService.getFailedAttempts();
    final newAttempts = currentAttempts + 1;
    await _storageService.storeFailedAttempts(newAttempts);

    // Lock if max attempts reached
    if (newAttempts >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now().add(lockoutDuration);
      await _storageService.storeLockoutUntil(lockoutUntil);
    }
  }

  /// Get the number of remaining attempts before lockout.
  ///
  /// Returns 0 if already locked out.
  Future<int> getRemainingAttempts() async {
    if (await _storageService.isLockedOut()) {
      return 0;
    }
    final currentAttempts = await _storageService.getFailedAttempts();
    return maxFailedAttempts - currentAttempts;
  }

  /// Get the lockout expiration time.
  ///
  /// Returns null if not locked out.
  Future<DateTime?> getLockoutExpiration() async {
    return await _storageService.getLockoutUntil();
  }

  /// Clear the lockout and reset attempts.
  ///
  /// Called after successful login or manually by admin.
  Future<void> resetLockout() async {
    await _storageService.clearFailedAttempts();
    await _storageService.clearLockout();
  }
}
