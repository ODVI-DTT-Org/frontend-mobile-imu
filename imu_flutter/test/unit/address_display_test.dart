import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/utils/address_display.dart';

void main() {
  group('resolveAddressDisplay', () {
    test('prefers full address over location fields and address lookup', () {
      final address = resolveAddressDisplay(
        fullAddress: 'Full Client Address',
        region: 'Region X',
        province: 'Province X',
        municipality: 'Municipality X',
        barangay: 'Barangay X',
        addressStreet: 'Street X',
      );

      expect(address, 'Full Client Address');
    });

    test('falls back to client location fields before address lookup', () {
      final address = resolveAddressDisplay(
        region: 'Region X',
        province: 'Province X',
        municipality: 'Municipality X',
        barangay: 'Barangay X',
        addressStreet: 'Street X',
        addressBarangay: 'Barangay Y',
        addressCity: 'City Y',
        addressProvince: 'Province Y',
      );

      expect(address, 'Region X, Province X, Municipality X, Barangay X');
    });

    test('falls back to address lookup before returning null', () {
      final address = resolveAddressDisplay(
        addressStreet: 'Street X',
        addressBarangay: 'Barangay Y',
        addressCity: 'City Y',
        addressProvince: 'Province Y',
      );

      expect(address, 'Street X, Barangay Y, City Y, Province Y');
    });

    test('returns display fallback when no address exists', () {
      final address = resolveAddressDisplayOrFallback();

      expect(address, 'No address available');
    });
  });
}
