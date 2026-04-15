import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/core/utils/app_notification.dart';

void main() {
  group('AppNotification', () {
    // Clean up any pending notifications after each test
    tearDown(() {
      AppNotification.dismiss();
    });

    testWidgets('showSuccess displays green notification at top', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showSuccess(
                  context,
                  'Success message',
                  duration: Duration.zero,
                ),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      // Verify notification appears at top
      expect(find.text('Success message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showError displays red notification at top', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showError(
                  context,
                  'Error message',
                  duration: Duration.zero,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('showWarning displays orange notification at top', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showWarning(
                  context,
                  'Warning message',
                  duration: Duration.zero,
                ),
                child: const Text('Show Warning'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Warning'));
      await tester.pump();

      expect(find.text('Warning message'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('showNeutral displays gray notification at top', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showNeutral(
                  context,
                  'Neutral message',
                  duration: Duration.zero,
                ),
                child: const Text('Show Neutral'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Neutral'));
      await tester.pump();

      expect(find.text('Neutral message'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('dismiss removes current notification', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showSuccess(
                    context,
                    'Test',
                    duration: Duration.zero,
                  );
                  // Immediately dismiss
                  AppNotification.dismiss();
                },
                child: const Text('Show and Dismiss'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show and Dismiss'));
      await tester.pump();

      // Notification should not appear since we dismissed immediately
      expect(find.byType(OverlayEntry), findsNothing);
    });

    testWidgets('notification positions at top with safe area padding', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppNotification.showSuccess(
                  context,
                  'Top positioned',
                  duration: Duration.zero,
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Verify notification is positioned at top
      final notificationFinder = find.byType(Positioned);
      expect(notificationFinder, findsAtLeastNWidgets(1));

      final positionedWidget = tester.widget<Positioned>(notificationFinder.first);
      expect(positionedWidget.top, greaterThan(0));
      expect(positionedWidget.top, lessThan(100));
    });

    testWidgets('notifications use correct icons for each type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppNotification.showSuccess(
                      context,
                      'Success',
                      duration: Duration.zero,
                    ),
                    child: const Text('Success'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppNotification.showError(
                      context,
                      'Error',
                      duration: Duration.zero,
                    ),
                    child: const Text('Error'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppNotification.showWarning(
                      context,
                      'Warning',
                      duration: Duration.zero,
                    ),
                    child: const Text('Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppNotification.showNeutral(
                      context,
                      'Neutral',
                      duration: Duration.zero,
                    ),
                    child: const Text('Neutral'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test success icon
      await tester.tap(find.text('Success').first);
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      AppNotification.dismiss();
      await tester.pump();

      // Test error icon
      await tester.tap(find.text('Error').first);
      await tester.pump();
      expect(find.byIcon(Icons.error), findsOneWidget);
      AppNotification.dismiss();
      await tester.pump();

      // Test warning icon
      await tester.tap(find.text('Warning').first);
      await tester.pump();
      expect(find.byIcon(Icons.warning), findsOneWidget);
      AppNotification.dismiss();
      await tester.pump();

      // Test neutral icon
      await tester.tap(find.text('Neutral').first);
      await tester.pump();
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
  });
}
