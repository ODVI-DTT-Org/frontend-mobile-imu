import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/data/services/pin_storage_service.dart';
import 'package:imu_flutter/features/auth/domain/services/pin_hash_service.dart';
import 'package:imu_flutter/features/auth/domain/services/pin_validation_service.dart';
import 'package:mocktail/mocktail.dart';

class MockPinStorageService extends Mock implements PinStorageService {}
class MockPinHashService extends Mock implements PinHashService {}

void main() {
  group('PinValidationService', () {
    late PinValidationService pinValidationService;
    late MockPinStorageService mockStorageService;
    late MockPinHashService mockHashService;

    setUp(() {
      mockStorageService = MockPinStorageService();
      mockHashService = MockPinHashService();
      pinValidationService = PinValidationService(
        storageService: mockStorageService,
        hashService: mockHashService,
      );

      // Set up default mock behaviors
      when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => false);
      when(() => mockStorageService.getPinHash()).thenAnswer((_) async => 'stored_hash');
      when(() => mockStorageService.getPinSalt()).thenAnswer((_) async => 'stored_salt');
      when(() => mockHashService.verifyPin(any(), any(), any())).thenReturn(true);
      when(() => mockStorageService.clearFailedAttempts()).thenAnswer((_) async {});
      when(() => mockStorageService.storeFailedAttempts(any())).thenAnswer((_) async {});
      when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 0);
    });

    group('PIN Format Validation', () {
      test('should validate correct 6-digit PIN', () {
        const pin = '123456';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isTrue);
      });

      test('should reject PIN with less than 6 digits', () {
        const pin = '12345';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isFalse);
      });

      test('should reject PIN with more than 6 digits', () {
        const pin = '1234567';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isFalse);
      });

      test('should reject PIN with non-digit characters', () {
        const pin = '12345a';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isFalse);
      });

      test('should reject empty PIN', () {
        const pin = '';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isFalse);
      });

      test('should reject PIN with special characters', () {
        const pin = '12!45@';

        final isValid = pinValidationService.isValidPinFormat(pin);

        expect(isValid, isFalse);
      });
    });

    group('PIN Verification', () {
      test('should return success for correct PIN', () async {
        const pin = '123456';
        when(() => mockHashService.verifyPin(pin, any(), any())).thenReturn(true);

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.success));
        verify(() => mockStorageService.clearFailedAttempts()).called(1);
      });

      test('should return incorrect for wrong PIN', () async {
        const pin = '654321';
        when(() => mockHashService.verifyPin(pin, any(), any())).thenReturn(false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 0);
        when(() => mockStorageService.storeFailedAttempts(1)).thenAnswer((_) async {});

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.incorrect));
        verify(() => mockStorageService.storeFailedAttempts(1)).called(1);
      });

      test('should return lockedOut when max attempts reached', () async {
        const pin = '654321';
        when(() => mockHashService.verifyPin(any(), any(), any())).thenReturn(false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 5);
        when(() => mockStorageService.storeFailedAttempts(6)).thenAnswer((_) async {});
        when(() => mockStorageService.storeLockoutUntil(any())).thenAnswer((_) async {});

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.incorrect));
        verify(() => mockStorageService.storeLockoutUntil(any())).called(1);
      });

      test('should return lockoutNotExpired when currently locked out', () async {
        const pin = '123456';
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => true);

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.lockoutNotExpired));
        verifyNever(() => mockHashService.verifyPin(any(), any(), any()));
      });

      test('should return incorrect when no PIN hash stored', () async {
        const pin = '123456';
        when(() => mockStorageService.getPinHash()).thenAnswer((_) async => null);

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.incorrect));
      });

      test('should return incorrect when no salt stored', () async {
        const pin = '123456';
        when(() => mockStorageService.getPinSalt()).thenAnswer((_) async => null);

        final result = await pinValidationService.validatePin(pin);

        expect(result, equals(PinValidationResult.incorrect));
      });
    });

    group('Failed Attempts Tracking', () {
      test('should increment failed attempts on wrong PIN', () async {
        const pin = '654321';
        when(() => mockHashService.verifyPin(pin, any(), any())).thenReturn(false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 2);
        when(() => mockStorageService.storeFailedAttempts(3)).thenAnswer((_) async {});

        await pinValidationService.validatePin(pin);

        verify(() => mockStorageService.storeFailedAttempts(3)).called(1);
      });

      test('should reset failed attempts on correct PIN', () async {
        const pin = '123456';
        when(() => mockHashService.verifyPin(pin, any(), any())).thenReturn(true);

        await pinValidationService.validatePin(pin);

        verify(() => mockStorageService.clearFailedAttempts()).called(1);
      });

      test('should lock after 5 failed attempts', () async {
        const pin = '654321';
        when(() => mockHashService.verifyPin(pin, any(), any())).thenReturn(false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 5);
        when(() => mockStorageService.storeFailedAttempts(6)).thenAnswer((_) async {});
        when(() => mockStorageService.storeLockoutUntil(any())).thenAnswer((_) async {});

        await pinValidationService.validatePin(pin);

        verify(() => mockStorageService.storeFailedAttempts(6)).called(1);
        verify(() => mockStorageService.storeLockoutUntil(any())).called(1);
      });
    });

    group('Remaining Attempts', () {
      test('should return 5 when no failed attempts', () async {
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 0);

        final remaining = await pinValidationService.getRemainingAttempts();

        expect(remaining, equals(5));
      });

      test('should return 3 when 2 failed attempts', () async {
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 2);

        final remaining = await pinValidationService.getRemainingAttempts();

        expect(remaining, equals(3));
      });

      test('should return 1 when 4 failed attempts', () async {
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 4);

        final remaining = await pinValidationService.getRemainingAttempts();

        expect(remaining, equals(1));
      });

      test('should return 0 when locked out', () async {
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => true);

        final remaining = await pinValidationService.getRemainingAttempts();

        expect(remaining, equals(0));
      });

      test('should return 0 when 5 failed attempts', () async {
        when(() => mockStorageService.isLockedOut()).thenAnswer((_) async => false);
        when(() => mockStorageService.getFailedAttempts()).thenAnswer((_) async => 5);

        final remaining = await pinValidationService.getRemainingAttempts();

        expect(remaining, equals(0));
      });
    });

    group('Lockout Management', () {
      test('should get lockout expiration time', () async {
        final lockoutTime = DateTime.now().add(const Duration(minutes: 30));
        when(() => mockStorageService.getLockoutUntil()).thenAnswer((_) async => lockoutTime);

        final retrievedTime = await pinValidationService.getLockoutExpiration();

        expect(retrievedTime, equals(lockoutTime));
      });

      test('should return null when no lockout', () async {
        when(() => mockStorageService.getLockoutUntil()).thenAnswer((_) async => null);

        final retrievedTime = await pinValidationService.getLockoutExpiration();

        expect(retrievedTime, isNull);
      });

      test('should reset lockout', () async {
        when(() => mockStorageService.clearFailedAttempts()).thenAnswer((_) async {});
        when(() => mockStorageService.clearLockout()).thenAnswer((_) async {});

        await pinValidationService.resetLockout();

        verify(() => mockStorageService.clearFailedAttempts()).called(1);
        verify(() => mockStorageService.clearLockout()).called(1);
      });
    });

    group('Constants', () {
      test('should have max failed attempts of 5', () {
        expect(PinValidationService.maxFailedAttempts, equals(5));
      });

      test('should have lockout duration of 30 minutes', () {
        expect(
          PinValidationService.lockoutDuration,
          equals(const Duration(minutes: 30)),
        );
      });

      test('should have required PIN length of 6', () {
        expect(PinValidationService.requiredPinLength, equals(6));
      });
    });
  });
}
