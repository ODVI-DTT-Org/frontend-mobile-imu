# Mobile My Day & Itinerary Card Redesign

**Date:** 2026-04-19
**Platforms:** Flutter mobile app

## Summary

Two problems to fix:

1. **Bug:** Scheduling a client from the Clients page doesn't refresh the My Day list
2. **Card redesign:** My Day and Itinerary pages use `ClientListCard` (touchpoint-focused). Replace with `ClientListTile` (product/pension/address layout) with a tap-to-show bottom sheet for actions.

---

## Problem 1 — Bug Fix: My Day list empty after scheduling

**Root cause:** `clients_page.dart` calls `ref.invalidate(todayItineraryProvider)` after scheduling, but the My Day page watches `myDayStateProvider` — a different provider. The invalidation never reaches My Day.

**Fix:** In `clients_page.dart`, after a successful schedule, also call:
```dart
ref.read(myDayStateProvider.notifier).refresh();
```

**Files:**
- `lib/features/clients/presentation/pages/clients_page.dart` — lines ~162 and ~1099 where `ref.invalidate(todayItineraryProvider)` is called

---

## Problem 2 — Card Redesign

### New card layout (same on both pages)

```
┌─────────────────────────────────────────────────┐
│ [SSS Pensioner] [GSIS] [Salary]                 │
│                                                 │
│ Juan Dela Cruz                                  │
│                                                 │
│ [📍 2/7 • Visit]                               │
│                                                 │
│ 📍 Brgy. San Jose, Ilocos Norte                │
└─────────────────────────────────────────────────┘
         ↓ tap anywhere on card

┌─────────────────────────────────────────────────┐
│ ▬▬▬  Juan Dela Cruz                             │
│ ─────────────────────────────────────────────── │
│  👁  View Details                               │
│  ✏️  Edit                                       │
│  🧭  Navigate                                   │
│  📍  Record Touchpoint                          │
│  🚶  Record Visit Only                          │
│  💰  Release Loan                               │
└─────────────────────────────────────────────────┘
```

### Part A — Extend `MyDayClient` with display fields

`MyDayClient` currently lacks `productType`, `pensionType`, `loanType`, `address`. The PowerSync JOIN row already contains these columns from the clients table.

Add to `MyDayClient`:
```dart
final String? productType;   // e.g. 'SSS_PENSIONER'
final String? pensionType;   // e.g. 'GSIS'
final String? loanType;      // e.g. 'SALARY'
final String? address;       // flat address string (municipality, province)
```

Update `fromPowerSync()` to read:
```dart
productType: row['product_type'] as String?,
pensionType: row['pension_type'] as String?,
loanType: row['loan_type'] as String?,
address: row['full_address'] as String?,  // or build from barangay/municipality/province
```

Update `fromJson()` to read from nested `client` object:
```dart
productType: json['client']?['product_type'] as String?,
pensionType: json['client']?['pension_type'] as String?,
loanType: json['client']?['loan_type'] as String?,
address: json['client']?['full_address'] as String?,
```

Update `copyWith()`, `==`, `hashCode`, `toJson()` accordingly.

### Part B — Extend `ItineraryItem` with display fields

Same fields to add to `ItineraryItem`:
```dart
final String? productType;
final String? pensionType;
final String? loanType;
// address already exists as flat String? — keep as-is
```

Update `fromJson()` to read from nested `client`:
```dart
productType: (json['client'] ?? json['expand'])?['product_type'] as String?,
pensionType: (json['client'] ?? json['expand'])?['pension_type'] as String?,
loanType: (json['client'] ?? json['expand'])?['loan_type'] as String?,
```

Update `copyWith()`, `==`, `hashCode` accordingly.

### Part C — Display helper: product type label

Both models store raw strings like `'SSS_PENSIONER'`. Use this map to display labels (same as `Client.productTypeDisplay`):
```dart
String _displayProductType(String? raw) {
  const map = {
    'SSS_PENSIONER': 'SSS Pensioner',
    'GSIS_PENSIONER': 'GSIS Pensioner',
    'PRIVATE': 'Private',
  };
  return map[raw] ?? raw ?? '-';
}
```

### Part D — Shared bottom sheet: `ClientActionsBottomSheet`

Create a new reusable widget:
**File:** `lib/shared/widgets/client/client_actions_bottom_sheet.dart`

```dart
class ClientActionsBottomSheet extends StatelessWidget {
  final String clientName;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onNavigate;
  final VoidCallback onRecordTouchpoint;
  final VoidCallback onRecordVisitOnly;
  final VoidCallback onReleaseLoan;

  // usage:
  // showModalBottomSheet(context: context, builder: (_) => ClientActionsBottomSheet(...))
}
```

Actions list (in order):
| Icon | Label | Callback |
|------|-------|----------|
| `LucideIcons.eye` | View Details | `onViewDetails` |
| `LucideIcons.pencil` | Edit | `onEdit` |
| `LucideIcons.navigation` | Navigate | `onNavigate` |
| `LucideIcons.mapPin` | Record Touchpoint | `onRecordTouchpoint` |
| `LucideIcons.footprints` | Record Visit Only | `onRecordVisitOnly` |
| `LucideIcons.banknote` | Release Loan | `onReleaseLoan` |

Bottom sheet has a drag handle at top, client name as title, then list tiles for each action. Dismisses on action tap.

### Part E — My Day page: replace `ClientListCard` with `ClientListTile`

**File:** `lib/features/my_day/presentation/pages/my_day_page.dart`

Replace `ClientListCard.fromMyDayClient(...)` (lines ~957-982) with:

```dart
ClientListTile(
  client: _myDayClientToClient(myDayClient),  // helper function
  onTap: () => _showClientActions(context, myDayClient),
)
```

Add helper to convert `MyDayClient` → minimal `Client` for display:
```dart
Client _myDayClientToClient(MyDayClient c) {
  return Client(
    id: c.clientId,
    firstName: c.fullName.split(' ').first,
    lastName: c.fullName.split(' ').skip(1).join(' '),
    productTypeRaw: c.productType,
    pensionTypeRaw: c.pensionType,
    loanTypeRaw: c.loanType,
    nextTouchpointNumber: c.nextTouchpointNumber,
    nextTouchpointType: c.nextTouchpointType != null
        ? (c.nextTouchpointType == 'Visit' ? TouchpointType.visit : TouchpointType.call)
        : null,
    completedTouchpoints: c.touchpointNumber,
    addresses: c.address != null ? [Address(id: '', street: c.address!, city: '')] : [],
    // all other required fields: empty defaults
  );
}
```

Add `_showClientActions()` that calls `showModalBottomSheet` with `ClientActionsBottomSheet`, wiring each callback to the existing handlers already in the My Day page (`_recordTouchpoint`, `_recordVisitOnly`, `_releaseLoan`, `_editClient`, `_navigateToClient`, `_viewClientDetails`).

Keep swipe-to-dismiss (for quick remove from My Day) separately — it wraps the tile and is independent of the tap action.

### Part F — Itinerary page: replace `ClientListCard` with `ClientListTile`

**File:** `lib/features/itinerary/presentation/pages/itinerary_page.dart`

Same pattern: replace `ClientListCard.fromItineraryItem(...)` (lines ~945-951) with:

```dart
ClientListTile(
  client: _itineraryItemToClient(visit),
  onTap: () => _showClientActions(context, visit),
)
```

Helper to convert `ItineraryItem` → minimal `Client`:
```dart
Client _itineraryItemToClient(ItineraryItem item) {
  return Client(
    id: item.clientId,
    firstName: item.clientName.split(' ').first,
    lastName: item.clientName.split(' ').skip(1).join(' '),
    productTypeRaw: item.productType,
    pensionTypeRaw: item.pensionType,
    loanTypeRaw: item.loanType,
    nextTouchpointNumber: item.touchpointNumber,
    nextTouchpointType: item.touchpointType != null
        ? (item.touchpointType == 'Visit' ? TouchpointType.visit : TouchpointType.call)
        : null,
    completedTouchpoints: (item.touchpointNumber ?? 1) - 1,
    addresses: item.address != null ? [Address(id: '', street: item.address!, city: '')] : [],
  );
}
```

`_showClientActions()` wires to existing handlers: `_handleRecordTouchpoint`, `_handleRecordVisitOnly`, `_handleReleaseLoan`, `_editClient`, `_onVisitTap` (view), and navigation.

Keep existing swipe actions (left: call/navigate, right: edit/delete) — they're independent of the tap.

---

## Out of Scope

- No changes to the Clients page card (already correct)
- No changes to the bottom sheet client picker / selector modal
- No backend changes
- No changes to the multi-select / time-in functionality
