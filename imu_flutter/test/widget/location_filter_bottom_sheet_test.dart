import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:imu_flutter/shared/widgets/location_filter_bottom_sheet.dart';

void main() {
  group('LocationFilterBottomSheet', () {
    testWidgets('should display title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterBottomSheet(
                onApply: (filter) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Filter by Location'), findsOneWidget);
    });

    testWidgets('should display province section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignedAreasProvider.overrideWith((ref) => AssignedAreas(
              provinces: {'Pangasinan', 'Cebu'},
              municipalitiesByProvince: {
                'Pangasinan': {'Dagupan', 'Urdaneta'},
                'Cebu': {'Cebu City', 'Mandaue'},
              },
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterBottomSheet(
                onApply: (filter) {}),
            ),
          ),
        ),
      );

      expect(find.text('Province'), findsOneWidget);
      expect(find.text('Pangasinan'), findsOneWidget);
      expect(find.text('Cebu'), findsOneWidget);
    });

    testWidgets('should display municipality section after selecting province', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignedAreasProvider.overrideWith((ref) => AssignedAreas(
              provinces: {'Pangasinan'},
              municipalitiesByProvince: {
                'Pangasinan': {'Dagupan', 'Urdaneta'},
              },
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: LocationFilterBottomSheet(
                onApply: (filter) {}),
            ),
          ),
        ),
      );

      // Tap on Pangasinan province
      await tester.tap(find.text('Pangasinan'));
      await tester.pump();

      expect(find.text('Municipality'), findsOneWidget);
      expect(find.text('All Municipalities'), findsOneWidget);
      expect(find.text('Dagupan'), findsOneWidget);
      expect(find.text('Urdaneta'), findsOneWidget);
    });

    testWidgets('should call onApply with filter when Apply button tapped', (tester) async {
      LocationFilter? appliedFilter;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignedAreasProvider.overrideWith((ref) => AssignedAreas(
              provinces: {'Pangasinan'},
              municipalitiesByProvince: {
                'Pangasinan': {'Dagupan'},
              },
            )),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800,
                child: LocationFilterBottomSheet(
                  onApply: (filter) {
                    appliedFilter = filter;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select province by tapping on RadioListTile
      await tester.tap(find.byType(RadioListTile<String>).first);
      await tester.pumpAndSettle();

      // Select municipality by tapping on CheckboxListTile (skip "All Municipalities")
      final checkboxTiles = find.byType(CheckboxListTile);
      expect(checkboxTiles, findsWidgets);

      // Tap the second checkbox (Dagupan, not "All Municipalities")
      await tester.tap(checkboxTiles.at(1));
      await tester.pumpAndSettle();

      // Tap Apply button
      final applyButton = find.text('Apply');
      expect(applyButton, findsOneWidget);

      // Find the ElevatedButton widget and tap it
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(appliedFilter, isNotNull);
      expect(appliedFilter?.province, 'Pangasinan');
      expect(appliedFilter?.municipalities, ['Dagupan']);
    });
  });
}
