/// Riverpod providers for offline search functionality
/// Integrates with existing client providers for seamless online/offline experience
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

import '../../../models/client_model.dart' show Client;
import '../../shared/providers/app_providers.dart'
    show
        assignedClientsProvider,
        powerSyncDatabaseProvider;
import '../../features/clients/data/repositories/client_repository.dart' show clientRepositoryProvider;
import 'client_search_service.dart' show ClientSearchService, SearchResult;
import 'powersync_search_service.dart' show PowerSyncSearchService;

/// Offline search results provider
/// Automatically switches between online API search and offline local search
final offlineClientSearchResultsProvider =
    FutureProvider.autoDispose<List<SearchResult>>((ref) async {
  // Get current search query
  final searchQuery = ref.watch(assignedClientSearchQueryProvider);

  // Get assigned clients (cached or from API)
  final clientsAsync = ref.watch(assignedClientsProvider);

  return clientsAsync.when(
    data: (response) {
      final clients = response.items;

      // If no search query, return all clients with high relevance
      if (searchQuery.trim().isEmpty) {
        return clients
            .map((client) => SearchResult(
                  client: client,
                  relevance: 1.0,
                  matchedPatterns: [],
                ))
            .toList();
      }

      // Use offline search service
      final searchService = ClientSearchService();
      return searchService.searchClients(clients, searchQuery.trim());
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// PowerSync offline search provider
/// Uses PowerSync local database for search without API calls
final powerSyncOfflineSearchProvider =
    FutureProvider.autoDispose<PowerSyncSearchService>((ref) async {
  final database = await ref.watch(powerSyncDatabaseProvider.future);
  return PowerSyncSearchService(database);
});

/// PowerSync search results provider
/// Direct search in local PowerSync database
final powerSyncSearchResultsProvider =
    FutureProvider.autoDispose.family<List<SearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }

  try {
    final searchService = await ref.watch(powerSyncOfflineSearchProvider.future);
    return await searchService.searchClients(query.trim(), limit: 50);
  } catch (e) {
    // Fallback to PowerSync SQLite if search service fails
    final clientRepo = ref.watch(clientRepositoryProvider);
    final clients = await clientRepo.getClients();

    final searchService = ClientSearchService();
    return searchService.searchClients(clients, query.trim());
  }
});

/// Hybrid search provider
/// Combines PowerSync search and Hive search for maximum reliability
final hybridOfflineSearchProvider =
    FutureProvider.autoDispose.family<List<SearchResult>, SearchQuery>((ref, params) async {
  if (params.query.trim().isEmpty) {
    return [];
  }

  final results = <SearchResult>[];

  // Try PowerSync search first
  try {
    final powerSyncService = await ref.watch(powerSyncOfflineSearchProvider.future);
    final powerSyncResults =
        await powerSyncService.searchClients(params.query.trim(), limit: params.limit ?? 50);
    results.addAll(powerSyncResults);
  } catch (e) {
    // PowerSync failed, continue to Hive fallback
  }

  // If PowerSync didn't return enough results, try direct SQLite query
  if (results.length < (params.minResults ?? 10)) {
    try {
      final clientRepo = ref.watch(clientRepositoryProvider);
      final clients = await clientRepo.getClients();

      final searchService = ClientSearchService();
      final hiveResults = searchService.searchClients(
        clients,
        params.query.trim(),
        maxResults: (params.limit ?? 50) - results.length,
      );

      // Merge results, avoiding duplicates
      final existingIds = results.map((r) => r.client.id).toSet();
      for (final result in hiveResults) {
        if (!existingIds.contains(result.client.id)) {
          results.add(result);
        }
      }
    } catch (e) {
      // Hive also failed, return what we have
    }
  }

  // Sort by relevance and limit results
  results.sort((a, b) => b.relevance.compareTo(a.relevance));
  return results.take(params.limit ?? 50).toList();
});

/// Search statistics provider
final searchStatsProvider = FutureProvider.autoDispose<SearchStats>((ref) async {
  int totalClients = 0;
  bool powerSyncAvailable = false;
  bool hiveAvailable = false;

  // Check PowerSync availability
  try {
    final powerSyncService = await ref.watch(powerSyncOfflineSearchProvider.future);
    final stats = await powerSyncService.getSearchStats();
    totalClients = stats.totalClients;
    powerSyncAvailable = stats.isSearchEnabled;
  } catch (e) {
    powerSyncAvailable = false;
  }

  // Check local SQLite availability
  bool localAvailable = false;
  try {
    final clientRepo = ref.watch(clientRepositoryProvider);
    final clients = await clientRepo.getClients();
    localAvailable = clients.isNotEmpty;
    if (!powerSyncAvailable) {
      totalClients = clients.length;
    }
  } catch (e) {
    localAvailable = false;
  }

  return SearchStats(
    totalClients: totalClients,
    powerSyncAvailable: powerSyncAvailable,
    hiveAvailable: localAvailable,
    lastUpdated: DateTime.now(),
  );
});

/// Search query parameters
class SearchQuery {
  final String query;
  final int? limit;
  final int? minResults;

  SearchQuery({
    required this.query,
    this.limit,
    this.minResults,
  });

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.query == query &&
      other.limit == limit &&
      other.minResults == minResults;

  @override
  int get hashCode => Object.hash(query, limit, minResults);
}

/// Search statistics
class SearchStats {
  final int totalClients;
  final bool powerSyncAvailable;
  final bool hiveAvailable;
  final DateTime lastUpdated;

  SearchStats({
    required this.totalClients,
    required this.powerSyncAvailable,
    required this.hiveAvailable,
    required this.lastUpdated,
  });

  /// Check if any offline search is available
  bool get isOfflineSearchAvailable => powerSyncAvailable || hiveAvailable;

  /// Get recommended search source
  String get recommendedSource {
    if (powerSyncAvailable) return 'PowerSync';
    if (hiveAvailable) return 'Hive';
    return 'None';
  }

  @override
  String toString() =>
      'SearchStats(clients: $totalClients, powerSync: $powerSyncAvailable, hive: $hiveAvailable)';
}

/// Search performance metrics
class SearchMetrics {
  final int queryCount;
  final int totalResults;
  final double averageRelevance;
  final Duration averageQueryTime;
  final DateTime lastUpdated;

  SearchMetrics({
    required this.queryCount,
    required this.totalResults,
    required this.averageRelevance,
    required this.averageQueryTime,
    required this.lastUpdated,
  });

  /// Calculate success rate
  double get successRate =>
      queryCount > 0 ? (totalResults / queryCount).clamp(0.0, 1.0) : 0.0;

  @override
  String toString() =>
      'SearchMetrics(queries: $queryCount, results: $totalResults, avg_relevance: $averageRelevance)';
}

/// Export for convenience
export 'client_search_service.dart'
    show
        ClientSearchService,
        SearchResult,
        SearchStrategy;
export 'powersync_search_service.dart'
    show
        PowerSyncSearchService,
        PowerSyncSearchStats;
export 'search_normalizer.dart' show SearchNormalizer;
export 'permutation_generator.dart' show PermutationGenerator;
export 'relevance_scorer.dart' show RelevanceScorer, RelevanceLevel;
