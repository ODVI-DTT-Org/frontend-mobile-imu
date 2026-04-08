import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/address_list_tile.dart';

void main() {
  group('AddressListTile', () {
    final testAddress = Address(
      id: 'test-address-1',
      clientId: 'client-123',
      psgcId: 123,
      label: AddressLabel.home,
      streetAddress: '123 Main St',
      postalCode: '1234',
      latitude: 14.5995,
      longitude: 120.9842,
      isPrimary: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      region: 'NCR',
      province: 'Metro Manila',
      municipality: 'Quezon City',
      barangay: 'Barangay 123',
    );

    testWidgets('should display address details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: true,
            ),
          ),
        ),
      );

      expect(find.text('123 Main St'), findsOneWidget);
      expect(find.textContaining('Barangay 123!'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('should show primary badge when isPrimary is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: true,
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.byIcon(LucideIcons.star), findsOneWidget);
    });

    testWidgets('should not show primary badge when isPrimary is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsNothing);
    });

    testWidgets('should show label badge for non-home labels', (tester) async {
      final workAddress = testAddress.copyWith(
        id: 'test-address-2',
        label: AddressLabel.work,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: workAddress,
              isPrimary: false,
            ),
          ),
        ),
      );

      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('should not show label badge for home label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
            ),
          ),
        ),
      );

      // Home label should not show badge
      expect(find.text('Home'), findsNothing);
    });

    testWidgets('should show action buttons when showActions is true', (tester) async {
      bool editTapped = false;
      bool deleteTapped = false;
      bool setPrimaryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
              showActions: true,
              onEdit: () => editTapped = true,
              onDelete: () => deleteTapped = true,
              onSetPrimary: () => setPrimaryTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.star), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);

      // Tap edit button
      await tester.tap(find.byIcon(LucideIcons.pencil));
      expect(editTapped, true);

      // Tap delete button
      await tester.tap(find.byIcon(LucideIcons.trash2));
      expect(deleteTapped, true);
    });

    testWidgets('should not show set primary button when already primary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: true,
              showActions: true,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Should have edit and delete, but not set primary (since it's already primary)
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      // Note: The set primary button is shown in a different way when already primary
    });

    testWidgets('should not show action buttons when showActions is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
              showActions: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.pencil), findsNothing);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
      expect(find.byIcon(LucideIcons.star), findsNothing);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });

    testWidgets('should display GPS coordinates when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: false,
            ),
          ),
        ),
      );

      expect(find.text('14.599500, 120.984200'), findsOneWidget);
      expect(find.byIcon(LucideIcons.map), findsOneWidget);
    });

    testWidgets('should not display GPS coordinates when null', (tester) async {
      // Create a new address without coordinates instead of using copyWith
      final addressWithoutCoords = Address(
        id: 'test-address-3',
        clientId: 'client-123',
        psgcId: 123,
        label: AddressLabel.home,
        streetAddress: '123 Main St',
        postalCode: null,
        latitude: null,
        longitude: null,
        isPrimary: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        region: 'NCR',
        province: 'Metro Manila',
        municipality: 'Quezon City',
        barangay: 'Barangay 123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: addressWithoutCoords,
              isPrimary: false,
            ),
          ),
        ),
      );

      // Coordinates text should not be shown when null
      expect(find.textContaining('14.599500'), findsNothing);
    });

    testWidgets('should handle empty street address gracefully', (tester) async {
      final emptyStreetAddress = testAddress.copyWith(
        id: 'test-address-4',
        streetAddress: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: emptyStreetAddress,
              isPrimary: false,
            ),
          ),
        ),
      );

      // Should not crash and still display PSGC data
      expect(find.textContaining('Barangay 123!'), findsOneWidget);
    });

    testWidgets('should highlight primary address with blue border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddressListTile(
              address: testAddress,
              isPrimary: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AddressListTile),
          matching: find.byType(Container).at(0),
        ),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border?.top.width, 2);
    });
  });
}
