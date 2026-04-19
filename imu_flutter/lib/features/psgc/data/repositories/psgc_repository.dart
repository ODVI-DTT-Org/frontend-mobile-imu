import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/psgc_models.dart';
import '../services/psgc_asset_service.dart';

class PsgcRepository {
  final PsgcAssetService _assetService;

  PsgcRepository(this._assetService);

  Future<List<PsgcRegion>> getRegions() async {
    await _assetService.loadIfNeeded();
    return _assetService.distinctRegions()
        .map((name) => PsgcRegion(name: name, code: name))
        .toList();
  }

  Future<List<PsgcProvince>> getProvincesByRegion(String region) async {
    await _assetService.loadIfNeeded();
    return _assetService.provincesForRegion(region)
        .map((name) => PsgcProvince(name: name, code: name, region: region))
        .toList();
  }

  Future<List<PsgcProvince>> getAllProvinces() async {
    await _assetService.loadIfNeeded();
    final seen = <String>{};
    final result = <PsgcProvince>[];
    for (final region in _assetService.distinctRegions()) {
      for (final name in _assetService.provincesForRegion(region)) {
        if (seen.add(name)) {
          result.add(PsgcProvince(name: name, code: name, region: region));
        }
      }
    }
    return result;
  }

  Future<List<PsgcMunicipality>> getMunicipalitiesByProvince(String province) async {
    await _assetService.loadIfNeeded();
    return _assetService.municipalitiesForProvince(province);
  }

  Future<List<PsgcMunicipality>> getAllMunicipalities() async {
    await _assetService.loadIfNeeded();
    final seen = <String>{};
    final result = <PsgcMunicipality>[];
    for (final region in _assetService.distinctRegions()) {
      for (final province in _assetService.provincesForRegion(region)) {
        for (final mun in _assetService.municipalitiesForProvince(province)) {
          if (seen.add(mun.name)) result.add(mun);
        }
      }
    }
    return result;
  }

  Future<List<PsgcBarangay>> getBarangaysByMunicipality(String municipality) async {
    await _assetService.loadIfNeeded();
    return _assetService.barangaysForMunicipality(municipality);
  }

  Future<List<PsgcBarangay>> getAllBarangays() async {
    await _assetService.loadIfNeeded();
    return _assetService.barangaysForMunicipality('');
  }

  Future<List<PsgcMunicipality>> searchMunicipalities(String query) async {
    if (query.length < 2) return [];
    await _assetService.loadIfNeeded();
    return _assetService.searchMunicipalities(query);
  }

  Future<List<PsgcBarangay>> searchBarangays(String query, {String? municipality}) async {
    if (query.length < 2) return [];
    await _assetService.loadIfNeeded();
    return _assetService.searchBarangays(query, municipality: municipality);
  }
}

final psgcAssetServiceProvider = Provider<PsgcAssetService>((ref) {
  return PsgcAssetService();
});

final psgcRepositoryProvider = Provider<PsgcRepository>((ref) {
  return PsgcRepository(ref.read(psgcAssetServiceProvider));
});

final regionsProvider = FutureProvider<List<PsgcRegion>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getRegions();
});

final provincesProvider = FutureProvider<List<PsgcProvince>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getAllProvinces();
});

final municipalitiesProvider = FutureProvider<List<PsgcMunicipality>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getAllMunicipalities();
});

final provincesByRegionProvider = FutureProvider.family<List<PsgcProvince>, String>((ref, region) async {
  return ref.watch(psgcRepositoryProvider).getProvincesByRegion(region);
});

final municipalitiesByProvinceProvider = FutureProvider.family<List<PsgcMunicipality>, String>((ref, province) async {
  return ref.watch(psgcRepositoryProvider).getMunicipalitiesByProvince(province);
});

final barangaysByMunicipalityProvider = FutureProvider.family<List<PsgcBarangay>, String>((ref, municipality) async {
  return ref.watch(psgcRepositoryProvider).getBarangaysByMunicipality(municipality);
});
