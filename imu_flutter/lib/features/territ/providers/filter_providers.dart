import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter mode - controls whether user is filtering by assigned municipalities or viewing all clients
enum FilterMode { all, assigned }

/// Provider for filter mode state
final filterModeProvider = StateProvider<FilterMode>((ref) {
  return FilterMode.all;
});

/// Provider for assigned municipality IDs (set of municipality IDs)
final assignedMunicipalityIdsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Provider that watches user's assigned municipalities from PowerSync
/// This will be connected to the user_municipalities_simple table
final userAssignedMunicipalitiesWatchProvider = StreamProvider<Set<String>>((ref) {
  // TODO: Connect to PowerSync user_municipalities_simple table
  // For now, return empty stream until PowerSync integration is complete
  return Stream.value({});
});
