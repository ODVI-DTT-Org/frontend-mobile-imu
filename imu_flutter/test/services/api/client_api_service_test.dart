import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/core/config/app_config.dart';

void main() {
  // Initialize AppConfig before running tests
  setUpAll(() async {
    await AppConfig.initialize(environment: 'test');
  });

  late ClientApiService clientApiService;

  setUp(() {
    clientApiService = ClientApiService();
  });

  group('ClientApiService', () {
    // TODO: Phase 1 - Add PowerSync/Supabase integration tests
    test('fetchClients throws ApiException when not authenticated', () async {
      // Act & Assert
      expect(
        () => clientApiService.fetchClients(),
        throwsA(isA<ApiException>()),
      );
    });

    test('fetchClient throws ApiException when not authenticated', () async {
      // Act & Assert
      expect(
        () => clientApiService.fetchClient('test-id'),
        throwsA(isA<ApiException>()),
      );
    });

    test('createClient throws ApiException when not authenticated', () async {
      // Arrange
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        clientType: ClientType.existing,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        marketType: MarketType.residential,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(
        () => clientApiService.createClient(client),
        throwsA(isA<ApiException>()),
      );
    });

    test('updateClient throws ApiException when not authenticated', () async {
      // Arrange
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Updated',
        email: 'john.updated@example.com',
        clientType: ClientType.existing,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        marketType: MarketType.residential,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(
        () => clientApiService.updateClient(client),
        throwsA(isA<ApiException>()),
      );
    });

    test('deleteClient throws ApiException when not authenticated', () async {
      // Act & Assert - Should throw ApiException
      expect(
        () => clientApiService.deleteClient('test-id'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
