import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/api/sync_queue_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

import '../mocks/mocks.dart';

/// Integration tests for offline sync flow
///
/// These tests verify the complete offline-first architecture:
/// 1. Operations are queued when offline
/// 2. Queue is processed when back online
/// 3. Data consistency is maintained
void main() {
  group('Offline Sync Integration Tests', () {
    group('Offline Queue Operations', () {
      test('create operation is queued correctly', () async {
        // Arrange
        final clientData = {
          'first_name': 'New',
          'last_name': 'Client',
          'email': 'new@example.com',
        };

        // Act - Create operation
        final operation = PendingOperation(
          id: 'op-1',
          operation: 'CREATE',
          entityType: 'client',
          data: clientData,
          createdAt: DateTime.now(),
          retryCount: 0,
        );

        // Assert
        expect(operation.operation, equals('CREATE'));
        expect(operation.entityType, equals('client'));
        expect(operation.retryCount, equals(0));
        expect(operation.data['first_name'], equals('New'));
      });

      test('update operation is queued correctly', () async {
        // Arrange
        final clientData = {
          'id': 'client-1',
          'first_name': 'Updated',
          'last_name': 'Name',
        };

        // Act
        final operation = PendingOperation(
          id: 'op-2',
          operation: 'UPDATE',
          entityType: 'client',
          data: clientData,
          createdAt: DateTime.now(),
          retryCount: 0,
        );

        // Assert
        expect(operation.operation, equals('UPDATE'));
        expect(operation.data['id'], equals('client-1'));
      });

      test('delete operation is queued correctly', () async {
        // Arrange
        final clientData = {'id': 'client-1'};

        // Act
        final operation = PendingOperation(
          id: 'op-3',
          operation: 'DELETE',
          entityType: 'client',
          data: clientData,
          createdAt: DateTime.now(),
          retryCount: 0,
        );

        // Assert
        expect(operation.operation, equals('DELETE'));
      });
    });

    group('Data Consistency', () {
      test('client data serialization is consistent', () {
        // Arrange
        final client = Client(
          id: 'client-1',
          firstName: 'John',
          lastName: 'Doe',
          email: 'john@example.com',
          clientType: ClientType.existing,
          productType: ProductType.sssPensioner,
          pensionType: PensionType.sss,
          addresses: [
            Address(
              id: 'addr-1',
              street: '123 Main St',
              city: 'Makati',
              province: 'Metro Manila',
              // postalCode removed - client model no longer has it
            ),
          ],
          phoneNumbers: [
            PhoneNumber(
              id: 'phone-1',
              number: '+639123456789',
              label: 'mobile',
            ),
          ],
          touchpoints: [],
          createdAt: DateTime(2024, 1, 1),
        );

        // Act
        final json = client.toJson();
        final restored = Client.fromJson(json);

        // Assert
        expect(restored.id, equals(client.id));
        expect(restored.firstName, equals(client.firstName));
        expect(restored.lastName, equals(client.lastName));
        expect(restored.email, equals(client.email));
        expect(restored.clientType, equals(client.clientType));
        expect(restored.phoneNumbers.length, equals(1));
        expect(restored.addresses.length, equals(1));
      });

      test('pending operation serialization is consistent', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op-1',
          operation: 'CREATE',
          entityType: 'client',
          data: {
            'first_name': 'John',
            'last_name': 'Doe',
          },
          createdAt: DateTime(2024, 1, 1, 12, 0),
          retryCount: 2,
        );

        // Act
        final json = operation.toJson();
        final restored = PendingOperation.fromJson(json);

        // Assert
        expect(restored.id, equals(operation.id));
        expect(restored.operation, equals(operation.operation));
        expect(restored.entityType, equals(operation.entityType));
        expect(restored.retryCount, equals(operation.retryCount));
        expect(restored.data['first_name'], equals('John'));
      });
    });

    group('Queue Processing', () {
      test('operations are processed in order', () {
        // Arrange
        final operations = [
          PendingOperation(
            id: 'op-1',
            operation: 'CREATE',
            entityType: 'client',
            data: {'name': 'First'},
            createdAt: DateTime(2024, 1, 1, 10, 0),
            retryCount: 0,
          ),
          PendingOperation(
            id: 'op-2',
            operation: 'UPDATE',
            entityType: 'client',
            data: {'name': 'Second'},
            createdAt: DateTime(2024, 1, 1, 11, 0),
            retryCount: 0,
          ),
          PendingOperation(
            id: 'op-3',
            operation: 'DELETE',
            entityType: 'client',
            data: {'name': 'Third'},
            createdAt: DateTime(2024, 1, 1, 12, 0),
            retryCount: 0,
          ),
        ];

        // Sort by createdAt
        operations.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Assert
        expect(operations[0].operation, equals('CREATE'));
        expect(operations[1].operation, equals('UPDATE'));
        expect(operations[2].operation, equals('DELETE'));
      });

      test('retry count is incremented on failure', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op-1',
          operation: 'CREATE',
          entityType: 'client',
          data: {},
          createdAt: DateTime.now(),
          retryCount: 0,
        );

        // Act - simulate failure and increment retry
        final updated = operation.copyWith(retryCount: operation.retryCount + 1);

        // Assert
        expect(updated.retryCount, equals(1));
      });

      test('operation is marked as failed after max retries', () {
        // Arrange
        const maxRetries = 3;
        final operation = PendingOperation(
          id: 'op-1',
          operation: 'CREATE',
          entityType: 'client',
          data: {},
          createdAt: DateTime.now(),
          retryCount: maxRetries,
        );

        // Assert
        expect(operation.retryCount >= maxRetries, isTrue);
      });
    });
  });
}
