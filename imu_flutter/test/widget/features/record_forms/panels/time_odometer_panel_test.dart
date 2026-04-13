// test/widget/features/record_forms/panels/time_odometer_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';

void main() {
  group('TimeOdometerPanel', () {
    testWidgets('shows time and odometer inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimeOdometerPanel(
                timeIn: DateTime(2025, 1, 15, 9, 30),
                timeOut: DateTime(2025, 1, 15, 9, 35),
                odometerIn: '125450',
                odometerOut: '125480',
                onTimeInChanged: (_) {},
                onTimeOutChanged: (_) {},
                onOdometerInChanged: (_) {},
                onOdometerOutChanged: (_) {},
                errors: const {},
              ),
            ),
          ),
        ),
      );

      // Check for labels
      expect(find.text('Time In'), findsOneWidget);
      expect(find.text('Time Out'), findsOneWidget);
      expect(find.text('Odometer In'), findsOneWidget);
      expect(find.text('Odometer Out'), findsOneWidget);

      // Check for odometer values (formatted with commas)
      expect(find.text('125,450'), findsOneWidget);
      expect(find.text('125,480'), findsOneWidget);

      // Check for Auto +5min subtitle
      expect(find.text('Auto +5min'), findsOneWidget);
    });

    testWidgets('shows select time when time not set', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimeOdometerPanel(
                timeIn: null,
                timeOut: null,
                odometerIn: '125450',
                odometerOut: '125480',
                onTimeInChanged: (_) {},
                onTimeOutChanged: (_) {},
                onOdometerInChanged: (_) {},
                onOdometerOutChanged: (_) {},
                errors: const {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Select Time'), findsNWidgets(2));
    });

    testWidgets('shows empty odometer when not set', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TimeOdometerPanel(
                timeIn: DateTime(2025, 1, 15, 9, 30),
                timeOut: DateTime(2025, 1, 15, 9, 35),
                odometerIn: null,
                odometerOut: null,
                onTimeInChanged: (_) {},
                onTimeOutChanged: (_) {},
                onOdometerInChanged: (_) {},
                onOdometerOutChanged: (_) {},
                errors: const {},
              ),
            ),
          ),
        ),
      );

      // Should show empty odometer fields
      final odometerFields = find.byType(TextField);
      expect(odometerFields, findsWidgets);
    });
  });
}
