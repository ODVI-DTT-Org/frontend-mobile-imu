import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/features/auth/domain/services/token_manager.dart';
import 'package:imu_flutter/features/auth/domain/services/token_refresh_service.dart';

// Mocks
class MockTokenManager extends Mock implements TokenManager {}

void main() {
  // Register fallback values for mocktail
  setUpAll(() {
    registerFallbackValue(TokenData(
      accessToken: 'test_token',
      refreshToken: 'test_refresh',
      expiresIn: const Duration(hours: 1),
    ));
  });

  group('TokenRefreshService', () {
    late MockTokenManager mockTokenManager;

    setUp(() {
      mockTokenManager = MockTokenManager();
    });

    tearDown(() {
      // Reset mock state between tests
      reset(mockTokenManager);
    });

    group('Initialization', () {
      test('should not be refreshing initially', () {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );
        expect(service.isRefreshing, isFalse);
        service.dispose();
      });

      test('should have zero retry attempts initially', () {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );
        expect(service.retryAttempt, equals(0));
        service.dispose();
      });
    });

    group('Token Refresh Success', () {
      test('should refresh token successfully', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new_access_token',
            refreshToken: 'new_refresh_token',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');
        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));
        when(() => mockTokenManager.storeTokens(any()))
            .thenAnswer((_) async {});

        final result = await service.refreshNow();

        expect(result.success, isTrue);
        expect(result.accessToken, equals('new_access_token'));
        expect(result.refreshToken, equals('new_refresh_token'));
        service.dispose();
      });

      test('should store new tokens on successful refresh', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');
        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));
        when(() => mockTokenManager.storeTokens(any()))
            .thenAnswer((_) async {});

        await service.refreshNow();

        verify(() => mockTokenManager.storeTokens(any())).called(1);
        service.dispose();
      });

      test('should reset retry counter on successful refresh', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');
        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));
        when(() => mockTokenManager.storeTokens(any()))
            .thenAnswer((_) async {});

        await service.refreshNow();

        expect(service.retryAttempt, equals(0));
        service.dispose();
      });

      test('should not be refreshing after successful refresh', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');
        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));
        when(() => mockTokenManager.storeTokens(any()))
            .thenAnswer((_) async {});

        await service.refreshNow();

        expect(service.isRefreshing, isFalse);
        service.dispose();
      });
    });

    group('Token Refresh Failure', () {
      test('should return failure result when refresh fails', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.failure(
            error: 'Invalid token',
            attempt: 0,
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        final result = await service.refreshNow();

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error, contains('Max retry attempts reached'));
        service.dispose();
      });

      test('should increment retry attempt on failure', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.failure(
            error: 'Invalid token',
            attempt: 0,
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        await service.refreshNow();

        expect(service.retryAttempt, equals(TokenRefreshService.maxRetryAttempts));
        service.dispose();
      });

      test('should stop retrying after max attempts', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.failure(
            error: 'Invalid token',
            attempt: 0,
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        final result = await service.refreshNow();

        expect(service.retryAttempt, equals(TokenRefreshService.maxRetryAttempts));
        expect(result.error, contains('Max retry attempts reached'));
        service.dispose();
      });

      test('should return in-progress when already refreshing', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        // Start first refresh (don't await)
        final future1 = service.refreshNow();

        // Try second refresh immediately
        final result2 = await service.refreshNow();

        expect(result2.success, isFalse);
        expect(result2.error, contains('already in progress'));

        // Wait for first refresh to complete
        await future1;
        service.dispose();
      });
    });

    group('Automatic Monitoring', () {
      test('should not start monitoring when no token exists', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.timeUntilExpiry).thenReturn(null);

        await service.startMonitoring();

        expect(service.isRefreshing, isFalse);
        service.dispose();
      });

      test('should schedule refresh for buffer time before expiry', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(minutes: 10));

        await service.startMonitoring();

        expect(service.isRefreshing, isFalse);
        service.dispose();
      });

      test('should refresh immediately when token expires soon', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(minutes: 4));
        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        await service.startMonitoring();

        // Give time for immediate refresh to trigger
        await Future.delayed(const Duration(milliseconds: 100));

        verify(() => mockTokenManager.getRefreshToken()).called(1);
        service.dispose();
      });
    });

    group('Stop Monitoring', () {
      test('should stop monitoring when requested', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));

        await service.startMonitoring();
        await service.stopMonitoring();

        expect(service.isRefreshing, isFalse);
        expect(service.retryAttempt, equals(0));
        service.dispose();
      });
    });

    group('Reset', () {
      test('should reset retry state', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.failure(
            error: 'Invalid token',
            attempt: 0,
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => 'any_token');

        await service.refreshNow();
        await service.reset();

        expect(service.retryAttempt, equals(0));
        expect(service.isRefreshing, isFalse);
        service.dispose();
      });

      test('should stop monitoring when reset', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.timeUntilExpiry)
            .thenReturn(const Duration(hours: 1));

        await service.startMonitoring();
        await service.reset();

        expect(service.isRefreshing, isFalse);
        service.dispose();
      });
    });

    group('Constants', () {
      test('should have 5-minute refresh buffer', () {
        expect(TokenRefreshService.refreshBuffer, equals(const Duration(minutes: 5)));
      });

      test('should have max 3 retry attempts', () {
        expect(TokenRefreshService.maxRetryAttempts, equals(3));
      });

      test('should have 1-second initial retry delay', () {
        expect(TokenRefreshService.initialRetryDelay, equals(const Duration(seconds: 1)));
      });

      test('should have 30-second max retry delay', () {
        expect(TokenRefreshService.maxRetryDelay, equals(const Duration(seconds: 30)));
      });

      test('should have 2.0 backoff multiplier', () {
        expect(TokenRefreshService.backoffMultiplier, equals(2.0));
      });
    });

    group('TokenRefreshResult', () {
      test('should create success result', () {
        final result = TokenRefreshResult.success(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresIn: const Duration(hours: 1),
          attempt: 1,
        );

        expect(result.success, isTrue);
        expect(result.accessToken, equals('token'));
        expect(result.refreshToken, equals('refresh'));
        expect(result.expiresIn, equals(const Duration(hours: 1)));
        expect(result.attempt, equals(1));
      });

      test('should create failure result', () {
        final result = TokenRefreshResult.failure(
          error: 'Network error',
          attempt: 2,
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Network error'));
        expect(result.attempt, equals(2));
      });

      test('should provide readable toString', () {
        final success = TokenRefreshResult.success(
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresIn: const Duration(hours: 1),
        );
        final failure = TokenRefreshResult.failure(error: 'Error');

        expect(success.toString(), contains('success'));
        expect(failure.toString(), contains('failure'));
        expect(failure.toString(), contains('Error'));
      });
    });

    group('Edge Cases', () {
      test('should handle no refresh token available', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => null);

        final result = await service.refreshNow();

        expect(result.success, isFalse);
        expect(result.error, contains('No refresh token available'));
        service.dispose();
      });

      test('should handle empty refresh token', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.success(
            accessToken: 'new',
            refreshToken: 'new',
            expiresIn: const Duration(hours: 1),
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenAnswer((_) async => '');

        final result = await service.refreshNow();

        expect(result.success, isFalse);
        expect(result.error, contains('No refresh token available'));
        service.dispose();
      });

      test('should handle exception during refresh', () async {
        final service = TokenRefreshService(
          tokenManager: mockTokenManager,
          refreshCallback: (token) async => TokenRefreshResult.failure(
            error: 'Invalid token',
            attempt: 0,
          ),
        );

        when(() => mockTokenManager.getRefreshToken())
            .thenThrow(Exception('Storage error'));

        final result = await service.refreshNow();

        expect(result.success, isFalse);
        // Exception during getRefreshToken causes a failure
        expect(result.error, isNotNull);
        service.dispose();
      });
    });
  });
}
