import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

void main() {
  test('should export locationFilterProvider', () {
    // Verify the provider is exported - this will fail if not exported
    expect(locationFilterProvider, isNotNull);
  });

  test('should export assignedAreasProvider', () {
    expect(assignedAreasProvider, isNotNull);
  });
}
