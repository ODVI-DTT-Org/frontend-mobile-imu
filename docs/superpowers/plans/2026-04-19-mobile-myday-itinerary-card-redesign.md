# Mobile My Day & Itinerary Card Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the My Day empty list bug after scheduling, and replace `ClientListCard` with `ClientListTile` (showing product/pension/address) on both My Day and Itinerary pages, with a tap-to-show bottom sheet for all actions.

**Architecture:** All changes are confined to Flutter models and pages. The existing `ActionBottomSheet` widget is reused — no new widget needed. A helper function per page converts the page's data model to a minimal `Client` for `ClientListTile` display. The bug fix adds a provider refresh call after scheduling in the Clients page.

**Tech Stack:** Flutter/Dart, Riverpod, `ActionBottomSheet`, `ClientListTile`, `LucideIcons`

---

## File Map

| File | Change |
|------|--------|
| `lib/features/clients/presentation/pages/clients_page.dart` | Bug fix: add `myDayStateProvider.notifier.refresh()` at lines 162, 1099 |
| `lib/features/my_day/data/models/my_day_client.dart` | Add `productType`, `pensionType`, `loanType`, `address` fields |
| `lib/services/api/itinerary_api_service.dart` | Add `productType`, `pensionType`, `loanType` to `ItineraryItem` |
| `lib/features/my_day/presentation/pages/my_day_page.dart` | Update `_onClientTap` bottom sheet + swap card to `ClientListTile` |
| `lib/features/itinerary/presentation/pages/itinerary_page.dart` | Add Navigate to `_onVisitTap` + swap card to `ClientListTile` |

---

## Task 1: Fix My Day empty list after scheduling

**Files:**
- Modify: `lib/features/clients/presentation/pages/clients_page.dart:162,1099`

- [ ] **Step 1: Add `myDayStateProvider` import**

The file already imports providers but may not have `myDayStateProvider`. Check line ~25:
```
import '../../../../features/my_day/presentation/providers/my_day_provider.dart';
```
If missing, add it after the existing My Day imports.

- [ ] **Step 2: Fix line ~162 (Schedule Today fast-path)**

Find this block (around line 158-163):
```dart
final success = await myDayApiService.addToMyDay(client.id!);
if (success && mounted) {
  HapticUtils.success();
  showToast('${client.fullName} added to My Day');
  ref.invalidate(todayItineraryProvider);
}
```

Replace with:
```dart
final success = await myDayApiService.addToMyDay(client.id!);
if (success && mounted) {
  HapticUtils.success();
  showToast('${client.fullName} added to My Day');
  ref.invalidate(todayItineraryProvider);
  ref.read(myDayStateProvider.notifier).refresh();
}
```

- [ ] **Step 3: Fix line ~1099 (Schedule Itinerary path)**

Find this block (around line 1092-1100):
```dart
if (success) {
  if (scheduledDate == null) {
    setState(() { _scheduledTodayIds.add(client.id!); });
    showToast('Added to today\'s itinerary');
  } else {
    showToast('Added to itinerary for ${DateFormat('MMM dd').format(scheduledDate)}');
  }
  // Refresh today's itinerary
  ref.invalidate(todayItineraryProvider);
}
```

Replace with:
```dart
if (success) {
  if (scheduledDate == null) {
    setState(() { _scheduledTodayIds.add(client.id!); });
    showToast('Added to today\'s itinerary');
    ref.read(myDayStateProvider.notifier).refresh();
  } else {
    showToast('Added to itinerary for ${DateFormat('MMM dd').format(scheduledDate)}');
  }
  // Refresh today's itinerary
  ref.invalidate(todayItineraryProvider);
}
```

- [ ] **Step 4: Hot reload and verify**

Run the app. On the Clients page, tap "Schedule Today" for a client. Navigate to My Day. The client should now appear immediately.

- [ ] **Step 5: Commit**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
git add lib/features/clients/presentation/pages/clients_page.dart
git commit -m "fix(my-day): refresh myDayStateProvider after scheduling from Clients page"
```

---

## Task 2: Extend `MyDayClient` with display fields

**Files:**
- Modify: `lib/features/my_day/data/models/my_day_client.dart`

- [ ] **Step 1: Add the four new fields after `previousTouchpointDate`**

Find the last field declaration (around line 28):
```dart
final DateTime? previousTouchpointDate;
```

Add after it:
```dart
final DateTime? previousTouchpointDate;
// Display fields for ClientListTile
final String? productType;  // raw e.g. 'SSS_PENSIONER'
final String? pensionType;  // raw e.g. 'GSIS'
final String? loanType;     // raw e.g. 'SALARY'
final String? address;      // flat string e.g. 'San Jose, Ilocos Norte'
```

- [ ] **Step 2: Add to constructor**

Find the constructor's last parameter (around line 50):
```dart
this.previousTouchpointDate,
```

Add after it:
```dart
this.previousTouchpointDate,
this.productType,
this.pensionType,
this.loanType,
this.address,
```

- [ ] **Step 3: Update `fromPowerSync()` constructor**

Find the `return MyDayClient(` block in `fromPowerSync` and add inside it after `previousTouchpointDate`:
```dart
previousTouchpointDate: previousDate,
productType: row['product_type'] as String?,
pensionType: row['pension_type'] as String?,
loanType: row['loan_type'] as String?,
address: [
  if (row['municipality'] != null && (row['municipality'] as String).isNotEmpty)
    row['municipality'] as String,
  if (row['province'] != null && (row['province'] as String).isNotEmpty)
    row['province'] as String,
].join(', ').nullIfEmpty(),
```

Add the `nullIfEmpty` extension above the class or use a local helper:
```dart
extension _StringExt on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
```

- [ ] **Step 4: Update `fromJson()` constructor**

In `fromJson`, find `previousTouchpointDate:` and add after it:
```dart
previousTouchpointDate: json['previous_touchpoint_date'] != null
    ? DateTime.parse(json['previous_touchpoint_date'])
    : null,
productType: (json['client'] as Map<String, dynamic>?)?['product_type'] as String?,
pensionType: (json['client'] as Map<String, dynamic>?)?['pension_type'] as String?,
loanType: (json['client'] as Map<String, dynamic>?)?['loan_type'] as String?,
address: (json['client'] as Map<String, dynamic>?)?['full_address'] as String?
    ?? json['address'] as String?,
```

- [ ] **Step 5: Update `copyWith()`**

Find the `copyWith` method and add the four new parameters and their assignments:
```dart
// Parameters:
String? productType,
String? pensionType,
String? loanType,
String? address,

// Assignments in return:
productType: productType ?? this.productType,
pensionType: pensionType ?? this.pensionType,
loanType: loanType ?? this.loanType,
address: address ?? this.address,
```

- [ ] **Step 6: Update `==`, `hashCode`, `toJson()`**

In `==`:
```dart
other.productType == productType &&
other.pensionType == pensionType &&
other.loanType == loanType &&
other.address == address;
```

In `hashCode` (inside `Object.hash(...)`) add the four new fields.

In `toJson()` add:
```dart
'product_type': productType,
'pension_type': pensionType,
'loan_type': loanType,
'address': address,
```

- [ ] **Step 7: Build and fix any compile errors**

```bash
flutter analyze lib/features/my_day/data/models/my_day_client.dart
```
Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add lib/features/my_day/data/models/my_day_client.dart
git commit -m "feat(my-day): add productType, pensionType, loanType, address to MyDayClient"
```

---

## Task 3: Extend `ItineraryItem` with display fields

**Files:**
- Modify: `lib/services/api/itinerary_api_service.dart`

- [ ] **Step 1: Add three new fields after `assignedByName`**

Find `final String? assignedByName;` (around line 29) and add after it:
```dart
final String? assignedByName;
// Display fields for ClientListTile
final String? productType;  // raw e.g. 'SSS_PENSIONER'
final String? pensionType;  // raw e.g. 'GSIS'
final String? loanType;     // raw e.g. 'SALARY'
```

- [ ] **Step 2: Add to constructor**

Find `this.assignedByName,` and add after it:
```dart
this.assignedByName,
this.productType,
this.pensionType,
this.loanType,
```

- [ ] **Step 3: Update `fromJson()`**

In `fromJson`, find `assignedByName:` and add after it:
```dart
assignedByName: json['assigned_by_name'] as String?,
productType: ((json['client'] ?? json['expand']) as Map<String, dynamic>?)?['product_type'] as String?,
pensionType: ((json['client'] ?? json['expand']) as Map<String, dynamic>?)?['pension_type'] as String?,
loanType: ((json['client'] ?? json['expand']) as Map<String, dynamic>?)?['loan_type'] as String?,
```

- [ ] **Step 4: Update `copyWith()`**

Add to `copyWith` parameters and return assignments:
```dart
// Parameters:
String? productType,
String? pensionType,
String? loanType,

// Assignments:
productType: productType ?? this.productType,
pensionType: pensionType ?? this.pensionType,
loanType: loanType ?? this.loanType,
```

- [ ] **Step 5: Update `==` and `hashCode`**

In `==` add:
```dart
other.productType == productType &&
other.pensionType == pensionType &&
other.loanType == loanType;
```

In `hashCode` add the three new fields.

- [ ] **Step 6: Build and fix any compile errors**

```bash
flutter analyze lib/services/api/itinerary_api_service.dart
```
Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add lib/services/api/itinerary_api_service.dart
git commit -m "feat(itinerary): add productType, pensionType, loanType to ItineraryItem"
```

---

## Task 4: Update My Day `_onClientTap` bottom sheet

**Files:**
- Modify: `lib/features/my_day/presentation/pages/my_day_page.dart:273-360`

Currently shows "View History" — change to "View Details" (navigate to client profile), keeping Navigate.

- [ ] **Step 1: Replace the `ActionBottomSheet.show` options in `_onClientTap`**

Find the `options:` list inside `_onClientTap` (lines ~288-331) and replace it with:

```dart
options: [
  ActionOption(
    icon: LucideIcons.user,
    title: 'View Details',
    description: 'Go to client profile',
    value: 'details',
  ),
  ActionOption(
    icon: LucideIcons.edit,
    title: 'Edit Client',
    description: 'View and update client information',
    value: 'edit',
  ),
  ActionOption(
    icon: LucideIcons.navigation,
    title: 'Navigate',
    description: 'Open navigation to client address',
    value: 'navigate',
  ),
  ActionOption(
    icon: LucideIcons.listChecks,
    title: 'Record Touchpoint',
    description: 'Create touchpoint + visit',
    value: 'touchpoint',
  ),
  ActionOption(
    icon: LucideIcons.mapPin,
    title: 'Record Visit Only',
    description: 'Create visit without touchpoint',
    value: 'visit_only',
  ),
  ActionOption(
    icon: LucideIcons.dollarSign,
    title: 'Release Loan',
    description: 'Record loan release',
    value: 'release_loan',
  ),
  ActionOption(
    icon: LucideIcons.x,
    title: 'Cancel',
    value: 'cancel',
    isDestructive: true,
  ),
],
```

- [ ] **Step 2: Update the switch statement**

Replace the existing `switch (action)` block with:
```dart
switch (action) {
  case 'touchpoint':
    await _handleRecordTouchpoint(client);
    break;
  case 'visit_only':
    await _handleRecordVisitOnly(client);
    break;
  case 'release_loan':
    await _handleReleaseLoan(client);
    break;
  case 'edit':
    await _editClient(client);
    break;
  case 'details':
    if (mounted) context.push('/clients/${client.clientId}');
    break;
  case 'navigate':
    await _navigateToClient(client);
    break;
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/my_day/presentation/pages/my_day_page.dart
git commit -m "feat(my-day): update action sheet to View Details + consistent actions"
```

---

## Task 5: Add Navigate to Itinerary `_onVisitTap` bottom sheet

**Files:**
- Modify: `lib/features/itinerary/presentation/pages/itinerary_page.dart:204-266`

Currently missing "Navigate". Add it between "Edit Client" and "Record Touchpoint".

- [ ] **Step 1: Add Navigate option to the `options:` list**

Find the options list in `_onVisitTap` (after the `ActionOption` for `edit`) and insert:
```dart
ActionOption(
  icon: LucideIcons.edit,
  title: 'Edit Client',
  description: 'View and update client information',
  value: 'edit',
),
ActionOption(
  icon: LucideIcons.navigation,
  title: 'Navigate',
  description: 'Open navigation to client address',
  value: 'navigate',
),
ActionOption(
  icon: LucideIcons.listChecks,
  title: 'Record Touchpoint',
```

- [ ] **Step 2: Add `navigate` case to switch statement**

In the `switch (action)` block, add:
```dart
case 'navigate':
  await _navigateToVisit(visit);
  break;
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/itinerary/presentation/pages/itinerary_page.dart
git commit -m "feat(itinerary): add Navigate option to action bottom sheet"
```

---

## Task 6: Replace card in My Day page with `ClientListTile`

**Files:**
- Modify: `lib/features/my_day/presentation/pages/my_day_page.dart`

- [ ] **Step 1: Add `ClientListTile` import**

Add at the top of the file with other widget imports:
```dart
import '../../../../shared/widgets/client/client_list_tile.dart';
```

- [ ] **Step 2: Add the `_myDayClientToClient` helper method**

Add this private method anywhere in the `_MyDayPageState` class (e.g. after `_navigateToClient`):

```dart
/// Converts a MyDayClient to a minimal Client for ClientListTile display.
Client _myDayClientToClient(MyDayClient c) {
  final nameParts = c.fullName.trim().split(' ');
  return Client(
    id: c.clientId,
    firstName: nameParts.first,
    lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    clientType: ClientType.potential,
    productType: ProductType.bfpActive,
    pensionType: PensionType.none,
    productTypeRaw: c.productType,
    pensionTypeRaw: c.pensionType,
    loanTypeRaw: c.loanType,
    nextTouchpointNumber: c.nextTouchpointNumber,
    municipality: c.address,
    createdAt: DateTime.now(),
  );
}
```

- [ ] **Step 3: Replace `ClientListCard.fromMyDayClient(...)` with `ClientListTile`**

Find lines ~957-982:
```dart
child: ClientListCard.fromMyDayClient(
  myDayClient: client,
  clientId: client.clientId,
  fullName: client.fullName,
  location: client.location,
  touchpointNumber: client.touchpointNumber,
  touchpointType: client.touchpointType,
  previousTouchpointNumber: client.previousTouchpointNumber,
  previousTouchpointReason: client.previousTouchpointReason,
  previousTouchpointType: client.previousTouchpointType,
  previousTouchpointDate: client.previousTouchpointDate,
  priority: client.priority,
  assignedByName: client.assignedByName,
  onTap: () => _onClientTap(client),
  onRemove: () => _confirmRemoveClient(client),
  onLongPress: () => _onClientLongPress(client),
  isSelected: _isClientSelected(client.id),
  isMultiSelectMode: _isMultiSelectMode,
  enableSwipeToDismiss: true,
  showInMyDayBadge: true,
),
```

Replace with:
```dart
child: ClientListTile(
  client: _myDayClientToClient(client),
  onTap: () => _onClientTap(client),
),
```

Note: swipe-to-dismiss wraps the tile via the existing `SwipeableTile` / `Dismissible` logic. The `onRemove` / `onLongPress` / multi-select are handled by the parent wrapper, not by `ClientListCard` params — verify the parent wrapper still calls `_confirmRemoveClient` and `_onClientLongPress` correctly and keep those wired up separately if needed.

- [ ] **Step 4: Build and verify**

```bash
flutter analyze lib/features/my_day/presentation/pages/my_day_page.dart
```
Expected: no errors.

Run the app, open My Day. Each client card should show:
- Product/Pension/Loan type badges at top
- Client full name
- Touchpoint progress badge (e.g. `2/7 • Visit`)
- Address line
- Tap → bottom sheet with 6 options

- [ ] **Step 5: Commit**

```bash
git add lib/features/my_day/presentation/pages/my_day_page.dart
git commit -m "feat(my-day): replace ClientListCard with ClientListTile + action bottom sheet"
```

---

## Task 7: Replace card in Itinerary page with `ClientListTile`

**Files:**
- Modify: `lib/features/itinerary/presentation/pages/itinerary_page.dart`

- [ ] **Step 1: Add `ClientListTile` import**

```dart
import '../../../../shared/widgets/client/client_list_tile.dart';
```

- [ ] **Step 2: Add the `_itineraryItemToClient` helper method**

Add inside `_ItineraryPageState`:

```dart
/// Converts an ItineraryItem to a minimal Client for ClientListTile display.
Client _itineraryItemToClient(ItineraryItem item) {
  final nameParts = item.clientName.trim().split(' ');
  final completedCount = item.touchpointNumber != null
      ? (item.touchpointNumber! - 1).clamp(0, 7)
      : 0;
  return Client(
    id: item.clientId,
    firstName: nameParts.first,
    lastName: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    clientType: ClientType.potential,
    productType: ProductType.bfpActive,
    pensionType: PensionType.none,
    productTypeRaw: item.productType,
    pensionTypeRaw: item.pensionType,
    loanTypeRaw: item.loanType,
    nextTouchpointNumber: item.touchpointNumber,
    municipality: item.address,
    createdAt: DateTime.now(),
  );
}
```

- [ ] **Step 3: Replace both `ClientListCard.fromItineraryItem(...)` usages**

There are two usages (lines ~922-928 for multi-select and ~945-951 for normal). Replace both with:

```dart
child: ClientListTile(
  client: _itineraryItemToClient(visit),
  onTap: () => _onVisitTap(visit),
),
```

The `onLongPress`, `isSelected`, `isMultiSelectMode` logic is handled by the parent `SwipeableListTile` / wrapper — keep those wired up as-is.

- [ ] **Step 4: Build and verify**

```bash
flutter analyze lib/features/itinerary/presentation/pages/itinerary_page.dart
```
Expected: no errors.

Run the app, open Itinerary. Each client card should show:
- Product/Pension/Loan type badges
- Client full name
- Touchpoint progress badge
- Address
- Tap → bottom sheet with 6 options including Navigate

- [ ] **Step 5: Commit**

```bash
git add lib/features/itinerary/presentation/pages/itinerary_page.dart
git commit -m "feat(itinerary): replace ClientListCard with ClientListTile + action bottom sheet"
```

---

## Self-Review Checklist

- [ ] Schedule Today → My Day list refreshes immediately (Task 1)
- [ ] My Day cards show product/pension badges, name, progress, address (Task 6)
- [ ] Itinerary cards show same layout (Task 7)
- [ ] Tap on any card opens bottom sheet with 6 actions (Tasks 4, 5, 6, 7)
- [ ] "View Details" navigates to `/clients/:id` on both pages
- [ ] Navigate works on both pages
- [ ] Swipe-to-dismiss still works on My Day
- [ ] Swipe actions (edit/delete) still work on Itinerary
- [ ] `flutter analyze` passes with no errors
