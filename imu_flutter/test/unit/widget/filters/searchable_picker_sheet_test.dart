import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/filters/searchable_picker_sheet.dart';

void main() {
  group('SearchablePickerSheet', () {
    testWidgets('shows all items initially', (tester) async {
      final items = ['Cebu', 'Metro Manila', 'Davao'];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchablePickerSheet(
            title: 'Province',
            items: items,
            selectedItems: const {},
            multiSelect: false,
            onConfirm: (_) {},
          ),
        ),
      ));

      expect(find.text('Cebu'), findsOneWidget);
      expect(find.text('Metro Manila'), findsOneWidget);
      expect(find.text('Davao'), findsOneWidget);
    });

    testWidgets('filters items on search input', (tester) async {
      final items = ['Cebu', 'Metro Manila', 'Davao'];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SearchablePickerSheet(
            title: 'Province',
            items: items,
            selectedItems: const {},
            multiSelect: false,
            onConfirm: (_) {},
          ),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'cebu');
      await tester.pump();

      expect(find.text('Cebu'), findsOneWidget);
      expect(find.text('Metro Manila'), findsNothing);
    });
  });
}
