import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/search/fuzzy_search_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('FuzzySearchService', () {
    late List<Client> testClients;

    setUp(() {
      final now = DateTime.now();
      testClients = [
        Client(
          id: '1',
          firstName: 'Maria',
          lastName: 'Cruz',
          middleName: 'Santos',
          clientType: ClientType.potential,
          productType: ProductType.pnpPension,
          pensionType: PensionType.sss,
          createdAt: now,
        ),
        Client(
          id: '2',
          firstName: 'Juan',
          lastName: 'De la Cruz',
          middleName: null,
          clientType: ClientType.potential,
          productType: ProductType.pnpPension,
          pensionType: PensionType.sss,
          createdAt: now,
        ),
        Client(
          id: '3',
          firstName: 'Pedro',
          lastName: 'Santos',
          middleName: null,
          clientType: ClientType.potential,
          productType: ProductType.pnpPension,
          pensionType: PensionType.sss,
          createdAt: now,
        ),
        Client(
          id: '4',
          firstName: 'Ana',
          lastName: 'Garcia',
          middleName: null,
          clientType: ClientType.potential,
          productType: ProductType.pnpPension,
          pensionType: PensionType.sss,
          createdAt: now,
        ),
      ];
    });

    test('finds exact match by last name', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Cruz');

      expect(results.length, greaterThan(0));
      expect(results.first.lastName, equals('Cruz'));
    });

    test('finds with typo tolerance', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Cruzz');

      expect(results.length, greaterThan(0));
      expect(results.any((c) => c.lastName == 'Cruz'), isTrue);
    });

    test('finds with reversed name', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Maria Cruz');

      expect(results.length, greaterThan(0));
      expect(results.any((c) => c.firstName == 'Maria' && c.lastName == 'Cruz'), isTrue);
    });

    test('finds compound name without space', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Delacruz');

      expect(results.length, greaterThan(0));
      expect(results.any((c) => c.lastName == 'De la Cruz'), isTrue);
    });

    test('finds by middle name', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Santos');

      // Should find both Maria Santos Cruz and Pedro Santos
      expect(results.length, equals(2));
      expect(results.any((c) => c.middleName == 'Santos'), isTrue);
      expect(results.any((c) => c.lastName == 'Santos'), isTrue);
    });

    test('returns empty for no match', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('NonexistentXYZ');

      expect(results, isEmpty);
    });

    test('returns all clients for empty query', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('');

      expect(results.length, equals(testClients.length));
    });

    test('sorts by relevance score', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('Cruz');

      // First result should be exact match "Cruz" before "De la Cruz"
      expect(results.first.lastName, equals('Cruz'));
    });

    test('handles comma variations', () {
      final service = FuzzySearchService(testClients);

      final results1 = service.searchByName('Cruz, Maria');
      final results2 = service.searchByName('Maria, Cruz');

      expect(results1.length, greaterThan(0));
      expect(results2.length, greaterThan(0));
    });

    test('handles partial middle name', () {
      final service = FuzzySearchService(testClients);
      final results = service.searchByName('M Santos');

      expect(results.length, greaterThan(0));
      expect(results.any((c) => c.middleName == 'Santos'), isTrue);
    });
  });
}
