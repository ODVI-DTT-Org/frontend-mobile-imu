import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/utils/address_display.dart';

void main() {
  group('resolveAddressDisplay', () {
    test('prefers selected primary address over full address and location fields', () {
      final address = resolveAddressDisplay(
        fullAddress: 'Full Client Address',
        region: 'Region X',
        province: 'Province X',
        municipality: 'Municipality X',
        barangay: 'Barangay X',
        addressStreet: 'Street X',
        addressBarangay: 'Barangay Y',
        addressCity: 'City Y',
        addressProvince: 'Province Y',
      );

      expect(address, 'Street X, Barangay Y, City Y, Province Y');
    });

    test('falls back to full address before client location fields', () {
      final address = resolveAddressDisplay(
        fullAddress: 'Full Client Address',
        region: 'Region X',
        province: 'Province X',
        municipality: 'Municipality X',
        barangay: 'Barangay X',
      );

      expect(address, 'Full Client Address');
    });

    test('falls back to PSGC fields in region to street order', () {
      final address = resolveAddressDisplay(
        region: 'Region X',
        province: 'Province X',
        municipality: 'Municipality X',
        barangay: 'Barangay X',
        street: 'Street X',
      );

      expect(address, 'Region X, Province X, Municipality X, Barangay X, Street X');
    });

    test('returns display fallback when no address exists', () {
      final address = resolveAddressDisplayOrFallback();

      expect(address, 'No address available');
    });
  });
}
