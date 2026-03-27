import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

/// Filter mode - controls whether user is filtering by assigned municipalities or viewing all clients
enum FilterMode { all, assigned }

/// Provider for filter mode state
final filterModeProvider = StateProvider<FilterMode>((ref) {
  return FilterMode.all;
});

/// Provider for selected municipality ID (for filtering clients)
final selectedMunicipalityIdProvider = StateProvider<String?>((ref) {
  return null;
});

/// Client view mode - controls whether user sees "my clients" or "all clients"
enum ClientViewMode { myClients, allClients }

/// Provider for client view mode state
final clientViewModeProvider = StateProvider<ClientViewMode>((ref) {
  return ClientViewMode.myClients; // Default to "my clients"
});

/// Provider for current user's ID (for filtering "my clients")
final currentUserIdProvider = Provider<String?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUserId;
});

/// Provider that watches user's assigned municipalities from PowerSync
/// Connects to the user_municipalities_simple table and returns municipality IDs
final userAssignedMunicipalitiesWatchProvider = StreamProvider<Set<String>>((ref) {
  // Get the current user's ID from auth service
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;

  if (userId == null || userId.isEmpty) {
    logDebug('User ID is null, returning empty municipality set');
    return Stream.value({});
  }

  // Create a stream controller to handle the watch stream
  final controller = StreamController<Set<String>>();

  // Initialize the stream
  Future<void> initWatch() async {
    try {
      final db = await PowerSyncService.database;

      // Use PowerSync's watch method to get real-time updates
      final stream = db.watch(
        'SELECT DISTINCT municipality_id FROM user_municipalities_simple WHERE user_id = ? AND deleted_at IS NULL',
        parameters: [userId],
      );

      // Listen to the stream and emit municipality ID sets
      stream.listen(
        (results) {
          final municipalityIds = results
              .map((row) => row['municipality_id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet();

          logDebug('Found ${municipalityIds.length} assigned municipalities for user $userId: $municipalityIds');
          controller.add(municipalityIds);
        },
        onError: (e) {
          logError('Error watching user municipalities', e);
          controller.add(<String>{});
        },
      );
    } catch (e) {
      logError('Error initializing municipality watch', e);
      controller.add(<String>{});
    }
  }

  // Start watching
  initWatch();

  // Return the stream
  return controller.stream;
});

/// Provider for the current set of assigned municipality IDs (convenience wrapper)
final currentAssignedMunicipalityIdsProvider = Provider<Set<String>>((ref) {
  final asyncValue = ref.watch(userAssignedMunicipalitiesWatchProvider);
  return asyncValue.value ?? {};
});
