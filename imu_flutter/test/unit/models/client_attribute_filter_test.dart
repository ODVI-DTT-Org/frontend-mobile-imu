// test/unit/models/client_attribute_filter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('ClientAttributeFilter', () {
    test('none() returns filter with no values set', () {
      final filter = ClientAttributeFilter.none();
      expect(filter.clientType, isNull);
      expect(filter.marketType, isNull);
      expect(filter.pensionType, isNull);
      expect(filter.productType, isNull);
    });

    test('hasFilter returns false when no filters set', () {
      final filter = ClientAttributeFilter.none();
      expect(filter.hasFilter, false);
    });

    test('hasFilter returns true when any filter is set', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
      );
      expect(filter.hasFilter, true);
    });

    test('activeFilterCount returns correct count', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
      );
      expect(filter.activeFilterCount, 2);
    });

    test('matches returns true when client matches all filters', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
      );

      final client = Client(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        marketType: MarketType.residential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
      );

      expect(filter.matches(client), true);
    });

    test('matches returns false when client fails any filter', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
      );

      final client = Client(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.existing, // Wrong!
        marketType: MarketType.residential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
      );

      expect(filter.matches(client), false);
    });

    test('matches returns true when filter is empty', () {
      final filter = ClientAttributeFilter.none();

      final client = Client(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
      );

      expect(filter.matches(client), true);
    });

    test('toQueryParams returns correct API parameters', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
        pensionType: PensionType.sss,
        productType: ProductType.pnpPension,
      );

      final params = filter.toQueryParams();

      expect(params['client_type'], 'POTENTIAL');
      expect(params['market_type'], 'RESIDENTIAL');
      expect(params['pension_type'], 'SSS');
      expect(params['product_type'], 'SSS_PENSIONER');
    });

    test('toQueryParams excludes null values', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
      );

      final params = filter.toQueryParams();

      expect(params['client_type'], 'POTENTIAL');
      expect(params.containsKey('market_type'), false);
      expect(params.containsKey('pension_type'), false);
      expect(params.containsKey('product_type'), false);
    });

    test('copyWith creates new instance with updated values', () {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
      );

      final updated = filter.copyWith(clientType: ClientType.existing);

      expect(filter.clientType, ClientType.potential); // Original unchanged
      expect(updated.clientType, ClientType.existing);
    });
  });
}
