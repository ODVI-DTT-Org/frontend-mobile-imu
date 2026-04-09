import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Fuzzy search service for offline client name matching
/// Uses simple contains matching with tolerance for typos
class FuzzySearchService {
  final List<Client> _clients;

  FuzzySearchService(this._clients);

  /// Search clients by name with fuzzy matching
  /// Handles typos, reversed names, compound names, and middle names
  List<Client> searchByName(String query) {
    if (query.isEmpty) return _clients;

    final normalizedQuery = _normalizeQuery(query);
    final terms = normalizedQuery.split(' ').where((t) => t.isNotEmpty).toList();

    // Score each client against all search terms
    final results = _clients.map((client) {
      // Build search strings in different formats (lowercase for comparison)
      final fullNameLower = client.fullName.toLowerCase(); // "cruz, maria santos"
      final lastFirstLower = '${client.lastName} ${client.firstName}'.toLowerCase(); // "cruz maria"
      final firstLastLower = '${client.firstName} ${client.lastName}'.toLowerCase(); // "maria cruz"
      final firstMiddleLastLower = client.middleName != null && client.middleName!.isNotEmpty
          ? '${client.firstName} ${client.middleName} ${client.lastName}'.toLowerCase() // "maria santos cruz"
          : null;

      int bestScore = 0;
      for (final term in terms) {
        final termLower = term.toLowerCase();

        // Check each search string for matches
        for (final searchStr in [fullNameLower, lastFirstLower, firstLastLower, if (firstMiddleLastLower != null) firstMiddleLastLower]) {
          if (searchStr == null) continue;

          // Check for contains match
          if (searchStr.contains(termLower)) {
            bestScore = 100;
            break; // Perfect match, no need to check other strings
          }

          // Check for word boundary matches (split by space and check each word)
          final searchWords = searchStr.split(' ');
          for (final word in searchWords) {
            if (word.contains(termLower) || termLower.contains(word)) {
              // Calculate partial match score
              final score = ((termLower.length / word.length) * 100).clamp(0, 100).round();
              if (score > bestScore) bestScore = score;
            }
          }
        }
      }

      return MapEntry(client, bestScore);
    }).where((entry) => entry.value >= 50) // Threshold of 50 for fuzzy matching
      .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by score descending

    return results.map((e) => e.key).toList();
  }

  /// Normalize search query for consistent matching
  /// - Convert to lowercase
  /// - Replace commas with spaces
  /// - Collapse multiple spaces
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
