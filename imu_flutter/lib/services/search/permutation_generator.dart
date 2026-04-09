/// Word permutation generator for enhanced search
/// Creates word order variations to match backend permutation search
library;

/// Permutation generator for multi-word search queries
class PermutationGenerator {
  /// Generate all permutations for 3-4 words
  /// Limited to prevent performance issues
  static List<String> generatePermutations(List<String> words) {
    if (words.length <= 1) return [words.join(' ')];
    if (words.length > 5) return [words.join(' ')]; // Too many permutations

    switch (words.length) {
      case 2:
        return _generate2WordPermutations(words);
      case 3:
        return _generate3WordPermutations(words);
      case 4:
        return _generate4WordPermutations(words, limit: 12);
      case 5:
        return _generate5WordPermutations(words);
      default:
        return [words.join(' ')];
    }
  }

  /// Generate common name patterns for 5+ words
  static List<String> generateCommonPatterns(List<String> words) {
    final patterns = <String>[];

    // Original order
    patterns.add(words.join(' '));

    // Reverse order
    patterns.add(words.reversed.join(' '));

    // First word + rest
    patterns.add('${words.first} ${words.skip(1).join(' ')}');

    // Last word + rest
    patterns.add('${words.last} ${words.take(words.length - 1).join(' ')}');

    // Middle words combinations
    if (words.length >= 3) {
      final midIndex = words.length ~/ 2;
      patterns.add(words[midIndex]);

      if (midIndex > 0) {
        patterns.add(words[midIndex - 1]);
      }
      if (midIndex < words.length - 1) {
        patterns.add(words[midIndex + 1]);
      }
    }

    return patterns.toSet().toList();
  }

  /// 2-word permutations (2 total)
  static List<String> _generate2WordPermutations(List<String> words) {
    return [
      words.join(' '), // Original: "A B"
      '${words[1]} ${words[0]}', // Reversed: "B A"
    ];
  }

  /// 3-word permutations (6 total)
  static List<String> _generate3WordPermutations(List<String> words) {
    return [
      '${words[0]} ${words[1]} ${words[2]}', // Original: A B C
      '${words[0]} ${words[2]} ${words[1]}', // Swap 1-2: A C B
      '${words[1]} ${words[0]} ${words[2]}', // Swap 0-1: B A C
      '${words[1]} ${words[2]} ${words[0]}', // Rotate left: B C A
      '${words[2]} ${words[0]} ${words[1]}', // Rotate right: C A B
      '${words[2]} ${words[1]} ${words[0]}', // Reverse: C B A
    ];
  }

  /// 4-word permutations (limited to 12 for performance)
  static List<String> _generate4WordPermutations(
    List<String> words, {
    int limit = 12,
  }) {
    final permutations = <String>[];

    // Add most likely patterns first
    permutations.add(words.join(' ')); // Original
    permutations.add(words.reversed.join(' ')); // Reverse

    // First word variations
    permutations.add('${words[0]} ${words[1]} ${words[2]} ${words[3]}');
    permutations.add('${words[0]} ${words[2]} ${words[1]} ${words[3]}');
    permutations.add('${words[0]} ${words[3]} ${words[1]} ${words[2]}');

    // Last word variations
    permutations.add('${words[3]} ${words[0]} ${words[1]} ${words[2]}');
    permutations.add('${words[1]} ${words[2]} ${words[3]} ${words[0]}');

    // Middle variations
    permutations.add('${words[1]} ${words[0]} ${words[2]} ${words[3]}');
    permutations.add('${words[1]} ${words[2]} ${words[0]} ${words[3]}');
    permutations.add('${words[2]} ${words[1]} ${words[0]} ${words[3]}');

    // Additional patterns
    permutations.add('${words[2]} ${words[0]} ${words[1]} ${words[3]}');
    permutations.add('${words[2]} ${words[3]} ${words[0]} ${words[1]}');

    return permutations.take(limit).toSet().toList();
  }

  /// 5-word permutations (common patterns only)
  static List<String> _generate5WordPermutations(List<String> words) {
    final patterns = <String>[];

    // Original and reverse
    patterns.add(words.join(' '));
    patterns.add(words.reversed.join(' '));

    // First/last combinations
    patterns.add('${words.first} ${words.skip(1).join(' ')}');
    patterns.add('${words.last} ${words.take(words.length - 1).join(' ')}');
    patterns.add('${words.first} ${words.last}');
    patterns.add('${words.last} ${words.first}');

    // Middle combinations
    final midIndex = words.length ~/ 2;
    patterns.add('${words[midIndex]} ${words[midIndex - 1]}');
    patterns.add('${words[midIndex]} ${words[midIndex + 1]}');

    // First + middle
    patterns.add('${words.first} ${words[midIndex]}');

    // Remove duplicates and limit
    return patterns.toSet().take(8).toList();
  }

  /// Calculate number of possible permutations
  static int calculatePermutationCount(int wordCount) {
    if (wordCount <= 1) return 1;
    if (wordCount > 5) return wordCount; // Limited patterns for 5+

    int factorial(int n) {
      if (n <= 1) return 1;
      return n * factorial(n - 1);
    }

    return factorial(wordCount);
  }

  /// Check if permutation limit is recommended
  static bool shouldLimitPermutations(int wordCount) {
    return wordCount >= 4;
  }

  /// Get recommended permutation limit for word count
  static int getRecommendedLimit(int wordCount) {
    switch (wordCount) {
      case 1:
      case 2:
      case 3:
        return wordCount * wordCount; // No limit needed
      case 4:
        return 12; // 24 total, limit to 12
      case 5:
        return 8; // 120 total, limit to 8
      default:
        return 6; // Common patterns only
    }
  }
}
