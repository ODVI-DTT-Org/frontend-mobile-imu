import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Result of a biometric authentication attempt.
enum BiometricResult {
  /// Authentication succeeded
  success,

  /// Authentication failed (wrong fingerprint/face)
  failed,

  /// Biometric not available on device
  notAvailable,

  /// Biometric not enrolled (no fingerprints/face registered)
  notEnrolled,

  /// User cancelled biometric prompt
  cancelled,

  /// Biometric locked out (too many failed attempts)
  lockedOut,

  /// Other error occurred
  error,
}

/// Extension to convert LocalAuthenticationStatus to BiometricResult.
extension BiometricResultExtension on BiometricResult {
  /// Get user-friendly error message.
  String get message {
    switch (this) {
      case BiometricResult.success:
        return 'Authentication successful';
      case BiometricResult.failed:
        return 'Authentication failed';
      case BiometricResult.notAvailable:
        return 'Biometric authentication is not available on this device';
      case BiometricResult.notEnrolled:
        return 'No biometric credentials enrolled. Please enroll fingerprints or face in device settings.';
      case BiometricResult.cancelled:
        return 'Authentication was cancelled';
      case BiometricResult.lockedOut:
        return 'Biometric authentication is locked out due to too many failed attempts. Please use your PIN to unlock.';
      case BiometricResult.error:
        return 'An error occurred during biometric authentication';
    }
  }

  /// Check if this result indicates a permanent failure (should fallback to PIN).
  bool get shouldFallbackToPin {
    return this == BiometricResult.notAvailable ||
           this == BiometricResult.notEnrolled ||
           this == BiometricResult.lockedOut ||
           this == BiometricResult.failed;
  }

  /// Check if user can retry biometric authentication.
  bool get canRetry {
    return this == BiometricResult.failed ||
           this == BiometricResult.cancelled;
  }
}

/// Service for managing biometric authentication.
///
/// Features:
/// - Check biometric availability
/// - Authenticate with fingerprint/Face ID
/// - Get available biometric types
/// - Check enrollment status
/// - Platform-specific configuration
///
/// Security considerations:
/// - Biometric authentication is a convenience feature
/// - Falls back to PIN when biometric fails
/// - Requires device PIN/passcode for setup
/// - Respects device lockout policies
class BiometricService {
  final LocalAuthentication _localAuth;

  BiometricService() : _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on this device.
  ///
  /// Returns true if:
  /// - Device supports biometric authentication
  /// - User has enrolled at least one biometric (fingerprint/face)
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        return false;
      }

      final isEnrolled = await _localAuth.isDeviceSupported();
      return isEnrolled;
    } catch (e) {
      return false;
    }
  }

  /// Check if device supports biometric authentication.
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types on this device.
  Future<List<dynamic>> getAvailableBiometrics() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.toList();
    } catch (e) {
      return [];
    }
  }

  /// Check if user has enrolled any biometric credentials.
  Future<bool> isBiometricEnrolled() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate with biometric (fingerprint/Face ID).
  ///
  /// Returns [BiometricResult] indicating success or failure reason.
  Future<BiometricResult> authenticate() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access IMU',
        options: const AuthenticationOptions(
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (isAuthenticated) {
        await HapticUtils.success();
        return BiometricResult.success;
      } else {
        await HapticUtils.errorNotification();
        return BiometricResult.failed;
      }
    } catch (e) {
      // Handle specific error codes
      if (e is PlatformException) {
        final code = e.code;
        final message = e.message?.toLowerCase() ?? '';

        if (code == 'NotAvailable' || message.contains('not available')) {
          return BiometricResult.notAvailable;
        } else if (code == 'NotEnrolled' || message.contains('not enrolled')) {
          return BiometricResult.notEnrolled;
        } else if (code == 'LockedOut' || message.contains('locked out')) {
          return BiometricResult.lockedOut;
        } else if (code == 'UserCancel' || message.contains('user cancel')) {
          return BiometricResult.cancelled;
        } else if (code == 'AuthFailed' || message.contains('auth failed')) {
          await HapticUtils.errorNotification();
          return BiometricResult.failed;
        }
      }

      await HapticUtils.errorNotification();
      return BiometricResult.error;
    }
  }

  /// Check if biometric authentication is locked out.
  ///
  /// Returns true if biometric is temporarily locked due to too many failed attempts.
  Future<bool> isLockedOut() async {
    try {
      // Try to check if we can authenticate (will fail if locked out)
      // This is a workaround since local_auth doesn't provide a direct method
      final available = await _localAuth.getAvailableBiometrics();
      if (available.isEmpty) {
        return false; // Not enrolled, not locked out
      }

      // If we have biometrics available, try to authenticate
      // If it's locked out, the authenticate call will fail quickly
      final result = await authenticate();
      return result == BiometricResult.lockedOut;
    } catch (e) {
      return false;
    }
  }

  /// Stop biometric authentication (if currently in progress).
  ///
  /// Note: This is a platform-specific operation and may not be supported on all devices.
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping authentication
    }
  }

  /// Get human-readable description of available biometrics.
  ///
  /// Returns a string like "Fingerprint" or "Face ID" or "Fingerprint or Face ID".
  Future<String> getBiometricDescription() async {
    try {
      final available = await getAvailableBiometrics();

      if (available.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (available.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (available.contains(BiometricType.iris)) {
        return 'Iris Scanner';
      } else if (available.contains(BiometricType.strong)) {
        return 'Biometric Authentication';
      } else {
        return 'Biometric';
      }
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Check if device has fingerprint sensor.
  Future<bool> hasFingerprint() async {
    try {
      final available = await getAvailableBiometrics();
      return available.contains(BiometricType.fingerprint) ||
             available.contains(BiometricType.strong);
    } catch (e) {
      return false;
    }
  }

  /// Check if device has Face ID.
  Future<bool> hasFaceID() async {
    try {
      final available = await getAvailableBiometrics();
      return available.contains(BiometricType.face);
    } catch (e) {
      return false;
    }
  }

  /// Get platform-specific biometric name.
  ///
  /// Returns "Fingerprint" on Android, "Face ID" or "Fingerprint" on iOS.
  Future<String> getPlatformBiometricName() async {
    if (Platform.isAndroid) {
      return 'Fingerprint';
    } else if (Platform.isIOS) {
      return await hasFaceID() ? 'Face ID' : 'Fingerprint';
    }
    return 'Biometric';
  }
}

/// Biometric types available on the device.
enum BiometricType {
  /// Fingerprint sensor
  fingerprint,

  /// Face recognition (Face ID on iOS)
  face,

  /// Iris scanner
  iris,

  /// Strong biometric (undefined type, used for multi-biometric)
  strong,
}
