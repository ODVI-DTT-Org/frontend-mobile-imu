import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Certificate pinning service for secure API communication
/// Prevents MITM attacks by validating server certificates against known hashes
class CertificatePinningService {
  static const List<String> _pinnedHashes = [
    // Placeholder - replace with actual production certificate hashes
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  List<String> get pinnedHashes => _pinnedHashes;

  bool get isEnabled => _pinnedHashes.isNotEmpty;

  /// Validate a certificate against pinned hashes
  /// Returns true if valid (in development mode) or if certificate is pinned (production)
  Future<bool> validateCertificate(X509Certificate? cert) async {
    if (cert == null) return false;

    // In development mode, accept any certificate
    if (kDebugMode) {
      return true;
    }

    // In production, validate certificate hash against pinned hashes
    final certBytes = cert.der;
    final digest = sha256.convert(certBytes);
    final certHash = 'sha256/${base64.encode(digest.bytes)}';

    return _pinnedHashes.contains(certHash);
  }

  /// Create a security context with pinned certificates
  /// Note: This is a basic implementation. For production, you may need
  /// to configure specific certificate chains
  SecurityContext createSecurityContext() {
    return SecurityContext(withTrustedRoots: false);
  }
}

/// Helper function to compute SHA-256 hash
Future<String> computeCertificateHash(X509Certificate cert) async {
  final certBytes = cert.der;
  final digest = sha256.convert(certBytes);
  return 'sha256/${base64.encode(digest.bytes)}';
}

/// Provider for CertificatePinningService

final certificatePinningServiceProvider = Provider<CertificatePinningService>((ref) {
  return CertificatePinningService();
});
