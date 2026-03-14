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

    syncQueueService = SyncQueueService();
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
  });
}
