import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/powersync_service.dart';
import '../../shared/providers/app_providers.dart' show isOnlineProvider, clientApiServiceProvider;
import '../../features/clients/data/models/client_model.dart';

/// Service for fetching touchpoint counts for multiple clients
/// Uses PowerSync as primary source with API fallback
class TouchpointCountService {
  final Ref _ref;

  TouchpointCountService(this._ref);

  /// Fetch touchpoint counts from PowerSync using Client.touchpointNumber
  Future<Map<String, int>> fetchFromPowerSync(List<String> clientIds) async {
    if (clientIds.isEmpty) return {};

    final counts = <String, int>{};

    for (final clientId in clientIds) {
      // Query client from PowerSync
      final results = await PowerSyncService.query(
        'SELECT * FROM clients WHERE id = ?',
        [clientId],
      );

      if (results.isNotEmpty) {
        final client = Client.fromRow(results.first);
        // touchpointNumber is next number, so completed = touchpointNumber - 1
        counts[clientId] = client.completedTouchpoints;
      } else {
        counts[clientId] = 0;
      }
    }

    return counts;
  }

  /// Fetch touchpoint counts from REST API as fallback
  Future<Map<String, int>> fetchFromAPI(List<String> clientIds) async {
    if (clientIds.isEmpty) return {};

    try {
      final clientApi = _ref.read(clientApiServiceProvider);

      // Fetch clients by IDs (this endpoint includes touchpoint info)
      final response = await clientApi.fetchClientsByIds(clientIds);

      final counts = <String, int>{};
      for (final client in response.items) {
        if (client.id != null) {
          // Use completedTouchpoints which is touchpointNumber - 1
          counts[client.id!] = client.completedTouchpoints;
        }
      }

      // Ensure all requested client IDs are in the result
      for (final clientId in clientIds) {
        counts.putIfAbsent(clientId, () => 0);
      }

      return counts;
    } catch (e) {
      debugPrint('TouchpointCountService: API fallback failed: $e');
      rethrow;
    }
  }

  /// Main fetch method with PowerSync-first, API fallback
  Future<Map<String, int>> fetchCounts(List<String> clientIds) async {
    if (clientIds.isEmpty) return {};

    try {
      // Try PowerSync first
      final counts = await fetchFromPowerSync(clientIds);
      return counts;
    } catch (e) {
      debugPrint('TouchpointCountService: PowerSync query failed: $e');

      // Fallback to API if online
      final isOnline = _ref.read(isOnlineProvider);
      if (isOnline) {
        try {
          final apiCounts = await fetchFromAPI(clientIds);
          return apiCounts;
        } catch (apiError) {
          debugPrint('TouchpointCountService: API fallback failed: $apiError');
        }
      }

      // Return empty map if all fails
      return {};
    }
  }
}

/// Provider for TouchpointCountService instance
final touchpointCountServiceProvider = Provider<TouchpointCountService>((ref) {
  return TouchpointCountService(ref);
});
