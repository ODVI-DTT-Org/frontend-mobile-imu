import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('DetailsCard (editable)', () {
    testWidgets('renders reason and status labels', (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: false,
        reason: null,
        status: null,
        availableReasons: TouchpointReason.values
            .where((r) => r != TouchpointReason.newReleaseLoan)
            .toList(),
        availableStatuses: [
          TouchpointStatus.interested,
          TouchpointStatus.undecided,
          TouchpointStatus.notInterested,
          TouchpointStatus.completed,
        ],
        onReasonChanged: (_) {},
        onStatusChanged: (_) {},
        showErrors: false,
      )));
      expect(find.text('Reason'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('shows Select hint and error text when showErrors true and null',
        (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: false,
        reason: null,
        status: null,
        availableReasons: TouchpointReason.values
            .where((r) => r != TouchpointReason.newReleaseLoan)
            .toList(),
        availableStatuses: [TouchpointStatus.interested, TouchpointStatus.undecided],
        onReasonChanged: (_) {},
        onStatusChanged: (_) {},
        showErrors: true,
      )));
      expect(find.text('Select reason'), findsOneWidget);
      expect(find.text('Select status'), findsOneWidget);
    });
  });

  group('DetailsCard (locked)', () {
    testWidgets('shows lock icons and locked labels', (tester) async {
      await tester.pumpWidget(_wrap(DetailsCard(
        locked: true,
        reason: null,
        status: null,
        availableReasons: const [],
        availableStatuses: const [],
        onReasonChanged: null,
        onStatusChanged: null,
        showErrors: false,
        lockedReasonLabel: 'New Loan Release',
        lockedStatusLabel: 'Completed',
      )));
      expect(find.text('New Loan Release'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
    });
  });
}
