import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  late ClientApiService clientApiService;

  setUp(() {
    clientApiService = ClientApiService();
  });

  group('ClientApiService', () {
    // TODO: Phase 1 - Add PowerSync/Supabase integration tests
    test('fetchClients returns empty list when no backend integration', () async {
      // Act
      final result = await clientApiService.fetchClients();

      // Assert - Currently returns empty list until PowerSync integration
      expect(result, isEmpty);
    });

    test('fetchClient returns null when no backend integration', () async {
      // Act
      final result = await clientApiService.fetchClient('test-id');

      // Assert - Currently returns null until PowerSync integration
      expect(result, isNull);
    });

    test('createClient returns null when no backend integration', () async {
      // Arrange
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        clientType: ClientType.existing,
        productType: ProductType.sssPensioner,
        pensionType: PensionType.sss,
        marketType: MarketType.residential,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      final result = await clientApiService.createClient(client);

      // Assert - Currently returns null until PowerSync integration
      expect(result, isNull);
    });

    test('updateClient returns null when no backend integration', () async {
      // Arrange
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Updated',
        email: 'john.updated@example.com',
        clientType: ClientType.existing,
        productType: ProductType.sssPensioner,
        pensionType: PensionType.sss,
        marketType: MarketType.residential,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      final result = await clientApiService.updateClient(client);

      // Assert - Currently returns null until PowerSync integration
      expect(result, isNull);
    });

    test('deleteClient completes without error', () async {
      // Act & Assert - Should not throw
      await clientApiService.deleteClient('test-id');
    });
  });
}
