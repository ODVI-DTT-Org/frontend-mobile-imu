import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Service for hashing and verifying PINs with salted SHA-256.
///
/// Security features:
/// - Uses cryptographically secure random salt
/// - SHA-256 hashing algorithm
/// - Constant-time comparison to prevent timing attacks
/// - Salt stored separately from hash
class PinHashService {
  /// Length of salt in bytes (16 bytes = 128 bits)
  static const int saltLength = 16;

  /// Generate a cryptographically secure random salt.
  ///
  /// Returns 16 random bytes encoded as hexadecimal string.
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return _bytesToHex(saltBytes);
  }

  /// Hash a PIN with the given salt.
  ///
  /// Uses SHA-256 algorithm with the salt.
  /// Returns the hash as a hexadecimal string.
  String hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify a PIN against a stored hash.
  ///
  /// Uses constant-time comparison to prevent timing attacks.
  /// Returns true if the PIN is correct.
  bool verifyPin(String pin, String storedHash, String salt) {
    final computedHash = hashPin(pin, salt);
    return _constantTimeEquals(computedHash, storedHash);
  }

  /// Constant-time string comparison to prevent timing attacks.
  ///
  /// This prevents attackers from guessing PINs by measuring response times.
  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }

    return result == 0;
  }

  /// Convert bytes to hexadecimal string.
  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
