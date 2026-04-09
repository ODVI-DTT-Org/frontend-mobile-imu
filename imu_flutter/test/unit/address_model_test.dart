import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/address_model.dart';

void main() {
  group('AddressLabel', () {
    test('should have correct display names', () {
      expect(AddressLabel.home.displayName, 'Home');
      expect(AddressLabel.work.displayName, 'Work');
      expect(AddressLabel.relative.displayName, 'Relative');
      expect(AddressLabel.other.displayName, 'Other');
    });

    test('fromString should parse correctly', () {
      expect(AddressLabel.fromString('home'), AddressLabel.home);
      expect(AddressLabel.fromString('HOME'), AddressLabel.home);
      expect(AddressLabel.fromString('Home'), AddressLabel.home);
      expect(AddressLabel.fromString('work'), AddressLabel.work);
      expect(AddressLabel.fromString('Work'), AddressLabel.work);
      expect(AddressLabel.fromString('relative'), AddressLabel.relative);
      expect(AddressLabel.fromString('other'), AddressLabel.other);
    });

    test('fromString should default to other for invalid values', () {
      expect(AddressLabel.fromString('invalid'), AddressLabel.other);
      expect(AddressLabel.fromString(''), AddressLabel.other);
    });
  });

  group('Address', () {
    final testAddress = Address(
      id: 'test-id',
      clientId: 'client-123',
      label: AddressLabel.home,
      streetAddress: '123 Main St',
      postalCode: '1234',
      psgcId: 123,
      region: 'National Capital Region (NCR)',
      province: 'Metro Manila',
      municipality: 'Quezon City',
      barangay: 'Barangay 123',
      latitude: 14.5995,
      longitude: 120.9842,
      isPrimary: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );

    test('should create Address with all fields', () {
      expect(testAddress.id, 'test-id');
      expect(testAddress.clientId, 'client-123');
      expect(testAddress.label, AddressLabel.home);
      expect(testAddress.streetAddress, '123 Main St');
      expect(testAddress.postalCode, '1234');
      expect(testAddress.psgcId, 123);
      expect(testAddress.region, 'National Capital Region (NCR)');
      expect(testAddress.province, 'Metro Manila');
      expect(testAddress.municipality, 'Quezon City');
      expect(testAddress.barangay, 'Barangay 123');
      expect(testAddress.latitude, 14.5995);
      expect(testAddress.longitude, 120.9842);
      expect(testAddress.isPrimary, true);
    });

    test('fullAddress should combine street address and PSGC fields', () {
      expect(
        testAddress.fullAddress,
        '123 Main St, Brgy. Barangay 123!, Quezon City, Metro Manila',
      );
    });

    test('fullAddress should handle missing PSGC fields', () {
      // Create a new address with empty fields instead of using copyWith with null
      final address = Address(
        id: 'test-id-2',
        clientId: 'client-123',
        psgcId: 0,
        label: AddressLabel.home,
        streetAddress: '',
        postalCode: null,
        latitude: null,
        longitude: null,
        isPrimary: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        barangay: null,
        municipality: null,
        province: null,
      );
      expect(address.fullAddress, '');
    });

    test('fullAddress should handle partial PSGC fields', () {
      // Create a new address with partial fields
      final address = Address(
        id: 'test-id-3',
        clientId: 'client-123',
        psgcId: 123,
        label: AddressLabel.home,
        streetAddress: '',
        postalCode: null,
        latitude: null,
        longitude: null,
        isPrimary: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        barangay: null,
        municipality: 'Quezon City',
        province: 'Metro Manila',
        region: 'NCR',
      );
      // Note: region is not included in fullAddress
      expect(address.fullAddress, 'Quezon City, Metro Manila');
    });

    test('fromSyncMap should parse PowerSync data correctly', () {
      final map = {
        'id': 'sync-id',
        'client_id': 'sync-client',
        'label': 'work',
        'street_address': '456 Work Ave',
        'postal_code': '5678',
        'psgc_id': 456,
        'region': 'Region IV-A',
        'province': 'Cavite',
        'municipality': 'Dasmariñas',
        'barangay': 'Barangay 1',
        'latitude': 14.1234,
        'longitude': 120.9876,
        'is_primary': 0,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final address = Address.fromSyncMap(map);

      expect(address.id, 'sync-id');
      expect(address.clientId, 'sync-client');
      expect(address.label, AddressLabel.work);
      expect(address.streetAddress, '456 Work Ave');
      expect(address.postalCode, '5678');
      expect(address.psgcId, 456);
      expect(address.region, 'Region IV-A');
      expect(address.province, 'Cavite');
      expect(address.municipality, 'Dasmariñas');
      expect(address.barangay, 'Barangay 1');
      expect(address.latitude, 14.1234);
      expect(address.longitude, 120.9876);
      expect(address.isPrimary, false);
    });

    test('fromSyncMap should handle null values gracefully', () {
      final map = {
        'id': 'minimal-id',
        'client_id': 'minimal-client',
        'label': 'home',
        'street_address': null,
        'postal_code': null,
        'psgc_id': 0,
        'region': null,
        'province': null,
        'municipality': null,
        'barangay': null,
        'latitude': null,
        'longitude': null,
        'is_primary': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final address = Address.fromSyncMap(map);

      expect(address.id, 'minimal-id');
      expect(address.streetAddress, '');
      expect(address.postalCode, null);
      expect(address.psgcId, 0);
      expect(address.region, null);
      expect(address.province, null);
      expect(address.municipality, null);
      expect(address.barangay, null);
      expect(address.latitude, null);
      expect(address.longitude, null);
      expect(address.isPrimary, true);
    });

    test('fromSyncMap should handle missing created_at/updated_at', () {
      final map = {
        'id': 'no-dates-id',
        'client_id': 'no-dates-client',
        'label': 'home',
        'street_address': null,
        'postal_code': null,
        'psgc_id': 0,
        'region': null,
        'province': null,
        'municipality': null,
        'barangay': null,
        'latitude': null,
        'longitude': null,
        'is_primary': 0,
        'created_at': null,
        'updated_at': null,
      };

      final address = Address.fromSyncMap(map);

      expect(address.createdAt, isNotNull);
      expect(address.updatedAt, isNotNull);
    });

    test('toJson should convert to JSON for API requests', () {
      final json = testAddress.toJson();

      expect(json['label'], 'home');
      expect(json['street_address'], '123 Main St');
      expect(json['postal_code'], '1234');
      expect(json['psgc_id'], 123);
      expect(json['latitude'], 14.5995);
      expect(json['longitude'], 120.9842);
      expect(json['is_primary'], true);
    });

    test('copyWith should create a new instance with updated fields', () {
      final updated = testAddress.copyWith(
        streetAddress: '789 New St',
        isPrimary: false,
      );

      expect(updated.id, testAddress.id); // unchanged
      expect(updated.streetAddress, '789 New St'); // changed
      expect(updated.isPrimary, false); // changed
      expect(updated.clientId, testAddress.clientId); // unchanged
    });

    test('toString should return readable representation', () {
      final str = testAddress.toString();
      expect(str, contains('123 Main St'));
      expect(str, contains('Quezon City'));
      expect(str, contains('Primary: true'));
    });

    test('equality should be based on id', () {
      final address1 = testAddress;
      final address2 = Address(
        id: 'test-id', // same id
        clientId: 'different-client',
        psgcId: 999,
        label: AddressLabel.work,
        streetAddress: 'Different Address',
        isPrimary: false,
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      expect(address1, equals(address2));
      expect(address1 == address2, true);
    });

    test('hashCode should be based on id', () {
      final address1 = testAddress;
      final address2 = Address(
        id: 'test-id', // same id
        clientId: 'different-client',
        psgcId: 999,
        label: AddressLabel.work,
        streetAddress: 'Different Address',
        isPrimary: false,
        createdAt: DateTime(2024, 2, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      expect(address1.hashCode, equals(address2.hashCode));
    });

    test('different addresses should not be equal', () {
      final address1 = testAddress;
      final address2 = Address(
        id: 'different-id',
        clientId: testAddress.clientId,
        psgcId: testAddress.psgcId,
        label: testAddress.label,
        streetAddress: testAddress.streetAddress,
        isPrimary: testAddress.isPrimary,
        createdAt: testAddress.createdAt,
        updatedAt: testAddress.updatedAt,
      );

      expect(address1, isNot(equals(address2)));
      expect(address1 == address2, false);
    });
  });
}
