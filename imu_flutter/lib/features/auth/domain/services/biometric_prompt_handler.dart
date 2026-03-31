import 'package:flutter/foundation.dart';
import 'biometric_service.dart';
import '../../data/services/biometric_storage_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Result of a biometric authentication prompt attempt.
class BiometricPromptResult {
  final bool success;
  final BiometricResult result;
  final String? errorMessage;
  final bool shouldFallbackToPin;

  const BiometricPromptResult({
    required this.success,
    required this.result,
    this.errorMessage,
    this.shouldFallbackToPin = false,
  });

  factory BiometricPromptResult.successful({required BiometricResult result}) {
    return BiometricPromptResult(
      success: true,
      result: result,
    );
  }

  factory BiometricPromptResult.failed({
    required BiometricResult result,
    String? errorMessage,
    bool shouldFallbackToPin = true,
  }) {
    return BiometricPromptResult(
      success: false,
      result: result,
      errorMessage: errorMessage,
      shouldFallbackToPin: shouldFallbackToPin,
    );
  }

  factory BiometricPromptResult.cancelled() {
    return BiometricPromptResult(
      success: false,
      result: BiometricResult.cancelled,
      errorMessage: 'Biometric authentication was cancelled',
      shouldFallbackToPin: true,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'BiometricPromptResult.successful';
    } else {
      return 'BiometricPromptResult.failed(result: $result, error: $errorMessage)';
    }
  }
}

/// Handler for biometric authentication prompts.
///
/// Features:
/// - Check biometric availability before prompting
/// - Handle biometric authentication with retry logic
/// - Fallback to PIN when biometric fails/unavailable
/// - Track usage statistics
/// - Show enrollment prompt when needed
///
/// Usage:
/// ```dart
/// final handler = BiometricPromptHandler(
///   biometricService: biometricService,
///   storageService: storageService,
/// );
///
/// // Prompt for biometric authentication
/// final result = await handler.promptBiometric();
///
/// if (result.success) {
///   // Biometric authentication succeeded
/// } else if (result.shouldFallbackToPin) {
///   // Fall back to PIN entry
/// }
/// ```
class BiometricPromptHandler {
  final BiometricService _biometricService;
  final BiometricStorageService _storageService;

  /// Maximum number of retry attempts for failed biometric authentication
  static const int maxRetryAttempts = 3;

  BiometricPromptHandler({
    required BiometricService biometricService,
    required BiometricStorageService storageService,
  })  : _biometricService = biometricService,
        _storageService = storageService;

  /// Check if biometric authentication should be offered to user.
  ///
  /// Returns true if:
  /// - Biometric is available and enrolled
  /// - User hasn't disabled biometric
  Future<bool> shouldOfferBiometric() async {
    // Check if biometric is available
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      return false;
    }

    // Check user preference
    final preference = await _storageService.getUserPreference();
    if (preference == BiometricPreference.disabled) {
      return false;
    }

    return true;
  }

  /// Prompt for biometric authentication.
  ///
  /// Returns [BiometricPromptResult] indicating success or failure.
  /// Automatically handles retries and fallback to PIN.
  Future<BiometricPromptResult> promptBiometric({
    bool allowRetry = true,
    int maxRetries = maxRetryAttempts,
  }) async {
    // Check if biometric is available
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (!isAvailable) {
      return BiometricPromptResult.failed(
        result: BiometricResult.notAvailable,
        errorMessage: 'Biometric authentication is not available',
        shouldFallbackToPin: true,
      );
    }

    // Increment prompt count
    await _storageService.incrementPromptCount();

    // Attempt biometric authentication with retries
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      final result = await _biometricService.authenticate();

      if (result == BiometricResult.success) {
        // Success: update statistics and return
        await _storageService.setLastUsedTime(DateTime.now());
        await _storageService.resetFailedAttempts();
        await HapticUtils.success();

        return BiometricPromptResult.successful(result: result);
      }

      if (result == BiometricResult.cancelled) {
        // User cancelled: don't retry, fall back to PIN
        return BiometricPromptResult.cancelled();
      }

      if (result == BiometricResult.lockedOut) {
        // Locked out: fall back to PIN
        await _storageService.incrementFailedAttempts();
        await HapticUtils.errorNotification();

        return BiometricPromptResult.failed(
          result: result,
          errorMessage: result.message,
          shouldFallbackToPin: true,
        );
      }

      if (result == BiometricResult.notEnrolled) {
        // Not enrolled: fall back to PIN
        return BiometricPromptResult.failed(
          result: result,
          errorMessage: result.message,
          shouldFallbackToPin: true,
        );
      }

      if (result == BiometricResult.notAvailable) {
        // Not available: fall back to PIN
        return BiometricPromptResult.failed(
          result: result,
          errorMessage: result.message,
          shouldFallbackToPin: true,
        );
      }

      // Authentication failed
      await _storageService.incrementFailedAttempts();
      await HapticUtils.errorNotification();

      // Check if we should retry
      if (allowRetry && attempt < maxRetries && result.canRetry) {
        // Wait a bit before retrying
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      // Max retries reached or can't retry: fall back to PIN
      return BiometricPromptResult.failed(
        result: result,
        errorMessage: result.message,
        shouldFallbackToPin: true,
      );
    }

    // Should not reach here, but handle gracefully
    return BiometricPromptResult.failed(
      result: BiometricResult.error,
      errorMessage: 'Unexpected error during biometric authentication',
      shouldFallbackToPin: true,
    );
  }

  /// Check if biometric enrollment prompt should be shown.
  ///
  /// Returns true if:
  /// - Biometric is available on device
  /// - User hasn't enrolled any biometrics
  /// - Enrollment prompt hasn't been shown before
  Future<bool> shouldShowEnrollmentPrompt() async {
    // Check if device supports biometric
    final isSupported = await _biometricService.isDeviceSupported();
    if (!isSupported) {
      return false;
    }

    // Check if user has enrolled biometrics
    final isEnrolled = await _biometricService.isBiometricEnrolled();
    if (isEnrolled) {
      return false; // Already enrolled
    }

    // Check if we've already shown the prompt
    final alreadyShown = await _storageService.hasEnrollmentPromptBeenShown();
    if (alreadyShown) {
      return false; // Already shown
    }

    return true;
  }

  /// Mark that enrollment prompt has been shown.
  Future<void> markEnrollmentPromptShown() async {
    await _storageService.setEnrollmentPromptShown();
  }

  /// Enable biometric authentication.
  Future<void> enableBiometric() async {
    await _storageService.setEnabled(true);
    await _storageService.setUserPreference(BiometricPreference.enabled);
  }

  /// Disable biometric authentication.
  Future<void> disableBiometric() async {
    await _storageService.setEnabled(false);
    await _storageService.setUserPreference(BiometricPreference.disabled);
  }

  /// Get biometric usage statistics.
  Future<Map<String, dynamic>> getUsageStats() async {
    return await _storageService.getUsageStats();
  }

  /// Get human-readable biometric type name.
  Future<String> getBiometricTypeName() async {
    return await _biometricService.getPlatformBiometricName();
  }

  /// Dispose of resources.
  void dispose() {
    // No resources to dispose
  }
}
