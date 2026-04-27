import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/sync/pending_upload_guard.dart';

void main() {
  group('PendingUploadGuard', () {
    test('returns clean when no pending uploads', () async {
      final result = await PendingUploadGuard.check(
        pendingCountProvider: () async => 0,
        isOnlineProvider: () => true,
      );
      expect(result, equals(PendingUploadStatus.clean));
    });

    test('returns mustWait when pending uploads but offline', () async {
      final result = await PendingUploadGuard.check(
        pendingCountProvider: () async => 3,
        isOnlineProvider: () => false,
      );
      expect(result, equals(PendingUploadStatus.mustWait));
    });

    test('returns flushing when pending uploads and online', () async {
      final result = await PendingUploadGuard.check(
        pendingCountProvider: () async => 3,
        isOnlineProvider: () => true,
      );
      expect(result, equals(PendingUploadStatus.flushing));
    });

    test('returns clean when pending count is exactly zero', () async {
      final result = await PendingUploadGuard.check(
        pendingCountProvider: () async => 0,
        isOnlineProvider: () => false,
      );
      expect(result, equals(PendingUploadStatus.clean));
    });
  });
}
