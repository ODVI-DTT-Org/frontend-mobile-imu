import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../sync/powersync_service.dart';
import '../../shared/providers/app_providers.dart' show isOnlineProvider, clientApiServiceProvider;

/// Service for fetching touchpoint counts for multiple clients
/// Uses PowerSync as primary source with API fallback
class TouchpointCountService {
  final Ref _ref;

  TouchpointCountService(this._ref);

  /// Fetch touchpoint counts from PowerSync using batch query
  Future<Map<String, int>> fetchFromPowerSync(List<String> clientIds) async {
    if (clientIds.isEmpty) return {};

    final placeholders = clientIds.map((_) => '?').join(',');
    final query = '''
      SELECT client_id, COUNT(*) as count
      FROM touchpoints
      WHERE client_id IN ($placeholders)
      GROUP BY client_id
    ''';

    final results = await PowerSyncService.query(query, clientIds);

    final counts = <String, int>{};
    for (final row in results) {
      final clientId = row['client_id'] as String;
      final count = row['count'] as int;
      counts[clientId] = count;
    }

    // Ensure all requested client IDs are in the result (even if 0)
    for (final clientId in clientIds) {
      counts.putIfAbsent(clientId, () => 0);
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
          counts[client.id!] = client.touchpoints.length;
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
