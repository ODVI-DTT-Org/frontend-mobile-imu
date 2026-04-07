import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:imu_flutter/shared/widgets/location_filter_chips.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('LocationFilterChips', () {
    testWidgets('should show nothing when no filter active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilter.none()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationFilterChips(),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsNothing);
      expect(find.text('Clear All'), findsNothing);
    });

    testWidgets('should show province chip when province filter active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilter(province: 'Pangasinan')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationFilterChips(),
            ),
          ),
        ),
      );

      expect(find.text('Pangasinan'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsWidgets);
    });

    testWidgets('should show province and municipality chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilter(
              province: 'Pangasinan',
              municipalities: ['Dagupan', 'Urdaneta'],
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationFilterChips(),
            ),
          ),
        ),
      );

      expect(find.textContaining('Pangasinan'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('should remove filter when chip x is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilter(province: 'Pangasinan')),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationFilterChips(),
            ),
          ),
        ),
      );

      // Chip should be visible
      expect(find.text('Pangasinan'), findsOneWidget);

      // Tap on the chip container (not just the icon)
      await tester.tap(find.text('Pangasinan').first);
      await tester.pumpAndSettle();

      // Chip should be removed (filter cleared)
      expect(find.text('Pangasinan'), findsNothing);
    });

    testWidgets('should clear all filters when Clear All is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilter(
              province: 'Pangasinan',
              municipalities: ['Dagupan'],
            )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationFilterChips(),
            ),
          ),
        ),
      );

      // Chips should be visible
      expect(find.textContaining('Pangasinan'), findsOneWidget);

      await tester.tap(find.text('Clear All'));
      await tester.pump();

      // All chips should be removed
      expect(find.textContaining('Pangasinan'), findsNothing);
    });
  });
}
