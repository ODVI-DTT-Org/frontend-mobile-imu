import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/client/client_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _pumpCard(
  WidgetTester tester, {
  String clientName = 'Maria Santos',
  String? address,
  String? priority,
  bool loanReleased = false,
  bool isCompleted = false,
  String? lastTouchpointType,
  int? lastTouchpointNumber,
  DateTime? lastTouchpointDate,
  String? scheduledTime,
  VoidCallback? onTap,
}) async {
  await tester.pumpWidget(
    _wrap(
      ClientCard(
        clientName: clientName,
        address: address,
        priority: priority,
        loanReleased: loanReleased,
        isCompleted: isCompleted,
        lastTouchpointType: lastTouchpointType,
        lastTouchpointNumber: lastTouchpointNumber,
        lastTouchpointDate: lastTouchpointDate,
        scheduledTime: scheduledTime,
        onTap: onTap ?? () {},
      ),
    ),
  );
}

void main() {
  group('ClientCard', () {
    testWidgets('renders client name', (tester) async {
      await _pumpCard(tester);
      expect(find.text('Maria Santos'), findsOneWidget);
    });

    testWidgets('renders address when provided', (tester) async {
      await _pumpCard(
        tester,
        address: '456 Mabini St, Makati City',
      );
      expect(find.text('456 Mabini St, Makati City'), findsOneWidget);
    });

    testWidgets('shows HIGH badge when priority is high', (tester) async {
      await _pumpCard(tester, priority: 'high');
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('shows HIGH badge when priority casing varies', (tester) async {
      await _pumpCard(tester, priority: 'High');
      expect(find.text('HIGH'), findsOneWidget);
    });

    testWidgets('shows LOAN RELEASED badge when loanReleased is true', (tester) async {
      await _pumpCard(tester, loanReleased: true);
      expect(find.text('LOAN RELEASED'), findsOneWidget);
    });

    testWidgets('shows DONE badge when isCompleted is true', (tester) async {
      await _pumpCard(tester, isCompleted: true);
      expect(find.text('DONE'), findsOneWidget);
    });

    testWidgets('shows no badges for normal client', (tester) async {
      await _pumpCard(tester);
      expect(find.text('HIGH'), findsNothing);
      expect(find.text('LOAN RELEASED'), findsNothing);
      expect(find.text('DONE'), findsNothing);
    });

    testWidgets('shows last touchpoint row when touchpoint data provided', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        lastTouchpointType: 'Visit',
        lastTouchpointNumber: 2,
        lastTouchpointDate: DateTime(2026, 4, 20),
      );
      expect(find.textContaining('Last: Visit #2'), findsOneWidget);
    });

    testWidgets('formats lowercase touchpoint type for display', (tester) async {
      await _pumpCard(
        tester,
        lastTouchpointType: 'call',
        lastTouchpointNumber: 2,
      );
      expect(find.textContaining('Last: Call #2'), findsOneWidget);
    });

    testWidgets('shows No touchpoints yet when no touchpoint data', (
      tester,
    ) async {
      await _pumpCard(tester);
      expect(find.text('No touchpoints yet'), findsOneWidget);
    });

    testWidgets('shows scheduled time when provided', (tester) async {
      await _pumpCard(tester, scheduledTime: '2:00 PM');
      expect(find.textContaining('2:00 PM'), findsOneWidget);
    });

    testWidgets('hides scheduled time row when scheduledTime is null', (
      tester,
    ) async {
      await _pumpCard(tester);
      expect(find.textContaining('Scheduled:'), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await _pumpCard(tester, onTap: () => tapped = true);
      await tester.tap(find.byType(ClientCard));
      expect(tapped, isTrue);
    });
  });
}
