import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('ScheduleCard', () {
    testWidgets('shows labels when no values set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null,
        timeOut: null,
        odometerArrival: null,
        odometerDeparture: null,
        onTimeInChanged: (_) {},
        onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {},
        onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Time In'), findsOneWidget);
      expect(find.text('Time Out'), findsOneWidget);
      expect(find.text('Odo Arrival'), findsOneWidget);
      expect(find.text('Odo Departure'), findsOneWidget);
    });

    testWidgets('shows Required hint on all fields when showErrors true and all null',
        (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null,
        timeOut: null,
        odometerArrival: null,
        odometerDeparture: null,
        onTimeInChanged: (_) {},
        onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {},
        onOdometerDepartureChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('Required'), findsNWidgets(4));
    });

    testWidgets('shows formatted time when value set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: const TimeOfDay(hour: 8, minute: 30),
        timeOut: null,
        odometerArrival: null,
        odometerDeparture: null,
        onTimeInChanged: (_) {},
        onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {},
        onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('8:30 AM'), findsOneWidget);
    });

    testWidgets('shows odometer value with km suffix when set', (tester) async {
      await tester.pumpWidget(_wrap(ScheduleCard(
        timeIn: null,
        timeOut: null,
        odometerArrival: '12345',
        odometerDeparture: null,
        onTimeInChanged: (_) {},
        onTimeOutChanged: (_) {},
        onOdometerArrivalChanged: (_) {},
        onOdometerDepartureChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('12345 km'), findsOneWidget);
    });
  });
}
