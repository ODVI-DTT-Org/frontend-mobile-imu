// test/widget/shared/expansion_form_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/expansion_form_panel.dart';

void main() {
  group('ExpansionFormPanel', () {
    testWidgets('shows title and expands on tap', (WidgetTester tester) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpansionFormPanel(
              title: 'Test Panel',
              icon: Icons.access_time,
              isExpanded: isExpanded,
              onTap: () => isExpanded = !isExpanded,
              summary: const Text('Summary'),
              child: const Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Child Content'), findsNothing);
    });

    testWidgets('shows child content when expanded', (WidgetTester tester) async {
      bool isExpanded = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpansionFormPanel(
              title: 'Test Panel',
              icon: Icons.access_time,
              isExpanded: isExpanded,
              onTap: () => isExpanded = !isExpanded,
              summary: const Text('Summary'),
              child: const Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Panel'), findsOneWidget);
      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('shows error when errorText provided', (WidgetTester tester) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpansionFormPanel(
              title: 'Test Panel',
              icon: Icons.access_time,
              isExpanded: isExpanded,
              onTap: () => isExpanded = !isExpanded,
              summary: const Text('Summary'),
              errorText: 'This field is required',
              child: const Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('This field is required'), findsOneWidget);
    });
  });
}
