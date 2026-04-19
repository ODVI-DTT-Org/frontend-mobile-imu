import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/psgc_models.dart';

class PsgcAssetService {
  static List<PsgcBarangay>? _cache;

  @visibleForTesting
  static void setTestData(List<PsgcBarangay> data) {
    _cache = data;
  }

  @visibleForTesting
  static void clearTestData() {
    _cache = null;
  }

  Future<void> loadIfNeeded() async {
    if (_cache != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/psgc.json');
    final list = (json.decode(jsonStr) as List)
        .map((e) => PsgcBarangay.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = list;
  }

  List<String> distinctRegions() {
    return _cache!
        .map((b) => b.region ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> provincesForRegion(String region) {
    return _cache!
        .where((b) => b.region == region)
        .map((b) => b.province ?? '')
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<PsgcMunicipality> municipalitiesForProvince(String province) {
    final seen = <String>{};
    final result = <PsgcMunicipality>[];
    for (final b in _cache!) {
      final mun = b.municipality ?? '';
      if (b.province == province && mun.isNotEmpty && seen.add(mun)) {
        result.add(PsgcMunicipality(
          name: mun,
          displayName: mun,
          province: province,
          region: b.region ?? '',
          kind: b.municipalityKind,
        ));
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<PsgcBarangay> barangaysForMunicipality(String municipality) {
    return _cache!
        .where((b) => b.municipality == municipality)
        .toList()
      ..sort((a, b) => (a.barangay ?? '').compareTo(b.barangay ?? ''));
  }

  List<PsgcMunicipality> searchMunicipalities(String query) {
    if (query.length < 2) return [];
    final q = query.toLowerCase();
    final seen = <String>{};
    final result = <PsgcMunicipality>[];
    for (final b in _cache!) {
      final mun = b.municipality ?? '';
      if (mun.toLowerCase().contains(q) && seen.add(mun)) {
        result.add(PsgcMunicipality(
          name: mun,
          displayName: mun,
          province: b.province ?? '',
          region: b.region ?? '',
          kind: b.municipalityKind,
        ));
        if (result.length >= 20) break;
      }
    }
    return result;
  }

  List<PsgcBarangay> searchBarangays(String query, {String? municipality}) {
    if (query.length < 2) return [];
    final q = query.toLowerCase();
    return _cache!
        .where((b) =>
            (b.barangay ?? '').toLowerCase().contains(q) &&
            (municipality == null || b.municipality == municipality))
        .take(20)
        .toList();
  }
}
