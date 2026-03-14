import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/clients/presentation/pages/clients_page.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/services/sync/sync_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';

import '../mocks/mocks.dart';

// Test helper to create sample clients
Client _createTestClient({
  required String id,
  required String firstName,
  required String lastName,
  ClientType clientType = ClientType.potential,
  int completedTouchpoints = 0,
}) {
  return Client(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: '$firstName@example.com',
    clientType: clientType,
    productType: ProductType.sssPensioner,
    pensionType: 'SSS',
    marketType: 'Residential',
    phoneNumbers: [],
    addresses: [],
    touchpoints: [],
    createdAt: DateTime.now(),
    completedTouchpoints: completedTouchpoints,
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
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
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
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No clients found'), findsOneWidget);
      expect(
          find.text('Pull down to refresh or add a new client'),
          findsOneWidget);
    });

    testWidgets('displays list of clients', (WidgetTester tester) async {
      // Arrange
      final testClients = [
        _createTestClient(id: '1', firstName: 'John', lastName: 'Doe'),
        _createTestClient(id: '2', firstName: 'Jane', lastName: 'Smith'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => testClients),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('shows search field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Search clients...'), findsOneWidget);
    });

    testWidgets('shows Potential and Existing tabs',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Potential'), findsOneWidget);
      expect(find.text('Existing'), findsOneWidget);
    });

    testWidgets('filters by tab selection', (WidgetTester tester) async {
      // Arrange
      final testClients = [
        _createTestClient(
          id: '1',
          firstName: 'Potential',
          lastName: 'Client',
          clientType: ClientType.potential,
        ),
        _createTestClient(
          id: '2',
          firstName: 'Existing',
          lastName: 'Client',
          clientType: ClientType.existing,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => testClients),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially shows Potential tab
      expect(find.text('Potential Client'), findsOneWidget);
      expect(find.text('Existing Client'), findsNothing);

      // Tap Existing tab
      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();

      // Now shows Existing clients
      expect(find.text('Existing Client'), findsOneWidget);
      expect(find.text('Potential Client'), findsNothing);
    });

    testWidgets('search filters clients by name', (WidgetTester tester) async {
      // Arrange
      final testClients = [
        _createTestClient(id: '1', firstName: 'John', lastName: 'Doe'),
        _createTestClient(id: '2', firstName: 'Jane', lastName: 'Smith'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => testClients),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type in search
      await tester.enterText(
          find.widgetWithText(TextField, 'Search clients...'), 'John');
      await tester.pump();

      // Assert - Only John should be visible
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsNothing);
    });

    testWidgets('shows loading indicator while loading',
        (WidgetTester tester) async {
      // Arrange - Async value in loading state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => throw Exception('Loading')),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: ClientsPage(),
          ),
        ),
      );

      // Should show error state
      await tester.pumpAndSettle();

      // Assert - Error state should have retry button
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tapping filter button shows filter dialog',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientsProvider.overrideWith((ref) => []),
            hiveServiceProvider.overrideWith((ref) => MockHiveService()),
            syncServiceProvider.overrideWith((ref) => MockSyncService()),
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

// Mock SyncService
class MockSyncService extends SyncService {
  MockSyncService() : super(hiveService: MockHiveService());

  @override
  Future<void> queueForSync({
    required String id,
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {}
}
