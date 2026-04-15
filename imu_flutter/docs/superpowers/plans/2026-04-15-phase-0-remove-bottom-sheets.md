# Phase 0: Remove Existing Bottom Sheets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete existing Record Touchpoint, Record Visit Only, and Record Loan Release bottom sheet implementations to prepare for new compact Material 3 designs.

**Architecture:** Remove 3 bottom sheet wrapper classes and their imports from client_detail_page.dart, update handler methods to show temporary disabled state.

**Tech Stack:** Flutter 3.19+, Dart

---

## Overview

This phase removes the existing bottom sheet implementations that use fixed heights (70-90% of screen) and outdated Material 2 design patterns. The current implementations wrap form widgets and don't follow modern mobile UX patterns.

**Current State:**
- `_RecordTouchpointBottomSheet` class (lines ~2290-2373)
- `_RecordVisitOnlyBottomSheet` class (lines ~2376-2459)
- `_ReleaseLoanBottomSheet` class (lines ~2462-2545)
- 3 form widget imports from `features/record_forms/`

**Desired State:**
- All bottom sheet classes removed
- Form widget imports removed
- Handler methods show temporary disabled state
- App compiles and runs without errors

---

## File Structure

**Files to modify:**
- `lib/features/clients/presentation/pages/client_detail_page.dart` - Remove bottom sheet classes and imports, update handlers

**Files to keep (will be reused later):**
- `lib/features/record_forms/presentation/widgets/record_touchpoint_form.dart` - Form widget (keep for reference)
- `lib/features/record_forms/presentation/widgets/record_visit_only_form.dart` - Form widget (keep for reference)
- `lib/features/record_forms/presentation/widgets/release_loan_form.dart` - Form widget (keep for reference)

---

## Task Breakdown

### Task 1: Remove Bottom Sheet Class Imports

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart:40-42`

- [ ] **Step 1: Remove form widget imports**

Delete these 3 import lines (lines 40-42):
```dart
import '../../../record_forms/presentation/widgets/record_touchpoint_form.dart';
import '../../../record_forms/presentation/widgets/record_visit_only_form.dart';
import '../../../record_forms/presentation/widgets/release_loan_form.dart';
```

- [ ] **Step 2: Verify imports are removed**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No errors about missing imports (yet, since classes aren't removed)

- [ ] **Step 3: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: remove bottom sheet form widget imports

- Remove imports for RecordTouchpointForm, RecordVisitOnlyForm, ReleaseLoanForm
- Prepare for removal of bottom sheet wrapper classes

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 2: Remove _RecordTouchpointBottomSheet Class

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart:2290-2373`

- [ ] **Step 1: Locate the class boundaries**

Find `_RecordTouchpointBottomSheet` class (starts at line ~2290)
Find the closing brace of `_RecordTouchpointBottomSheetState` class (ends at line ~2373)

- [ ] **Step 2: Delete the entire bottom sheet class**

Delete lines 2290-2373 (approximately 84 lines):
```dart
/// Bottom sheet wrapper for Record Touchpoint form
class _RecordTouchpointBottomSheet extends ConsumerStatefulWidget {
  final Client client;

  const _RecordTouchpointBottomSheet({
    required this.client,
  });

  @override
  ConsumerState<_RecordTouchpointBottomSheet> createState() => _RecordTouchpointBottomSheetState();
}

class _RecordTouchpointBottomSheetState extends ConsumerState<_RecordTouchpointBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          // Header with client name and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Touchpoint',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.client.fullName,
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
          // Form content
          Expanded(
            child: RecordTouchpointForm(
              key: ValueKey('touchpoint_form_${widget.client.id}'),
              client: widget.client,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify file still compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: Error about `_RecordTouchpointBottomSheet` not found in `_handleRecordTouchpoint` method (this is expected for now)

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: remove _RecordTouchpointBottomSheet class

- Delete _RecordTouchpointBottomSheet wrapper class (84 lines)
- Remove RecordTouchpointForm integration
- Prepare for new compact bottom sheet implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 3: Remove _RecordVisitOnlyBottomSheet Class

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart:2376-2459`

- [ ] **Step 1: Locate the class boundaries**

Find `_RecordVisitOnlyBottomSheet` class (starts at line ~2376, after Task 2 deletion)
Find the closing brace of `_RecordVisitOnlyBottomSheetState` class (ends at line ~2459)

- [ ] **Step 2: Delete the entire bottom sheet class**

Delete the entire `_RecordVisitOnlyBottomSheet` and `_RecordVisitOnlyBottomSheetState` classes (approximately 84 lines)

- [ ] **Step 3: Verify file still compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: Error about `_RecordVisitOnlyBottomSheet` not found in `_handleRecordVisitOnly` method (expected)

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: remove _RecordVisitOnlyBottomSheet class

- Delete _RecordVisitOnlyBottomSheet wrapper class
- Remove RecordVisitOnlyForm integration
- Prepare for new compact bottom sheet implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 4: Remove _ReleaseLoanBottomSheet Class

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart:2462-2545`

- [ ] **Step 1: Locate the class boundaries**

Find `_ReleaseLoanBottomSheet` class (starts at line ~2462, after Task 3 deletion)
Find the closing brace of `_ReleaseLoanBottomSheetState` class (ends at line ~2545)

- [ ] **Step 2: Delete the entire bottom sheet class**

Delete the entire `_ReleaseLoanBottomSheet` and `_ReleaseLoanBottomSheetState` classes (approximately 84 lines)

- [ ] **Step 3: Verify file still compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: Error about `_ReleaseLoanBottomSheet` not found in `_handleReleaseLoanBottomSheet` method (expected)

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: remove _ReleaseLoanBottomSheet class

- Delete _ReleaseLoanBottomSheet wrapper class
- Remove ReleaseLoanForm integration
- Prepare for new compact bottom sheet implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 5: Update _handleRecordTouchpoint Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart` (around line 1074)

- [ ] **Step 1: Find the _handleRecordTouchpoint method**

Search for: `Future<void> _handleRecordTouchpoint()`

- [ ] **Step 2: Replace method with temporary disabled state**

Replace the existing method implementation with:
```dart
/// Open Record Touchpoint bottom sheet
Future<void> _handleRecordTouchpoint() async {
  if (_client == null) return;

  // Prevent touchpoint creation for loan released clients
  if (_client!.loanReleased) {
    if (mounted) {
      HapticUtils.error();
      AppNotification.showError(context, 'Cannot create touchpoints: Loan has been released');
    }
    return;
  }

  // TODO: Phase 1 - Implement new compact Record Touchpoint bottom sheet
  if (mounted) {
    HapticUtils.error();
    AppNotification.showError(context, 'Record Touchpoint - Coming soon in Phase 1');
  }
}
```

- [ ] **Step 3: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No compilation errors

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: update _handleRecordTouchpoint with temporary disabled state

- Replace bottom sheet call with TODO comment for Phase 1
- Show coming soon notification when tapped
- Keep loan released validation in place

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Update _handleRecordVisitOnly Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart` (around line 1105)

- [ ] **Step 1: Find the _handleRecordVisitOnly method**

Search for: `Future<void> _handleRecordVisitOnly()`

- [ ] **Step 2: Remove loan released validation and add TODO**

Replace the existing method implementation with:
```dart
/// Open Record Visit Only bottom sheet
Future<void> _handleRecordVisitOnly() async {
  if (_client == null) return;

  HapticUtils.lightImpact();

  // TODO: Phase 1 - Implement new compact Record Visit Only bottom sheet
  if (mounted) {
    HapticUtils.error();
    AppNotification.showError(context, 'Record Visit Only - Coming soon in Phase 1');
  }
}
```

- [ ] **Step 3: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No compilation errors

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: update _handleRecordVisitOnly with temporary disabled state

- Remove loan released validation (visits now allowed when loan released)
- Replace bottom sheet call with TODO comment for Phase 1
- Show coming soon notification when tapped

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 7: Update _handleReleaseLoanBottomSheet Method

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart` (around line 1136)

- [ ] **Step 1: Find the _handleReleaseLoanBottomSheet method**

Search for: `Future<void> _handleReleaseLoanBottomSheet()`

- [ ] **Step 2: Remove loan released validation and add TODO**

Replace the existing method implementation with:
```dart
/// Open Release Loan bottom sheet
Future<void> _handleReleaseLoanBottomSheet() async {
  if (_client == null) return;

  HapticUtils.lightImpact();

  // TODO: Phase 1 - Implement new compact Release Loan bottom sheet
  if (mounted) {
    HapticUtils.error();
    AppNotification.showError(context, 'Release Loan - Coming soon in Phase 1');
  }
}
```

- [ ] **Step 3: Verify method compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No compilation errors

- [ ] **Step 4: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: update _handleReleaseLoanBottomSheet with temporary disabled state

- Remove loan released validation (additional releases now allowed)
- Replace bottom sheet call with TODO comment for Phase 1
- Show coming soon notification when tapped

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 8: Update _QuickActionsSection to Remove Loan Release Restriction

**Files:**
- Modify: `lib/features/clients/presentation/pages/client_detail_page.dart` (around line 1790-1800)

- [ ] **Step 1: Find the Release Loan button in _QuickActionsSection**

Search for the `if (canReleaseLoan && !isLoanReleased)` condition

- [ ] **Step 2: Remove !isLoanReleased condition**

Find this code:
```dart
if (canReleaseLoan && !isLoanReleased)
  _QuickActionButton(
    icon: LucideIcons.dollarSign,
    label: 'Release Loan',
    onTap: onReleaseLoan,
    color: Colors.green[600],
  ),
```

Replace with:
```dart
if (canReleaseLoan)
  _QuickActionButton(
    icon: LucideIcons.dollarSign,
    label: 'Release Loan',
    onTap: onReleaseLoan,
    color: Colors.green[600],
  ),
```

- [ ] **Step 3: Find the Record Visit button**

Search for the Record Visit button that has `onTap: isLoanReleased ? null : onRecordVisitOnly`

- [ ] **Step 4: Remove loan released restriction from Record Visit button**

Find this code:
```dart
_QuickActionButton(
  icon: LucideIcons.userCheck,
  label: 'Record Visit',
  onTap: isLoanReleased ? null : onRecordVisitOnly,
),
```

Replace with:
```dart
_QuickActionButton(
  icon: LucideIcons.userCheck,
  label: 'Record Visit',
  onTap: onRecordVisitOnly,
),
```

- [ ] **Step 5: Verify UI compiles**

Run: `cd mobile/imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart`
Expected: No compilation errors

- [ ] **Step 6: Commit changes**

```bash
cd mobile/imu_flutter && git add lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "phase 0: remove loan release restrictions from quick action buttons

- Remove !isLoanReleased condition from Release Loan button
- Remove isLoanReleased check from Record Visit button
- Allow visits and additional releases when loan is released
- Keep Record Touchpoint disabled when loan is released

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 9: Build and Verify App Compiles

**Files:**
- Test: Flutter build compilation

- [ ] **Step 1: Run Flutter build**

Run: `cd mobile/imu_flutter && flutter build apk --debug`

Expected output:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 2: Verify no compilation errors**

Check that the build completes successfully with no errors about missing classes or undefined references

- [ ] **Step 3: Run Flutter analyze**

Run: `cd mobile/imu_flutter && flutter analyze`

Expected: No errors, only warnings (if any)

- [ ] **Step 4: Commit final Phase 0 completion**

```bash
cd mobile/imu_flutter && git add -A
git commit -m "phase 0: complete - all bottom sheets removed, app compiles successfully

- Removed all 3 bottom sheet wrapper classes
- Removed form widget imports
- Updated handler methods with TODO placeholders
- Removed loan release restrictions from UI
- App compiles and builds successfully
- Ready for Phase 1 implementation

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Success Criteria

### Functional
- ✅ All 3 bottom sheet classes removed from codebase
- ✅ Form widget imports removed
- ✅ Handler methods show "coming soon" notifications
- ✅ App compiles without errors
- ✅ Debug APK builds successfully

### Validation Changes
- ✅ "Record Visit" button enabled when loan is released
- ✅ "Release Loan" button enabled when loan is released
- ✅ "Record Touchpoint" still disabled when loan is released

### Code Quality
- ✅ No unused imports remain
- ✅ TODO comments added for Phase 1
- ✅ Clean git history with atomic commits

---

## Testing Verification

### Manual Testing
- [ ] Open client detail page
- [ ] Tap "Record Touchpoint" → Should show error notification
- [ ] Tap "Record Visit" → Should show "coming soon" notification
- [ ] Tap "Release Loan" → Should show "coming soon" notification
- [ ] Verify client with released loan shows all buttons enabled (except touchpoint)

### Build Verification
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter build apk --debug` succeeds
- [ ] APK installs on device
- [ ] App launches without crashes

---

## Migration Notes

### What's Removed
- 3 bottom sheet wrapper classes (~250 lines total)
- 3 form widget imports
- Old fixed-height (70-90%) bottom sheet implementations

### What's Preserved
- Form widget files kept for reference in Phase 1
- Client detail page structure unchanged
- Handler method signatures unchanged

### What's Next
- **Phase 1:** Implement new compact Material 3 bottom sheets
- **Phase 2:** Add auto-height sizing and modern styling
- **Phase 3:** Integrate with existing forms and APIs

---

**Phase 0 Status:** ✅ Complete when all tasks finished and app compiles successfully

**Next Steps:** Proceed to Phase 1 implementation plan for new bottom sheet designs
