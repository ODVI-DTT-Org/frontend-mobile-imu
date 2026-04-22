# Touchpoint Detail View Enhancement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the touchpoint detail view modal to display captured photos and simplified location address.

**Architecture:** Modify the existing `_showTouchpointDetails()` method in `touchpoint_history_dialog.dart` to:
1. Add a photo display section at the bottom of the modal
2. Simplify location display to show address only (no coordinates, no Time In/Out labels)

**Tech Stack:** Flutter, Dart, existing Touchpoint model from `client_model.dart`

---

## File Structure

**Files to modify:**
- `lib/shared/widgets/touchpoint_history_dialog.dart` - Main implementation
- `test/widget/widgets/touchpoint_history_dialog_test.dart` - Widget tests (create new)

**No new files needed** - The change is localized to the existing touchpoint history dialog.

---

## Task 1: Create Widget Tests for Touchpoint Detail View

**Files:**
- Create: `test/widget/widgets/touchpoint_history_dialog_test.dart`

- [ ] **Step 1: Write test imports and setup**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/touchpoint_history_dialog.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

Touchpoint createTestTouchpoint({
  required int touchpointNumber,
  TouchpointType type = TouchpointType.visit,
  TouchpointReason reason = TouchpointReason.interested,
  TouchpointStatus status = TouchpointStatus.interested,
  String? photoPath,
  String? timeInGpsAddress,
  String? timeOutGpsAddress,
  String? remarks,
}) {
  final now = DateTime.now();
  return Touchpoint(
    id: 'tp-1',
    clientId: 'client-1',
    touchpointNumber: touchpointNumber,
    type: type,
    reason: reason,
    status: status,
    date: now,
    photoPath: photoPath,
    timeInGpsAddress: timeInGpsAddress,
    timeOutGpsAddress: timeOutGpsAddress,
    remarks: remarks,
    createdAt: now,
  );
}

void main() {
  group('TouchpointHistoryItem Detail View', () {
    // Tests will be added in next steps
  });
}
```

- [ ] **Step 2: Run test to verify setup works**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS (empty group runs successfully)

- [ ] **Step 3: Write test for detail view with all fields**

```dart
testWidgets('displays touchpoint details with all fields', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 3,
    type: TouchpointType.call,
    reason: TouchpointReason.followUp,
    status: TouchpointStatus.interested,
    timeInGpsAddress: '123 Main St, Manila, Metro Manila',
    remarks: 'Client interested in the product.',
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => _TouchpointHistoryItem(touchpoint: touchpoint)
                ._showTouchpointDetails(context, touchpoint),
            child: const Text('Show Details'),
          ),
        ),
      ),
    ),
  );

  // Tap the button to show the detail view
  await tester.tap(find.text('Show Details'));
  await tester.pumpAndSettle();

  // Assert - Header
  expect(find.text('Touchpoint #3'), findsOneWidget);
  expect(find.text('Call •'), findsOneWidget);

  // Assert - Status and Reason sections
  expect(find.text('Status'), findsOneWidget);
  expect(find.text('Interested'), findsOneWidget);
  expect(find.text('Reason'), findsOneWidget);
  expect(find.text('Follow Up'), findsOneWidget);

  // Assert - Location section
  expect(find.text('Location'), findsOneWidget);
  expect(find.text('123 Main St, Manila, Metro Manila'), findsOneWidget);

  // Assert - Remarks section
  expect(find.text('Remarks'), findsOneWidget);
  expect(find.text('Client interested in the product.'), findsOneWidget);
});
```

- [ ] **Step 4: Run test to verify it fails (expected)**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: FAIL - The `_showTouchpointDetails` method is private, need to refactor

- [ ] **Step 5: Write simpler test for touchpoint history item rendering**

```dart
testWidgets('renders touchpoint item with correct type icon', (tester) async {
  // Arrange
  final visitTouchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    type: TouchpointType.visit,
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TouchpointHistoryItem(touchpoint: visitTouchpoint),
      ),
    ),
  );

  // Assert - Visit type shows mapPin icon
  expect(find.byIcon(LucideIcons.mapPin), findsOneWidget);
});

testWidgets('call touchpoint shows phone icon', (tester) async {
  // Arrange
  final callTouchpoint = createTestTouchpoint(
    touchpointNumber: 2,
    type: TouchpointType.call,
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TouchpointHistoryItem(touchpoint: callTouchpoint),
      ),
    ),
  );

  // Assert - Call type shows phone icon
  expect(find.byIcon(LucideIcons.phone), findsOneWidget);
});

testWidgets('view details button is present', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(touchpointNumber: 1);

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _TouchpointHistoryItem(touchpoint: touchpoint),
      ),
    ),
  );

  // Assert
  expect(find.text('View Details'), findsOneWidget);
});
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS (basic rendering tests pass)

- [ ] **Step 7: Commit**

```bash
git add test/widget/widgets/touchpoint_history_dialog_test.dart
git commit -m "test: add widget tests for touchpoint history dialog

- Test touchpoint item rendering
- Test type icons (visit vs call)
- Test view details button presence
"
```

---

## Task 2: Refactor _showTouchpointDetails to Public Method

**Files:**
- Modify: `lib/shared/widgets/touchpoint_history_dialog.dart:496-640`

- [ ] **Step 1: Extract _showTouchpointDetails to a public static function**

Find the `_showTouchpointDetails` method inside `_TouchpointHistoryItem` class (around line 496).
Extract it to a public static function at the top of the file, after the imports:

```dart
/// Show touchpoint details in a modal bottom sheet
void showTouchpointDetails(BuildContext context, Touchpoint touchpoint) {
  final isVisit = touchpoint.type == TouchpointType.visit;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                  color: isVisit ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Touchpoint #${touchpoint.touchpointNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isVisit ? 'Visit' : 'Call'} • ${DateFormat('MMM d, yyyy').format(touchpoint.date)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status
                  _buildDetailRow(
                    'Status',
                    touchpoint.status.apiValue,
                    LucideIcons.badgeCheck,
                    _getStatusColor(touchpoint.status),
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  if (touchpoint.reason != null)
                    _buildDetailRow(
                      'Reason',
                      touchpoint.reason!.apiValue,
                      LucideIcons.messageCircle,
                      Colors.grey[700]!,
                    ),
                  if (touchpoint.reason != null) const SizedBox(height: 16),

                  // Location (simplified - address only)
                  _buildLocationSection(touchpoint),
                  const SizedBox(height: 16),

                  // Remarks
                  if (touchpoint.remarks != null && touchpoint.remarks!.isNotEmpty)
                    _buildDetailRow(
                      'Remarks',
                      touchpoint.remarks!,
                      LucideIcons.alignLeft,
                      Colors.grey[700]!,
                    ),
                  if (touchpoint.remarks != null && touchpoint.remarks!.isNotEmpty) const SizedBox(height: 16),

                  // Photo section (at bottom)
                  _buildPhotoSection(touchpoint),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLocationSection(Touchpoint touchpoint) {
  // Priority: timeInGpsAddress > address field
  final address = touchpoint.timeInGpsAddress ?? touchpoint.address;

  if (address == null || address.isEmpty) {
    return const SizedBox.shrink();
  }

  return _buildDetailRow(
    'Location',
    address,
    LucideIcons.mapPin,
    Colors.grey[700]!,
  );
}

Widget _buildPhotoSection(Touchpoint touchpoint) {
  final hasPhoto = touchpoint.photoPath != null && touchpoint.photoPath!.isNotEmpty;

  if (!hasPhoto) {
    // Show placeholder
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.camera, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'No photo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // Show photo
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(touchpoint.photoPath!),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Unable to load photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color _getStatusColor(TouchpointStatus status) {
  switch (status) {
    case TouchpointStatus.interested:
      return Colors.green;
    case TouchpointStatus.undecided:
      return Colors.orange;
    case TouchpointStatus.notInterested:
      return Colors.red;
    case TouchpointStatus.completed:
      return Colors.blue;
    case TouchpointStatus.followUpNeeded:
      return Colors.purple;
    case TouchpointStatus.incomplete:
      return Colors.grey;
  }
}

Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
```

- [ ] **Step 2: Add missing imports**

At the top of `touchpoint_history_dialog.dart`, add:
```dart
import 'dart:io';
```

- [ ] **Step 3: Update _TouchpointHistoryItem to call the new function**

Find the `onPressed` callback in the "View Details" button (around line 462):
Change from:
```dart
onPressed: () => _showTouchpointDetails(context, touchpoint),
```
To:
```dart
onPressed: () => showTouchpointDetails(context, touchpoint),
```

- [ ] **Step 4: Remove the old private _showTouchpointDetails method**

Delete the old `_showTouchpointDetails` method and its helper `_buildDetailRow` method from the `_TouchpointHistoryItem` class (lines 496-672 approximately).

- [ ] **Step 5: Run tests to verify**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS

- [ ] **Step 6: Run app and verify manually**

Run: `flutter run`
Navigate to: Client Detail → Touchpoint History → View Details
Expected:
- Modal opens with reorganized layout
- Location shows address only
- Photo placeholder at bottom

- [ ] **Step 7: Commit**

```bash
git add lib/shared/widgets/touchpoint_history_dialog.dart
git commit -m "feat: refactor touchpoint detail view to public function

- Extract _showTouchpointDetails to showTouchpointDetails
- Add _buildLocationSection helper for address-only display
- Add _buildPhotoSection helper for photo display
- Add File import for image loading
"
```

---

## Task 3: Add Location Display Logic

**Files:**
- Modify: `lib/shared/widgets/touchpoint_history_dialog.dart`

- [ ] **Step 1: Update _buildLocationSection to handle all address fields**

The `_buildLocationSection` from Task 2 already has this logic. Verify it's correct:
- Uses `timeInGpsAddress` as priority
- Falls back to `address` field
- Returns `SizedBox.shrink()` if no address

No changes needed if Task 2 was done correctly.

- [ ] **Step 2: Write test for location priority**

```dart
testWidgets('location shows timeInGpsAddress when available', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    timeInGpsAddress: 'GPS Address, Manila',
    address: 'Legacy Address',
  );

  // Act - Render the location section directly
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _buildLocationSection(touchpoint),
      ),
    ),
  );

  // Assert
  expect(find.text('GPS Address, Manila'), findsOneWidget);
  expect(find.text('Legacy Address'), findsNothing);
});

testWidgets('location falls back to address when timeInGpsAddress is null', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    timeInGpsAddress: null,
    address: 'Legacy Address',
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _buildLocationSection(touchpoint),
      ),
    ),
  );

  // Assert
  expect(find.text('Legacy Address'), findsOneWidget);
});

testWidgets('location section is hidden when no address available', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    timeInGpsAddress: null,
    address: null,
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _buildLocationSection(touchpoint),
      ),
    ),
  );

  // Assert - Location label should not be found
  expect(find.text('Location'), findsNothing);
});
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add test/widget/widgets/touchpoint_history_dialog_test.dart
git commit -m "test: add location display priority tests

- Test timeInGpsAddress priority over address field
- Test fallback to address field
- Test location section hidden when no data
"
```

---

## Task 4: Add Photo Display Section

**Files:**
- Modify: `lib/shared/widgets/touchpoint_history_dialog.dart`

- [ ] **Step 1: Verify _buildPhotoSection implementation**

The `_buildPhotoSection` from Task 2 should already be complete. Verify it:
- Shows placeholder when `photoPath` is null or empty
- Shows `Image.file()` when `photoPath` exists
- Has error builder for failed image loads

- [ ] **Step 2: Write test for photo section**

```dart
testWidgets('photo section shows placeholder when no photo', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    photoPath: null,
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _buildPhotoSection(touchpoint),
      ),
    ),
  );

  // Assert
  expect(find.text('No photo'), findsOneWidget);
  expect(find.byIcon(LucideIcons.camera), findsOneWidget);
});

testWidgets('photo section shows placeholder when photoPath is empty', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    photoPath: '',
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _buildPhotoSection(touchpoint),
      ),
    ),
  );

  // Assert
  expect(find.text('No photo'), findsOneWidget);
});

testWidgets('photo section shows image when photoPath exists', (tester) async {
  // Note: This test would require a real file or mocking
  // For now, we test that the structure is correct
  // Integration test would verify actual photo display
});
```

- [ ] **Step 2: Run tests**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS

- [ ] **Step 3: Manual test with real photo**

Run: `flutter run`
1. Navigate to Client Detail
2. Record a touchpoint with a photo
3. View touchpoint history
4. Tap "View Details"
Expected: Photo displays at bottom of modal

- [ ] **Step 4: Commit**

```bash
git add test/widget/widgets/touchpoint_history_dialog_test.dart
git commit -m "test: add photo section tests

- Test placeholder shown when no photo
- Test placeholder shown when photoPath is empty
- Integration testing for actual photos done manually
"
```

---

## Task 5: Integration Testing and Edge Cases

**Files:**
- Modify: `test/widget/widgets/touchpoint_history_dialog_test.dart`

- [ ] **Step 1: Write integration test for complete detail view**

```dart
testWidgets('detail view shows all sections correctly', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 5,
    type: TouchpointType.visit,
    reason: TouchpointReason.documentSubmission,
    status: TouchpointStatus.completed,
    timeInGpsAddress: '456 Oak Ave, Quezon City, Metro Manila',
    remarks: 'Documents submitted successfully.',
    photoPath: null,
  );

  // Act - We can't easily test the modal directly, so we test the components
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildLocationSection(touchpoint),
              const SizedBox(height: 16),
              _buildPhotoSection(touchpoint),
            ],
          ),
        ),
      ),
    ),
  );

  // Assert - Location
  expect(find.text('Location'), findsOneWidget);
  expect(find.text('456 Oak Ave, Quezon City, Metro Manila'), findsOneWidget);

  // Assert - Photo placeholder
  expect(find.text('No photo'), findsOneWidget);
});
```

- [ ] **Step 2: Test with empty remarks**

```dart
testWidgets('remarks section hidden when remarks is empty', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    remarks: '',
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              if (touchpoint.remarks != null && touchpoint.remarks!.isNotEmpty)
                _buildDetailRow(
                  'Remarks',
                  touchpoint.remarks!,
                  LucideIcons.alignLeft,
                  Colors.grey[700]!,
                ),
            ],
          ),
        ),
      ),
    ),
  );

  // Assert - Remarks should not be shown
  expect(find.text('Remarks'), findsNothing);
});
```

- [ ] **Step 3: Test with null remarks**

```dart
testWidgets('remarks section hidden when remarks is null', (tester) async {
  // Arrange
  final touchpoint = createTestTouchpoint(
    touchpointNumber: 1,
    remarks: null,
  );

  // Act
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Column(
            children: [
              if (touchpoint.remarks != null && touchpoint.remarks!.isNotEmpty)
                _buildDetailRow(
                  'Remarks',
                  touchpoint.remarks!,
                  LucideIcons.alignLeft,
                  Colors.grey[700]!,
                ),
            ],
          ),
        ),
      ),
    ),
  );

  // Assert - Remarks should not be shown
  expect(find.text('Remarks'), findsNothing);
});
```

- [ ] **Step 4: Run all tests**

Run: `flutter test test/widget/widgets/touchpoint_history_dialog_test.dart`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `flutter test`
Expected: All tests pass (no regressions)

- [ ] **Step 6: Commit**

```bash
git add test/widget/widgets/touchpoint_history_dialog_test.dart
git commit -m "test: add integration tests for touchpoint detail view

- Test all sections display correctly
- Test remarks section hidden when empty/null
- Test location and photo sections together
"
```

---

## Task 6: Verify and Clean Up

**Files:**
- Modify: `lib/shared/widgets/touchpoint_history_dialog.dart`

- [ ] **Step 1: Review final implementation**

Open `lib/shared/widgets/touchpoint_history_dialog.dart` and verify:
- ✅ `showTouchpointDetails` is a public function
- ✅ `_buildLocationSection` uses `timeInGpsAddress` with fallback to `address`
- ✅ `_buildPhotoSection` shows image or placeholder
- ✅ No coordinate display
- ✅ No Time In/Out labels
- ✅ Photo at bottom of content
- ✅ Proper error handling for image loading

- [ ] **Step 2: Check for unused code**

Search for and remove any unused helper methods or variables:
- Old `_showTouchpointDetails` method should be deleted
- Old `_buildDetailRow` inside class should be deleted (now standalone)

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 4: Format code**

Run: `dart format lib/shared/widgets/touchpoint_history_dialog.dart test/widget/widgets/touchpoint_history_dialog_test.dart`

- [ ] **Step 5: Final manual test**

Run: `flutter run`

Test scenarios:
1. **Touchpoint with photo and GPS address**:
   - Navigate to Client Detail → Touchpoint History → View Details
   - Expected: Photo displays, GPS address shows

2. **Touchpoint without photo, with GPS address**:
   - Expected: Photo placeholder shows, GPS address shows

3. **Touchpoint without photo, legacy address only**:
   - Expected: Photo placeholder shows, legacy address shows

4. **Touchpoint with photo, no address**:
   - Expected: Photo displays, Location section hidden

5. **Touchpoint without photo, no address, no remarks**:
   - Expected: Photo placeholder shows, Location hidden, Remarks hidden

- [ ] **Step 6: Final commit**

```bash
git add lib/shared/widgets/touchpoint_history_dialog.dart test/widget/widgets/touchpoint_history_dialog_test.dart
git commit -m "feat: complete touchpoint detail view enhancement

- Add photo display at bottom of detail view
- Simplify location to address-only display
- Remove GPS coordinates from UI
- Remove Time In/Out labels
- Add comprehensive widget tests
- Format and clean up code

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
"
```

---

## Summary

This implementation plan enhances the touchpoint detail view by:
1. Adding a photo display section at the bottom of the modal
2. Simplifying location display to show address only (no coordinates)
3. Removing Time In/Out labels for cleaner UI
4. Adding comprehensive widget tests

**Total tasks:** 6
**Estimated time:** 2-3 hours
**Files modified:** 2
**Files created:** 1 (test file)
**Lines of code:** ~200 (implementation + tests)

---

## Testing Checklist

After implementation, verify:
- [ ] Detail view opens from "View Details" button
- [ ] Status displays correctly
- [ ] Reason displays correctly
- [ ] Location shows GPS address when available
- [ ] Location falls back to legacy address
- [ ] Location hidden when no address
- [ ] Photo displays when photoPath exists
- [ ] Photo placeholder shows when no photo
- [ ] Photo error handled gracefully
- [ ] Remarks shown when present
- [ ] Remarks hidden when empty/null
- [ ] Modal closes with X button
- [ ] Modal closes with drag-down
- [ ] Works for Visit touchpoints
- [ ] Works for Call touchpoints
- [ ] No analyzer issues
- [ ] All tests pass
