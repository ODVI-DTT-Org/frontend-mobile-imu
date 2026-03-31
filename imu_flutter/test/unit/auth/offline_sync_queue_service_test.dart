import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/data/services/offline_sync_queue_service.dart';

void main() {
  // Initialize Flutter test binding for tests that use platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineSyncQueueService', () {
    late OfflineSyncQueueService syncQueue;

    setUp(() async {
      syncQueue = OfflineSyncQueueService();
      // Skip initialize() to avoid platform channel calls in tests
      // await syncQueue.initialize();
    });

    tearDown(() {
      syncQueue.dispose();
    });

    group('Queue Operations', () {
      test('should add operation to queue', () async {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John Doe'},
          queuedAt: DateTime.now(),
        );

        final added = await syncQueue.addOperation(operation);

        expect(added, isTrue);
        expect(syncQueue.pendingOperationCount, equals(1));
      });

      test('should not add operation when queue is full', () async {
        // Fill queue to max capacity
        for (int i = 0; i < OfflineSyncQueueService.maxQueueSize; i++) {
          final operation = SyncOperation(
            id: 'op-$i',
            type: SyncOperationType.create,
            resourceType: 'client',
            data: {'index': i},
            queuedAt: DateTime.now(),
          );
          await syncQueue.addOperation(operation);
        }

        // Try to add one more
        final overflowOperation = SyncOperation(
          id: 'op-overflow',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'overflow': true},
          queuedAt: DateTime.now(),
        );

        final added = await syncQueue.addOperation(overflowOperation);

        expect(added, isFalse);
      });

      test('should get pending operations', () async {
        final op1 = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        final op2 = SyncOperation(
          id: 'op-2',
          type: SyncOperationType.update,
          resourceType: 'client',
          resourceId: 'client-123',
          data: {'name': 'Jane'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(op1);
        await syncQueue.addOperation(op2);

        final pending = syncQueue.getPendingOperations();

        expect(pending.length, equals(2));
        expect(pending[0].type, equals(SyncOperationType.create));
        expect(pending[1].type, equals(SyncOperationType.update));
      });

      test('should return empty list when queue is empty', () {
        final pending = syncQueue.getPendingOperations();

        expect(pending, isEmpty);
      });

      test('should check if queue is empty', () {
        expect(syncQueue.isEmpty, isTrue);

        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        syncQueue.addOperation(operation);
        expect(syncQueue.isEmpty, isFalse);
      });

      test('should return correct pending operation count', () async {
        expect(syncQueue.pendingOperationCount, equals(0));

        await syncQueue.addOperation(SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        ));

        expect(syncQueue.pendingOperationCount, equals(1));
      });
    });

    group('Queue Processing', () {
      test('should process pending operations', () async {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(operation);

        final results = await syncQueue.processQueue((op) async {
          return SyncResult.success(operation: op);
        });

        expect(results.length, equals(1));
        expect(results[0].success, isTrue);
        expect(syncQueue.pendingOperationCount, equals(0));
      });

      test('should stop processing on failure', () async {
        final op1 = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        final op2 = SyncOperation(
          id: 'op-2',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'Jane'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(op1);
        await syncQueue.addOperation(op2);

        final results = await syncQueue.processQueue((op) async {
          if (op.id == 'op-1') {
            return SyncResult.failure('Network error', operation: op);
          }
          return SyncResult.success(operation: op);
        });

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
        expect(syncQueue.pendingOperationCount, equals(2)); // Both still pending
      });

      test('should increment retry count on failure', () async {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(operation);

        await syncQueue.processQueue((op) async {
          return SyncResult.failure('Network error', operation: op);
        });

        final pending = syncQueue.getPendingOperations();
        expect(pending[0].retryCount, equals(1));
      });

      test('should skip operations exceeding max retries', () async {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
          retryCount: OfflineSyncQueueService.maxRetryAttempts,
        );

        await syncQueue.addOperation(operation);

        final results = await syncQueue.processQueue((op) async {
          return SyncResult.success(operation: op);
        });

        // Should be skipped due to max retries
        expect(results[0].success, isFalse);
        expect(results[0].error, contains('Max retry attempts exceeded'));
      });
    });

    group('Queue Management', () {
      test('should clear all operations', () async {
        await syncQueue.addOperation(SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        ));

        await syncQueue.clearQueue();

        expect(syncQueue.pendingOperationCount, equals(0));
      });

      test('should remove specific operation', () async {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(operation);

        await syncQueue.removeOperation('op-1');

        expect(syncQueue.pendingOperationCount, equals(0));
      });

      test('should get queue statistics', () async {
        final op1 = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        await syncQueue.addOperation(op1);

        final stats = syncQueue.getQueueStats();

        expect(stats['totalOperations'], equals(1));
        expect(stats['pendingOperations'], equals(1));
        expect(stats['syncedOperations'], equals(0));
        expect(stats['isProcessing'], isFalse);
      });
    });

    group('SyncOperation', () {
      test('should create from JSON', () {
        final json = {
          'id': 'op-1',
          'type': 'create',
          'resourceType': 'client',
          'resourceId': 'client-123',
          'data': {'name': 'John'},
          'queuedAt': '2024-01-01T00:00:00.000Z',
          'retryCount': 1,
          'isSynced': false,
        };

        final operation = SyncOperation.fromJson(json);

        expect(operation.id, equals('op-1'));
        expect(operation.type, equals(SyncOperationType.create));
        expect(operation.resourceType, equals('client'));
        expect(operation.resourceId, equals('client-123'));
        expect(operation.data, equals({'name': 'John'}));
        expect(operation.retryCount, equals(1));
        expect(operation.isSynced, isFalse);
      });

      test('should convert to JSON', () {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          resourceId: 'client-123',
          data: {'name': 'John'},
          queuedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
          retryCount: 1,
        );

        final json = operation.toJson();

        expect(json['id'], equals('op-1'));
        expect(json['type'], equals('create'));
        expect(json['resourceType'], equals('client'));
        expect(json['resourceId'], equals('client-123'));
        expect(json['retryCount'], equals(1));
      });

      test('should create copy with modified properties', () {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        final copy = operation.copyWith(
          retryCount: 5,
          isSynced: true,
        );

        expect(copy.id, equals(operation.id));
        expect(copy.retryCount, equals(5));
        expect(copy.isSynced, isTrue);
        expect(operation.retryCount, equals(0)); // Original unchanged
      });
    });

    group('SyncResult', () {
      test('should create success result', () {
        final operation = SyncOperation(
          id: 'op-1',
          type: SyncOperationType.create,
          resourceType: 'client',
          data: {'name': 'John'},
          queuedAt: DateTime.now(),
        );

        final result = SyncResult.success(operation: operation);

        expect(result.success, isTrue);
        expect(result.operation, equals(operation));
      });

      test('should create failure result', () {
        final result = SyncResult.failure('Network error');

        expect(result.success, isFalse);
        expect(result.error, equals('Network error'));
      });
    });

    group('Constants', () {
      test('should have max queue size of 100', () {
        expect(OfflineSyncQueueService.maxQueueSize, equals(100));
      });

      test('should have max retry attempts of 3', () {
        expect(OfflineSyncQueueService.maxRetryAttempts, equals(3));
      });
    });
  });
}
