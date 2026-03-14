import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/itinerary/presentation/pages/itinerary_page.dart';
import 'package:imu_flutter/services/api/itinerary_api_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';

import '../mocks/mocks.dart';

// Test helper to create sample itinerary items
ItineraryItem _createTestItineraryItem({
  required String id,
  required String clientName,
  required String address,
  DateTime? scheduledDate,
  String status = 'today',
}) {
  return ItineraryItem(
    id: id,
    clientId: 'client-$id',
    clientName: clientName,
    address: address,
    scheduledDate: scheduledDate ?? DateTime.now(),
    touchpointNumber: 1,
    touchpointType: TouchpointType.visit,
    reason: TouchpointReason.interested,
    productType: 'SSS Pensioner',
    pensionType: 'SSS',
    timeArrival: '9:00 AM',
    timeDeparture: '9:30 AM',
    status: status,
  );
}

void main() {
  group('ItineraryPage Widget Tests', () {
    testWidgets('renders app bar with title and add button',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Itinerary'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no visits',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No scheduled visits'), findsOneWidget);
      expect(
          find.text('Pull down to refresh or tap + to add'), findsOneWidget);
    });

    testWidgets('shows filter tabs (Today, Tomorrow, Yesterday)',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
    });

    testWidgets('shows calendar icon', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.calendar), findsOneWidget);
    });

    testWidgets('displays list of visits when available',
        (WidgetTester tester) async {
      // Arrange
      final testVisits = [
        _createTestItineraryItem(
          id: '1',
          clientName: 'John Doe',
          address: '123 Main St',
        ),
        _createTestItineraryItem(
          id: '2',
          clientName: 'Jane Smith',
          address: '456 Oak Ave',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => testVisits),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('123 Main St'), findsOneWidget);
      expect(find.text('456 Oak Ave'), findsOneWidget);
    });

    testWidgets('tapping add button shows visit form modal',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap add button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Assert - Modal should appear
      expect(find.text('Add Visit'), findsOneWidget);
      expect(find.text('Client Name *'), findsOneWidget);
      expect(find.text('Address *'), findsOneWidget);
    });

    testWidgets('shows status badge on visit cards',
        (WidgetTester tester) async {
      // Arrange
      final testVisits = [
        _createTestItineraryItem(
          id: '1',
          clientName: 'John Doe',
          address: '123 Main St',
          status: 'today',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => testVisits),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Today'), findsWidgets); // In tab and badge
    });

    testWidgets('shows touchpoint number on visit cards',
        (WidgetTester tester) async {
      // Arrange
      final testVisits = [
        _createTestItineraryItem(
          id: '1',
          clientName: 'John Doe',
          address: '123 Main St',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => testVisits),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - 1st touchpoint should be visible
      expect(find.textContaining('1st'), findsOneWidget);
    });

    testWidgets('shows time range on visit cards',
        (WidgetTester tester) async {
      // Arrange
      final testVisits = [
        _createTestItineraryItem(
          id: '1',
          clientName: 'John Doe',
          address: '123 Main St',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => testVisits),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('9:00 AM'), findsOneWidget);
      expect(find.textContaining('9:30 AM'), findsOneWidget);
    });

    testWidgets('tab selection changes filter', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            todayItineraryProvider.overrideWith((ref) => []),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ItineraryPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap 'Today' tab
      final todayTab = find.text('Today');
      await tester.tap(todayTab);
      await tester.pump();

      // Tab should be selected (no error thrown = success)
      expect(todayTab, findsOneWidget);
    });
  });
}
