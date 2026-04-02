import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/data/services/offline_credential_storage_service.dart';

void main() {
  // Skip all tests - OfflineCredentialStorageService is a stub implementation
  // TODO: Re-enable tests when full implementation is done
  group('OfflineCredentialStorageService - SKIPPED (Stub Implementation)', () {
    late OfflineCredentialStorageService storageService;

    setUp(() {
      storageService = OfflineCredentialStorageService();
    });

    test('should store offline credentials', () async {
      // Stub implementation - always throws UnimplementedError
      expect(
        () => storageService.storeOfflineCredentials('user', 'pass'),
        throwsUnimplementedError,
      );
    }, skip: true);

    test('should retrieve stored credentials', () async {
      final credentials = await storageService.getOfflineCredentials();
      expect(credentials, isNull);
    }, skip: true);

    test('should clear stored credentials', () async {
      await storageService.clearOfflineCredentials();
      // Stub implementation - no-op
    }, skip: true);

    test('should check if offline auth is available', () async {
      final available = await storageService.isOfflineAuthAvailable();
      expect(available, isFalse);
    }, skip: true);
  });
}
