import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/call_model.dart';

void main() {
  group('Call Model', () {
    test('should create Call from row map', () {
      // Arrange
      final row = {
        'id': 'call-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'phone_number': '09123456789',
        'dial_time': '2024-01-15T14:30:00.000Z',
        'duration': 300,
        'notes': 'Client interested in product',
        'reason': 'Follow-up call',
        'status': 'completed',
        'created_at': '2024-01-15T14:00:00.000Z',
        'updated_at': '2024-01-15T14:35:00.000Z',
      };

      // Act
      final call = Call.fromRow(row);

      // Assert
      expect(call.id, equals('call-123'));
      expect(call.clientId, equals('client-123'));
      expect(call.userId, equals('user-456'));
      expect(call.phoneNumber, equals('09123456789'));
      expect(call.dialTime, isNotNull);
      expect(call.duration, equals(300));
      expect(call.notes, equals('Client interested in product'));
      expect(call.reason, equals('Follow-up call'));
      expect(call.status, equals('completed'));
    });

    test('should create Call with null optional fields', () {
      // Arrange
      final row = {
        'id': 'call-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'phone_number': '09987654321',
        'dial_time': null,
        'duration': null,
        'notes': null,
        'reason': null,
        'status': null,
        'created_at': '2024-01-15T14:00:00.000Z',
        'updated_at': '2024-01-15T14:00:00.000Z',
      };

      // Act
      final call = Call.fromRow(row);

      // Assert
      expect(call.dialTime, isNull);
      expect(call.duration, isNull);
      expect(call.notes, isNull);
      expect(call.reason, isNull);
      expect(call.status, isNull);
    });

    test('should convert Call to row map', () {
      // Arrange
      final call = Call(
        id: 'call-123',
        clientId: 'client-123',
        userId: 'user-456',
        phoneNumber: '09123456789',
        dialTime: DateTime.parse('2024-01-15T14:30:00.000Z'),
        duration: 300,
        notes: 'Follow up next week',
        reason: 'Initial inquiry',
        status: 'completed',
        createdAt: DateTime.parse('2024-01-15T14:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T14:35:00.000Z'),
      );

      // Act
      final row = call.toRow();

      // Assert
      expect(row['id'], equals('call-123'));
      expect(row['client_id'], equals('client-123'));
      expect(row['user_id'], equals('user-456'));
      expect(row['phone_number'], equals('09123456789'));
      expect(row['dial_time'], isNotNull);
      expect(row['duration'], equals(300));
      expect(row['notes'], equals('Follow up next week'));
      expect(row['reason'], equals('Initial inquiry'));
      expect(row['status'], equals('completed'));
    });

    test('should copy Call with new values', () {
      // Arrange
      final original = Call(
        id: 'call-123',
        clientId: 'client-123',
        userId: 'user-456',
        phoneNumber: '09123456789',
        status: 'pending',
        notes: 'Original notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final copy = original.copyWith(
        status: 'completed',
        duration: 450,
      );

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.phoneNumber, equals(original.phoneNumber));
      expect(copy.status, equals('completed'));
      expect(copy.duration, equals(450));
      expect(copy.notes, equals(original.notes));
    });
  });
}
