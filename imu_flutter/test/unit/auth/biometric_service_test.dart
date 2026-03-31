import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/features/auth/domain/services/biometric_service.dart';
import 'package:imu_flutter/features/auth/domain/services/biometric_prompt_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricService', () {
    late BiometricService biometricService;

    setUp(() {
      biometricService = BiometricService();
    });

    tearDown(() {
      // BiometricService doesn't need disposal
    });

    group('BiometricResult', () {
      test('should provide message for each result type', () {
        expect(BiometricResult.success.message, equals('Authentication successful'));
        expect(BiometricResult.failed.message, equals('Authentication failed'));
        expect(BiometricResult.notAvailable.message, contains('not available'));
        expect(BiometricResult.notEnrolled.message, contains('credentials enrolled'));
        expect(BiometricResult.cancelled.message, equals('Authentication was cancelled'));
        expect(BiometricResult.lockedOut.message, contains('locked out'));
        expect(BiometricResult.error.message, equals('An error occurred during biometric authentication'));
      });

      test('should determine when to fallback to PIN', () {
        expect(BiometricResult.notAvailable.shouldFallbackToPin, isTrue);
        expect(BiometricResult.notEnrolled.shouldFallbackToPin, isTrue);
        expect(BiometricResult.lockedOut.shouldFallbackToPin, isTrue);
        expect(BiometricResult.failed.shouldFallbackToPin, isTrue);
        expect(BiometricResult.success.shouldFallbackToPin, isFalse);
        expect(BiometricResult.cancelled.shouldFallbackToPin, isFalse);
      });

      test('should determine when user can retry', () {
        expect(BiometricResult.failed.canRetry, isTrue);
        expect(BiometricResult.cancelled.canRetry, isTrue);
        expect(BiometricResult.success.canRetry, isFalse);
        expect(BiometricResult.notAvailable.canRetry, isFalse);
        expect(BiometricResult.lockedOut.canRetry, isFalse);
      });
    });

    group('Constants', () {
      test('should have correct max retry attempts', () {
        expect(BiometricPromptHandler.maxRetryAttempts, equals(3));
      });
    });
  });
}
