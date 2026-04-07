# Client Card UI Consistency & Naming Convention Fix

**Date:** 2025-01-08
**Status:** Design Approved
**Type:** UI Refactoring + Consistency Fix

## Overview

Create a unified client card design for My Day and Itinerary pages based on the Clients page reference design, while fixing the client naming convention throughout the entire mobile app.

## Problem Statement

1. **Inconsistent UI:** My Day and Itinerary pages use different card designs for displaying clients
2. **Naming Convention:** Client names are displayed inconsistently (some "First Middle Last", some "Last, First Middle")
3. **Missing Navigation:** No "Navigate" action in My Day/Itinerary menus to open maps navigation

## Solution

1. Create a shared `ClientListCard` widget for My Day and Itinerary pages
2. Fix `Client.fullName` getter to use "LastName, FirstName MiddleName" format strictly
3. Audit and fix ALL client name displays across the app
4. Add "Navigate" action to My Day and Itinerary action menus

## Client Name Format

### Standard

**Format:** `LastName, FirstName MiddleName` (strict)
- Comma after last name
- Space after comma
- No comma before middle name
- Example: `"Delos Santos, Juan Miguel"`

### Implementation

```dart
// File: mobile/imu_flutter/lib/features/clients/data/models/client_model.dart

// BEFORE:
String get fullName => '$firstName ${middleName != null ? '$middleName ' : ''}$lastName';

// AFTER:
String get fullName => '$lastName, $firstName${middleName != null ? ' $middleName' : ''}';
```

### Scope of Changes

All locations displaying client names must use `client.fullName`:

| File | Component | Change |
|------|-----------|--------|
| `client_model.dart` | `fullName` getter | Update to "Last, First Middle" |
| `client_detail_page.dart` | Page headers | Use `fullName` |
| `client_list_tile.dart` | ListTile titles | Use `fullName` |
| `my_day/client_card.dart` | Card titles | Use `fullName` |
| `itinerary_page.dart` | Visit card names | Use `fullName` |
| `touchpoint_history_dialog.dart` | Dialog titles | Use `fullName` |
| `action_bottom_sheet.dart` | Sheet titles | Use `fullName` |
| `client_selector_modal.dart` | List items | Use `fullName` |
| `my_day_page.dart` | Client displays | Use `fullName` |
| Any toasts/notifications | Client names | Use `fullName` |

## Card Design

### Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│ [NEW/TP#] LastName, FirstName MiddleName    [In My Day] │
│ 3/7 • Visit  |  Interested  |  Loan Released: UDI123    │
│ 📍 Barangay, Municipality, Province, Region            │
│ 📍/📞 3rd Visit - 2 days ago                              │
│ 💬 Follow-up discussion                                   │
│ [☑] (checkbox when multi-select mode)                    │
└─────────────────────────────────────────────────────────┘
```

### Card Elements (Top to Bottom)

1. **Top Row:**
   - Left: NEW badge (first-time) OR Touchpoint ordinal badge (e.g., "3rd")
   - Center: Client name (LastName, FirstName MiddleName)
   - Right: "In My Day" badge (green checkmark) - optional

2. **Badges Row:**
   - Touchpoint Progress Badge (e.g., "3/7 • Visit")
   - Touchpoint Status Badge (e.g., "Interested")
   - Loan Released Badge with UDI (only if `loanReleased == true`)

3. **Address Row:**
   - Map pin icon (📍)
   - Full address: `barangay, municipality, province, region`

4. **Touchpoint Summary:**
   - Icon: Map pin (visit) or phone (call)
   - Text: "3rd Visit - 2 days ago"

5. **Touchpoint Reason:**
   - Message icon (💬)
   - Text: Reason from last touchpoint

6. **Multi-select Indicator:**
   - Checkbox overlay when in multi-select mode
   - Blue border/background when selected

### Styling

- **Background:** White with grey border (#E2E8F0)
- **Selected:** Light blue background (#EFF6FF) with blue border (#3B82F6)
- **Name:** Dark grey (#0F172A), font-weight 600, size 15
- **Address:** Grey (#64748B), size 12
- **Touchpoint Summary:** Grey (#64748B), size 11
- **Reason:** Light grey (#94A3B8), size 11, italic

### Loan Released Badge

**Display Condition:** Only when `client.loanReleased == true`

**Visual:**
- Icon: 💰 (LucideIcons.dollarSign)
- Text: "Loan Released: [UDI_NUMBER]"
- Background: Green with opacity 0.1
- Border: Green with opacity 0.3
- Text Color: Green (#16A34A)

## Shared Widget: ClientListCard

### Location

`mobile/imu_flutter/lib/shared/widgets/client/client_list_card.dart`

### Purpose

Reusable client card widget for My Day and Itinerary pages, providing consistent client display with multi-select support.

### Interface

```dart
class ClientListCard extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove; // For swipe-to-dismiss callback
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool enableSwipeToDismiss; // Enable swipe-to-remove
  final bool showInMyDayBadge; // Show "In My Day" indicator
  final int? touchpointCount; // Optional pre-fetched count
  final String? scheduledDate; // For itinerary visit date

  const ClientListCard({
    super.key,
    required this.client,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.enableSwipeToDismiss = false,
    this.showInMyDayBadge = false,
    this.touchpointCount,
    this.scheduledDate,
  });
}
```

### Features

1. **Consistent Display:** Same visual layout as Clients page reference
2. **Multi-select Mode:** Checkbox overlay when enabled
3. **Swipe-to-Dismiss:** Optional (for My Day page)
4. **Gesture Handling:** Tap and long-press callbacks
5. **Badge Support:** NEW, touchpoint, "In My Day", loan released
6. **Touchpoint Info:** Progress, status, summary, reason
7. **Address Display:** Full address with map pin icon

## Navigate Action

### Purpose

Add "Navigate" action to My Day and Itinerary action menus to open external maps navigation to client's address.

### Implementation

**ActionBottomSheet Option:**
```dart
ActionOption(
  icon: LucideIcons.navigation,
  title: 'Navigate',
  description: 'Open navigation to client address',
  value: 'navigate',
)
```

**Navigation Behavior:**
1. Get `client.fullAddress`
2. Open external maps app (Google Maps, Waze, Apple Maps)
3. Use address as search/query parameter
4. Fallback to browser if no maps app available

**Files to Update:**
- `my_day_page.dart` - Add to `_onClientTap()` ActionBottomSheet
- `itinerary_page.dart` - Add to visit card action menu

## Page-Specific Usage

### My Day Page

**Changes:**
1. Replace current `ClientCard` with `ClientListCard`
2. Set `enableSwipeToDismiss: true`
3. Set `showInMyDayBadge: true`
4. Add "Navigate" option to ActionBottomSheet
5. Keep existing multi-select and bulk operations

**Configuration:**
```dart
ClientListCard(
  client: client,
  onTap: () => _onClientTap(client),
  onLongPress: () => _onClientLongPress(client),
  onRemove: () => _confirmRemoveClient(client),
  isSelected: _isClientSelected(client.id),
  isMultiSelectMode: _isMultiSelectMode,
  enableSwipeToDismiss: true, // Allow swipe-to-remove
  showInMyDayBadge: true,
)
```

### Itinerary Page

**Changes:**
1. Replace inline visit card with `ClientListCard`
2. Set `enableSwipeToDismiss: false`
3. Set `showInMyDayBadge: false` (already in itinerary)
4. Add "Navigate" option to action menu
5. Keep existing swipe actions (Call, Navigate, Edit, Delete)

**Configuration:**
```dart
ClientListCard(
  client: visit.client,
  onTap: () => _handleVisitTap(visit),
  onLongPress: () => _toggleVisitSelection(visit.id),
  isSelected: _selectedVisitIds.contains(visit.id),
  isMultiSelectMode: _isMultiSelectMode,
  enableSwipeToDismiss: false, // No swipe-to-dismiss
  showInMyDayBadge: false,
  scheduledDate: visit.scheduledDate,
)
```

### Clients Page

**No Changes:** Keep existing `_buildClientCard()` implementation as reference design.

## Implementation Files

### New Files

1. `mobile/imu_flutter/lib/shared/widgets/client/client_list_card.dart`
   - New shared widget for My Day and Itinerary

### Modified Files

1. `mobile/imu_flutter/lib/features/clients/data/models/client_model.dart`
   - Update `fullName` getter to "Last, First Middle" format

2. `mobile/imu_flutter/lib/features/my_day/presentation/widgets/client_card.dart`
   - DELETE - replaced by shared ClientListCard

3. `mobile/imu_flutter/lib/features/my_day/presentation/pages/my_day_page.dart`
   - Import and use ClientListCard
   - Add Navigate action to ActionBottomSheet

4. `mobile/imu_flutter/lib/features/itinerary/presentation/pages/itinerary_page.dart`
   - Import and use ClientListCard
   - Add Navigate action to visit menu

### Files to Audit for Naming Convention

1. `mobile/imu_flutter/lib/shared/widgets/client/client_list_tile.dart`
2. `mobile/imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart`
3. `mobile/imu_flutter/lib/shared/widgets/touchpoint_history_dialog.dart`
4. `mobile/imu_flutter/lib/shared/widgets/action_bottom_sheet.dart`
5. `mobile/imu_flutter/lib/shared/widgets/client_selector_modal.dart`
6. Any other files displaying client names

## Testing Checklist

### Naming Convention

- [ ] All client names display as "Last, First Middle"
- [ ] My Day cards show correct format
- [ ] Itinerary cards show correct format
- [ ] Clients page cards show correct format
- [ ] Client detail page header shows correct format
- [ ] Touchpoint history shows correct format
- [ ] Action bottom sheets show correct format
- [ ] Client selector modal shows correct format
- [ ] Any toasts/notifications show correct format

### UI Consistency

- [ ] My Day uses new ClientListCard widget
- [ ] Itinerary uses new ClientListCard widget
- [ ] Both pages show consistent card layout
- [ ] Loan Released + UDI displays correctly
- [ ] "In My Day" badge works correctly
- [ ] Multi-select mode shows checkbox overlay
- [ ] Selected state has blue border/background

### Functionality

- [ ] Navigate action opens maps with correct address
- [ ] Swipe-to-dismiss works on My Day
- [ ] Tap gesture works correctly
- [ ] Long-press enters multi-select mode
- [ ] Multi-select bulk operations work

## Dependencies

### Existing Components

- `TouchpointProgressBadge` - Already exists
- `TouchpointStatusBadge` - Already exists
- `ClientStatusBadge` - Already exists
- `ActionBottomSheet` - Already exists (needs Navigate option)

### Data Models

- `Client` - Has all required fields (name, address, touchpoints, loanReleased, udi)
- `Touchpoint` - Used for summary display
- `MyDayClient` - May need updates to match Client model

## Migration Notes

1. **Breaking Changes:** None - this is internal refactoring
2. **Backward Compatibility:** Existing functionality preserved
3. **User Impact:** Positive - more consistent UI
4. **Performance:** No impact - same data, better presentation

## Success Criteria

1. All client names follow "Last, First Middle" format
2. My Day and Itinerary use identical card design
3. Loan Released + UDI displays correctly
4. Navigate action works from action menus
5. All existing functionality preserved
6. No regressions in multi-select or swipe actions
