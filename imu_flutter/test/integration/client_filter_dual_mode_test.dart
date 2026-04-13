// test/integration/client_filter_dual_mode_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';

void main() {
  group('Client Filter Dual-Mode Integration', () {
    group('Assigned Clients Mode (Local Filtering)', () {
      test('filters clients locally using AND logic', () {
        // Setup: Create test clients with various attributes
        final testClients = [
          Client(
            id: '1',
            firstName: 'John',
            lastName: 'Doe',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '2',
            firstName: 'Jane',
            lastName: 'Smith',
            clientType: ClientType.existing, // Different client type
            marketType: MarketType.residential,
            productType: ProductType.gsisPensioner,
            pensionType: PensionType.gsis,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '3',
            firstName: 'Bob',
            lastName: 'Johnson',
            clientType: ClientType.potential,
            marketType: MarketType.commercial, // Different market type
            productType: ProductType.private,
            pensionType: PensionType.private,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '4',
            firstName: 'Alice',
            lastName: 'Williams',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.gsisPensioner, // Different product type
            pensionType: PensionType.gsis,
            createdAt: DateTime.now(),
          ),
        ];

        // Apply filter: client_type = POTENTIAL AND market_type = RESIDENTIAL
        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        // Simulate local filtering (as done in Assigned Clients mode)
        final filtered = testClients.where(filter.matches).toList();

        // Verify: Only clients matching BOTH criteria
        expect(filtered.length, 2);
        expect(filtered[0].id, '1');
        expect(filtered[1].id, '4');
        expect(filtered.every((c) =>
          c.clientType == ClientType.potential &&
          c.marketType == MarketType.residential
        ), true);
      });

      test('applies all four filters together (AND logic)', () {
        final testClients = [
          Client(
            id: '1',
            firstName: 'Perfect',
            lastName: 'Match',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '2',
            firstName: 'Wrong',
            lastName: 'ClientType',
            clientType: ClientType.existing, // Wrong
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '3',
            firstName: 'Wrong',
            lastName: 'MarketType',
            clientType: ClientType.potential,
            marketType: MarketType.commercial, // Wrong
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '4',
            firstName: 'Wrong',
            lastName: 'ProductType',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.gsisPensioner, // Wrong
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '5',
            firstName: 'Wrong',
            lastName: 'PensionType',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.gsis, // Wrong
            createdAt: DateTime.now(),
          ),
        ];

        // Apply all four filters
        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          productType: ProductType.sssPensioner,
        );

        final filtered = testClients.where(filter.matches).toList();

        // Verify: Only the perfect match
        expect(filtered.length, 1);
        expect(filtered[0].id, '1');
      });

      test('empty filter returns all clients (no filtering applied)', () {
        final testClients = [
          Client(
            id: '1',
            firstName: 'John',
            lastName: 'Doe',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '2',
            firstName: 'Jane',
            lastName: 'Smith',
            clientType: ClientType.existing,
            marketType: MarketType.commercial,
            productType: ProductType.gsisPensioner,
            pensionType: PensionType.gsis,
            createdAt: DateTime.now(),
          ),
        ];

        final filter = ClientAttributeFilter.none();
        final filtered = testClients.where(filter.matches).toList();

        expect(filtered.length, 2);
        expect(filtered.map((c) => c.id).toSet(), {'1', '2'});
      });

      test('handles clients with null address data gracefully', () {
        final testClients = [
          Client(
            id: '1',
            firstName: 'John',
            lastName: 'Doe',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
            addresses: [], // Empty addresses
          ),
        ];

        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
        );

        expect(() => testClients.where(filter.matches), returnsNormally);
        expect(testClients.where(filter.matches).length, 1);
      });
    });

    group('All Clients Mode (Server Filtering)', () {
      test('converts all filter types to API query parameters', () {
        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          productType: ProductType.sssPensioner,
        );

        final params = filter.toQueryParams();

        // Verify all filters are converted to uppercase format
        expect(params['client_type'], 'POTENTIAL');
        expect(params['market_type'], 'RESIDENTIAL');
        expect(params['pension_type'], 'SSS');
        expect(params['product_type'], 'SSS_PENSIONER');
      });

      test('excludes null filters from API parameters (server receives only active filters)', () {
        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
          // Other filters are null
        );

        final params = filter.toQueryParams();

        // Verify only non-null filters are included
        expect(params.containsKey('client_type'), true);
        expect(params.containsKey('market_type'), false);
        expect(params.containsKey('pension_type'), false);
        expect(params.containsKey('product_type'), false);
      });

      test('converts product type enum values to correct API format', () {
        final sssFilter = ClientAttributeFilter(
          productType: ProductType.sssPensioner,
        );
        expect(sssFilter.toQueryParams()['product_type'], 'SSS_PENSIONER');

        final gsisFilter = ClientAttributeFilter(
          productType: ProductType.gsisPensioner,
        );
        expect(gsisFilter.toQueryParams()['product_type'], 'GSIS_PENSIONER');

        final privateFilter = ClientAttributeFilter(
          productType: ProductType.private,
        );
        expect(privateFilter.toQueryParams()['product_type'], 'PRIVATE');
      });

      test('converts pension type enum values to uppercase', () {
        final sssFilter = ClientAttributeFilter(
          pensionType: PensionType.sss,
        );
        expect(sssFilter.toQueryParams()['pension_type'], 'SSS');

        final gsisFilter = ClientAttributeFilter(
          pensionType: PensionType.gsis,
        );
        expect(gsisFilter.toQueryParams()['pension_type'], 'GSIS');

        final privateFilter = ClientAttributeFilter(
          pensionType: PensionType.private,
        );
        expect(privateFilter.toQueryParams()['pension_type'], 'PRIVATE');

        final noneFilter = ClientAttributeFilter(
          pensionType: PensionType.none,
        );
        expect(noneFilter.toQueryParams()['pension_type'], 'NONE');
      });

      test('converts market type enum values to uppercase', () {
        final residentialFilter = ClientAttributeFilter(
          marketType: MarketType.residential,
        );
        expect(residentialFilter.toQueryParams()['market_type'], 'RESIDENTIAL');

        final commercialFilter = ClientAttributeFilter(
          marketType: MarketType.commercial,
        );
        expect(commercialFilter.toQueryParams()['market_type'], 'COMMERCIAL');

        final industrialFilter = ClientAttributeFilter(
          marketType: MarketType.industrial,
        );
        expect(industrialFilter.toQueryParams()['market_type'], 'INDUSTRIAL');
      });
    });

    group('Filter State Management', () {
      test('activeFilterCount updates correctly', () {
        final filter0 = ClientAttributeFilter.none();
        expect(filter0.activeFilterCount, 0);

        final filter1 = ClientAttributeFilter(
          clientType: ClientType.potential,
        );
        expect(filter1.activeFilterCount, 1);

        final filter2 = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );
        expect(filter2.activeFilterCount, 2);

        final filter4 = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          productType: ProductType.sssPensioner,
        );
        expect(filter4.activeFilterCount, 4);
      });

      test('hasFilter returns correct boolean value', () {
        final emptyFilter = ClientAttributeFilter.none();
        expect(emptyFilter.hasFilter, false);

        final filterWithOne = ClientAttributeFilter(
          clientType: ClientType.potential,
        );
        expect(filterWithOne.hasFilter, true);
      });

      test('copyWith creates independent filter instances', () {
        final original = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        final updated = original.copyWith(
          clientType: ClientType.existing,
        );

        // Original should be unchanged
        expect(original.clientType, ClientType.potential);
        expect(original.marketType, MarketType.residential);

        // Updated should have new value for changed field
        expect(updated.clientType, ClientType.existing);
        expect(updated.marketType, MarketType.residential);
      });

      test('copyWith updates individual filters', () {
        final original = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        final updated = original.copyWith(
          clientType: ClientType.existing, // Update this filter
        );

        expect(original.clientType, ClientType.potential); // Unchanged
        expect(updated.clientType, ClientType.existing); // Updated
        expect(updated.marketType, MarketType.residential); // Unchanged
      });

      test('equality works correctly for filter comparison', () {
        final filter1 = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        final filter2 = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        final filter3 = ClientAttributeFilter(
          clientType: ClientType.existing,
          marketType: MarketType.residential,
        );

        expect(filter1, equals(filter2));
        expect(filter1, isNot(equals(filter3)));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('handles null enum values correctly in matches', () {
        final testClients = [
          Client(
            id: '1',
            firstName: 'John',
            lastName: 'Doe',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
        ];

        // Filter with null values should not cause errors
        final filter = ClientAttributeFilter(
          clientType: null,
          marketType: null,
          pensionType: null,
          productType: null,
        );

        expect(() => testClients.where(filter.matches), returnsNormally);
        expect(testClients.where(filter.matches).length, 1);
      });

      test('partial filter matches clients with matching attributes', () {
        final testClients = [
          Client(
            id: '1',
            firstName: 'John',
            lastName: 'Doe',
            clientType: ClientType.potential,
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
          Client(
            id: '2',
            firstName: 'Jane',
            lastName: 'Smith',
            clientType: ClientType.existing, // Different
            marketType: MarketType.residential,
            productType: ProductType.sssPensioner,
            pensionType: PensionType.sss,
            createdAt: DateTime.now(),
          ),
        ];

        // Only filter by market_type
        final filter = ClientAttributeFilter(
          marketType: MarketType.residential,
        );

        final filtered = testClients.where(filter.matches).toList();

        // Both should match since both have residential market type
        expect(filtered.length, 2);
      });

      test('toString provides useful debugging information', () {
        final filter = ClientAttributeFilter(
          clientType: ClientType.potential,
          marketType: MarketType.residential,
        );

        final str = filter.toString();
        expect(str, contains('ClientAttributeFilter'));
        expect(str, contains('clientType'));
        expect(str, contains('marketType'));
      });
    });
  });
}
