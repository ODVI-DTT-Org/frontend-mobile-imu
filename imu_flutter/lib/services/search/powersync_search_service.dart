/// PowerSync local database search integration
/// Provides SQL-based search for offline client data
library;

import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import '../../../features/clients/data/models/client_model.dart' show Client;
import 'client_search_service.dart' show ClientSearchService, SearchResult, SearchStrategy;

/// PowerSync search service for local database queries
class PowerSyncSearchService {
  final PowerSyncDatabase database;
  final ClientSearchService _searchService = ClientSearchService();

  PowerSyncSearchService(this.database);

  /// Search clients using PowerSync SQL queries
  /// Falls back to in-memory search if SQL search fails
  Future<List<SearchResult>> searchClients(
    String query, {
    int limit = 50,
    int offset = 0,
    SearchStrategy? preferredStrategy,
  }) async {
    try {
      // Determine search strategy
      final words = query.toLowerCase().split(RegExp(r'\s+'));
      final strategy = preferredStrategy ?? _determineSearchStrategy(words.length);

      // Execute PowerSync search
      final results = await _executePowerSyncSearch(query, strategy, limit, offset);

      return results;
    } catch (e) {
      // Fallback to in-memory search if PowerSync search fails
      final clients = await _getAllClients();
      return _searchService.searchClients(clients, query, maxResults: limit);
    }
  }

  /// Get all clients from local database
  Future<List<Client>> _getAllClients() async {
    try {
      final results = await database.getAll(
        'SELECT * FROM clients ORDER BY full_name ASC',
      );

      return results.map((row) => _mapRowToClient(row)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Execute PowerSync SQL search
  Future<List<SearchResult>> _executePowerSyncSearch(
    String query,
    SearchStrategy strategy,
    int limit,
    int offset,
  ) async {
    switch (strategy) {
      case SearchStrategy.fuzzy:
        return _fuzzySqlSearch(query, limit, offset);
      case SearchStrategy.permutation:
        return _permutationSqlSearch(query, limit, offset);
      case SearchStrategy.pattern:
        return _patternSqlSearch(query, limit, offset);
    }
  }

  /// Fuzzy SQL search for 1-2 word queries
  Future<List<SearchResult>> _fuzzySqlSearch(
    String query,
    int limit,
    int offset,
  ) async {
    final normalizedQuery = query.toLowerCase();
    final likeQuery = '%$normalizedQuery%';

    try {
      final results = await database.getAll(
        '''
        SELECT
          c.*,
          CASE
            WHEN LOWER(c.full_name) LIKE ? THEN 1.0
            WHEN LOWER(c.first_name) LIKE ? THEN 0.9
            WHEN LOWER(c.last_name) LIKE ? THEN 0.9
            WHEN LOWER(c.middle_name) LIKE ? THEN 0.7
            ELSE 0.5
          END as relevance_score
        FROM clients c
        WHERE
          LOWER(c.full_name) LIKE ? OR
          LOWER(c.first_name) LIKE ? OR
          LOWER(c.last_name) LIKE ? OR
          LOWER(c.middle_name) LIKE ?
        ORDER BY relevance_score DESC, full_name ASC
        LIMIT ? OFFSET ?
        ''',
        [
          likeQuery, // for relevance check
          likeQuery,
          likeQuery,
          likeQuery,
          likeQuery, // for WHERE clause
          likeQuery,
          likeQuery,
          likeQuery,
          limit,
          offset,
        ],
      );

      return results.map((row) {
        final client = _mapRowToClient(row);
        final relevance = (row['relevance_score'] as num?)?.toDouble() ?? 0.5;

        return SearchResult(
          client: client,
          relevance: relevance,
          matchedPatterns: ['sql_fuzzy_match'],
        );
      }).toList();
    } catch (e) {
      // Fallback to simpler query if complex one fails
      return _simpleFuzzySearch(normalizedQuery, limit);
    }
  }

  /// Simple fuzzy search fallback
  Future<List<SearchResult>> _simpleFuzzySearch(
    String query,
    int limit,
  ) async {
    try {
      final results = await database.getAll(
        '''
        SELECT * FROM clients
        WHERE LOWER(full_name) LIKE ?
        ORDER BY full_name ASC
        LIMIT ?
        ''',
        ['%$query%', limit],
      );

      return results.map((row) {
        final client = _mapRowToClient(row);
        return SearchResult(
          client: client,
          relevance: 0.7,
          matchedPatterns: ['simple_fuzzy_match'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Permutation SQL search for 3-4 word queries
  Future<List<SearchResult>> _permutationSqlSearch(
    String query,
    int limit,
    int offset,
  ) async {
    // For permutation search, we'll use multiple LIKE queries
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    try {
      // Build OR conditions for each word
      final conditions = <String>[];
      final params = <dynamic>[];

      for (final word in words) {
        conditions.add('LOWER(full_name) LIKE ?');
        conditions.add('LOWER(first_name) LIKE ?');
        conditions.add('LOWER(last_name) LIKE ?');
        params.add('%$word%');
        params.add('%$word%');
        params.add('%$word%');
      }

      final whereClause = conditions.join(' OR ');

      final results = await database.getAll(
        '''
        SELECT *, COUNT(*) as match_count
        FROM clients
        WHERE $whereClause
        GROUP BY id
        ORDER BY match_count DESC, full_name ASC
        LIMIT ? OFFSET ?
        ''',
        [...params, limit, offset],
      );

      return results.map((row) {
        final client = _mapRowToClient(row);
        final matchCount = (row['match_count'] as num?)?.toInt() ?? 1;
        final relevance = (matchCount / words.length).clamp(0.3, 1.0);

        return SearchResult(
          client: client,
          relevance: relevance,
          matchedPatterns: ['permutation_sql_match'],
        );
      }).toList();
    } catch (e) {
      // Fallback to in-memory search
      final clients = await _getAllClients();
      return _searchService.searchClients(clients, query, maxResults: limit);
    }
  }

  /// Pattern SQL search for 5+ word queries
  Future<List<SearchResult>> _patternSqlSearch(
    String query,
    int limit,
    int offset,
  ) async {
    // For pattern search, focus on key words
    final words = query.toLowerCase().split(RegExp(r'\s+'));
    final keyWords = words.take(4).toList(); // Use first 4 key words

    try {
      final conditions = <String>[];
      final params = <dynamic>[];

      for (final word in keyWords) {
        conditions.add('LOWER(full_name) LIKE ?');
        params.add('%$word%');
      }

      final whereClause = conditions.join(' OR ');

      final results = await database.getAll(
        '''
        SELECT *, COUNT(*) as match_count
        FROM clients
        WHERE $whereClause
        GROUP BY id
        ORDER BY match_count DESC, full_name ASC
        LIMIT ? OFFSET ?
        ''',
        [...params, limit, offset],
      );

      return results.map((row) {
        final client = _mapRowToClient(row);
        final matchCount = (row['match_count'] as num?)?.toInt() ?? 1;
        final relevance = (matchCount / keyWords.length).clamp(0.2, 1.0);

        return SearchResult(
          client: client,
          relevance: relevance,
          matchedPatterns: ['pattern_sql_match'],
        );
      }).toList();
    } catch (e) {
      // Fallback to in-memory search
      final clients = await _getAllClients();
      return _searchService.searchClients(clients, query, maxResults: limit);
    }
  }

  /// Determine search strategy based on word count
  SearchStrategy _determineSearchStrategy(int wordCount) {
    switch (wordCount) {
      case 1:
      case 2:
        return SearchStrategy.fuzzy;
      case 3:
      case 4:
        return SearchStrategy.permutation;
      default:
        return SearchStrategy.pattern;
    }
  }

  /// Map database row to Client model
  Client _mapRowToClient(Map<String, dynamic> row) {
    return Client(
      id: row['id'] as String? ?? '',
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      middleName: row['middle_name'] as String?,
      clientType: row['client_type'] as String? ?? 'POTENTIAL',
      productType: row['product_type'] as String? ?? '',
      marketType: row['market_type'] as String? ?? '',
      pensionType: row['pension_type'] as String?,
      addresses: [], // Would need to parse from JSON if stored
      phoneNumbers: [], // Would need to parse from JSON if stored
      touchpoints: [], // Would need separate query or parsing
      isStarred: (row['is_starred'] as int?) == 1,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : null,
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  /// Get search statistics
  Future<PowerSyncSearchStats> getSearchStats() async {
    try {
      final result = await database.get(
        'SELECT COUNT(*) as total FROM clients',
      );

      final totalClients = result?['total'] as int? ?? 0;

      return PowerSyncSearchStats(
        totalClients: totalClients,
        isSearchEnabled: totalClients > 0,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return PowerSyncSearchStats(
        totalClients: 0,
        isSearchEnabled: false,
        lastUpdated: DateTime.now(),
      );
    }
  }
}

/// PowerSync search statistics
class PowerSyncSearchStats {
  final int totalClients;
  final bool isSearchEnabled;
  final DateTime lastUpdated;

  PowerSyncSearchStats({
    required this.totalClients,
    required this.isSearchEnabled,
    required this.lastUpdated,
  });

  @override
  String toString() =>
      'PowerSyncSearchStats(clients: $totalClients, enabled: $isSearchEnabled)';
}
