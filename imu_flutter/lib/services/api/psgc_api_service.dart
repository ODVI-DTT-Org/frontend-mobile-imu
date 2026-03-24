/// PSGC API Service
/// Handles all geographic data lookups using the Philippine Standard Geographic Code

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Models
class PsgcRegion {
  final String id;
  final String name;

  PsgcRegion({required this.id, required this.name});

  factory PsgcRegion.fromJson(Map<String, dynamic> json) {
    return PsgcRegion(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PsgcProvince {
  final String id;
  final String region;
  final String name;

  PsgcProvince({required this.id, required this.region, required this.name});

  factory PsgcProvince.fromJson(Map<String, dynamic> json) {
    return PsgcProvince(
      id: json['id'] ?? '',
      region: json['region'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class PsgcMunicipality {
  final String id;
  final String region;
  final String province;
  final String name;
  final String kind;
  final bool isCity;

  PsgcMunicipality({
    required this.id,
    required this.region,
    required this.province,
    required this.name,
    required this.kind,
    required this.isCity,
  });

  factory PsgcMunicipality.fromJson(Map<String, dynamic> json) {
    return PsgcMunicipality(
      id: json['id'] ?? '',
      region: json['region'] ?? '',
      province: json['province'] ?? '',
      name: json['name'] ?? '',
      kind: json['kind'] ?? '',
      isCity: json['isCity'] ?? false,
    );
  }
}

class PsgcBarangay {
  final int id;
  final String region;
  final String province;
  final String municipality;
  final String barangay;
  final Map<String, dynamic>? pinLocation;
  final String? zipCode;

  PsgcBarangay({
    required this.id,
    required this.region,
    required this.province,
    required this.municipality,
    required this.barangay,
    this.pinLocation,
    this.zipCode,
  });

  factory PsgcBarangay.fromJson(Map<String, dynamic> json) {
    return PsgcBarangay(
      id: json['id'] ?? 0,
      region: json['region'] ?? '',
      province: json['province'] ?? '',
      municipality: json['municipality'] ?? '',
      barangay: json['barangay'] ?? '',
      pinLocation: json['pinLocation'],
      zipCode: json['zipCode'],
    );
  }

  String get fullAddress => '$barangay, $municipality, $province, $region';
}

class PsgcSearchResult {
  final String type;
  final dynamic id;
  final String name;
  final String label;
  final String? region;
  final String? province;
  final String? municipality;
  final String? zipCode;

  PsgcSearchResult({
    required this.type,
    required this.id,
    required this.name,
    required this.label,
    this.region,
    this.province,
    this.municipality,
    this.zipCode,
  });

  factory PsgcSearchResult.fromJson(Map<String, dynamic> json) {
    return PsgcSearchResult(
      type: json['type'] ?? '',
      id: json['id'],
      name: json['name'] ?? '',
      label: json['label'] ?? '',
      region: json['region'],
      province: json['province'],
      municipality: json['municipality'],
      zipCode: json['zipCode'],
    );
  }
}

// Service
class PsgcApiService {
  final String baseUrl;
  final String? authToken;

  PsgcApiService({required this.baseUrl, this.authToken});

  Map<String, String> get _headers => {
    if (authToken != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
    }
    return {'Content-Type': 'application/json'};
  }

  /// Get all regions
  Future<List<PsgcRegion>> getRegions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/psgc/regions'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((e) => PsgcRegion.fromJson(e)).toList();
    }
    throw Exception('Failed to load regions');
  }

  /// Get provinces (optionally filtered by region)
  Future<List<PsgcProvince>> getProvinces({String? region}) async {
    var url = '$baseUrl/api/psgc/provinces';
    if (region != null) {
      url += '?region=${Uri.encodeQueryComponent(region)}';
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((e) => PsgcProvince.fromJson(e)).toList();
    }
    throw Exception('Failed to load provinces');
  }

  /// Get municipalities (optionally filtered)
  Future<List<PsgcMunicipality>> getMunicipalities({
    String? region,
    String? province,
  }) async {
    final params = <String, String>{};
    if (region != null) params['region'] = region;
    if (province != null) params['province'] = province;

    var url = '$baseUrl/api/psgc/municipalities';
    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
    }

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((e) => PsgcMunicipality.fromJson(e)).toList();
    }
    throw Exception('Failed to load municipalities');
  }

  /// Get barangays with filtering and pagination
  Future<Map<String, dynamic>> getBarangays({
    String? region,
    String? province,
    String? municipality,
    String? search,
    int page = 1,
    int perPage = 100,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'perPage': perPage.toString(),
    };
    if (region != null) params['region'] = region;
    if (province != null) params['province'] = province;
    if (municipality != null) params['municipality'] = municipality;
    if (search != null) params['search'] = search;

    final url = '$baseUrl/api/psgc/barangays?' +
        params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = (data['items'] as List).map((e) => PsgcBarangay.fromJson(e)).toList();
      return {
        'items': items,
        'page': data['page'],
        'perPage': data['perPage'],
        'totalItems': data['totalItems'],
        'totalPages': data['totalPages'],
      };
    }
    throw Exception('Failed to load barangays');
  }

  /// Search across all PSGC levels
  Future<List<PsgcSearchResult>> search(
    String query, {
    String level = 'all',
    int limit = 20,
  }) async {
    if (query.length < 2) return [];

    final url = '$baseUrl/api/psgc/search?q=${Uri.encodeQueryComponent(query)}&level=$level&limit=$limit';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'] as List;
      return items.map((e) => PsgcSearchResult.fromJson(e)).toList();
    }
    throw Exception('Search failed');
  }

  /// Get single barangay by ID
  Future<PsgcBarangay> getBarangayById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/psgc/barangays/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PsgcBarangay.fromJson(json.decode(response.body));
    }
    throw Exception('Barangay not found');
  }
}

// Provider
final psgcApiServiceProvider = Provider<PsgcApiService>((ref) {
  // Get base URL from environment or use default
  const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000');
  // In production, get auth token from secure storage
  return PsgcApiService(baseUrl: baseUrl);
});

// State providers
final psgcRegionsProvider = FutureProvider<List<PsgcRegion>>((ref) async {
  final service = ref.watch(psgcApiServiceProvider);
  return await service.getRegions();
});

final psgcProvincesProvider = FutureProvider.family<List<PsgcProvince>, String?>((ref, region) async {
  final service = ref.watch(psgcApiServiceProvider);
  return await service.getProvinces(region: region);
});

final psgcMunicipalitiesProvider = FutureProvider.family<List<PsgcMunicipality>, ({String? region, String? province})>((ref, params) async {
  final service = ref.watch(psgcApiServiceProvider);
  return await service.getMunicipalities(region: params.region, province: params.province);
});

final psgcBarangaysProvider = FutureProvider.family<Map<String, dynamic>, ({String? region, String? province, String? municipality, int page, int perPage})>((ref, params) async {
  final service = ref.watch(psgcApiServiceProvider);
  return await service.getBarangays(
    region: params.region,
    province: params.province,
    municipality: params.municipality,
    page: params.page,
    perPage: params.perPage,
  );
});

final psgcSearchProvider = FutureProvider.family<List<PsgcSearchResult>, String>((ref, query) async {
  if (query.length < 2) return [];
  final service = ref.watch(psgcApiServiceProvider);
  return await service.search(query);
});
