import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/psgc/data/repositories/psgc_repository.dart';
import 'package:imu_flutter/features/psgc/data/services/psgc_asset_service.dart';
import 'package:imu_flutter/features/psgc/data/models/psgc_models.dart';

void main() {
  late PsgcRepository repo;

  final testData = [
    PsgcBarangay(id: '1', region: 'Region I', province: 'Ilocos Norte', municipality: 'Laoag City', municipalityKind: 'City', barangay: 'Barangay 1', zipCode: '2900'),
    PsgcBarangay(id: '2', region: 'Region I', province: 'Ilocos Norte', municipality: 'Laoag City', municipalityKind: 'City', barangay: 'Barangay 2', zipCode: '2900'),
    PsgcBarangay(id: '3', region: 'Region I', province: 'Ilocos Sur', municipality: 'Vigan City', municipalityKind: 'City', barangay: 'Bantay', zipCode: '2700'),
    PsgcBarangay(id: '4', region: 'Region II', province: 'Cagayan', municipality: 'Tuguegarao City', municipalityKind: 'City', barangay: 'Annafunan', zipCode: '3500'),
  ];

  setUp(() {
    PsgcAssetService.setTestData(testData);
    repo = PsgcRepository(PsgcAssetService());
  });

  tearDown(() {
    PsgcAssetService.clearTestData();
  });

  test('getRegions returns PsgcRegion list', () async {
    final result = await repo.getRegions();
    expect(result, isA<List<PsgcRegion>>());
    expect(result.map((r) => r.name).toList(), ['Region I', 'Region II']);
  });

  test('getProvincesByRegion returns PsgcProvince list for region', () async {
    final result = await repo.getProvincesByRegion('Region I');
    expect(result, isA<List<PsgcProvince>>());
    expect(result.map((p) => p.name).toList(), ['Ilocos Norte', 'Ilocos Sur']);
    expect(result.every((p) => p.region == 'Region I'), isTrue);
  });

  test('getMunicipalitiesByProvince returns municipalities for province', () async {
    final result = await repo.getMunicipalitiesByProvince('Ilocos Norte');
    expect(result, isA<List<PsgcMunicipality>>());
    expect(result.map((m) => m.name).toList(), ['Laoag City']);
  });

  test('getBarangaysByMunicipality returns barangays for municipality', () async {
    final result = await repo.getBarangaysByMunicipality('Laoag City');
    expect(result, isA<List<PsgcBarangay>>());
    expect(result.length, 2);
  });

  test('searchMunicipalities returns matches', () async {
    final result = await repo.searchMunicipalities('Lao');
    expect(result.length, 1);
    expect(result.first.name, 'Laoag City');
  });

  test('searchMunicipalities returns empty for short query', () async {
    expect(await repo.searchMunicipalities('L'), isEmpty);
  });

  test('searchBarangays returns matches scoped to municipality', () async {
    final result = await repo.searchBarangays('Barangay', municipality: 'Laoag City');
    expect(result.length, 2);
    expect(result.every((b) => b.municipality == 'Laoag City'), isTrue);
  });
}
