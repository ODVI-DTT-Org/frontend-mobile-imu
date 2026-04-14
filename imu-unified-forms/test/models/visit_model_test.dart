import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/models/visit_model.dart';

void main() {
  group('Visit Model', () {
    test('should create Visit from row map', () {
      // Arrange
      final row = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'type': 'regular_visit',
        'time_in': '2024-01-15T09:00:00.000Z',
        'time_out': '2024-01-15T10:30:00.000Z',
        'odometer_arrival': '12345 km',
        'odometer_departure': '12350 km',
        'photo_url': 'https://example.com/photo.jpg',
        'notes': 'Client interested in new loan',
        'reason': 'Follow-up',
        'status': 'completed',
        'address': '123 Main St, City',
        'latitude': 14.5995,
        'longitude': 120.9842,
        'created_at': '2024-01-15T08:00:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
      };

      // Act
      final visit = Visit.fromRow(row);

      // Assert
      expect(visit.id, equals('123e4567-e89b-12d3-a456-426614174000'));
      expect(visit.clientId, equals('client-123'));
      expect(visit.userId, equals('user-456'));
      expect(visit.type, equals('regular_visit'));
      expect(visit.timeIn, isNotNull);
      expect(visit.timeOut, isNotNull);
      expect(visit.odometerArrival, equals('12345 km'));
      expect(visit.odometerDeparture, equals('12350 km'));
      expect(visit.photoUrl, equals('https://example.com/photo.jpg'));
      expect(visit.notes, equals('Client interested in new loan'));
      expect(visit.reason, equals('Follow-up'));
      expect(visit.status, equals('completed'));
      expect(visit.address, equals('123 Main St, City'));
      expect(visit.latitude, equals(14.5995));
      expect(visit.longitude, equals(120.9842));
    });

    test('should create Visit with null optional fields', () {
      // Arrange
      final row = {
        'id': 'visit-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'type': 'regular_visit',
        'time_in': null,
        'time_out': null,
        'odometer_arrival': null,
        'odometer_departure': null,
        'photo_url': null,
        'notes': null,
        'reason': null,
        'status': null,
        'address': null,
        'latitude': null,
        'longitude': null,
        'created_at': '2024-01-15T08:00:00.000Z',
        'updated_at': '2024-01-15T08:00:00.000Z',
      };

      // Act
      final visit = Visit.fromRow(row);

      // Assert
      expect(visit.timeIn, isNull);
      expect(visit.timeOut, isNull);
      expect(visit.odometerArrival, isNull);
      expect(visit.odometerDeparture, isNull);
      expect(visit.photoUrl, isNull);
      expect(visit.notes, isNull);
      expect(visit.reason, isNull);
      expect(visit.status, isNull);
      expect(visit.address, isNull);
      expect(visit.latitude, isNull);
      expect(visit.longitude, isNull);
    });

    test('should convert Visit to row map', () {
      // Arrange
      final visit = Visit(
        id: 'visit-123',
        clientId: 'client-123',
        userId: 'user-456',
        type: 'release_loan',
        timeIn: DateTime.parse('2024-01-15T09:00:00.000Z'),
        timeOut: DateTime.parse('2024-01-15T10:30:00.000Z'),
        odometerArrival: '10000 km',
        odometerDeparture: '10005 km',
        photoUrl: 'https://example.com/photo.jpg',
        notes: 'Release loan application',
        reason: 'New Loan',
        status: 'pending',
        address: '456 Oak Ave, Town',
        latitude: 14.6000,
        longitude: 120.9850,
        createdAt: DateTime.parse('2024-01-15T08:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      // Act
      final row = visit.toRow();

      // Assert
      expect(row['id'], equals('visit-123'));
      expect(row['client_id'], equals('client-123'));
      expect(row['user_id'], equals('user-456'));
      expect(row['type'], equals('release_loan'));
      expect(row['time_in'], isNotNull);
      expect(row['time_out'], isNotNull);
      expect(row['odometer_arrival'], equals('10000 km'));
      expect(row['odometer_departure'], equals('10005 km'));
      expect(row['photo_url'], equals('https://example.com/photo.jpg'));
      expect(row['notes'], equals('Release loan application'));
      expect(row['reason'], equals('New Loan'));
      expect(row['status'], equals('pending'));
      expect(row['address'], equals('456 Oak Ave, Town'));
      expect(row['latitude'], equals(14.6000));
      expect(row['longitude'], equals(120.9850));
    });

    test('should copy Visit with new values', () {
      // Arrange
      final original = Visit(
        id: 'visit-123',
        clientId: 'client-123',
        userId: 'user-456',
        type: 'regular_visit',
        notes: 'Original notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final copy = original.copyWith(
        notes: 'Updated notes',
        status: 'completed',
      );

      // Assert
      expect(copy.id, equals(original.id));
      expect(copy.clientId, equals(original.clientId));
      expect(copy.notes, equals('Updated notes'));
      expect(copy.status, equals('completed'));
      expect(copy.type, equals(original.type));
    });

    test('should handle null visit type with default', () {
      // Arrange
      final row = {
        'id': 'visit-123',
        'client_id': 'client-123',
        'user_id': 'user-456',
        'type': null, // Null type should default to 'regular_visit'
        'created_at': '2024-01-15T08:00:00.000Z',
        'updated_at': '2024-01-15T08:00:00.000Z',
        // Other fields null
        'time_in': null,
        'time_out': null,
        'odometer_arrival': null,
        'odometer_departure': null,
        'photo_url': null,
        'notes': null,
        'reason': null,
        'status': null,
        'address': null,
        'latitude': null,
        'longitude': null,
      };

      // Act
      final visit = Visit.fromRow(row);

      // Assert
      expect(visit.type, equals('regular_visit')); // Default value
    });
  });
}
