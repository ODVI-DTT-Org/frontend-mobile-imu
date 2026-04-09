/// Unit tests for mobile offline search service
/// Tests permutation matching, fuzzy search, and relevance scoring
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/search/client_search_service.dart';
import 'package:imu_flutter/services/search/search_normalizer.dart';
import 'package:imu_flutter/services/search/permutation_generator.dart';
import 'package:imu_flutter/services/search/relevance_scorer.dart';

void main() {
  group('ClientSearchService', () {
    late ClientSearchService searchService;
    late List<Client> testClients;

    setUp(() {
      searchService = ClientSearchService();

      // Create test clients with various name patterns
      testClients = [
        // 5-word name
        Client(
          id: '1',
          firstName: 'PRINCE VANN EISEN',
          lastName: 'ACNAM',
          middleName: 'DANAO',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          touchpoints: const [],
          createdAt: DateTime.now(),
          isStarred: false,
        ),
        // 6-word name
        Client(
          id: '2',
          firstName: 'JACK BRIAN EMANUEL',
          lastName: 'BERNARDINO',
          middleName: 'DELA CRUZ',
          clientType: ClientType.existing,
          productType: ProductType.sssPensioner,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          touchpoints: const [],
          createdAt: DateTime.now(),
          isStarred: false,
        ),
        // 5-word name with special character
        Client(
          id: '3',
          firstName: 'ELMER',
          lastName: 'ALMADEN',
          middleName: 'DE LA PEÑA',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          touchpoints: const [],
          createdAt: DateTime.now(),
          isStarred: false,
        ),
        // Simple 2-word name
        Client(
          id: '4',
          firstName: 'JUAN',
          lastName: 'DELA CRUZ',
          middleName: null,
          clientType: ClientType.existing,
          productType: ProductType.sssPensioner,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          touchpoints: const [],
          createdAt: DateTime.now(),
          isStarred: false,
        ),
        // 6-word name
        Client(
          id: '5',
          firstName: 'MARAH ELAINE KAY',
          lastName: 'COLADO',
          middleName: 'DELA PENA',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          touchpoints: const [],
          createdAt: DateTime.now(),
          isStarred: false,
        ),
      ];
    });

    test('should find exact match with original name order', () {
      final results = searchService.searchClients(
        testClients,
        'ACNAM PRINCE VANN EISEN DANAO',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '1');
      expect(results.first.relevance, closeTo(1.0, 0.1));
    });

    test('should find client with reversed name order', () {
      final results = searchService.searchClients(
        testClients,
        'DANAO EISEN VANN PRINCE ACNAM',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '1');
    });

    test('should find client with first-last combination', () {
      final results = searchService.searchClients(
        testClients,
        'ACNAM DANAO',
      );

      expect(results.length, greaterThan(0));
      final acnamClient = results.firstWhere(
        (result) => result.client.id == '1',
        orElse: () => throw Exception('ACNAM client not found'),
      );
      expect(acnamClient.client.id, '1');
    });

    test('should find client with last-first combination', () {
      final results = searchService.searchClients(
        testClients,
        'DANAO ACNAM',
      );

      expect(results.length, greaterThan(0));
    });

    test('should find client with middle words', () {
      final results = searchService.searchClients(
        testClients,
        'VANN PRINCE',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '1');
    });

    test('should handle special characters (Ñ)', () {
      final results = searchService.searchClients(
        testClients,
        'ALMADEN ELMER DE LA PEÑA',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '3');
    });

    test('should handle special characters without tilde', () {
      final results = searchService.searchClients(
        testClients,
        'ALMADEN ELMER DE LA PENA',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '3');
    });

    test('should return empty list for empty query', () {
      final results = searchService.searchClients(testClients, '');

      expect(results.length, equals(5)); // All clients with relevance 1.0
    });

    test('should find 6-word client with permutation', () {
      final results = searchService.searchClients(
        testClients,
        'COLADO MARAH ELAINE KAY DELA PENA',
      );

      expect(results.length, greaterThan(0));
      expect(results.first.client.id, '5');
    });

    test('should rank results by relevance', () {
      final results = searchService.searchClients(
        testClients,
        'ACNAM',
      );

      expect(results.length, greaterThan(1));

      // First result should have highest relevance
      for (int i = 0; i < results.length - 1; i++) {
        expect(results[i].relevance, greaterThanOrEqualTo(results[i + 1].relevance));
      }
    });

    test('should respect maxResults parameter', () {
      final results = searchService.searchClients(
        testClients,
        'A', // Broad query
        maxResults: 2,
      );

      expect(results.length, lessThanOrEqualTo(2));
    });

    test('should filter by minimum relevance', () {
      final results = searchService.searchClients(
        testClients,
        'NONEXISTENT NAME XYZ',
        minRelevance: 0.5,
      );

      expect(results.length, equals(0));
    });
  });

  group('SearchNormalizer', () {
    test('should normalize Spanish characters', () {
      final normalized = SearchNormalizer.normalizeQuery('PEÑA GARCÍA');

      expect(normalized, contains('pena'));
      expect(normalized, contains('garcia'));
      expect(normalized, isNot(contains('ñ')));
      expect(normalized, isNot(contains('í')));
    });

    test('should normalize client name', () {
      final client = Client(
        id: '1',
        firstName: 'MARÍA JOSÉ',
        lastName: 'PEÑA',
        middleName: 'GARCÍA',
        clientType: ClientType.potential,
        productType: ProductType.sssPensioner,
        marketType: MarketType.residential,
        pensionType: PensionType.sss,
        touchpoints: const [],
        createdAt: DateTime.now(),
        isStarred: false,
      );

      final normalized = SearchNormalizer.normalizeClient(client);

      expect(normalized.toLowerCase(), equals('maria jose pena garcia'));
      expect(normalized, isNot(contains('í')));
      expect(normalized, isNot(contains('é')));
    });

    test('should extract words from query', () {
      final words = SearchNormalizer.extractWords('  Juan  dela  Cruz  ');

      expect(words, equals(['juan', 'dela', 'cruz']));
    });

    test('should detect special characters', () {
      expect(SearchNormalizer.hasSpecialCharacters('PEÑA'), isTrue);
      expect(SearchNormalizer.hasSpecialCharacters('GARCÍA'), isTrue);
      expect(SearchNormalizer.hasSpecialCharacters('JUAN'), isFalse);
    });
  });

  group('PermutationGenerator', () {
    test('should generate 2-word permutations', () {
      final words = ['A', 'B'];
      final permutations = PermutationGenerator.generatePermutations(words);

      expect(permutations.length, equals(2));
      expect(permutations, contains('A B'));
      expect(permutations, contains('B A'));
    });

    test('should generate 3-word permutations', () {
      final words = ['A', 'B', 'C'];
      final permutations = PermutationGenerator.generatePermutations(words);

      expect(permutations.length, equals(6));
      expect(permutations, contains('A B C'));
      expect(permutations, contains('C B A')); // Reverse
    });

    test('should generate 4-word permutations with limit', () {
      final words = ['A', 'B', 'C', 'D'];
      final permutations = PermutationGenerator.generatePermutations(words);

      expect(permutations.length, greaterThanOrEqualTo(6));
      expect(permutations.length, lessThanOrEqualTo(12));
    });

    test('should generate 5-word common patterns', () {
      final words = ['A', 'B', 'C', 'D', 'E'];
      final patterns = PermutationGenerator.generateCommonPatterns(words);

      expect(patterns.length, greaterThan(1));
      expect(patterns, contains(words.join(' ')));
      expect(patterns, contains(words.reversed.join(' ')));
    });

    test('should recommend permutation limit for 4+ words', () {
      expect(PermutationGenerator.shouldLimitPermutations(3), isFalse);
      expect(PermutationGenerator.shouldLimitPermutations(4), isTrue);
      expect(PermutationGenerator.shouldLimitPermutations(5), isTrue);
    });
  });

  group('RelevanceScorer', () {
    test('should calculate perfect relevance for exact match', () {
      final relevance = RelevanceScorer.calculateRelevance(
        'juan dela cruz',
        'juan dela cruz',
      );

      expect(relevance, equals(1.0));
    });

    test('should calculate high relevance for starts with', () {
      final relevance = RelevanceScorer.calculateRelevance(
        'juan dela cruz',
        'juan',
      );

      expect(relevance, greaterThan(0.8));
    });

    test('should calculate moderate relevance for contains', () {
      final relevance = RelevanceScorer.calculateRelevance(
        'juan dela cruz',
        'cruz',
      );

      expect(relevance, greaterThan(0.3));
      expect(relevance, lessThan(0.8));
    });

    test('should return zero relevance for no match', () {
      final relevance = RelevanceScorer.calculateRelevance(
        'juan dela cruz',
        'nonexistent',
      );

      expect(relevance, lessThan(0.3));
    });

    test('should categorize relevance levels correctly', () {
      expect(
        RelevanceScorer.getRelevanceLevel(0.95),
        equals(RelevanceLevel.excellent),
      );
      expect(
        RelevanceScorer.getRelevanceLevel(0.75),
        equals(RelevanceLevel.good),
      );
      expect(
        RelevanceScorer.getRelevanceLevel(0.55),
        equals(RelevanceLevel.fair),
      );
      expect(
        RelevanceScorer.getRelevanceLevel(0.35),
        equals(RelevanceLevel.poor),
      );
      expect(
        RelevanceScorer.getRelevanceLevel(0.15),
        equals(RelevanceLevel.veryPoor),
      );
    });

    test('should calculate fuzzy similarity', () {
      final similarity = RelevanceScorer.calculateSimilarity('test', 'test');

      expect(similarity, equals(1.0));

      final partialSimilarity = RelevanceScorer.calculateSimilarity('test', 'testing');

      expect(partialSimilarity, greaterThan(0.5));
    });
  });
}
