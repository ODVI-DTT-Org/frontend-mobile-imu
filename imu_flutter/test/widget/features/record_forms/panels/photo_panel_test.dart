// test/widget/features/record_forms/panels/photo_panel_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('PhotoPanel', () {
    testWidgets('shows photo preview when photo provided', (WidgetTester tester) async {
      // Note: File images cannot be tested in widget tests
      // This test checks the UI structure
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPanel(
              photoPath: '/path/to/photo.jpg',
              onPhotoCaptured: (_) {},
              onPhotoRemoved: () {},
              error: null,
            ),
          ),
        ),
      );

      // Check for the Remove button (X icon)
      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows capture prompt when no photo', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPanel(
              photoPath: null,
              onPhotoCaptured: (_) {},
              onPhotoRemoved: () {},
              error: null,
            ),
          ),
        ),
      );

      expect(find.text('Tap to take photo'), findsOneWidget);
      expect(find.text('Photo (Required)'), findsOneWidget);
    });

    testWidgets('shows error when error provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhotoPanel(
              photoPath: null,
              onPhotoCaptured: (_) {},
              onPhotoRemoved: () {},
              error: 'Photo is required',
            ),
          ),
        ),
      );

      expect(find.text('Photo is required'), findsOneWidget);
    });
  });
}
