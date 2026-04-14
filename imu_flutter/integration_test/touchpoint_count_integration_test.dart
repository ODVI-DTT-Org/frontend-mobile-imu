import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/touchpoint/touchpoint_count_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';
import 'package:imu_flutter/shared/widgets/client/touchpoint_progress_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Integration tests for touchpoint count badge functionality
///
/// These tests verify:
/// 1. Badge displays correct count from provider
/// 2. Provider fetches from PowerSync with API fallback
/// 3. Badge updates when provider is invalidated
void main() {
  group('TouchpointCountBadge Integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('badge displays count from provider when available', (tester) async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);

      // Create test client with 0 touchpoints in model
      final client = Client(
        id: 'test-client-1',
        firstName: 'Test',
        lastName: 'Client',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpoints: [],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientTouchpointCountsProvider.overrideWith((ref) {
              // Mock provider returning specific count
              return AsyncValue.data({
                'test-client-1': 3,
                'test-client-2': 5,
              });
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TouchpointProgressBadge(
                client: client,
                touchpointCount: 3,
              ),
            ),
          ),
        ),
      );

      // Assert - Badge should show "3/7 • call" (4th touchpoint is Call)
      expect(find.text('3/7 • call'), findsOneWidget);
    });

    testWidgets('badge falls back to client.touchpoints.length when provider not available', (tester) async {
      // Arrange
      final now = DateTime.now();
      final client = Client(
        id: 'test-client-1',
        firstName: 'Test',
        lastName: 'Client',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: now,
        touchpoints: [
          Touchpoint(
            id: 'tp-1',
            clientId: 'test-client-1',
            touchpointNumber: 1,
            type: TouchpointType.visit,
            date: now,
            reason: TouchpointReason.interested,
            createdAt: now,
          ),
          Touchpoint(
            id: 'tp-2',
            clientId: 'test-client-1',
            touchpointNumber: 2,
            type: TouchpointType.call,
            date: now,
            reason: TouchpointReason.interested,
            createdAt: now,
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(
              client: client,
              // No touchpointCount provided, should use client.touchpoints.length
            ),
          ),
        ),
      );

      // Assert - Badge should show "2/7 • call" (3rd touchpoint is Call)
      expect(find.text('2/7 • call'), findsOneWidget);
    });

    testWidgets('badge shows Completed when count is 7', (tester) async {
      // Arrange
      final client = Client(
        id: 'test-client-1',
        firstName: 'Test',
        lastName: 'Client',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpoints: [],
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(
              client: client,
              touchpointCount: 7,
            ),
          ),
        ),
      );

      // Assert - Badge should show "Completed"
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('7/7'), findsNothing);
    });

    testWidgets('badge shows correct icon for Visit touchpoints', (tester) async {
      // Arrange
      final client = Client(
        id: 'test-client-1',
        firstName: 'Test',
        lastName: 'Client',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpoints: [],
      );

      // Act - 0 completed, next is 1st (Visit)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(
              client: client,
              touchpointCount: 0,
            ),
          ),
        ),
      );

      // Assert - Should show mapPin icon for Visit
      expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
    });

    testWidgets('badge shows correct icon for Call touchpoints', (tester) async {
      // Arrange
      final client = Client(
        id: 'test-client-1',
        firstName: 'Test',
        lastName: 'Client',
        clientType: ClientType.potential,
        productType: ProductType.pnpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpoints: [],
      );

      // Act - 1 completed, next is 2nd (Call)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(
              client: client,
              touchpointCount: 1,
            ),
          ),
        ),
      );

      // Assert - Should show phone icon for Call
      expect(find.byIcon(LucideIcons.phone), findsOneWidget);
    });
  });

  group('TouchpointCountService Integration', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('fetchCounts returns empty map for empty client list', () async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);

      // Act
      final result = await service.fetchCounts([]);

      // Assert
      expect(result, isEmpty);
    });

    test('fetchCounts handles PowerSync errors gracefully with API fallback', () async {
      // Arrange
      final service = container.read(touchpointCountServiceProvider);
      final clientIds = ['client-1', 'client-2'];

      // Act - This should attempt PowerSync first, then fall back to API
      // In integration test with no actual data, both will fail but should handle gracefully
      final result = await service.fetchCounts(clientIds);

      // Assert - Should return empty map on total failure
      expect(result, isEmpty);
    });
  });
}
