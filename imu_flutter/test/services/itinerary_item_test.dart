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

  test('ItineraryItem.fromPowerSync uses full address then location then address lookup', () {
    final fullAddressItem = ItineraryItem.fromPowerSync({
      'id': 'item-3',
      'client_id': 'client-1',
      'scheduled_date': '2026-04-20',
      'status': 'pending',
      'first_name': 'Juan',
      'last_name': 'Dela Cruz',
      'full_address': 'Stored Full Address',
      'region': 'Region X',
      'province': 'Province X',
      'municipality': 'Municipality X',
      'barangay': 'Barangay X',
      'address_street': 'Street X',
      'address_city': 'City Y',
      'address_province': 'Province Y',
    });

    expect(fullAddressItem.address, 'Stored Full Address');

    final locationItem = ItineraryItem.fromPowerSync({
      'id': 'item-4',
      'client_id': 'client-2',
      'scheduled_date': '2026-04-20',
      'status': 'pending',
      'first_name': 'Maria',
      'last_name': 'Santos',
      'region': 'Region X',
      'province': 'Province X',
      'municipality': 'Municipality X',
      'barangay': 'Barangay X',
      'address_street': 'Street X',
      'address_city': 'City Y',
      'address_province': 'Province Y',
    });

    expect(locationItem.address, 'Region X, Province X, Municipality X, Barangay X');

    final addressLookupItem = ItineraryItem.fromPowerSync({
      'id': 'item-5',
      'client_id': 'client-3',
      'scheduled_date': '2026-04-20',
      'status': 'pending',
      'first_name': 'Pedro',
      'last_name': 'Reyes',
      'address_street': 'Street X',
      'address_barangay': 'Barangay Y',
      'address_city': 'City Y',
      'address_province': 'Province Y',
    });

    expect(addressLookupItem.address, 'Street X, Barangay Y, City Y, Province Y');
  });
}
