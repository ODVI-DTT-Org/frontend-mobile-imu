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
  static const String _keyLoanType = 'filter_loan_type';

  // Touchpoint filter key
  static const String _keyTouchpointNumbers = 'filter_touchpoint_numbers';

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
  // CLIENT ATTRIBUTE FILTERS (multi-select lists)
  // ============================================

  /// Client Types Filter (multi-select)
  Future<List<String>> getClientTypes() async {
    await init();
    final jsonStr = _prefs?.getString(_keyClientType);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return (json.decode(jsonStr) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setClientTypes(List<String> values) async {
    await init();
    if (values.isEmpty) {
      await _prefs?.remove(_keyClientType);
    } else {
      await _prefs?.setString(_keyClientType, json.encode(values));
    }
  }

  /// Market Types Filter (multi-select)
  Future<List<String>> getMarketTypes() async {
    await init();
    final jsonStr = _prefs?.getString(_keyMarketType);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return (json.decode(jsonStr) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setMarketTypes(List<String> values) async {
    await init();
    if (values.isEmpty) {
      await _prefs?.remove(_keyMarketType);
    } else {
      await _prefs?.setString(_keyMarketType, json.encode(values));
    }
  }

  /// Pension Types Filter (multi-select)
  Future<List<String>> getPensionTypes() async {
    await init();
    final jsonStr = _prefs?.getString(_keyPensionType);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return (json.decode(jsonStr) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setPensionTypes(List<String> values) async {
    await init();
    if (values.isEmpty) {
      await _prefs?.remove(_keyPensionType);
    } else {
      await _prefs?.setString(_keyPensionType, json.encode(values));
    }
  }

  /// Product Types Filter (multi-select)
  Future<List<String>> getProductTypes() async {
    await init();
    final jsonStr = _prefs?.getString(_keyProductType);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return (json.decode(jsonStr) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setProductTypes(List<String> values) async {
    await init();
    if (values.isEmpty) {
      await _prefs?.remove(_keyProductType);
    } else {
      await _prefs?.setString(_keyProductType, json.encode(values));
    }
  }

  /// Loan Types Filter (multi-select)
  Future<List<String>> getLoanTypes() async {
    await init();
    final jsonStr = _prefs?.getString(_keyLoanType);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      return (json.decode(jsonStr) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> setLoanTypes(List<String> values) async {
    await init();
    if (values.isEmpty) {
      await _prefs?.remove(_keyLoanType);
    } else {
      await _prefs?.setString(_keyLoanType, json.encode(values));
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
    await _prefs?.remove(_keyLoanType);
    // Touchpoint filter
    await _prefs?.remove(_keyTouchpointNumbers);
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
    await _prefs?.remove(_keyLoanType);
  }

  // ============================================
  // TOUCHPOINT FILTER
  // ============================================

  /// Touchpoint Numbers Filter (1–7 = touchpoint positions, 8 = archive)
  List<int> getTouchpointNumbers() {
    final jsonString = _prefs?.getString(_keyTouchpointNumbers);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<int>();
    } catch (e) {
      return [];
    }
  }

  Future<void> setTouchpointNumbers(List<int> value) async {
    await init();
    if (value.isEmpty) {
      await _prefs?.remove(_keyTouchpointNumbers);
    } else {
      await _prefs?.setString(_keyTouchpointNumbers, json.encode(value));
    }
  }

  /// Check if any filters are active
  Future<bool> hasActiveFilters() async {
    final assignedOnly = await getAssignedOnly();
    final province = getProvince();
    final municipalities = getMunicipalities();
    final clientTypes = await getClientTypes();
    final marketTypes = await getMarketTypes();
    final pensionTypes = await getPensionTypes();
    final productTypes = await getProductTypes();

    return assignedOnly ||
        (province?.isNotEmpty ?? false) ||
        municipalities.isNotEmpty ||
        clientTypes.isNotEmpty ||
        marketTypes.isNotEmpty ||
        pensionTypes.isNotEmpty ||
        productTypes.isNotEmpty;
  }

  /// Get count of active filters
  Future<int> getActiveFilterCount() async {
    int count = 0;

    if (await getAssignedOnly()) count++;
    if (getProvince()?.isNotEmpty ?? false) count++;
    if (getMunicipalities().isNotEmpty) count++;
    count += (await getClientTypes()).length;
    count += (await getMarketTypes()).length;
    count += (await getPensionTypes()).length;
    count += (await getProductTypes()).length;

    return count;
  }

  /// Get all filter values as a map (useful for debugging/restore)
  Future<Map<String, dynamic>> getAllFilters() async {
    await init();
    return {
      'assigned_only': await getAssignedOnly(),
      'province': getProvince(),
      'municipalities': getMunicipalities(),
      'client_types': await getClientTypes(),
      'market_types': await getMarketTypes(),
      'pension_types': await getPensionTypes(),
      'product_types': await getProductTypes(),
    };
  }
}
