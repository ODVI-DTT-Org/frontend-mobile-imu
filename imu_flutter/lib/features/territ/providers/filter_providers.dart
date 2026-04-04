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

/// Provider that watches user's assigned locations from PowerSync
/// Connects to the user_locations table and returns location keys (province-municipality)
final userAssignedLocationsWatchProvider = StreamProvider<Set<String>>((ref) {
  // Get the current user's ID from auth service
  final authService = ref.watch(authServiceProvider);
  final userId = authService.currentUserId;

  if (userId == null || userId.isEmpty) {
    logDebug('User ID is null, returning empty location set');
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
        'SELECT DISTINCT province, municipality FROM user_locations WHERE user_id = ? AND deleted_at IS NULL',
        parameters: [userId],
      );

      // Listen to the stream and emit location key sets
      stream.listen(
        (results) {
          final locationKeys = <String>{};

          // Construct "province-municipality" keys
          for (final row in results) {
            final province = row['province'] as String?;
            final municipality = row['municipality'] as String?;
            if (province != null && municipality != null) {
              locationKeys.add('$province-$municipality');
            }
          }

          logDebug('Found ${locationKeys.length} assigned locations for user $userId: $locationKeys');
          controller.add(locationKeys);
        },
        onError: (e) {
          logError('Error watching user locations', e);
          controller.add(<String>{});
        },
      );
    } catch (e) {
      logError('Error initializing location watch', e);
      controller.add(<String>{});
    }
  }

  // Start watching
  initWatch();

  // Return the stream
  return controller.stream;
});

/// Provider for the current set of assigned location keys (convenience wrapper)
final currentAssignedLocationKeysProvider = Provider<Set<String>>((ref) {
  final asyncValue = ref.watch(userAssignedLocationsWatchProvider);
  return asyncValue.value ?? {};
});

/// Legacy provider aliases for backward compatibility
final userAssignedMunicipalitiesWatchProvider = userAssignedLocationsWatchProvider;
final currentAssignedMunicipalityIdsProvider = currentAssignedLocationKeysProvider;
