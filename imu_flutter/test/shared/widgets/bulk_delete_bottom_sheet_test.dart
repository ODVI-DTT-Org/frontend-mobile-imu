import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/bulk_delete_bottom_sheet.dart';
import 'package:imu_flutter/shared/models/bulk_delete_models.dart';

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
                      await Future.delayed(const Duration(seconds: 2));
                      return BulkDeleteResult(
                        successCount: 3,
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
      await tester.pumpAndSettle();

      // Verify progress indicator exists
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
                      await Future.delayed(const Duration(seconds: 3));
                      return BulkDeleteResult(
                        successCount: 1,
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
      await tester.pumpAndSettle();

      // Verify undo button with countdown
      expect(find.text('Undo (5s)'), findsOneWidget);

      // Wait for countdown to update
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Undo (3s)'), findsOneWidget);
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
                      await Future.delayed(const Duration(milliseconds: 100));
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
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Verify success message
      expect(find.text('2 visits deleted'), findsOneWidget);
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
                      await Future.delayed(const Duration(seconds: 5));
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
      await tester.pumpAndSettle();

      // Tap undo button immediately
      await tester.tap(find.text('Undo (5s)'));
      await tester.pumpAndSettle();

      // Verify bottom sheet dismissed
      expect(find.text('Show Bottom Sheet'), findsOneWidget);
      expect(deleteCalled, false);
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
                      await Future.delayed(const Duration(milliseconds: 100));
                      return BulkDeleteResult(
                        successCount: 1,
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
      await tester.pumpAndSettle();

      // Tap cancel button (X icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify bottom sheet dismissed
      expect(find.text('Show Bottom Sheet'), findsOneWidget);
    });
  });
}
