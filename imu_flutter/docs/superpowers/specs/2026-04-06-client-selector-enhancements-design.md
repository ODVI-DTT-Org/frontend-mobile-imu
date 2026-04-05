# Client Selector Modal Enhancements - Design Spec

**Date:** 2026-04-06
**Status:** Approved
**Related Issues:** Touchpoints not loading in real-time, missing visual feedback for client status

## Overview

Enhance the client selector modal to display comprehensive client status information (loan released, already in itinerary, next touchpoint type) while migrating touchpoints to PowerSync for real-time sync.

**Goals:**
1. Show visual badges for client status (loan released, in itinerary, next touchpoint)
2. Disable buttons when actions not allowed with clear reasons
3. Use expansion panels for organized client details
4. Migrate touchpoints to PowerSync for real-time sync
5. Implement hybrid API/PowerSync fallback for offline support

## Architecture

### Provider Categorization

**Separate providers for different use cases:**

| Provider | Data Source | Use Case | Purpose |
|----------|-------------|----------|---------|
| `clientTouchpointsProvider` | Hive | Touchpoint Form | Create new touchpoints (offline-first) |
| `clientTouchpointsSyncProvider` | PowerSync (+ Hive fallback) | Client Selector | Read-only status display |

**Rationale:** Keep Hive for touchpoint creation (works offline), use PowerSync for real-time status display in client selector.

### Status Loading Flow

```
┌─────────────────┐
│ Modal Opens      │
└────────┬────────┘
         │
         ▼
    ┌────────────────┐
    │ Check Internet │
    └────┬───────────┘
         │
    ┌────┴────┐
    │         │
Online   Offline
    │         │
    ▼         ▼
┌─────────┐  ┌──────────┐
│ Call API│  │Query     │
│/my-day  │  │PowerSync │
│tasks    │  │itineraries│
└────┬────┘  └────┬─────┘
     │            │
     ▼            ▼
┌────────────────────┐
│ Build ClientStatus  │
│ Map for all clients │
└────────────────────┘
```

**Hybrid Fallback:**
1. Try API when online (`GET /api/my-day/tasks?date=today`)
2. On API error, fall back to PowerSync local query
3. PowerSync query: `SELECT client_id FROM itineraries WHERE scheduled_date = CURRENT_DATE`

## UI Design

### Expansion Panel Layout

```
┌─────────────────────────────────────────────┐
│ Client Selector Modal                      │
├─────────────────────────────────────────────┤
│ Search: [_________________] [A..] [All Clients]│
├─────────────────────────────────────────────┤
│ ▼ Client 1 - EXPANSION PANEL                │
│ ┌─────────────────────────────────────────┐ │
│ │ [👤] John Doe                           │ │
│ │ john@email.com                          │ │
│ │                                         │ │
│ │ 🟡 Next: 2nd Call ⚠️                    │ │ ← Badge
│ │ 🔴 Loan Released                        │ │ ← Badge
│ │                                         │ │
│ │ ┌───────────────────────────────────┐   │ │
│ │ │ [Add to Today]  [Add w/ Date]     │   │ │ ← Disabled
│ │ └───────────────────────────────────┘   │ │
│ └─────────────────────────────────────────┘ │
├─────────────────────────────────────────────┤
│ ▼ Client 2 - EXPANSION PANEL                │
│ ┌─────────────────────────────────────────┐ │
│ │ [👤] Jane Smith                         │ │
│ │ jane@email.com                          │ │
│ │                                         │ │
│ │ 🟢 Next: 4th Visit ✅                   │ │ ← Badge
│ │ 🟠 Already added                        │ │ ← Badge
│ │                                         │ │
│ │ ┌───────────────────────────────────┐   │ │
│ │ │ [Add to Today]  [Add w/ Date]     │   │ │ ← Disabled
│ │ └───────────────────────────────────┘   │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Badge Styles

| Status | Icon | Color | Label |
|--------|------|-------|-------|
| Loan Released | Ban | Red | "Loan Released" |
| Already Added | Calendar Check | Orange | "Already added" |
| Visit Touchpoint | Map Pin | Green | "Next: 1st/4th/7th Visit" |
| Call Touchpoint | Phone | Orange | "Next: 2nd/3rd/5th/6th Call" |

### Button States

| State | Appearance | Tap Behavior |
|-------|------------|--------------|
| Enabled | Dark fill (primary) / Light fill (secondary) | Executes action |
| Disabled | Gray fill, gray border | Shows toast with reason |

## Data Models

### ClientStatus Model

```dart
class ClientStatus {
  final bool inItinerary;
  final bool loanReleased;

  const ClientStatus({
    required this.inItinerary,
    required this.loanReleased,
  });
}
```

## Implementation Details

### 1. PowerSync Touchpoint Provider

**File:** `lib/shared/providers/app_providers.dart`

```dart
/// NEW: PowerSync-based touchpoints for client selector (read-only status)
final clientTouchpointsSyncProvider = FutureProvider.autoDispose<List<Touchpoint>>((ref) async {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return [];

  // Query PowerSync for touchpoints
  final touchpoints = await PowerSyncService.query('''
    SELECT t.id, t.client_id, t.user_id, t.touchpoint_number, t.type,
           t.date, t.reason, t.status
    FROM touchpoints t
    WHERE t.client_id = ?
    ORDER BY t.touchpoint_number DESC
  ''', [clientId]);

  // Fallback to Hive if PowerSync empty (migration safety)
  if (touchpoints.isEmpty) {
    final hiveService = ref.watch(hiveServiceProvider);
    final touchpointsData = hiveService.getTouchpointsForClient(clientId);
    return touchpointsData.map((data) => Touchpoint.fromJson(data)).toList();
  }

  return touchpoints.map((row) => Touchpoint.fromRow(row)).toList();
});
```

### 2. Status Loading Logic

**Key Methods:**

- `_loadClientStatuses()`: Main orchestrator with hybrid fallback
- `_loadStatusesFromAPI()`: API call when online
- `_loadStatusesFromPowerSync()`: Local query when offline
- `_canAddToItinerary()`: Validation logic
- `_getDisableReason()`: User-facing reason text

### 3. Disabled Button Validation Rules

**When to disable "Add to Today" button:**

1. **Loan Released** → Disabled, reason: "Loan released - cannot add"
2. **Already in Today's Itinerary** → Disabled, reason: "Already added today"
3. **Next Touchpoint is Call (Caravan role)** → Disabled, reason: "Next is Call - use Call feature"

**Role-Based Touchpoint Permissions:**

| Role | Can Add For Touchpoints | Visit (1,4,7) | Call (2,3,5,6) |
|------|------------------------|---------------|----------------|
| Caravan | Itinerary/Visit only | ✅ Yes | ❌ No - use Call feature |
| Tele | Itinerary/Call only | ❌ No | ✅ Yes |
| Managers | All | ✅ Yes | ✅ Yes |

### 4. Skeleton Loading

**Show 5 skeleton cards while loading:**
- Circle avatar placeholder
- Name line placeholders (120px, 180px, 100px)
- Two button placeholders

## Error Handling

### API Fallback Strategy

```
Try API (when online)
    │
    ├─ Success → Use API results
    │
    └─ Error → Log error
              │
              ▼
         Try PowerSync
              │
              ├─ Success → Use PowerSync results
              │
              └─ Error → Show error state
```

**Error State Display:**
- Show error message: "Failed to load client status. Tap to retry."
- Retry button to reload statuses
- Can still interact with client list but no status badges

## Files to Modify

1. **lib/shared/providers/app_providers.dart**
   - Add `clientTouchpointsSyncProvider`
   - Keep existing `clientTouchpointsProvider`

2. **lib/shared/widgets/client_selector_modal.dart**
   - Add expansion panel UI
   - Add skeleton loading state
   - Add badge widgets
   - Add disabled button logic
   - Implement hybrid status loading

3. **lib/services/sync/powersync_service.dart**
   - Add Touchpoint.fromRow() factory method to parse PowerSync rows

4. **lib/features/clients/data/models/touchpoint_model.dart**
   - Add `static Touchpoint fromRow(Map<String, dynamic> row)` factory method
   - Parse snake_case columns from PowerSync database
   - Handle nullable fields correctly

## Files to Create

1. **lib/models/client_status.dart**
   - ClientStatus model class

## Testing Checklist

- [ ] Online: API used for status loading
- [ ] Offline: PowerSync used for status loading
- [ ] Loan released clients show red badge
- [ ] Already in itinerary clients show orange badge
- [ ] Next touchpoint badge shows correct type and number
- [ ] Buttons disabled correctly with reasons
- [ ] Tapping disabled button shows toast reason
- [ ] Skeleton loading shows during status fetch
- [ ] Expansion panel expands/collapses correctly
- [ ] PowerSync fallback works when API fails
- [ ] Hive fallback works when PowerSync empty

## Acceptance Criteria

1. ✅ Client selector modal shows all status badges
2. ✅ Buttons disabled when action not allowed
3. ✅ Disabled buttons show reason on tap
4. ✅ Touchpoints loaded from PowerSync in real-time
5. ✅ Offline support via PowerSync fallback
6. ✅ Loading states show skeleton cards
7. ✅ Expansion panels organize client details
8. ✅ No performance regression on modal open

## Dependencies

- PowerSync database connection
- Network connectivity state (isOnlineProvider)
- Existing providers: clientsProvider, currentUserRoleProvider
- Existing services: MyDayApiService, PowerSyncService

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| PowerSync query performance | Slow modal open | Add index on touchpoints.client_id |
| API reliability | Fallback fails | Implement robust error handling with retries |
| Touchpoint data sync | Stale data | Use API as primary, PowerSync as fallback |
| Expansion panel complexity | UX issues | Test with real users, iterate on design |

## Future Enhancements

- Bulk add multiple clients at once
- Filter by status (show only addable clients)
- Sort by next touchpoint priority
- Show last touchpoint date in expansion panel
- Add "View Touchpoint History" in expansion panel
