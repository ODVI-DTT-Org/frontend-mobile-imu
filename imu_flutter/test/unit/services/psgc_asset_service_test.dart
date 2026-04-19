import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/psgc/data/services/psgc_asset_service.dart';
import 'package:imu_flutter/features/psgc/data/models/psgc_models.dart';

void main() {
  late PsgcAssetService service;

  final testData = [
    PsgcBarangay(id: '1', region: 'Region I', province: 'Ilocos Norte', municipality: 'Laoag City', municipalityKind: 'City', barangay: 'Barangay 1', zipCode: '2900'),
    PsgcBarangay(id: '2', region: 'Region I', province: 'Ilocos Norte', municipality: 'Laoag City', municipalityKind: 'City', barangay: 'Barangay 2', zipCode: '2900'),
    PsgcBarangay(id: '3', region: 'Region I', province: 'Ilocos Norte', municipality: 'Adams', municipalityKind: 'Municipality', barangay: 'Bacsil', zipCode: '2901'),
    PsgcBarangay(id: '4', region: 'Region I', province: 'Ilocos Sur', municipality: 'Vigan City', municipalityKind: 'City', barangay: 'Bantay', zipCode: '2700'),
    PsgcBarangay(id: '5', region: 'Region II', province: 'Cagayan', municipality: 'Tuguegarao City', municipalityKind: 'City', barangay: 'Annafunan', zipCode: '3500'),
  ];

  setUp(() {
    service = PsgcAssetService();
    PsgcAssetService.setTestData(testData);
  });

  tearDown(() {
    PsgcAssetService.clearTestData();
  });

  group('distinctRegions', () {
    test('returns sorted unique regions', () {
      final result = service.distinctRegions();
      expect(result, ['Region I', 'Region II']);
    });
  });

  group('provincesForRegion', () {
    test('returns sorted unique provinces for given region', () {
      final result = service.provincesForRegion('Region I');
      expect(result, ['Ilocos Norte', 'Ilocos Sur']);
    });

    test('returns empty list for unknown region', () {
      expect(service.provincesForRegion('Unknown'), isEmpty);
    });
  });

  group('municipalitiesForProvince', () {
    test('returns unique municipalities with correct metadata', () {
      final result = service.municipalitiesForProvince('Ilocos Norte');
      expect(result.length, 2);
      expect(result.map((m) => m.name).toList(), ['Adams', 'Laoag City']);
      expect(result.first.region, 'Region I');
      expect(result.first.province, 'Ilocos Norte');
    });

    test('returns empty list for unknown province', () {
      expect(service.municipalitiesForProvince('Unknown'), isEmpty);
    });
  });

  group('barangaysForMunicipality', () {
    test('returns all barangays for given municipality sorted by name', () {
      final result = service.barangaysForMunicipality('Laoag City');
      expect(result.length, 2);
      expect(result.map((b) => b.barangay).toList(), ['Barangay 1', 'Barangay 2']);
    });

    test('returns empty list for unknown municipality', () {
      expect(service.barangaysForMunicipality('Unknown'), isEmpty);
    });
  });

  group('searchMunicipalities', () {
    test('returns empty for query shorter than 2 chars', () {
      expect(service.searchMunicipalities('L'), isEmpty);
    });

    test('returns matching municipalities case-insensitively', () {
      final result = service.searchMunicipalities('laoag');
      expect(result.length, 1);
      expect(result.first.name, 'Laoag City');
    });

    test('deduplicates results', () {
      final result = service.searchMunicipalities('City');
      final names = result.map((m) => m.name).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('searchBarangays', () {
    test('returns empty for query shorter than 2 chars', () {
      expect(service.searchBarangays('B'), isEmpty);
    });

    test('returns matching barangays case-insensitively', () {
      final result = service.searchBarangays('barangay');
      expect(result.length, 2);
    });

    test('filters by municipality when provided', () {
      final result = service.searchBarangays('barangay', municipality: 'Laoag City');
      expect(result.length, 2);
      expect(result.every((b) => b.municipality == 'Laoag City'), isTrue);
    });
  });
}
