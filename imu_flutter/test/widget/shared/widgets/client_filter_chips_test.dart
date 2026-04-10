// test/widget/shared/widgets/client_filter_chips_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/widgets/client_filter_chips.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/models/client_attribute_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('ClientFilterChips', () {
    testWidgets('displays nothing when no filters active', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterChips(
                locationFilter: LocationFilter.none(),
                attributeFilter: ClientAttributeFilter.none(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Chip), findsNothing);
      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('displays location filter chip', (tester) async {
      final filter = LocationFilter(province: 'Pangasinan');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterChips(
                locationFilter: filter,
                attributeFilter: ClientAttributeFilter.none(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Pangasinan'), findsOneWidget);
    });

    testWidgets('displays attribute filter chips', (tester) async {
      final filter = ClientAttributeFilter(
        clientType: ClientType.potential,
        marketType: MarketType.residential,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterChips(
                locationFilter: LocationFilter.none(),
                attributeFilter: filter,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Chip), findsNWidgets(2));
      expect(find.text('Potential'), findsOneWidget);
      expect(find.text('Residential'), findsOneWidget);
    });

    testWidgets('remove button calls onRemove callback', (tester) async {
      FilterType? capturedType;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ClientFilterChips(
                locationFilter: LocationFilter.none(),
                attributeFilter: ClientAttributeFilter(
                  clientType: ClientType.potential,
                ),
                onRemove: (type) => capturedType = type,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Tap remove button on chip (delete icon)
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pump();

      expect(capturedType, FilterType.clientType);
    });
  });
}