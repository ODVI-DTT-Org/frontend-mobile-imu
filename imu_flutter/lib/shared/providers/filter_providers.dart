import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter mode enum
enum FilterMode { all, assigned }

/// Filter mode provider - controls whether user is filtering by assigned municipalities
final filterModeProvider = StateProvider<FilterMode>((ref) {
  return FilterMode.all;
});

/// Assigned municipalities provider
final assignedMunicipalitiesProvider = StateProvider<List<String>>((ref) {
  return [];
});
