import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:imu_flutter/shared/widgets/location_filter_icon.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('LocationFilterIcon', () {
    testWidgets('should display filter icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterIcon(
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.filter), findsOneWidget);
    });

    testWidgets('should be gray when no filter active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => LocationFilterNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterIcon(
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(LucideIcons.filter));
      expect(icon.color, Colors.grey);
    });

    testWidgets('should be primary color when filter active', (tester) async {
      final notifier = LocationFilterNotifier();
      notifier.updateFilter(LocationFilter(province: 'Pangasinan'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationFilterProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterIcon(
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(LucideIcons.filter));
      expect(icon.color, const Color(0xFF0F172A));
    });

    testWidgets('should call onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterIcon(
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });
  });
}
