import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('Touchpoint.fromRow', () {
    test('should create Touchpoint from PowerSync row', () {
      final row = {
        'id': 'uuid-123',
        'client_id': 'client-456',
        'user_id': 'user-789',
        'touchpoint_number': 1,
        'type': 'Visit',
        'date': '2026-04-06',
        'time_arrival': '09:30',
        'time_departure': '10:30',
        'reason': 'INTERESTED',
        'status': 'Interested',
        'notes': 'Some notes',
        'photo_path': '/path/to/photo.jpg',
        'audio_path': '/path/to/audio.mp3',
        'latitude': 14.5,
        'longitude': 121.0,
        'time_in': '2026-04-06T09:30:00',
        'time_in_gps_lat': 14.5,
        'time_in_gps_lng': 121.0,
        'time_in_gps_address': 'Test Address',
        'time_out': '2026-04-06T10:30:00',
        'time_out_gps_lat': 14.5,
        'time_out_gps_lng': 121.0,
        'time_out_gps_address': 'Test Address',
        'created_at': '2026-04-06T08:00:00',
      };

      final touchpoint = Touchpoint.fromRow(row);

      expect(touchpoint.id, 'uuid-123');
      expect(touchpoint.clientId, 'client-456');
      expect(touchpoint.userId, 'user-789');
      expect(touchpoint.touchpointNumber, 1);
      expect(touchpoint.type, TouchpointType.visit);
      expect(touchpoint.date, DateTime.parse('2026-04-06'));
      expect(touchpoint.timeArrival?.hour, 9);
      expect(touchpoint.timeArrival?.minute, 30);
      expect(touchpoint.reason, TouchpointReason.interested);
      expect(touchpoint.status, TouchpointStatus.interested);
    });

    test('should handle Call type correctly', () {
      final row = {
        'id': 'uuid-123',
        'client_id': 'client-456',
        'user_id': null,
        'touchpoint_number': 2,
        'type': 'Call',
        'date': '2026-04-06',
        'reason': 'NOT_INTERESTED',
        'status': 'Not Interested',
        'created_at': '2026-04-06T08:00:00',
      };

      final touchpoint = Touchpoint.fromRow(row);

      expect(touchpoint.userId, null);
      expect(touchpoint.touchpointNumber, 2);
      expect(touchpoint.type, TouchpointType.call);
      expect(touchpoint.reason, TouchpointReason.notInterested);
      expect(touchpoint.status, TouchpointStatus.notInterested);
    });

    test('should handle null optional fields', () {
      final row = {
        'id': 'uuid-123',
        'client_id': 'client-456',
        'user_id': null,
        'touchpoint_number': 3,
        'type': 'Call',
        'date': '2026-04-06',
        'reason': 'UNDECIDED',
        'status': 'Undecided',
        'time_arrival': null,
        'time_departure': null,
        'latitude': null,
        'longitude': null,
        'created_at': '2026-04-06T08:00:00',
      };

      final touchpoint = Touchpoint.fromRow(row);

      expect(touchpoint.userId, null);
      expect(touchpoint.timeArrival, null);
      expect(touchpoint.timeDeparture, null);
      expect(touchpoint.latitude, null);
      expect(touchpoint.longitude, null);
    });

    test('should parse DateTime fields correctly', () {
      final row = {
        'id': 'uuid-123',
        'client_id': 'client-456',
        'touchpoint_number': 1,
        'type': 'Visit',
        'date': '2026-04-06',
        'reason': 'INTERESTED',
        'status': 'Interested',
        'time_in': '2026-04-06T09:30:15',
        'time_out': '2026-04-06T10:45:30',
        'created_at': '2026-04-06T08:00:00',
      };

      final touchpoint = Touchpoint.fromRow(row);

      expect(touchpoint.timeIn, DateTime.parse('2026-04-06T09:30:15'));
      expect(touchpoint.timeOut, DateTime.parse('2026-04-06T10:45:30'));
    });

    test('should handle GPS location data', () {
      final row = {
        'id': 'uuid-123',
        'client_id': 'client-456',
        'touchpoint_number': 1,
        'type': 'Visit',
        'date': '2026-04-06',
        'reason': 'INTERESTED',
        'status': 'Interested',
        'latitude': 14.6091,
        'longitude': 121.0223,
        'time_in_gps_lat': 14.6091,
        'time_in_gps_lng': 121.0223,
        'time_in_gps_address': 'Makati City, Philippines',
        'created_at': '2026-04-06T08:00:00',
      };

      final touchpoint = Touchpoint.fromRow(row);

      expect(touchpoint.latitude, 14.6091);
      expect(touchpoint.longitude, 121.0223);
      expect(touchpoint.timeInGpsLat, 14.6091);
      expect(touchpoint.timeInGpsLng, 121.0223);
      expect(touchpoint.timeInGpsAddress, 'Makati City, Philippines');
    });
  });
}
