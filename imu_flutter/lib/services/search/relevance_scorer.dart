/// Relevance scoring for search results
/// Calculates how well a client matches a search query
library;

/// Relevance scorer for search result ranking
class RelevanceScorer {
  /// Calculate relevance score between client and query
  /// Returns 0.0 (no match) to 1.0 (perfect match)
  static double calculateRelevance(
    String normalizedClient,
    String normalizedQuery, {
    double baseRelevance = 0.0,
  }) {
    if (normalizedQuery.isEmpty) return 0.0;
    if (normalizedClient.isEmpty) return 0.0;

    double score = baseRelevance;

    // Exact match
    if (normalizedClient == normalizedQuery) {
      return 1.0;
    }

    // Starts with query (high relevance)
    if (normalizedClient.startsWith(normalizedQuery)) {
      score = score * 0.9 + 0.1;
    }

    // Contains query (good relevance)
    if (normalizedClient.contains(normalizedQuery)) {
      score = score * 0.7 + 0.3;
    }

    // Word-by-word matching
    final queryWords = normalizedQuery.split(' ');
    final clientWords = normalizedClient.split(' ');

    int wordMatches = 0;
    for (final queryWord in queryWords) {
      for (final clientWord in clientWords) {
        if (clientWord == queryWord) {
          wordMatches++;
          score += 0.2;
          break;
        } else if (clientWord.contains(queryWord) || queryWord.contains(clientWord)) {
          wordMatches++;
          score += 0.1;
          break;
        }
      }
    }

    // Word boundary matches get higher score
    final wordBoundaryMatches = _countWordBoundaryMatches(normalizedClient, normalizedQuery);
    score += wordBoundaryMatches * 0.15;

    // First word match bonus
    if (clientWords.isNotEmpty && queryWords.isNotEmpty) {
      if (clientWords.first == queryWords.first) {
        score += 0.2;
      }
    }

    // Exact phrase match bonus
    if (_containsPhrase(normalizedClient, normalizedQuery)) {
      score += 0.3;
    }

    // Penalize for length difference
    final lengthDiff = (clientWords.length - queryWords.length).abs();
    if (lengthDiff > 2) {
      score -= lengthDiff * 0.05;
    }

    // Ensure score is within bounds
    return score.clamp(0.0, 1.0);
  }

  /// Count word boundary matches
  static int _countWordBoundaryMatches(String text, String query) {
    if (query.isEmpty) return 0;

    final queryWords = query.split(' ');
    int matches = 0;

    for (final word in queryWords) {
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(text)) {
        matches++;
      }
    }

    return matches;
  }

  /// Check if text contains phrase
  static bool _containsPhrase(String text, String phrase) {
    if (phrase.isEmpty) return false;
    final pattern = RegExp(r'\b' + RegExp.escape(phrase) + r'\b', caseSensitive: false);
    return pattern.hasMatch(text);
  }

  /// Calculate similarity score using simple algorithm
  /// Similar to Levenshtein distance but optimized for speed
  static double calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final len1 = str1.length;
    final len2 = str2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    // Count matching characters
    int matches = 0;
    final minLen = len1 < len2 ? len1 : len2;

    for (int i = 0; i < minLen; i++) {
      if (str1[i] == str2[i]) {
        matches++;
      }
    }

    return matches / maxLen;
  }

  /// Calculate fuzzy match score for typos and slight variations
  static double calculateFuzzyScore(String text, String query) {
    if (query.isEmpty) return 0.0;
    if (text.isEmpty) return 0.0;

    // Direct contains check
    if (text.toLowerCase().contains(query.toLowerCase())) {
      return 0.8;
    }

    // Word-based fuzzy match
    final textWords = text.toLowerCase().split(' ');
    final queryWords = query.toLowerCase().split(' ');

    double maxScore = 0.0;
    for (final queryWord in queryWords) {
      for (final textWord in textWords) {
        final similarity = calculateSimilarity(textWord, queryWord);
        if (similarity > maxScore) {
          maxScore = similarity;
        }
      }
    }

    return maxScore * 0.7; // Slightly lower than exact match
  }

  /// Boost relevance based on match position
  static double boostByPosition(double relevance, int matchPosition) {
    // Early matches get higher boost
    if (matchPosition == 0) {
      return relevance * 1.2;
    } else if (matchPosition == 1) {
      return relevance * 1.1;
    } else if (matchPosition == 2) {
      return relevance * 1.05;
    }
    return relevance;
  }

  /// Calculate combined relevance from multiple sources
  static double combineRelevance(List<double> scores) {
    if (scores.isEmpty) return 0.0;

    // Use weighted average
    double total = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < scores.length; i++) {
      final weight = 1.0 / (i + 1); // Decreasing weights
      total += scores[i] * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? total / totalWeight : 0.0;
  }

  /// Get relevance level category
  static RelevanceLevel getRelevanceLevel(double relevance) {
    if (relevance >= 0.9) return RelevanceLevel.excellent;
    if (relevance >= 0.7) return RelevanceLevel.good;
    if (relevance >= 0.5) return RelevanceLevel.fair;
    if (relevance >= 0.3) return RelevanceLevel.poor;
    return RelevanceLevel.veryPoor;
  }
}

/// Relevance level categories
enum RelevanceLevel {
  /// Excellent match (90%+)
  excellent,

  /// Good match (70-89%)
  good,

  /// Fair match (50-69%)
  fair,

  /// Poor match (30-49%)
  poor,

  /// Very poor match (<30%)
  veryPoor,
}

extension RelevanceLevelExtension on RelevanceLevel {
  String get label {
    switch (this) {
      case RelevanceLevel.excellent:
        return 'Excellent';
      case RelevanceLevel.good:
        return 'Good';
      case RelevanceLevel.fair:
        return 'Fair';
      case RelevanceLevel.poor:
        return 'Poor';
      case RelevanceLevel.veryPoor:
        return 'Very Poor';
    }
  }

  String get description {
    switch (this) {
      case RelevanceLevel.excellent:
        return 'Perfect or near-perfect match';
      case RelevanceLevel.good:
        return 'Strong match with high confidence';
      case RelevanceLevel.fair:
        return 'Moderate match, may be relevant';
      case RelevanceLevel.poor:
        return 'Weak match, possibly relevant';
      case RelevanceLevel.veryPoor:
        return 'Very weak match, unlikely to be relevant';
    }
  }
}
