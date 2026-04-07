import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';

void main() {
  group('LocationFilter', () {
    test('should create empty filter with none()', () {
      final filter = LocationFilter.none();
      expect(filter.province, isNull);
      expect(filter.municipalities, isNull);
      expect(filter.hasFilter, isFalse);
    });

    test('should create filter with province only', () {
      final filter = LocationFilter(province: 'Pangasinan');
      expect(filter.province, 'Pangasinan');
      expect(filter.municipalities, isNull);
      expect(filter.hasFilter, isTrue);
    });

    test('should create filter with province and single municipality', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      expect(filter.province, 'Pangasinan');
      expect(filter.municipalities, ['Dagupan']);
      expect(filter.hasFilter, isTrue);
    });

    test('should create filter with province and multiple municipalities', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan', 'Urdaneta']);
      expect(filter.province, 'Pangasinan');
      expect(filter.municipalities, ['Dagupan', 'Urdaneta']);
    });

    test('copyWith should update only specified fields', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      final updated = filter.copyWith(province: 'Cebu');
      expect(updated.province, 'Cebu');
      expect(updated.municipalities, ['Dagupan']);
    });

    test('copyWith should update only specified fields', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan', 'Urdaneta']);
      final updated = filter.copyWith(municipalities: ['Dagupan']);
      expect(updated.province, 'Pangasinan');
      expect(updated.municipalities, ['Dagupan']);
    });

    test('toQueryParams should return empty map for no filter', () {
      final filter = LocationFilter.none();
      expect(filter.toQueryParams(), isEmpty);
    });

    test('toQueryParams should return province only', () {
      final filter = LocationFilter(province: 'Pangasinan');
      expect(filter.toQueryParams(), {'province': 'Pangasinan'});
    });

    test('toQueryParams should return province and single municipality', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      expect(filter.toQueryParams(), {'province': 'Pangasinan', 'municipality': 'Dagupan'});
    });

    test('toQueryParams should return province and multiple municipalities as comma-separated', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan', 'Urdaneta']);
      expect(filter.toQueryParams(), {'province': 'Pangasinan', 'municipality': 'Dagupan,Urdaneta'});
    });

    test('getDisplayLabel should return province only', () {
      final filter = LocationFilter(province: 'Pangasinan');
      expect(filter.getDisplayLabel(), 'Pangasinan');
    });

    test('getDisplayLabel should return province and single municipality', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      expect(filter.getDisplayLabel(), 'Pangasinan • Dagupan');
    });

    test('getDisplayLabel should return province and multiple municipalities with count', () {
      final filter = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan', 'Urdaneta', 'Mangaldan']);
      expect(filter.getDisplayLabel(), 'Pangasinan • Dagupan, Urdaneta (+1)');
    });

    test('should implement equality correctly', () {
      final filter1 = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      final filter2 = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      final filter3 = LocationFilter(province: 'Cebu');

      expect(filter1, equals(filter2));
      expect(filter1, isNot(equals(filter3)));
    });

    test('hashCode should be consistent with equality', () {
      final filter1 = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);
      final filter2 = LocationFilter(province: 'Pangasinan', municipalities: ['Dagupan']);

      expect(filter1.hashCode, equals(filter2.hashCode));
    });
  });
}
