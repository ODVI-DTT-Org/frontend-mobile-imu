import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/services/area/area_filter_service.dart';

/// Active location filter state
/// Auto-disposes when navigating away from pages that use it
final locationFilterProvider = StateProvider<LocationFilter>((ref) {
  return LocationFilter.none();
});

/// User's assigned areas (provinces and municipalities)
/// Fetches from AreaFilterService which uses cached data
final assignedAreasProvider = FutureProvider<AssignedAreas>((ref) async {
  final areaFilterService = ref.watch(areaFilterServiceProvider);
  final locations = await areaFilterService.getCachedLocations();

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
