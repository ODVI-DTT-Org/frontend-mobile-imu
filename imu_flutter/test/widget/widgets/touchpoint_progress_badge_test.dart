import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/client/touchpoint_progress_badge.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

Client createTestClient({int touchpointCount = 0}) {
  final now = DateTime.now();
  return Client(
    id: 'test-client-1',
    firstName: 'Test',
    lastName: 'Client',
    clientType: ClientType.potential,
    productType: ProductType.sssPensioner,
    pensionType: PensionType.sss,
    createdAt: now,
    touchpoints: List.generate(
      touchpointCount,
      (index) => Touchpoint(
        id: 'tp-$index',
        clientId: 'test-client-1',
        touchpointNumber: index + 1,
        type: TouchpointPattern.types[index],
        date: now,
        reason: TouchpointReason.interested,
        createdAt: now,
      ),
    ),
  );
}

void main() {
  group('TouchpointProgressBadge', () {
    testWidgets('uses client.touchpoints.length when touchpointCount not provided', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 3);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(client: client),
          ),
        ),
      );

      // Assert - 3 completed, next is 4th (Visit)
      expect(find.text('3/7 • visit'), findsOneWidget);
    });

    testWidgets('uses provided touchpointCount when available', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 0); // Empty in client model

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TouchpointProgressBadge(
              client: client,
              touchpointCount: 5, // Override with provided count
            ),
          ),
        ),
      );

      // Assert - 5 completed, next is 6th (Call)
      expect(find.text('5/7 • call'), findsOneWidget);
    });

    testWidgets('shows 0/7 when touchpointCount is 0', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 0);

      // Act
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

      // Assert - 0 completed, next is 1st (Visit)
      expect(find.text('0/7 • visit'), findsOneWidget);
    });

    testWidgets('shows Completed when touchpointCount is 7', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 0);

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

      // Assert
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('7/7'), findsNothing);
    });

    testWidgets('shows correct next touchpoint type (Visit/Call)', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 0);

      // Act - Test 0 completed -> Next is 1st touchpoint (Visit)
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

      // Assert - 1st touchpoint is Visit (should show mapPin icon)
      expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
    });

    testWidgets('shows Call icon for 2nd touchpoint', (tester) async {
      // Arrange
      final client = createTestClient(touchpointCount: 0);

      // Act - Test 1 completed -> Next is 2nd touchpoint (Call)
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

      // Assert - 2nd touchpoint is Call (should show phone icon)
      expect(find.byIcon(LucideIcons.phone), findsOneWidget);
    });
  });
}
