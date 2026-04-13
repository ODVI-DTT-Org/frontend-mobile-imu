import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for persisting and retrieving filter preferences
/// Used to remember user's filter choices across app sessions
class FilterPreferencesService {
  // Location filter keys
  static const String _keyAssignedOnly = 'filter_assigned_only';
  static const String _keyProvince = 'filter_province';
  static const String _keyMunicipalities = 'filter_municipalities'; // Changed to support list

  // Client attribute filter keys
  static const String _keyClientType = 'filter_client_type';
  static const String _keyMarketType = 'filter_market_type';
  static const String _keyPensionType = 'filter_pension_type';
  static const String _keyProductType = 'filter_product_type';

  /// Get singleton instance
  static final FilterPreferencesService _instance = FilterPreferencesService._internal();
  factory FilterPreferencesService() => _instance;
  FilterPreferencesService._internal();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ============================================
  // LOCATION FILTERS
  // ============================================

  /// Assigned Only Filter
  Future<bool> getAssignedOnly() async {
    await init();
    return _prefs?.getBool(_keyAssignedOnly) ?? false;
  }

  Future<void> setAssignedOnly(bool value) async {
    await init();
    await _prefs?.setBool(_keyAssignedOnly, value);
  }

  /// Province Filter
  String? getProvince() {
    return _prefs?.getString(_keyProvince);
  }

  Future<void> setProvince(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyProvince);
    } else {
      await _prefs?.setString(_keyProvince, value);
    }
  }

  /// Municipality Filter (supports multiple municipalities)
  List<String> getMunicipalities() {
    final jsonString = _prefs?.getString(_keyMunicipalities);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<String>();
    } catch (e) {
      return [];
    }
  }

  Future<void> setMunicipalities(List<String> value) async {
    await init();
    if (value.isEmpty) {
      await _prefs?.remove(_keyMunicipalities);
    } else {
      await _prefs?.setString(_keyMunicipalities, json.encode(value));
    }
  }

  // ============================================
  // CLIENT ATTRIBUTE FILTERS
  // ============================================

  /// Client Type Filter
  String? getClientType() {
    return _prefs?.getString(_keyClientType);
  }

  Future<void> setClientType(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyClientType);
    } else {
      await _prefs?.setString(_keyClientType, value);
    }
  }

  /// Market Type Filter
  String? getMarketType() {
    return _prefs?.getString(_keyMarketType);
  }

  Future<void> setMarketType(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyMarketType);
    } else {
      await _prefs?.setString(_keyMarketType, value);
    }
  }

  /// Pension Type Filter
  String? getPensionType() {
    return _prefs?.getString(_keyPensionType);
  }

  Future<void> setPensionType(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyPensionType);
    } else {
      await _prefs?.setString(_keyPensionType, value);
    }
  }

  /// Product Type Filter
  String? getProductType() {
    return _prefs?.getString(_keyProductType);
  }

  Future<void> setProductType(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyProductType);
    } else {
      await _prefs?.setString(_keyProductType, value);
    }
  }

  // ============================================
  // BULK OPERATIONS
  // ============================================

  /// Clear all filter preferences
  Future<void> clearAll() async {
    await init();
    // Location filters
    await _prefs?.remove(_keyAssignedOnly);
    await _prefs?.remove(_keyProvince);
    await _prefs?.remove(_keyMunicipalities);
    // Client attribute filters
    await _prefs?.remove(_keyClientType);
    await _prefs?.remove(_keyMarketType);
    await _prefs?.remove(_keyPensionType);
    await _prefs?.remove(_keyProductType);
  }

  /// Clear only location filters
  Future<void> clearLocationFilters() async {
    await init();
    await _prefs?.remove(_keyAssignedOnly);
    await _prefs?.remove(_keyProvince);
    await _prefs?.remove(_keyMunicipalities);
  }

  /// Clear only client attribute filters
  Future<void> clearAttributeFilters() async {
    await init();
    await _prefs?.remove(_keyClientType);
    await _prefs?.remove(_keyMarketType);
    await _prefs?.remove(_keyPensionType);
    await _prefs?.remove(_keyProductType);
  }

  /// Check if any filters are active
  Future<bool> hasActiveFilters() async {
    final assignedOnly = await getAssignedOnly();
    final province = getProvince();
    final municipalities = getMunicipalities();
    final clientType = getClientType();
    final marketType = getMarketType();
    final pensionType = getPensionType();
    final productType = getProductType();

    return assignedOnly ||
        (province?.isNotEmpty ?? false) ||
        municipalities.isNotEmpty ||
        (clientType?.isNotEmpty ?? false) ||
        (marketType?.isNotEmpty ?? false) ||
        (pensionType?.isNotEmpty ?? false) ||
        (productType?.isNotEmpty ?? false);
  }

  /// Get count of active filters
  Future<int> getActiveFilterCount() async {
    int count = 0;

    if (await getAssignedOnly()) count++;
    if (getProvince()?.isNotEmpty ?? false) count++;
    if (getMunicipalities().isNotEmpty) count++;
    if (getClientType()?.isNotEmpty ?? false) count++;
    if (getMarketType()?.isNotEmpty ?? false) count++;
    if (getPensionType()?.isNotEmpty ?? false) count++;
    if (getProductType()?.isNotEmpty ?? false) count++;

    return count;
  }

  /// Get all filter values as a map (useful for debugging/restore)
  Future<Map<String, dynamic>> getAllFilters() async {
    await init();
    return {
      'assigned_only': await getAssignedOnly(),
      'province': getProvince(),
      'municipalities': getMunicipalities(),
      'client_type': getClientType(),
      'market_type': getMarketType(),
      'pension_type': getPensionType(),
      'product_type': getProductType(),
    };
  }
}
