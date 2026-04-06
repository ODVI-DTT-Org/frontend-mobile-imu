import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import '../models/psgc_models.dart';

/// Repository for PSGC geographic data
class PsgcRepository {
  final PowerSyncDatabase _db;

  PsgcRepository(this._db);

  /// Get all regions
  /// Note: PowerSync syncs a single 'psgc' table, so we derive regions from it
  Future<List<PsgcRegion>> getRegions() async {
    final results = await _db.getAll(
      'SELECT DISTINCT region as name, region as code FROM psgc ORDER BY region',
    );
    return results.map((row) => PsgcRegion(
      name: row['region'] as String,
      code: row['region'] as String,
    )).toList();
  }

  /// Get provinces by region
  Future<List<PsgcProvince>> getProvincesByRegion(String region) async {
    final results = await _db.getAll(
      'SELECT DISTINCT province as name, province as code, region FROM psgc WHERE region = ? ORDER BY province',
      [region],
    );
    return results.map((row) => PsgcProvince(
      name: row['province'] as String,
      code: row['province'] as String,
      region: row['region'] as String,
    )).toList();
  }

  /// Get all provinces
  Future<List<PsgcProvince>> getAllProvinces() async {
    final results = await _db.getAll(
      'SELECT DISTINCT province as name, province as code, region FROM psgc ORDER BY region, province',
    );
    return results.map((row) => PsgcProvince(
      name: row['province'] as String,
      code: row['province'] as String,
      region: row['region'] as String,
    )).toList();
  }

  /// Get municipalities/cities by province
  Future<List<PsgcMunicipality>> getMunicipalitiesByProvince(String province) async {
    final results = await _db.getAll(
      'SELECT DISTINCT mun_city as name, mun_city as displayName, province as province, region FROM psgc WHERE province = ? ORDER BY mun_city',
      [province],
    );
    return results.map((row) => PsgcMunicipality(
      name: row['mun_city'] as String,
      displayName: row['mun_city'] as String,
      province: row['province'] as String,
      region: row['region'] as String,
    )).toList();
  }

  /// Get all municipalities
  Future<List<PsgcMunicipality>> getAllMunicipalities() async {
    final results = await _db.getAll(
      'SELECT DISTINCT mun_city as name, mun_city as displayName, province as province, region FROM psgc ORDER BY region, province, mun_city',
    );
    return results.map((row) => PsgcMunicipality(
      name: row['mun_city'] as String,
      displayName: row['mun_city'] as String,
      province: row['province'] as String,
      region: row['region'] as String,
    )).toList();
  }

  /// Get barangays by municipality
  Future<List<PsgcBarangay>> getBarangaysByMunicipality(String municipality) async {
    final results = await _db.getAll(
      'SELECT id, region, province, mun_city as municipality, barangay, zip_code FROM psgc WHERE mun_city = ? ORDER BY barangay',
      [municipality],
    );
    return results.map((row) => PsgcBarangay(
      id: row['id'] as String,
      region: row['region'] as String?,
      province: row['province'] as String?,
      municipality: row['mun_city'] as String?,
      barangay: row['barangay'] as String?,
      zipCode: row['zip_code'] as String?,
    )).toList();
  }

  /// Get all barangays
  Future<List<PsgcBarangay>> getAllBarangays() async {
    final results = await _db.getAll(
      'SELECT id, region, province, mun_city as municipality, barangay, zip_code FROM psgc ORDER BY region, province, mun_city, barangay',
    );
    return results.map((row) => PsgcBarangay(
      id: row['id'] as String,
      region: row['region'] as String?,
      province: row['province'] as String?,
      municipality: row['mun_city'] as String?,
      barangay: row['barangay'] as String?,
      zipCode: row['zip_code'] as String?,
    )).toList();
  }

  /// Search municipalities by name (for autocomplete)
  Future<List<PsgcMunicipality>> searchMunicipalities(String query) async {
    final searchQuery = '%${query.toLowerCase()}%';
    final results = await _db.getAll(
      "SELECT DISTINCT mun_city as name, mun_city as displayName, province, region FROM psgc WHERE LOWER(mun_city) LIKE ? ORDER BY mun_city LIMIT 20",
      [searchQuery],
    );
    return results.map((row) => PsgcMunicipality(
      name: row['mun_city'] as String,
      displayName: row['mun_city'] as String,
      province: row['province'] as String,
      region: row['region'] as String,
    )).toList();
  }

  /// Search barangays by name (for autocomplete)
  Future<List<PsgcBarangay>> searchBarangays(String query, {String? municipality}) async {
    final searchQuery = '%${query.toLowerCase()}%';
    List<Object?> params = [searchQuery];
    String sql = "SELECT id, region, province, mun_city as municipality, barangay, zip_code FROM psgc WHERE LOWER(barangay) LIKE ?";

    if (municipality != null) {
      sql += " AND mun_city = ?";
      params.add(municipality);
    }

    sql += " ORDER BY barangay LIMIT 20";

    final results = await _db.getAll(sql, params);
    return results.map((row) => PsgcBarangay(
      id: row['id'] as String,
      region: row['region'] as String?,
      province: row['province'] as String?,
      municipality: row['mun_city'] as String?,
      barangay: row['barangay'] as String?,
      zipCode: row['zip_code'] as String?,
    )).toList();
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
