import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:imu_flutter/services/api/sync_queue_service.dart';

import '../../mocks/mocks.dart';

void main() {
  late SyncQueueService syncQueueService;
  late MockHiveService mockHiveService;

  setUp(() {
    mockHiveService = MockHiveService();
    when(() => mockHiveService.isInitialized).thenReturn(true);

    syncQueueService = SyncQueueService(hiveService: mockHiveService);
  });

  group('SyncQueueService', () {
    test('PendingOperation.fromJson creates correct operation', () {
      // Arrange
      final operationData = {
        'id': 'op-1',
        'operation': 'create',
        'entityType': 'client',
        'data': {
          'id': 'client-1',
          'first_name': 'Test',
          'last_name': 'Client',
        },
        'createdAt': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };

      // Act
      final operation = PendingOperation.fromJson(operationData);

      // Assert
      expect(operation.id, equals('op-1'));
      expect(operation.operation, equals('create'));
      expect(operation.entityType, equals('client'));
      expect(operation.retryCount, equals(0));
    });

    test('PendingOperation.toJson serializes correctly', () {
      // Arrange
      final operation = PendingOperation(
        id: 'op-1',
        operation: 'create',
        entityType: 'client',
        data: {'first_name': 'Test'},
        createdAt: DateTime(2024, 1, 1),
        retryCount: 0,
      );

      // Act
      final json = operation.toJson();

      // Assert
      expect(json['id'], equals('op-1'));
      expect(json['operation'], equals('create'));
      expect(json['entityType'], equals('client'));
      expect(json['retryCount'], equals(0));
    });

    test('SyncConflict creates correct conflict', () {
      // Arrange & Act
      final conflict = SyncConflict(
        id: 'conflict-1',
        entityType: 'client',
        operation: 'update',
        localData: {'id': '1', 'name': 'Local'},
        serverData: {'id': '1', 'name': 'Server'},
        detectedAt: DateTime.now(),
        conflictType: 'update_conflict',
      );

      // Assert
      expect(conflict.id, equals('conflict-1'));
      expect(conflict.entityType, equals('client'));
      expect(conflict.conflictType, equals('update_conflict'));
      expect(conflict.localData['name'], equals('Local'));
      expect(conflict.serverData['name'], equals('Server'));
    });

    test('ConflictResult creates correct result', () {
      // Arrange & Act
      final result = ConflictResult(
        resolved: true,
        resolution: ConflictResolution.serverWins,
        resolvedData: {'id': '1', 'name': 'Server'},
      );

      // Assert
      expect(result.resolved, isTrue);
      expect(result.resolution, equals(ConflictResolution.serverWins));
      expect(result.resolvedData?['name'], equals('Server'));
    });

    test('ConflictResolution enum has all strategies', () {
      // Assert
      expect(ConflictResolution.values.length, equals(4));
      expect(ConflictResolution.values, contains(ConflictResolution.localWins));
      expect(ConflictResolution.values, contains(ConflictResolution.serverWins));
      expect(ConflictResolution.values, contains(ConflictResolution.merge));
      expect(ConflictResolution.values, contains(ConflictResolution.askUser));
    });
  });
}
