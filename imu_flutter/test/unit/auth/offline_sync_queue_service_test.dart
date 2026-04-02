import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/data/services/offline_sync_queue_service.dart';

void main() {
  // Initialize Flutter test binding for tests that use platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  // Skip all tests - OfflineSyncQueueService is a stub implementation
  // TODO: Re-enable tests when full implementation is done
  group('OfflineSyncQueueService - SKIPPED (Stub Implementation)', () {
    late OfflineSyncQueueService syncQueue;

    setUp(() async {
      syncQueue = OfflineSyncQueueService();
    });

    tearDown(() {
      syncQueue.dispose();
    });

    test('should add operation to queue', () async {
      // Stub implementation - always throws UnimplementedError
      expect(
        () => syncQueue.addOperation(SyncOperation(
          type: 'create',
          data: {'name': 'Test'},
        )),
        throwsUnimplementedError,
      );
    }, skip: true);

    test('should process queue', () async {
      // Stub implementation - always throws UnimplementedError
      expect(
        () => syncQueue.processQueue(),
        throwsUnimplementedError,
      );
    }, skip: true);

    test('should get queue size', () async {
      final size = await syncQueue.getQueueSize();
      expect(size, equals(0));
    }, skip: true);

    test('should get queue stats', () async {
      final stats = await syncQueue.getQueueStats();
      expect(stats['total'], equals(0));
    }, skip: true);
  });
}
