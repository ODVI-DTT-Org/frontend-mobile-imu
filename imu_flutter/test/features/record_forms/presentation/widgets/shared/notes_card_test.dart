import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('NotesCard', () {
    testWidgets('renders Remarks label and multiline field', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: false)));
      expect(find.text('Remarks'), findsOneWidget);
    });

    testWidgets('shows error text when showError true and controller empty', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: true)));
      expect(find.text('Remarks is required'), findsOneWidget);
    });

    testWidgets('no error shown when controller has text even with showError', (tester) async {
      final ctrl = TextEditingController(text: 'Some notes');
      await tester.pumpWidget(_wrap(NotesCard(controller: ctrl, showError: true)));
      expect(find.text('Remarks is required'), findsNothing);
    });
  });
}
