import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  group('PhotoCard', () {
    testWidgets('shows Take Photo button when no photo', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: null,
        onPhotoTaken: (_) {},
        showError: false,
      )));
      expect(find.text('Take Photo'), findsOneWidget);
    });

    testWidgets('shows Photo Captured and retake text when photo set', (tester) async {
      // We use a non-existent path; PhotoCard shows text-based state without rendering File
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: 'fake_path',
        onPhotoTaken: (_) {},
        showError: false,
      )));
      expect(find.text('Photo Captured'), findsOneWidget);
      expect(find.text('Tap to retake'), findsOneWidget);
    });

    testWidgets('shows error text when showError and no photo', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: null,
        onPhotoTaken: (_) {},
        showError: true,
      )));
      expect(find.text('Photo is required'), findsOneWidget);
    });

    testWidgets('no error shown when photo is set even with showError', (tester) async {
      await tester.pumpWidget(_wrap(PhotoCard(
        photoPath: 'fake_path',
        onPhotoTaken: (_) {},
        showError: true,
      )));
      expect(find.text('Photo is required'), findsNothing);
    });
  });
}
