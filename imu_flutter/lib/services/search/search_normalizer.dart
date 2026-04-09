/// Search query and client name normalization utilities
/// Handles special characters, case conversion, and text standardization
library;

import '../../../features/clients/data/models/client_model.dart' show Client;

/// Search normalizer for consistent text processing
class SearchNormalizer {
  /// Normalize search query for processing
  /// - Convert to lowercase
  /// - Handle special characters (Spanish, etc.)
  /// - Remove extra whitespace
  /// - Standardize common abbreviations
  static String normalizeQuery(String query) {
    return query
        .toLowerCase()
        .replaceAll(RegExp(r'[ñÑ]'), 'n')
        .replaceAll(RegExp(r'[áÁ]'), 'a')
        .replaceAll(RegExp(r'[éÉ]'), 'e')
        .replaceAll(RegExp(r'[íÍ]'), 'i')
        .replaceAll(RegExp(r'[óÓ]'), 'o')
        .replaceAll(RegExp(r'[úÚüÜ]'), 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  /// Normalize client name for search comparison
  /// Combines all name fields and applies normalization
  static String normalizeClient(Client client) {
    final parts = <String>[
      client.firstName,
      client.lastName,
      if (client.middleName != null && client.middleName!.isNotEmpty)
        client.middleName!,
    ];

    return normalizeQuery(parts.join(' '));
  }

  /// Extract individual words from normalized query
  static List<String> extractWords(String query) {
    final normalized = normalizeQuery(query);
    return normalized.split(' ').where((word) => word.isNotEmpty).toList();
  }

  /// Check if query contains special characters that need handling
  static bool hasSpecialCharacters(String query) {
    return RegExp(r'[ñÑáÁéÉíÍóÓúÚüÜ]').hasMatch(query);
  }

  /// Standardize common name abbreviations
  static String standardizeAbbreviations(String text) {
    return text
        .replaceAll(RegExp(r'\bda\b'), 'dela')
        .replaceAll(RegExp(r'\bde\b'), 'dela')
        .replaceAll(RegExp(r'\bdel\b'), 'dela')
        .replaceAll(RegExp(r'\blos\b'), 'dela')
        .replaceAll(RegExp(r'\bla\b'), 'dela')
        .replaceAll(RegExp(r'\bsta\b'), 'santa')
        .replaceAll(RegExp(r'\bsto\b'), 'santo')
        .toLowerCase();
  }

  /// Check if two queries are semantically similar
  static bool areSimilar(String query1, String query2) {
    final normalized1 = normalizeQuery(query1);
    final normalized2 = normalizeQuery(query2);
    return normalized1 == normalized2;
  }

  /// Generate search variations for better matching
  static List<String> generateVariations(String query) {
    final variations = <String>[];

    // Original normalized
    variations.add(normalizeQuery(query));

    // With abbreviation standardization
    variations.add(standardizeAbbreviations(normalizeQuery(query)));

    // Individual words
    variations.addAll(extractWords(query));

    return variations.toSet().toList();
  }
}
