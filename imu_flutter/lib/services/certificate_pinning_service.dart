import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Certificate pinning service for secure API communication
/// Note: This is a stub implementation. Full implementation requires
/// proper certificate configuration for production.
class CertificatePinningService extends ChangeNotifier {
  bool _isPinningEnabled = false;
  List<String> _pinnedCertificates = [];

  bool get isPinningEnabled => _isPinningEnabled;
  List<String> get pinnedCertificates => List.unmodifiable(_pinnedCertificates);

  /// Enable certificate pinning
  Future<void> enablePinning(List<String> certificates) async {
    _pinnedCertificates = certificates;
    _isPinningEnabled = true;
    debugPrint('CertificatePinningService: Pinning enabled with ${certificates.length} certificates');
  }

  /// Disable certificate pinning
  void disablePinning() {
    _isPinningEnabled = false;
    _pinnedCertificates = [];
    debugPrint('CertificatePinningService: Pinning disabled');
  }

  /// Verify certificate (stub)
  Future<bool> verifyCertificate(String certificate) async {
    if (!_isPinningEnabled) return true;
    return _pinnedCertificates.contains(certificate);
  }
}

/// Provider for CertificatePinningService
final certificatePinningServiceProvider = Provider<CertificatePinningService>((ref) {
  return CertificatePinningService();
});
