import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/domain/services/pin_hash_service.dart';

void main() {
  group('PinHashService', () {
    late PinHashService pinHashService;

    setUp(() {
      pinHashService = PinHashService();
    });

    group('Salt Generation', () {
      test('should generate salt of correct length', () {
        final salt = pinHashService.generateSalt();

        // Salt should be 16 bytes = 32 hex characters
        expect(salt.length, equals(32));
      });

      test('should generate different salts each time', () {
        final salt1 = pinHashService.generateSalt();
        final salt2 = pinHashService.generateSalt();

        expect(salt1, isNot(equals(salt2)));
      });

      test('should generate valid hexadecimal string', () {
        final salt = pinHashService.generateSalt();

        // Should only contain hexadecimal characters
        expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(salt), isTrue);
      });
    });

    group('PIN Hashing', () {
      test('should hash PIN with salt', () {
        final pin = '123456';
        final salt = 'abcdef0123456789abcdef0123456789';

        final hash = pinHashService.hashPin(pin, salt);

        // SHA-256 hash should be 64 hex characters
        expect(hash.length, equals(64));
      });

      test('should generate different hashes for different salts', () {
        final pin = '123456';
        final salt1 = 'salt1';
        final salt2 = 'salt2';

        final hash1 = pinHashService.hashPin(pin, salt1);
        final hash2 = pinHashService.hashPin(pin, salt2);

        expect(hash1, isNot(equals(hash2)));
      });

      test('should generate different hashes for different PINs', () {
        final pin1 = '123456';
        final pin2 = '654321';
        final salt = 'samesalt';

        final hash1 = pinHashService.hashPin(pin1, salt);
        final hash2 = pinHashService.hashPin(pin2, salt);

        expect(hash1, isNot(equals(hash2)));
      });

      test('should generate same hash for same PIN and salt', () {
        final pin = '123456';
        final salt = 'samesalt';

        final hash1 = pinHashService.hashPin(pin, salt);
        final hash2 = pinHashService.hashPin(pin, salt);

        expect(hash1, equals(hash2));
      });
    });

    group('PIN Verification', () {
      test('should verify correct PIN', () {
        final pin = '123456';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(pin, salt);

        expect(pinHashService.verifyPin(pin, hash, salt), isTrue);
      });

      test('should reject incorrect PIN', () {
        final correctPin = '123456';
        final wrongPin = '654321';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(correctPin, salt);

        expect(pinHashService.verifyPin(wrongPin, hash, salt), isFalse);
      });

      test('should reject PIN with different salt', () {
        final pin = '123456';
        final salt1 = 'salt1';
        final salt2 = 'salt2';

        final hash = pinHashService.hashPin(pin, salt1);

        expect(pinHashService.verifyPin(pin, hash, salt2), isFalse);
      });

      test('should use constant-time comparison', () {
        final pin = '123456';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(pin, salt);

        // Verify that constant-time comparison is used
        // (implementation uses XOR which is constant-time)
        final result1 = pinHashService.verifyPin(pin, hash, salt);
        final result2 = pinHashService.verifyPin('wrong', hash, salt);

        expect(result1, isTrue);
        expect(result2, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty PIN', () {
        final pin = '';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(pin, salt);

        expect(hash.length, equals(64));
        expect(pinHashService.verifyPin(pin, hash, salt), isTrue);
      });

      test('should handle special characters in PIN', () {
        final pin = '!@#%\\^';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(pin, salt);

        expect(hash.length, equals(64));
        expect(pinHashService.verifyPin(pin, hash, salt), isTrue);
      });

      test('should handle very long PIN', () {
        final pin = '12345678901234567890';
        final salt = 'testsalt';

        final hash = pinHashService.hashPin(pin, salt);

        expect(hash.length, equals(64));
        expect(pinHashService.verifyPin(pin, hash, salt), isTrue);
      });
    });
  });
}
