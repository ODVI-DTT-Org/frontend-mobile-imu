import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and retrieving filter preferences
/// Used to remember user's filter choices across app sessions
class FilterPreferencesService {
  static const String _keyAssignedOnly = 'filter_assigned_only';
  static const String _keyProvince = 'filter_province';
  static const String _keyMunicipality = 'filter_municipality';

  /// Get singleton instance
  static final FilterPreferencesService _instance = FilterPreferencesService._internal();
  factory FilterPreferencesService() => _instance;
  FilterPreferencesService._internal();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Assigned Only Filter
  Future<bool> getAssignedOnly() async {
    await init();
    return _prefs?.getBool(_keyAssignedOnly) ?? false;
  }

  Future<void> setAssignedOnly(bool value) async {
    await init();
    await _prefs?.setBool(_keyAssignedOnly, value);
  }

  // Province Filter
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

  // Municipality Filter
  String? getMunicipality() {
    return _prefs?.getString(_keyMunicipality);
  }

  Future<void> setMunicipality(String? value) async {
    await init();
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_keyMunicipality);
    } else {
      await _prefs?.setString(_keyMunicipality, value);
    }
  }

  /// Clear all filter preferences
  Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_keyAssignedOnly);
    await _prefs?.remove(_keyProvince);
    await _prefs?.remove(_keyMunicipality);
  }

  /// Check if any filters are active
  Future<bool> hasActiveFilters() async {
    final assignedOnly = await getAssignedOnly();
    final province = getProvince();
    final municipality = getMunicipality();
    return assignedOnly || (province?.isNotEmpty ?? false) || (municipality?.isNotEmpty ?? false);
  }
}
