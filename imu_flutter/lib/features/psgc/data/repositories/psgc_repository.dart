import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/psgc_models.dart';

/// Repository for PSGC geographic data — fetches from REST API.
/// The psgc table was removed from PowerSync; data is served by the backend.
class PsgcRepository {
  final String _baseUrl;

  PsgcRepository(this._baseUrl);

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<List<PsgcRegion>> getRegions() async {
    final res = await http.get(Uri.parse('$_baseUrl/psgc/regions'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load regions');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcRegion(
      name: e['name'] ?? '',
      code: e['name'] ?? '',
    )).toList();
  }

  Future<List<PsgcProvince>> getProvincesByRegion(String region) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/psgc/provinces?region=${Uri.encodeQueryComponent(region)}'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load provinces');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcProvince(
      name: e['name'] ?? '',
      code: e['name'] ?? '',
      region: e['region'] ?? region,
    )).toList();
  }

  Future<List<PsgcProvince>> getAllProvinces() async {
    final res = await http.get(Uri.parse('$_baseUrl/psgc/provinces'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load provinces');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcProvince(
      name: e['name'] ?? '',
      code: e['name'] ?? '',
      region: e['region'] ?? '',
    )).toList();
  }

  Future<List<PsgcMunicipality>> getMunicipalitiesByProvince(String province) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/psgc/municipalities?province=${Uri.encodeQueryComponent(province)}'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load municipalities');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) {
      final name = e['name'] ?? '';
      return PsgcMunicipality(
        name: name,
        displayName: name,
        province: e['province'] ?? province,
        region: e['region'] ?? '',
      );
    }).toList();
  }

  Future<List<PsgcMunicipality>> getAllMunicipalities() async {
    final res = await http.get(Uri.parse('$_baseUrl/psgc/municipalities'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to load municipalities');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) {
      final name = e['name'] ?? '';
      return PsgcMunicipality(
        name: name,
        displayName: name,
        province: e['province'] ?? '',
        region: e['region'] ?? '',
      );
    }).toList();
  }

  Future<List<PsgcBarangay>> getBarangaysByMunicipality(String municipality) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/psgc/barangays?municipality=${Uri.encodeQueryComponent(municipality)}&perPage=500'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load barangays');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcBarangay.fromJson(e)).where((b) => b.barangay != null && b.barangay!.isNotEmpty).toList();
  }

  Future<List<PsgcBarangay>> getAllBarangays() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/psgc/barangays?perPage=1000'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Failed to load barangays');
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcBarangay.fromJson(e)).where((b) => b.barangay != null && b.barangay!.isNotEmpty).toList();
  }

  Future<List<PsgcMunicipality>> searchMunicipalities(String query) async {
    if (query.length < 2) return [];
    final res = await http.get(
      Uri.parse('$_baseUrl/psgc/search?q=${Uri.encodeQueryComponent(query)}&level=municipality&limit=20'),
      headers: _headers,
    );
    if (res.statusCode != 200) return [];
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) {
      final name = e['name'] ?? '';
      return PsgcMunicipality(
        name: name,
        displayName: name,
        province: e['province'] ?? '',
        region: e['region'] ?? '',
      );
    }).toList();
  }

  Future<List<PsgcBarangay>> searchBarangays(String query, {String? municipality}) async {
    if (query.length < 2) return [];
    var url = '$_baseUrl/psgc/search?q=${Uri.encodeQueryComponent(query)}&level=barangay&limit=20';
    if (municipality != null) url += '&municipality=${Uri.encodeQueryComponent(municipality)}';
    final res = await http.get(Uri.parse(url), headers: _headers);
    if (res.statusCode != 200) return [];
    final items = (json.decode(res.body)['items'] as List?) ?? [];
    return items.map((e) => PsgcBarangay.fromJson(e)).where((b) => b.barangay != null && b.barangay!.isNotEmpty).toList();
  }
}

/// Provider for PSGC repository
final psgcRepositoryProvider = Provider<PsgcRepository>((ref) {
  final baseUrl = AppConfig.postgresApiUrl;
  return PsgcRepository(baseUrl);
});

/// Provider for all regions
final regionsProvider = FutureProvider<List<PsgcRegion>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getRegions();
});

/// Provider for all provinces
final provincesProvider = FutureProvider<List<PsgcProvince>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getAllProvinces();
});

/// Provider for all municipalities
final municipalitiesProvider = FutureProvider<List<PsgcMunicipality>>((ref) async {
  return ref.watch(psgcRepositoryProvider).getAllMunicipalities();
});

/// Family provider for provinces by region
final provincesByRegionProvider = FutureProvider.family<List<PsgcProvince>, String>((ref, region) async {
  return ref.watch(psgcRepositoryProvider).getProvincesByRegion(region);
});

/// Family provider for municipalities by province
final municipalitiesByProvinceProvider = FutureProvider.family<List<PsgcMunicipality>, String>((ref, province) async {
  return ref.watch(psgcRepositoryProvider).getMunicipalitiesByProvince(province);
});

/// Family provider for barangays by municipality
final barangaysByMunicipalityProvider = FutureProvider.family<List<PsgcBarangay>, String>((ref, municipality) async {
  return ref.watch(psgcRepositoryProvider).getBarangaysByMunicipality(municipality);
});
