import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imu_flutter/services/filter_preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('FilterPreferencesService — attribute lists', () {
    test('getClientTypes returns empty list by default', () async {
      final svc = FilterPreferencesService();
      expect(await svc.getClientTypes(), isEmpty);
    });

    test('setClientTypes and getClientTypes round-trips a list', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential', 'existing']);
      expect(await svc.getClientTypes(), ['potential', 'existing']);
    });

    test('setClientTypes with empty list clears the key', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential']);
      await svc.setClientTypes([]);
      expect(await svc.getClientTypes(), isEmpty);
    });

    test('clearAttributeFilters clears all attribute list keys', () async {
      final svc = FilterPreferencesService();
      await svc.setClientTypes(['potential']);
      await svc.setMarketTypes(['residential']);
      await svc.clearAttributeFilters();
      expect(await svc.getClientTypes(), isEmpty);
      expect(await svc.getMarketTypes(), isEmpty);
    });
  });
}
