import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/sync/powersync_service.dart';
import '../models/psgc_models.dart';

/// Repository for PSGC geographic data
class PsgcRepository {
  final PowerSyncDatabase _db;

  PsgcRepository(this._db);

  /// Get all regions
  Future<List<PsgcRegion>> getRegions() async {
    final results = await _db.getAll('SELECT * FROM psgc_regions ORDER BY name');
    return results.map((row) => PsgcRegion.fromJson(row)).toList();
  }

  /// Get provinces by region
  Future<List<PsgcProvince>> getProvincesByRegion(String region) async {
    final results = await _db.getAll(
      'SELECT * FROM psgc_provinces WHERE region = ? ORDER BY name',
      [region],
    );
    return results.map((row) => PsgcProvince.fromJson(row)).toList();
  }

  /// Get all provinces
  Future<List<PsgcProvince>> getAllProvinces() async {
    final results = await _db.getAll('SELECT * FROM psgc_provinces ORDER BY region, name');
    return results.map((row) => PsgcProvince.fromJson(row)).toList();
  }

  /// Get municipalities/cities by province
  Future<List<PsgcMunicipality>> getMunicipalitiesByProvince(String province) async {
    final results = await _db.getAll(
      'SELECT * FROM psgc_municipalities WHERE province = ? ORDER BY name',
      [province],
    );
    return results.map((row) => PsgcMunicipality.fromJson(row)).toList();
  }

  /// Get all municipalities
  Future<List<PsgcMunicipality>> getAllMunicipalities() async {
    final results = await _db.getAll(
      'SELECT * FROM psgc_municipalities ORDER BY region, province, name',
    );
    return results.map((row) => PsgcMunicipality.fromJson(row)).toList();
  }

  /// Get barangays by municipality
  Future<List<PsgcBarangay>> getBarangaysByMunicipality(String municipality) async {
    final results = await _db.getAll(
      'SELECT id, region, province, mun_city as municipality, barangay, zip_code, pin_location FROM psgc_barangays WHERE mun_city = ? ORDER BY barangay',
      [municipality],
    );
    return results.map((row) => PsgcBarangay.fromJson(row)).toList();
  }

  /// Get all barangays
  Future<List<PsgcBarangay>> getAllBarangays() async {
    final results = await _db.getAll(
      'SELECT id, region, province, mun_city as municipality, barangay, zip_code, pin_location FROM psgc_barangays ORDER BY region, province, mun_city, barangay',
    );
    return results.map((row) => PsgcBarangay.fromJson(row)).toList();
  }

  /// Search municipalities by name (for autocomplete)
  Future<List<PsgcMunicipality>> searchMunicipalities(String query) async {
    final searchQuery = '%${query.toLowerCase()}%';
    final results = await _db.getAll(
      "SELECT * FROM psgc_municipalities WHERE LOWER(name) LIKE ? ORDER BY name LIMIT 20",
      [searchQuery],
    );
    return results.map((row) => PsgcMunicipality.fromJson(row)).toList();
  }

  /// Search barangays by name (for autocomplete)
  Future<List<PsgcBarangay>> searchBarangays(String query, {String? municipality}) async {
    final searchQuery = '%${query.toLowerCase()}%';
    List<Object?> params = [searchQuery];
    String sql = "SELECT id, region, province, mun_city as municipality, barangay, zip_code, pin_location FROM psgc_barangays WHERE LOWER(barangay) LIKE ?";

    if (municipality != null) {
      sql += " AND mun_city = ?";
      params.add(municipality);
    }

    sql += " ORDER BY barangay LIMIT 20";

    final results = await _db.getAll(sql, params);
    return results.map((row) => PsgcBarangay.fromJson(row)).toList();
  }
}

/// Provider for PSGC repository
final psgcRepositoryProvider = FutureProvider<PsgcRepository>((ref) async {
  final db = await PowerSyncService.database;
  return PsgcRepository(db);
});

/// Provider for all regions
final regionsProvider = FutureProvider<List<PsgcRegion>>((ref) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getRegions();
});

/// Provider for all provinces
final provincesProvider = FutureProvider<List<PsgcProvince>>((ref) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getAllProvinces();
});

/// Provider for all municipalities
final municipalitiesProvider = FutureProvider<List<PsgcMunicipality>>((ref) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getAllMunicipalities();
});

/// Family provider for provinces by region
final provincesByRegionProvider = FutureProvider.family<List<PsgcProvince>, String>((ref, region) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getProvincesByRegion(region);
});

/// Family provider for municipalities by province
final municipalitiesByProvinceProvider = FutureProvider.family<List<PsgcMunicipality>, String>((ref, province) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getMunicipalitiesByProvince(province);
});

/// Family provider for barangays by municipality
final barangaysByMunicipalityProvider = FutureProvider.family<List<PsgcBarangay>, String>((ref, municipality) async {
  final repository = await ref.watch(psgcRepositoryProvider.future);
  return repository.getBarangaysByMunicipality(municipality);
});
