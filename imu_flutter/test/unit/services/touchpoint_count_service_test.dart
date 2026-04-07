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
}
