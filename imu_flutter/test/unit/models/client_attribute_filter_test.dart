import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('ClientAttributeFilter', () {
    test('none() returns filter with no values set', () {
      final filter = ClientAttributeFilter.none();
      expect(filter.clientTypes, isNull);
      expect(filter.marketTypes, isNull);
      expect(filter.pensionTypes, isNull);
      expect(filter.productTypes, isNull);
    });

    test('hasFilter returns false when no filters set', () {
      expect(ClientAttributeFilter.none().hasFilter, false);
    });

    test('hasFilter returns true when any filter list is non-empty', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      expect(filter.hasFilter, true);
    });

    test('activeFilterCount sums total selected values across all categories', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
        pensionTypes: [PensionType.sss],
      );
      expect(filter.activeFilterCount, 3);
    });

    test('matches returns true when no filters set', () {
      final filter = ClientAttributeFilter.none();
      final client = _makeClient(ClientType.potential, MarketType.residential, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), true);
    });

    test('matches returns true when client value is in list (OR within category)', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
      );
      final client = _makeClient(ClientType.existing, MarketType.residential, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), true);
    });

    test('matches returns false when client value is NOT in list', () {
      final filter = ClientAttributeFilter(
        pensionTypes: [PensionType.sss, PensionType.gsis],
      );
      final client = _makeClient(ClientType.potential, MarketType.residential, PensionType.private, ProductType.pnpPension);
      expect(filter.matches(client), false);
    });

    test('matches uses AND across categories', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential],
        marketTypes: [MarketType.residential],
      );
      // Correct client type, wrong market type
      final client = _makeClient(ClientType.potential, MarketType.commercial, PensionType.sss, ProductType.pnpPension);
      expect(filter.matches(client), false);
    });

    test('toQueryParams emits comma-separated uppercase values', () {
      final filter = ClientAttributeFilter(
        clientTypes: [ClientType.potential, ClientType.existing],
        marketTypes: [MarketType.residential],
        pensionTypes: [PensionType.sss, PensionType.gsis],
        productTypes: [ProductType.pnpPension, ProductType.bfpActive],
      );
      final params = filter.toQueryParams();
      expect(params['client_type'], 'POTENTIAL,EXISTING');
      expect(params['market_type'], 'RESIDENTIAL');
      expect(params['pension_type'], 'SSS,GSIS');
      expect(params['product_type'], 'PNP PENSION,BFP ACTIVE');
    });

    test('toQueryParams excludes empty lists', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      final params = filter.toQueryParams();
      expect(params['client_type'], 'POTENTIAL');
      expect(params.containsKey('market_type'), false);
      expect(params.containsKey('pension_type'), false);
      expect(params.containsKey('product_type'), false);
    });

    test('toQueryParams returns empty map when no filters', () {
      expect(ClientAttributeFilter.none().toQueryParams(), isEmpty);
    });

    test('copyWith preserves unspecified fields', () {
      final filter = ClientAttributeFilter(clientTypes: [ClientType.potential]);
      final updated = filter.copyWith(pensionTypes: [PensionType.sss]);
      expect(updated.clientTypes, [ClientType.potential]);
      expect(updated.pensionTypes, [PensionType.sss]);
    });

    test('equality: two filters with same lists are equal', () {
      final a = ClientAttributeFilter(clientTypes: [ClientType.potential, ClientType.existing]);
      final b = ClientAttributeFilter(clientTypes: [ClientType.potential, ClientType.existing]);
      expect(a, equals(b));
    });
  });
}

Client _makeClient(ClientType ct, MarketType mt, PensionType pt, ProductType pdt) {
  return Client(
    id: '1',
    firstName: 'Test',
    lastName: 'User',
    clientType: ct,
    marketType: mt,
    pensionType: pt,
    productType: pdt,
    createdAt: DateTime.now(),
  );
}
