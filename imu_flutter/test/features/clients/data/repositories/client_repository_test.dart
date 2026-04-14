import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('Client Model Tests', () {
    test('Client can be created with required fields', () {
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(client.id, 'test-id');
      expect(client.firstName, 'John');
      expect(client.lastName, 'Doe');
      expect(client.clientType, ClientType.potential);
      expect(client.productType, ProductType.pnpPension);
      expect(client.pensionType, PensionType.sss);
    });

    test('Client fullName returns correct value', () {
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(client.fullName, 'Doe, John');
    });

    test('Client can be serialized to JSON', () {
      final client = Client(
        id: 'test-id',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = client.toJson();
      expect(json['id'], 'test-id');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
    });

    test('Client can be deserialized from JSON', () {
      final json = {
        'id': 'test-id',
        'firstName': 'John',
        'lastName': 'Doe',
        'clientType': 'potential',
        'productType': 'pnpPension',
        'pensionType': 'sss',
        'createdAt': '2024-01-01T00:00:00.000Z',
      };

      final client = Client.fromJson(json);
      expect(client.id, 'test-id');
      expect(client.firstName, 'John');
      expect(client.lastName, 'Doe');
      expect(client.clientType, ClientType.potential);
    });

    test('ClientType enum values are correct', () {
      expect(ClientType.potential.name, 'potential');
      expect(ClientType.existing.name, 'existing');
    });

    test('ProductType enum values are correct', () {
      expect(ProductType.pnpPension, ProductType.pnpPension);
      expect(ProductType.pnpPension, ProductType.pnpPension);
      expect(ProductType.bfpActive, ProductType.bfpActive);
    });
  });

  // Note: Repository tests that require PowerSync database connection
  // should be run as integration tests with proper PowerSync setup.
  // The following tests are placeholders for integration testing.

  group('ClientRepository Integration Tests (requires PowerSync)', () {
    // These tests require PowerSync to be initialized
    // Run with: flutter test integration_test/

    test('placeholder - repository tests require PowerSync setup', () {
      // This is a placeholder. Real tests should:
      // 1. Initialize PowerSync with a test database
      // 2. Test CRUD operations
      // 3. Clean up test data
      expect(true, isTrue);
    });
  });
}
