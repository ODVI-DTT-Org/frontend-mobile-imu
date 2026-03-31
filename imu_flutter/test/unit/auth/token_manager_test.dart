import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:imu_flutter/features/auth/domain/services/token_manager.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('TokenManager', () {
    late TokenManager tokenManager;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      tokenManager = TokenManager(secureStorage: mockStorage);
      
      // Set up default mock behaviors
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
    });

    group('Token Storage', () {
      test('should store access token in memory', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(hours: 1),
          userId: 'user-123',
        );

        await tokenManager.storeTokens(tokenData);

        final accessToken = await tokenManager.getAccessToken();
        expect(accessToken, 'access123');
      });

      test('should store refresh token in secure storage', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(hours: 1),
        );

        await tokenManager.storeTokens(tokenData);

        verify(() => mockStorage.write(key: 'refresh_token', value: 'refresh123')).called(1);
      });

      test('should retrieve refresh token from storage', () async {
        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'refresh123');

        final refreshToken = await tokenManager.getRefreshToken();

        expect(refreshToken, 'refresh123');
      });

      test('should retrieve user ID from storage', () async {
        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'user-123');

        final userId = await tokenManager.getUserId();

        expect(userId, 'user-123');
      });
    });

    group('Token Expiry', () {
      test('should know when token is expired', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(seconds: -1),
        );

        await tokenManager.storeTokens(tokenData);

        expect(tokenManager.isTokenExpired(), isTrue);
      });

      test('should know when token will expire soon', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(minutes: 4),
        );

        await tokenManager.storeTokens(tokenData);

        expect(tokenManager.willExpireSoon(), isTrue);
      });

      test('should calculate time until expiry', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(minutes: 10),
        );

        await tokenManager.storeTokens(tokenData);

        final remaining = tokenManager.timeUntilExpiry;
        expect(remaining, isNotNull);
        expect(remaining!.inMinutes, greaterThanOrEqualTo(9));
      });

      test('should return null when getting expired access token', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(seconds: -1),
        );

        await tokenManager.storeTokens(tokenData);

        final accessToken = await tokenManager.getAccessToken();
        expect(accessToken, isNull);
      });
    });

    group('Token Clearing', () {
      test('should clear all tokens', () async {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(hours: 1),
          userId: 'user-123',
        );

        await tokenManager.storeTokens(tokenData);
        await tokenManager.clearTokens();

        final accessToken = await tokenManager.getAccessToken();
        expect(accessToken, isNull);

        verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
        verify(() => mockStorage.delete(key: 'user_id')).called(1);
      });
    });

    group('Refresh Token Availability', () {
      test('should return true when refresh token exists', () async {
        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'refresh123');

        final hasToken = await tokenManager.hasRefreshToken();

        expect(hasToken, isTrue);
      });

      test('should return false when no refresh token', () async {
        when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

        final hasToken = await tokenManager.hasRefreshToken();

        expect(hasToken, isFalse);
      });
    });

    group('TokenData', () {
      test('should create from JSON', () {
        final json = {
          'access_token': 'access123',
          'refresh_token': 'refresh123',
          'expires_in': 3600,
          'user_id': 'user-123',
        };

        final tokenData = TokenData.fromJson(json);

        expect(tokenData.accessToken, 'access123');
        expect(tokenData.refreshToken, 'refresh123');
        expect(tokenData.expiresIn.inSeconds, 3600);
        expect(tokenData.userId, 'user-123');
      });

      test('should convert to JSON', () {
        final tokenData = TokenData(
          accessToken: 'access123',
          refreshToken: 'refresh123',
          expiresIn: const Duration(seconds: 3600),
          userId: 'user-123',
        );

        final json = tokenData.toJson();

        expect(json['access_token'], 'access123');
        expect(json['refresh_token'], 'refresh123');
        expect(json['expires_in'], 3600);
        expect(json['user_id'], 'user-123');
      });

      test('should handle missing user_id in JSON', () {
        final json = {
          'access_token': 'access123',
          'refresh_token': 'refresh123',
          'expires_in': 3600,
        };

        final tokenData = TokenData.fromJson(json);

        expect(tokenData.userId, isNull);
      });

      test('should default expires_in to 3600 seconds', () {
        final json = {
          'access_token': 'access123',
          'refresh_token': 'refresh123',
        };

        final tokenData = TokenData.fromJson(json);

        expect(tokenData.expiresIn.inSeconds, 3600);
      });
    });
  });
}
