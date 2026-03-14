import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Biometric authentication service
class BiometricService extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAvailable = false;
  String? _lastError;

  bool get isAvailable => _isAvailable;
  String? get lastError => _lastError;

  BiometricService() {
    _checkAvailability();
  }

  /// Check if device supports biometric authentication
  Future<void> _checkAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      _isAvailable = isAvailable;
      notifyListeners();
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error checking availability: $e');
      _lastError = e.toString();
      _isAvailable = false;
      notifyListeners();
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Error getting biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate() async {
    try {
      if (!_isAvailable) {
        throw Exception('Biometric authentication not available');
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate) {
        debugPrint('BiometricService: Authentication successful');
        notifyListeners();
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Authentication failed: $e');
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      debugPrint('BiometricService: Error stopping authentication: $e');
    }
  }
}

/// Provider for BiometricService
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

/// Provider for biometric availability
final biometricAvailableProvider = Provider<bool>((ref) {
  final biometric = ref.watch(biometricServiceProvider);
  return biometric.isAvailable;
});
