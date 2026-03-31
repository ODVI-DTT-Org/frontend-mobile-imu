import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imu_flutter/features/auth/data/services/offline_credential_storage_service.dart';

// Mock for FlutterSecureStorage
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('OfflineCredentialStorageService', () {
    late OfflineCredentialStorageService storageService;
    late MockSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockSecureStorage();
      storageService = OfflineCredentialStorageService(secureStorage: mockStorage);
    });

    tearDown(() {
      storageService.dispose();
    });

    group('Credential Storage', () {
      test('should store offline credentials', () async {
        when(() => mockStorage.write(
          key: any(),
          value: any(),
        )).thenAnswer((_) async {});

        await storageService.storeOfflineCredentials(
          accessToken: 'test_access_token',
          refreshToken: 'test_refresh_token',
          userId: 'user-123',
        );

        verify(() => mockStorage.write(
          key: 'offline_last_valid_token',
          value: 'test_access_token',
        )).called(1);
      });

      test('should store grace period expiry', () async {
        when(() => mockStorage.write(
          key: any(),
          value: any(),
        )).thenAnswer((_) async {});

        final gracePeriod = const Duration(hours: 24);
        await storageService.storeOfflineCredentials(
          accessToken: 'token',
          refreshToken: 'refresh',
          userId: 'user-123',
          gracePeriod: gracePeriod,
        );

        verify(() => mockStorage.write(
          key: 'grace_period_expiry',
          value: any(that: isA<String>()),
        )).called(1);
      });

      test('should store credentials hash for integrity', () async {
        when(() => mockStorage.write(
          key: any(),
          value: any(),
        )).thenAnswer((_) async {});

        await storageService.storeOfflineCredentials(
          accessToken: 'token',
          refreshToken: 'refresh',
          userId: 'user-123',
        );

        verify(() => mockStorage.write(
          key: 'credentials_hash',
          value: any(that: isA<String>()),
        )).called(1);
      });
    });

    group('Credential Retrieval', () {
      test('should return null when no credentials stored', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async => null);

        final credentials = await storageService.getOfflineCredentials();

        expect(credentials, isNull);
      });

      test('should return null when grace period expired', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async {
          // Return expired timestamp
          return DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
        });

        when(() => mockStorage.delete(key: any()))
            .thenAnswer((_) async {});

        final credentials = await storageService.getOfflineCredentials();

        expect(credentials, isNull);
      });

      test('should return null when hash validation fails', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async {
          // Return future timestamp for grace period
          return DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        });

        // Override the credentials hash read to return invalid hash
        when(() => mockStorage.read(key: 'credentials_hash'))
            .thenAnswer((_) async => 'invalid_hash');

        when(() => mockStorage.delete(key: any()))
            .thenAnswer((_) async {});

        final credentials = await storageService.getOfflineCredentials();

        expect(credentials, isNull);
      });
    });

    group('Offline Auth Availability', () {
      test('should return true when offline auth available', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async {
          // Return future timestamp for grace period
          return DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        });

        when(() => mockStorage.read(key: 'credentials_hash'))
            .thenAnswer((_) async {
          // Return a valid hash
          return '12345';
        });

        final isAvailable = await storageService.isOfflineAuthAvailable();

        expect(isAvailable, isTrue);
      });

      test('should return false when offline auth unavailable', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async => null);

        final isAvailable = await storageService.isOfflineAuthAvailable();

        expect(isAvailable, isFalse);
      });
    });

    group('Grace Period', () {
      test('should return remaining grace period', () async {
        final expectedRemaining = const Duration(hours: 12);

        when(() => mockStorage.read(key: 'grace_period_expiry'))
            .thenAnswer((_) async {
          final expiry = DateTime.now().add(expectedRemaining);
          return expiry.toIso8601String();
        });

        final remaining = await storageService.getRemainingGracePeriod();

        expect(remaining, isNotNull);
        expect(remaining!.inHours, greaterThanOrEqualTo(11));
      });

      test('should return null when no grace period set', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async => null);

        final remaining = await storageService.getRemainingGracePeriod();

        expect(remaining, isNull);
      });
    });

    group('Credential Cleanup', () {
      test('should clear all offline credentials', () async {
        when(() => mockStorage.delete(key: any()))
            .thenAnswer((_) async {});

        await storageService.clearOfflineCredentials();

        verify(() => mockStorage.delete(key: 'offline_last_valid_token')).called(1);
        verify(() => mockStorage.delete(key: 'offline_last_valid_refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'offline_last_valid_user_id')).called(1);
      });
    });

    group('Integrity Validation', () {
      test('should validate credential integrity', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async {
          return DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        });

        when(() => mockStorage.read(key: 'credentials_hash'))
            .thenAnswer((_) async => '12345');

        final isValid = await storageService.validateCredentialsIntegrity();

        expect(isValid, isTrue);
      });

      test('should fail integrity validation with bad hash', () async {
        when(() => mockStorage.read(key: any()))
            .thenAnswer((_) async {
          return DateTime.now().add(const Duration(hours: 1)).toIso8601String();
        });

        when(() => mockStorage.read(key: 'credentials_hash'))
            .thenAnswer((_) async => 'bad_hash');

        when(() => mockStorage.delete(key: any()))
            .thenAnswer((_) async {});

        final isValid = await storageService.validateCredentialsIntegrity();

        expect(isValid, isFalse);
      });
    });

    group('Constants', () {
      test('should have 24-hour default grace period', () {
        expect(
          OfflineCredentialStorageService.defaultGracePeriod,
          equals(const Duration(hours: 24)),
        );
      });
    });
  });
}
