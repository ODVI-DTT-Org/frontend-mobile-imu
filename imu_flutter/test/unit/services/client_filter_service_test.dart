// test/unit/services/client_filter_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/filter/client_filter_service.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('ClientFilterService', () {
    late ClientFilterService service;
    late List<Client> testClients;

    setUp(() {
      service = ClientFilterService();

      testClients = [
        Client(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          clientType: ClientType.potential,
          marketType: MarketType.residential,
          pensionType: PensionType.sss,
          productType: ProductType.sssPensioner,
          createdAt: DateTime.now(),
        ),
        Client(
          id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          clientType: ClientType.existing,
          marketType: MarketType.commercial,
          pensionType: PensionType.gsis,
          productType: ProductType.gsisPensioner,
          createdAt: DateTime.now(),
        ),
        Client(
          id: '3',
          firstName: 'Bob',
          lastName: 'Johnson',
          clientType: ClientType.potential,
          marketType: MarketType.residential,
          pensionType: PensionType.private,
          productType: ProductType.private,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('filterClients returns all when no filters applied', () {
      final result = service.filterClients(
        clients: testClients,
        searchQuery: '',
        locationFilter: LocationFilter.none(),
        attributeFilter: ClientAttributeFilter.none(),
      );

      expect(result.length, 3);
    });

    test('filterClients filters by search query', () {
      final result = service.filterClients(
        clients: testClients,
        searchQuery: 'john',
        locationFilter: LocationFilter.none(),
        attributeFilter: ClientAttributeFilter.none(),
      );

      expect(result.length, 2); // John Doe, Bob Johnson
      expect(result.every((c) => c.fullName.toLowerCase().contains('john')), true);
    });

    test('filterClients filters by location (province)', () {
      final locationFilter = LocationFilter(province: 'Pangasinan');

      final clientsWithLocation = [
        Client(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          province: 'Pangasinan',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
        ),
        Client(
          id: '2',
          firstName: 'Jane',
          lastName: 'Smith',
          province: 'Metro Manila',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
        ),
      ];

      final result = service.filterClients(
        clients: clientsWithLocation,
        searchQuery: '',
        locationFilter: locationFilter,
        attributeFilter: ClientAttributeFilter.none(),
      );

      expect(result.length, 1);
      expect(result.first.province, 'Pangasinan');
    });

    test('filterClients filters by client attribute (AND logic)', () {
      final attributeFilter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
      );

      final result = service.filterClients(
        clients: testClients,
        searchQuery: '',
        locationFilter: LocationFilter.none(),
        attributeFilter: attributeFilter,
      );

      expect(result.length, 2); // John Doe, Bob Johnson (both potential + residential)
      expect(result.every((c) => c.clientType == ClientType.potential), true);
      expect(result.every((c) => c.marketType == MarketType.residential), true);
    });

    test('filterClients combines search + location + attributes (AND logic)', () {
      final locationFilter = LocationFilter(province: 'Pangasinan');
      final attributeFilter = ClientAttributeFilter(
        clientType: ClientType.potential,
      );

      final clientsWithLocation = [
        Client(
          id: '1',
          firstName: 'John',
          lastName: 'Doe',
          province: 'Pangasinan',
          clientType: ClientType.potential,
          productType: ProductType.sssPensioner,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
        ),
        Client(
          id: '2',
          firstName: 'Jane',
          lastName: 'Doe',
          province: 'Pangasinan',
          clientType: ClientType.existing,
          productType: ProductType.sssPensioner,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
        ),
      ];

      final result = service.filterClients(
        clients: clientsWithLocation,
        searchQuery: 'doe',
        locationFilter: locationFilter,
        attributeFilter: attributeFilter,
      );

      expect(result.length, 1); // John Doe only (matches all criteria)
      expect(result.first.id, '1');
    });

    test('filterClients returns empty when no clients match', () {
      final attributeFilter = ClientAttributeFilter(
        clientType: ClientType.potential,
        pensionType: PensionType.none, // No clients have this
      );

      final result = service.filterClients(
        clients: testClients,
        searchQuery: '',
        locationFilter: LocationFilter.none(),
        attributeFilter: attributeFilter,
      );

      expect(result.length, 0);
    });
  });
}
