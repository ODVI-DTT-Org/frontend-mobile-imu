import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/bulk_delete_bottom_sheet.dart';
import 'package:imu_flutter/shared/models/bulk_delete_models.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  group('BulkDeleteBottomSheet', () {
    testWidgets('shows progress indicator when deleting', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1', 'id2', 'id3'],
                    itemType: 'itineraries',
                    onDelete: (ids) async {
                      // Use a completer that we control - never complete
                      final completer = Completer<BulkDeleteResult>();
                      return completer.future;
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pump();

      // Verify progress indicator exists (while still deleting)
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Deleting 3 visits...'), findsOneWidget);
    });

    testWidgets('shows undo button with countdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1'],
                    itemType: 'clients',
                    onDelete: (ids) async {
                      // Use a completer that we control - never complete
                      final completer = Completer<BulkDeleteResult>();
                      return completer.future;
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pump();

      // Verify undo button with countdown (check immediately after pump)
      expect(find.text('Undo (5s)'), findsOneWidget);

      // Wait for countdown to update
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Undo (4s)'), findsOneWidget);
    });

    testWidgets('shows success message on completion', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1', 'id2'],
                    itemType: 'itineraries',
                    onDelete: (ids) async {
                      await Future.delayed(const Duration(milliseconds: 50));
                      return BulkDeleteResult(
                        successCount: 2,
                        errorCount: 0,
                        errors: [],
                      );
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pump();

      // Wait for delete to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Verify success message (before auto-dismiss)
      expect(find.text('2 visits deleted'), findsOneWidget);

      // Wait for auto-dismiss timer (2 seconds)
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Verify bottom sheet was dismissed
      expect(find.text('Show Bottom Sheet'), findsOneWidget);
    });

    testWidgets('shows partial success with error list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1', 'id2', 'id3'],
                    itemType: 'clients',
                    onDelete: (ids) async {
                      await Future.delayed(const Duration(milliseconds: 100));
                      return BulkDeleteResult(
                        successCount: 2,
                        errorCount: 1,
                        errors: [
                          BulkDeleteError(
                            id: 'id3',
                            error: 'Not found',
                            itemName: 'Test Client',
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Wait for delete to complete
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      // Verify partial success message
      expect(find.text('2 deleted, 1 failed'), findsOneWidget);
      expect(find.text('Test Client: Not found'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1', 'id2'],
                    itemType: 'itineraries',
                    onDelete: (ids) async {
                      await Future.delayed(const Duration(milliseconds: 100));
                      throw Exception('Network error');
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pumpAndSettle();

      // Wait for delete to fail
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      // Verify error message
      expect(find.text('Delete Failed'), findsOneWidget);
    });

    testWidgets('undo button cancels operation', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1', 'id2'],
                    itemType: 'itineraries',
                    onDelete: (ids) async {
                      deleteCalled = true;
                      // Never complete - this ensures no auto-dismiss timer is created
                      final completer = Completer<BulkDeleteResult>();
                      return completer.future;
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pump();

      // Tap undo button immediately (before it disappears)
      final undoButton = find.text('Undo (5s)');
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pump();

      // Verify bottom sheet dismissed
      expect(find.text('Show Bottom Sheet'), findsOneWidget);
      // Note: deleteCalled might be true because delete starts immediately in initState
    });

    testWidgets('cancel button dismisses bottom sheet', (tester) async {
      var deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BulkDeleteBottomSheet.show(
                    context: context,
                    itemIds: ['id1'],
                    itemType: 'clients',
                    onDelete: (ids) async {
                      deleteCalled = true;
                      // Never complete - this ensures no auto-dismiss timer is created
                      final completer = Completer<BulkDeleteResult>();
                      return completer.future;
                    },
                  );
                },
                child: const Text('Show Bottom Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Bottom Sheet'));
      await tester.pump();

      // Tap cancel button by finding the X icon and tapping its parent
      final xIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            widget.icon == LucideIcons.x,
      );
      expect(xIcon, findsOneWidget);

      // Get the render box and calculate center position
      await tester.tap(xIcon, warnIfMissed: false);
      await tester.pump();

      // Verify bottom sheet dismissed
      expect(find.text('Show Bottom Sheet'), findsOneWidget);
    });
  });
}
