import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imu_flutter/features/auth/data/services/pin_storage_service.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('PinStorageService', () {
    late PinStorageService pinStorageService;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      pinStorageService = PinStorageService(secureStorage: mockStorage);

      // Set up default mock behaviors
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
    });

    group('PIN Storage', () {
      test('should store PIN hash and salt', () async {
        const pinHash = 'abc123';
        const salt = 'def456';

        await pinStorageService.storePin(pinHash, salt);

        verify(() => mockStorage.write(key: 'pin_hash', value: pinHash)).called(1);
        verify(() => mockStorage.write(key: 'pin_salt', value: salt)).called(1);
      });

      test('should retrieve stored PIN hash', () async {
        const storedHash = 'abc123';
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => storedHash);

        final retrievedHash = await pinStorageService.getPinHash();

        expect(retrievedHash, equals(storedHash));
        verify(() => mockStorage.read(key: 'pin_hash')).called(1);
      });

      test('should retrieve stored salt', () async {
        const storedSalt = 'def456';
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => storedSalt);

        final retrievedSalt = await pinStorageService.getPinSalt();

        expect(retrievedSalt, equals(storedSalt));
        verify(() => mockStorage.read(key: 'pin_salt')).called(1);
      });

      test('should return null when no PIN hash stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final retrievedHash = await pinStorageService.getPinHash();

        expect(retrievedHash, isNull);
      });

      test('should return null when no salt stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final retrievedSalt = await pinStorageService.getPinSalt();

        expect(retrievedSalt, isNull);
      });
    });

    group('PIN Setup Status', () {
      test('should return true when PIN is set up', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'stored_hash');

        final isSetup = await pinStorageService.isPinSetup();

        expect(isSetup, isTrue);
      });

      test('should return false when PIN is not set up', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final isSetup = await pinStorageService.isPinSetup();

        expect(isSetup, isFalse);
      });

      test('should return false when PIN hash is empty', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => '');

        final isSetup = await pinStorageService.isPinSetup();

        expect(isSetup, isFalse);
      });
    });

    group('PIN Clearing', () {
      test('should clear all PIN data', () async {
        await pinStorageService.clearPin();

        verify(() => mockStorage.delete(key: 'pin_hash')).called(1);
        verify(() => mockStorage.delete(key: 'pin_salt')).called(1);
        verify(() => mockStorage.delete(key: 'pin_failed_attempts')).called(1);
        verify(() => mockStorage.delete(key: 'pin_lockout_until')).called(1);
      });
    });

    group('Failed Attempts', () {
      test('should store failed attempts count', () async {
        const attempts = 3;

        await pinStorageService.storeFailedAttempts(attempts);

        verify(() => mockStorage.write(
          key: 'pin_failed_attempts',
          value: attempts.toString(),
        )).called(1);
      });

      test('should retrieve failed attempts count', () async {
        const storedAttempts = 3;
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => storedAttempts.toString());

        final retrievedAttempts = await pinStorageService.getFailedAttempts();

        expect(retrievedAttempts, equals(storedAttempts));
      });

      test('should return 0 when no failed attempts stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final retrievedAttempts = await pinStorageService.getFailedAttempts();

        expect(retrievedAttempts, equals(0));
      });

      test('should return 0 when stored value is invalid', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'invalid');

        final retrievedAttempts = await pinStorageService.getFailedAttempts();

        expect(retrievedAttempts, equals(0));
      });

      test('should clear failed attempts', () async {
        await pinStorageService.clearFailedAttempts();

        verify(() => mockStorage.delete(key: 'pin_failed_attempts')).called(1);
      });
    });

    group('Lockout Management', () {
      test('should store lockout expiration time', () async {
        final lockoutUntil = DateTime(2024, 1, 1, 12, 0);

        await pinStorageService.storeLockoutUntil(lockoutUntil);

        verify(() => mockStorage.write(
          key: 'pin_lockout_until',
          value: lockoutUntil.toIso8601String(),
        )).called(1);
      });

      test('should retrieve lockout expiration time', () async {
        final storedTime = DateTime(2024, 1, 1, 12, 0);
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => storedTime.toIso8601String());

        final retrievedTime = await pinStorageService.getLockoutUntil();

        expect(retrievedTime, equals(storedTime));
      });

      test('should return null when no lockout stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final retrievedTime = await pinStorageService.getLockoutUntil();

        expect(retrievedTime, isNull);
      });

      test('should clear lockout', () async {
        await pinStorageService.clearLockout();

        verify(() => mockStorage.delete(key: 'pin_lockout_until')).called(1);
      });

      test('should return true when currently locked out', () async {
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => futureTime.toIso8601String());

        final isLocked = await pinStorageService.isLockedOut();

        expect(isLocked, isTrue);
      });

      test('should return false when lockout has expired', () async {
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => pastTime.toIso8601String());

        final isLocked = await pinStorageService.isLockedOut();

        expect(isLocked, isFalse);
      });

      test('should return false when no lockout stored', () async {
        when(() => mockStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => null);

        final isLocked = await pinStorageService.isLockedOut();

        expect(isLocked, isFalse);
      });
    });
  });
}
