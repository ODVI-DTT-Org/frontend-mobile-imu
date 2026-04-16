import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/touchpoint/touchpoint_count_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('TouchpointCountService', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchFromPowerSync returns empty map for empty client list', () async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);

      // Act
      final result = await service.fetchFromPowerSync([]);

      // Assert
      expect(result, isEmpty);
    });

    test('fetchCounts returns empty map for empty client list', () async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);

      // Act
      final result = await service.fetchCounts([]);

      // Assert
      expect(result, isEmpty);
    });

    test('fetchFromAPI returns empty map for empty client list', () async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);

      // Act
      final result = await service.fetchFromAPI([]);

      // Assert
      expect(result, isEmpty);
    });

    // Note: Full integration tests with PowerSync and API mocking
    // require database test setup and are covered in integration tests
  });

  group('Client.completedTouchpoints', () {
    test('should return touchpointNumber minus 1', () {
      final client = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.existing,
        productType: ProductType.bfpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpointNumber: 3, // Has 2 completed touchpoints
        touchpointSummary: [],
      );

      expect(client.completedTouchpoints, 2); // touchpointNumber - 1
    });

    test('should return 0 when touchpointNumber is 1', () {
      final client = Client(
        id: 'client-1',
        firstName: 'Jane',
        lastName: 'Smith',
        clientType: ClientType.existing,
        productType: ProductType.bfpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpointNumber: 1, // Has 0 completed touchpoints
        touchpointSummary: [],
      );

      expect(client.completedTouchpoints, 0); // touchpointNumber - 1
    });

    test('should handle multiple clients correctly', () {
      final clients = [
        Client(
          id: 'client-1',
          firstName: 'John',
          lastName: 'Doe',
          clientType: ClientType.existing,
          productType: ProductType.bfpPension,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
          touchpointNumber: 3, // 2 completed
          touchpointSummary: [],
        ),
        Client(
          id: 'client-2',
          firstName: 'Jane',
          lastName: 'Smith',
          clientType: ClientType.existing,
          productType: ProductType.bfpPension,
          pensionType: PensionType.sss,
          createdAt: DateTime.now(),
          touchpointNumber: 5, // 4 completed
          touchpointSummary: [],
        ),
      ];

      final expectedCounts = {
        'client-1': 2, // touchpointNumber - 1
        'client-2': 4, // touchpointNumber - 1
      };

      expect(clients[0].completedTouchpoints, expectedCounts['client-1']);
      expect(clients[1].completedTouchpoints, expectedCounts['client-2']);
    });
  });
}
