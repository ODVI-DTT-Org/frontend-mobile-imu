import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/api/itinerary_api_service.dart';

void main() {
  test('ItineraryItem.fromJson parses assignedByName from expand', () {
    final json = {
      'id': 'item-1',
      'client_id': 'client-1',
      'scheduled_date': '2026-04-20',
      'status': 'pending',
      'priority': 'high',
      'created_at': '2026-04-18T00:00:00.000Z',
      'expand': {
        'client_id': {
          'first_name': 'Juan',
          'last_name': 'Dela Cruz',
          'middle_name': '',
        },
        'created_by': {
          'id': 'mgr-1',
          'name': 'Maria Santos',
        },
      },
    };

    final item = ItineraryItem.fromJson(json);
    expect(item.assignedByName, 'Maria Santos');
    expect(item.priority, 'high');
  });

  test('ItineraryItem.fromJson handles missing assignedByName gracefully', () {
    final json = {
      'id': 'item-2',
      'client_id': 'client-1',
      'scheduled_date': '2026-04-20',
      'status': 'pending',
      'priority': 'normal',
      'created_at': '2026-04-18T00:00:00.000Z',
    };

    final item = ItineraryItem.fromJson(json);
    expect(item.assignedByName, isNull);
  });
}
