import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/services/area/area_filter_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/services/filter_preferences_service.dart';
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

    if (province != null || municipalities.isNotEmpty) {
      state = LocationFilter(
        province: province,
        municipalities: municipalities.isNotEmpty ? municipalities : null,
      );
    }
  }

  /// Update filter and persist to SharedPreferences
  void updateFilter(LocationFilter newFilter) {
    state = newFilter;
    _persistFilter(newFilter);
  }

  /// Set province and persist
  void setProvince(String? province) {
    state = state.copyWith(province: province);
    _prefs.setProvince(province);
  }

  /// Set municipalities and persist
  void setMunicipalities(List<String>? municipalities) {
    state = state.copyWith(municipalities: municipalities);
    _prefs.setMunicipalities(municipalities ?? []);
  }

  /// Clear filter and persist
  void clear() {
    state = LocationFilter.none();
    _prefs.setProvince(null);
    _prefs.setMunicipalities([]);
  }

  /// Persist filter to SharedPreferences
  void _persistFilter(LocationFilter filter) {
    _prefs.setProvince(filter.province);
    _prefs.setMunicipalities(filter.municipalities ?? []);
  }
}

/// User's assigned areas (provinces and municipalities)
/// Fetches from AreaFilterService, falls back to API if cache is empty
final assignedAreasProvider = FutureProvider<AssignedAreas>((ref) async {
  final areaFilterService = ref.watch(areaFilterServiceProvider);
  final jwtAuth = ref.watch(jwtAuthProvider);

  // Try cache first
  var locations = await areaFilterService.getCachedLocations();

  // If cache is empty, fetch from API
  if (locations.isEmpty) {
    final token = jwtAuth.accessToken;
    final userId = jwtAuth.currentUser?.id ?? '';

    if (token != null && userId.isNotEmpty) {
      try {
        locations = await areaFilterService.fetchUserLocations(token, userId);
      } catch (e) {
        // If API fetch fails, return empty areas
        return AssignedAreas(provinces: {}, municipalitiesByProvince: {});
      }
    }
  }

  if (locations.isEmpty) {
    return AssignedAreas(provinces: {}, municipalitiesByProvince: {});
  }

  // Extract unique provinces
  final provinces = locations.map((l) => l.province).toSet();

  // Group municipalities by province
  final municipalitiesByProvince = <String, Set<String>>{};
  for (final location in locations) {
    municipalitiesByProvince.putIfAbsent(location.province, () => {});
    municipalitiesByProvince[location.province]!.add(location.municipality);
  }

  return AssignedAreas(
    provinces: provinces,
    municipalitiesByProvince: municipalitiesByProvince,
  );
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
