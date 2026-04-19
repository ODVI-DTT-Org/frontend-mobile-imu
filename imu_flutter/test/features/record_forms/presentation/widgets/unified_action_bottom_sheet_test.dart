import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('UnifiedActionBottomSheet', () {
    testWidgets('shows title, client name, pension, and touchpoint label', (tester) async {
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Record Touchpoint',
        clientName: 'Juan dela Cruz',
        pensionLabel: 'PNP Pension',
        touchpointLabel: 'Touchpoint 3 of 7',
        cards: const [],
        submitLabel: 'Record Touchpoint',
        isFormValid: false,
        isSubmitting: false,
        onSubmit: () {},
      )));
      expect(find.text('Record Touchpoint'), findsWidgets);
      expect(find.text('Juan dela Cruz'), findsOneWidget);
      expect(find.text('PNP Pension'), findsOneWidget);
      expect(find.text('Touchpoint 3 of 7'), findsOneWidget);
    });

    testWidgets('submit button does not fire when isFormValid is false', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Test',
        clientName: 'Juan',
        pensionLabel: 'PNP',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: false,
        isSubmitting: false,
        onSubmit: () => tapped = true,
      )));
      await tester.tap(find.text('Submit'));
      expect(tapped, isFalse);
    });

    testWidgets('submit button fires when isFormValid is true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Test',
        clientName: 'Juan',
        pensionLabel: 'PNP',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: true,
        isSubmitting: false,
        onSubmit: () => tapped = true,
      )));
      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);
    });

    testWidgets('shows CircularProgressIndicator when isSubmitting', (tester) async {
      await tester.pumpWidget(_wrap(UnifiedActionBottomSheet(
        icon: Icons.assignment,
        title: 'Test',
        clientName: 'Juan',
        pensionLabel: 'PNP',
        touchpointLabel: null,
        cards: const [],
        submitLabel: 'Submit',
        isFormValid: true,
        isSubmitting: true,
        onSubmit: () {},
      )));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });
  });
}
