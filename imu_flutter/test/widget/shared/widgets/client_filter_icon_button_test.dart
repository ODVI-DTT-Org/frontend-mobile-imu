// test/widget/shared/widgets/client_filter_icon_button_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:imu_flutter/features/clients/presentation/widgets/client_filter_icon_button.dart';
import 'package:imu_flutter/shared/providers/client_attribute_filter_provider.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';

void main() {
  group('ClientFilterIconButton', () {
    testWidgets('displays icon without badge when no filters active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeFilterCountProvider.overrideWithValue(0),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterIconButton(
                showAttributeOnly: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(badges.Badge), findsNothing);
    });

    testWidgets('displays badge with count when filters active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeFilterCountProvider.overrideWithValue(3),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterIconButton(
                showAttributeOnly: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(badges.Badge), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterIconButton(
                showAttributeOnly: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.byType(IconButton));

      expect(tapped, true);
    });
  });
}