import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/touchpoint_model_v2.dart';

void main() {
  group('TouchpointV2 Model', () {
    test('should create TouchpointV2 from row map with visit', () {
      // Arrange
      final row = {
        'id': 'touchpoint-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': 'visit-789',
        'call_id': null,
        'touchpoint_number': 1,
        'type': 'Visit',
        'rejection_reason': null,
        'created_at': '2024-01-15T09:00:00.000Z',
        'updated_at': '2024-01-15T09:00:00.000Z',
      };

      // Act
      final touchpoint = TouchpointV2.fromRow(row);

      // Assert
      expect(touchpoint.id, equals('touchpoint-123'));
      expect(touchpoint.clientId, equals('client-123'));
      expect(touchpoint.userId, equals('user-456'));
      expect(touchpoint.visitId, equals('visit-789'));
      expect(touchpoint.callId, isNull);
      expect(touchpoint.touchpointNumber, equals(1));
      expect(touchpoint.type, equals('Visit'));
      expect(touchpoint.rejectionReason, isNull);
    });

    test('should create TouchpointV2 from row map with call', () {
      // Arrange
      final row = {
        'id': 'touchpoint-456',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': null,
        'call_id': 'call-789',
        'touchpoint_number': 2,
        'type': 'Call',
        'rejection_reason': null,
        'created_at': '2024-01-16T10:00:00.000Z',
        'updated_at': '2024-01-16T10:00:00.000Z',
      };

      // Act
      final touchpoint = TouchpointV2.fromRow(row);

      // Assert
      expect(touchpoint.id, equals('touchpoint-456'));
      expect(touchpoint.visitId, isNull);
      expect(touchpoint.callId, equals('call-789'));
      expect(touchpoint.touchpointNumber, equals(2));
      expect(touchpoint.type, equals('Call'));
    });

    test('should create TouchpointV2 with rejection reason', () {
      // Arrange
      final row = {
        'id': 'touchpoint-789',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'visit_id': 'visit-abc',
        'call_id': null,
        'touchpoint_number': 4,
        'type': 'Visit',
        'rejection_reason': 'Client not interested',
        'created_at': '2024-01-17T11:00:00.000Z',
        'updated_at': '2024-01-17T11:00:00.000Z',
      };

      // Act
      final touchpoint = TouchpointV2.fromRow(row);

      // Assert
      expect(touchpoint.rejectionReason, equals('Client not interested'));
      expect(touchpoint.touchpointNumber, equals(4));
    });

    test('should convert TouchpointV2 to row map', () {
      // Arrange
      final touchpoint = TouchpointV2(
        id: 'touchpoint-123',
        clientId: 'client-123',
        userId: 'user-456',
        visitId: 'visit-789',
        callId: null,
        touchpointNumber: 1,
        type: 'Visit',
        rejectionReason: null,
        createdAt: DateTime.parse('2024-01-15T09:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T09:00:00.000Z'),
      );

      // Act
      final row = touchpoint.toRow();

      // Assert
      expect(row['id'], equals('touchpoint-123'));
      expect(row['client_id'], equals('client-123'));
      expect(row['user_id'], equals('user-456'));
      expect(row['visit_id'], equals('visit-789'));
      expect(row['call_id'], isNull);
      expect(row['touchpoint_number'], equals(1));
      expect(row['type'], equals('Visit'));
      expect(row['rejection_reason'], isNull);
    });

    test('should copy TouchpointV2 with new values', () {
      // Arrange
      final original = TouchpointV2(
        id: 'touchpoint-123',
        clientId: 'client-123',
        userId: 'user-456',
        visitId: 'visit-789',
        callId: null,
        touchpointNumber: 1,
        type: 'Visit',
        rejectionReason: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final copy = original.copyWith(
        visitId: 'visit-new',
        rejectionReason: 'Rescheduled',
      );

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.touchpointNumber, equals(original.touchpointNumber));
      expect(copy.visitId, equals('visit-new'));
      expect(copy.rejectionReason, equals('Rescheduled'));
      expect(copy.type, equals(original.type));
    });

    test('should handle touchpoint numbers 1-7', () {
      // Test all valid touchpoint numbers
      for (int i = 1; i <= 7; i++) {
        // Arrange
        final row = {
          'id': 'touchpoint-$i',
          'client_id': 'client-123',
          'user_id': 'user-456',
          'visit_id': i.isOdd ? 'visit-$i' : null,
          'call_id': i.isEven ? 'call-$i' : null,
          'touchpoint_number': i,
          'type': i.isOdd ? 'Visit' : 'Call',
          'rejection_reason': null,
          'created_at': '2024-01-15T09:00:00.000Z',
          'updated_at': '2024-01-15T09:00:00.000Z',
        };

        // Act
        final touchpoint = TouchpointV2.fromRow(row);

        // Assert
        expect(touchpoint.touchpointNumber, equals(i));
        expect(touchpoint.type, equals(i.isOdd ? 'Visit' : 'Call'));
      }
    });

    test('should swap visit and call references', () {
      // Arrange - Touchpoint originally linked to visit
      final original = TouchpointV2(
        id: 'touchpoint-123',
        clientId: 'client-123',
        userId: 'user-456',
        visitId: 'visit-789',
        callId: null,
        touchpointNumber: 1,
        type: 'Visit',
        rejectionReason: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act - Change to call
      final updated = original.copyWith(
        visitId: null,
        callId: 'call-456',
        type: 'Call',
      );

      // Assert
      expect(updated.visitId, isNull);
      expect(updated.callId, equals('call-456'));
      expect(updated.type, equals('Call'));
      expect(updated.touchpointNumber, equals(original.touchpointNumber));
    });
  });
}
