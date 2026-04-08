import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/services/area/area_filter_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;

/// Active location filter state
/// Auto-disposes when navigating away from pages that use it
final locationFilterProvider = StateProvider<LocationFilter>((ref) {
  return LocationFilter.none();
});

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
