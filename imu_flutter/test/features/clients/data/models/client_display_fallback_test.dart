import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('Client display fallbacks', () {
    test('parses and displays backend pension labels with spaces and hyphens', () {
      final client = Client.fromJson({
        'id': 'client-1',
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'client_type': 'potential',
        'product_type': 'PNP PENSION',
        'pension_type': 'PNP - RETIREE OPTIONAL',
        'created_at': '2026-05-19T00:00:00.000Z',
      });

      expect(client.pensionType, PensionType.pnpRetireeOptional);
      expect(client.pensionTypeDisplay, 'PNP - RETIREE OPTIONAL');
    });

    test('uses touchpoint status next type when next_touchpoint is absent', () {
      final client = Client.fromJson({
        'id': 'client-1',
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'client_type': 'potential',
        'product_type': 'PNP PENSION',
        'pension_type': 'PNP - RETIREE OPTIONAL',
        'touchpoint_number': 4,
        'touchpoint_status': {
          'completed_touchpoints': 4,
          'next_touchpoint_number': 5,
          'next_touchpoint_type': 'Call',
          'can_create_touchpoint': true,
          'is_complete': false,
          'loan_released': false,
        },
        'created_at': '2026-05-19T00:00:00.000Z',
      });

      expect(client.nextTouchpoint, 'Call');
      expect(client.nextTouchpointDisplay, '5 • call');
    });

    test('uses full address then client location before address records', () {
      final fromFullAddress = Client.fromJson({
        'id': 'client-1',
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'client_type': 'potential',
        'product_type': 'PNP PENSION',
        'pension_type': 'PNP - RETIREE OPTIONAL',
        'full_address': 'Stored Full Address',
        'region': 'Region X',
        'province': 'Province X',
        'municipality': 'Municipality X',
        'barangay': 'Barangay X',
        'addresses': [
          {
            'id': 'address-1',
            'client_id': 'client-1',
            'street': 'Street X',
            'barangay': 'Barangay Y',
            'city': 'City Y',
            'province': 'Province Y',
            'is_primary': true,
          }
        ],
        'created_at': '2026-05-19T00:00:00.000Z',
      });

      expect(fromFullAddress.fullAddress, 'Stored Full Address');

      final fromLocation = Client.fromJson({
        'id': 'client-2',
        'first_name': 'Maria',
        'last_name': 'Santos',
        'client_type': 'potential',
        'product_type': 'PNP PENSION',
        'pension_type': 'PNP - RETIREE OPTIONAL',
        'region': 'Region X',
        'province': 'Province X',
        'municipality': 'Municipality X',
        'barangay': 'Barangay X',
        'addresses': [
          {
            'id': 'address-2',
            'client_id': 'client-2',
            'street': 'Street X',
            'barangay': 'Barangay Y',
            'city': 'City Y',
            'province': 'Province Y',
            'is_primary': true,
          }
        ],
        'created_at': '2026-05-19T00:00:00.000Z',
      });

      expect(fromLocation.fullAddress, 'Region X, Province X, Municipality X, Barangay X');
    });
  });
}
