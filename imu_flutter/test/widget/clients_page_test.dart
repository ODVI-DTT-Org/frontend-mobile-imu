import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/presentation/pages/clients_page.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

import '../mocks/mocks.dart';

// Test helper to create sample clients
Client _createTestClient({
  required String id,
  required String firstName,
  required String lastName,
  ClientType clientType = ClientType.potential,
}) {
  return Client(
    id: id,
    firstName: firstName,
    lastName: lastName,
    middleName: null,
    agencyName: null,
    department: null,
    position: null,
    employmentStatus: null,
    payrollDate: null,
    tenure: null,
    birthDate: null,
    phone: null,
    remarks: null,
    pan: null,
    facebookLink: null,
    email: '$firstName@example.com',
    clientType: clientType,
    marketType: MarketType.residential,
    productType: ProductType.sssPensioner,
    pensionType: PensionType.sss,
    phoneNumbers: [],
    addresses: [],
    touchpoints: [],
    createdAt: DateTime.now(),
  );
}

void main() {
  group('ClientsPage Widget Tests', () {
    testWidgets('renders app bar with title and add button',
        (WidgetTester tester) async {
      // Arrange
      final testClients = [
        _createTestClient(id: '1', firstName: 'John', lastName: 'Doe'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => testClients),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('My Clients'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows empty state when no clients',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No clients yet'), findsOneWidget);
    });

    testWidgets('shows loading indicator while loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) async => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) async => throw Exception('Test error')),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Should show error state
      expect(find.text('Failed to load'), findsOneWidget);
    });

    testWidgets('shows search bar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Search bar should be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search clients...'), findsOneWidget);
    });

    testWidgets('shows filter dialog when tapping filter button', (WidgetTester tester) async {
      // Arrange
      final testClients = [
        _createTestClient(id: '1', firstName: 'John', lastName: 'Doe'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => testClients),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap filter button (filter icon)
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert - Filter dialog should appear
      expect(find.text('Filter Options'), findsOneWidget);
      expect(find.text('Market Type'), findsOneWidget);
      expect(find.text('Product Type'), findsOneWidget);
    });
  });
}
