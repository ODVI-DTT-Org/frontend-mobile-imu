import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/services/filter_preferences_service.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Active location filter state with persistence
/// Loads from SharedPreferences on initialization, saves on change
final locationFilterProvider = StateNotifierProvider<LocationFilterNotifier, LocationFilter>((ref) {
  return LocationFilterNotifier();
});

/// Notifier for location filter with persistence support
class LocationFilterNotifier extends StateNotifier<LocationFilter> {
  final FilterPreferencesService _prefs = FilterPreferencesService();

  LocationFilterNotifier() : super(LocationFilter.none()) {
    _loadFromPreferences();
  }

  /// Load saved filter from SharedPreferences
  Future<void> _loadFromPreferences() async {
    final province = _prefs.getProvince();
    final municipalities = _prefs.getMunicipalities();
    final barangays = _prefs.getBarangays();
    final addressQuery = _prefs.getAddressQuery();

    if (province != null ||
        municipalities.isNotEmpty ||
        barangays.isNotEmpty ||
        (addressQuery != null && addressQuery.trim().isNotEmpty)) {
      state = LocationFilter(
        province: province,
        municipalities: municipalities.isNotEmpty ? municipalities : null,
        barangays: barangays.isNotEmpty ? barangays : null,
        addressQuery: addressQuery,
      );
    }
  }

  /// Update filter and persist to SharedPreferences
  void updateFilter(LocationFilter newFilter) {
    state = newFilter;
    _persistFilter(newFilter);
  }

  /// Set province and persist — clears municipalities since they belong to the old province
  void setProvince(String? province) {
    state = LocationFilter(province: province, addressQuery: state.addressQuery);
    _prefs.setProvince(province);
    _prefs.setMunicipalities([]);
    _prefs.setBarangays([]);
  }

  /// Set municipalities and persist
  void setMunicipalities(List<String>? municipalities) {
    state = state.copyWith(municipalities: municipalities, barangays: null);
    _prefs.setMunicipalities(municipalities ?? []);
    _prefs.setBarangays([]);
  }

  void setBarangays(List<String>? barangays) {
    state = state.copyWith(barangays: barangays);
    _prefs.setBarangays(barangays ?? []);
  }

  void setAddressQuery(String? addressQuery) {
    state = state.copyWith(
      addressQuery: addressQuery == null || addressQuery.trim().isEmpty
          ? null
          : addressQuery.trim(),
    );
    _prefs.setAddressQuery(state.addressQuery);
  }

  /// Clear filter and persist
  void clear() {
    state = LocationFilter.none();
    _prefs.setProvince(null);
    _prefs.setMunicipalities([]);
    _prefs.setBarangays([]);
    _prefs.setAddressQuery(null);
  }

  /// Persist filter to SharedPreferences
  void _persistFilter(LocationFilter filter) {
    _prefs.setProvince(filter.province);
    _prefs.setMunicipalities(filter.municipalities ?? []);
    _prefs.setBarangays(filter.barangays ?? []);
    _prefs.setAddressQuery(filter.addressQuery);
  }
}

/// User's assigned areas (provinces and municipalities)
/// Streams directly from the PowerSync user_locations table so it updates
/// automatically when user_locations syncs from the backend.
final assignedAreasProvider = StreamProvider<AssignedAreas>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  final userId = jwtAuth.currentUser?.id ?? '';

  if (userId.isEmpty) {
    return Stream.value(AssignedAreas(provinces: {}, municipalitiesByProvince: {}));
  }

  return PowerSyncService.database.asStream().asyncExpand((db) {
    return db.watch(
      'SELECT DISTINCT province, municipality FROM user_locations WHERE user_id = ? AND deleted_at IS NULL',
      parameters: [userId],
    ).map((rows) {
      final provinces = <String>{};
      final municipalitiesByProvince = <String, Set<String>>{};
      for (final row in rows) {
        final province = row['province'] as String?;
        final municipality = row['municipality'] as String?;
        if (province == null || municipality == null) continue;
        provinces.add(province);
        municipalitiesByProvince.putIfAbsent(province, () => {});
        municipalitiesByProvince[province]!.add(municipality);
      }
      return AssignedAreas(
        provinces: provinces,
        municipalitiesByProvince: municipalitiesByProvince,
      );
    });
  });
});

class AssignedAreas {
  final Set<String> provinces;
  final Map<String, Set<String>> municipalitiesByProvince;

  const AssignedAreas({
    required this.provinces,
    required this.municipalitiesByProvince,
  });

  List<String> getMunicipalities(String province) {
    return municipalitiesByProvince[province]?.toList() ?? [];
  }

  bool get hasAreas => provinces.isNotEmpty;
}
