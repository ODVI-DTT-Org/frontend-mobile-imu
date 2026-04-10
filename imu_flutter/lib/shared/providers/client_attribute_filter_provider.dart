// lib/shared/providers/client_attribute_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_attribute_filter.dart';
import 'location_filter_providers.dart' show locationFilterProvider;

/// Active client attribute filter state (session-only, no persistence)
/// Auto-disposes when navigating away from pages that use it
final clientAttributeFilterProvider =
    StateProvider<ClientAttributeFilter>((ref) {
  return ClientAttributeFilter.none();
});

/// Total count of active filters (location + attributes)
/// Used for badge display on filter icons
final activeFilterCountProvider = Provider<int>((ref) {
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);

  int count = 0;

  // Count location filters
  if (locationFilter.province != null) {
    count += 1;
    if (locationFilter.municipalities != null &&
        locationFilter.municipalities!.isNotEmpty) {
      count += locationFilter.municipalities!.length;
    }
  }

  // Count attribute filters
  count += attributeFilter.activeFilterCount;

  return count;
});
