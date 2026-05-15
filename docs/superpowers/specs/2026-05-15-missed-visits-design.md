# Missed Visits Page — Real Data Design

**Date:** 2026-05-15
**Scope:** Flutter mobile app (`imu_flutter`), Caravan/Tele roles only
**Status:** Approved

---

## Problem

The existing `missed_visits_page.dart` uses estimated data: it guesses a "scheduled date" by adding 3 days to the last touchpoint, then flags any client past that date as missed. This produces inaccurate results and only scans the first page (10 clients) of the assigned-client Hive cache.

---

## Definition of "Missed Visit"

Two sources, merged and deduplicated by `client_id`:

1. **Missed itinerary** — an itinerary record with `status IN ('pending', 'in_progress')` and `scheduled_date < today`. The agent formally scheduled this visit and never completed it.

2. **Overdue client** — a client whose last touchpoint (or enrollment date if no touchpoints) is more than **7 days ago**, with no future itinerary already scheduled. Loan-released clients and clients with a completed journey (`next_touchpoint IS NULL`) are excluded.

When both conditions apply to the same client, the missed itinerary entry takes precedence (deduplication by `client_id`).

---

## Architecture

```
PowerSync (reactive stream)
  └─ itineraries WHERE scheduled_date < today
      AND status IN ('pending', 'in_progress')
      AND user_id = currentUser
  → raw rows enriched from Hive cache → MissedVisit(source: missedItinerary)

Hive cache (API-backed, all assigned clients — not paginated)
  └─ clients WHERE last_touchpoint_or_enrolled > 7 days ago
      AND NOT loan_released
      AND next_touchpoint IS NOT NULL
      AND no future itinerary in PowerSync
      AND client_id NOT IN missed itineraries above
  → MissedVisit(source: overdueClient)

Both merged → missedVisitsProvider → filtered/counted → UI
```

### PowerSync schema notes

The ACTIVE schema (inline in `powersync_service.dart`, not the stale `powersync_schema_v2.dart`) includes all needed fields on `clients`: `first_name`, `last_name`, `middle_name`, `phone`, `loan_released`, `touchpoint_number` (integer), `next_touchpoint` (text), and `touchpoint_summary` (text — JSON array). The full JOIN query works without any Hive enrichment for Set A.

---

## Data Layer

### New method: `itinerary_repository.dart`

```dart
Stream<List<Map<String, dynamic>>> watchMissedItineraries(String userId) {
  return PowerSyncService.database.asStream().asyncExpand((db) =>
    db.watch('''
      SELECT i.id, i.client_id, i.scheduled_date, i.status, i.created_at,
             c.first_name, c.last_name, c.middle_name,
             c.next_touchpoint, c.touchpoint_number,
             c.loan_released, c.phone
      FROM itineraries i
      LEFT JOIN clients c ON c.id = i.client_id
      WHERE i.user_id = ?
        AND DATE(i.scheduled_date) < DATE('now', 'localtime')
        AND i.status IN ('pending', 'in_progress')
      ORDER BY i.scheduled_date ASC
    ''', parameters: [userId]),
  );
}
```

Reactive: entries disappear automatically when an itinerary is completed or cancelled. No Hive enrichment needed for Set A — all required fields are available in the PowerSync SQLite JOIN.

### Overdue client computation

Read directly from `HiveService().getAllClients()` filtered through `filterAssignedClientCache()` — all clients, not the paginated `assignedClientsProvider`.

Before iterating clients, fetch one Set via a bulk query:

```sql
-- Set B: client IDs that already have a future pending itinerary
SELECT DISTINCT client_id FROM itineraries
WHERE user_id = ?
  AND DATE(scheduled_date) >= DATE('now', 'localtime')
  AND status IN ('pending', 'in_progress')
```

Set A (client IDs covered by missed itineraries) comes from the stream's current value — no extra query needed.

Then for each client:

1. Skip if `client.loanReleased == true`
2. Skip if `client.nextTouchpoint == null` (journey complete)
3. Skip if `client.id` is in Set A (already a missed itinerary entry)
4. Skip if `client.id` is in Set B (future itinerary already scheduled)
5. Compute `lastActivity`:
   - `touchpointSummary.isNotEmpty` → use `.reduce((a, b) => a.date.isAfter(b.date) ? a : b).date` (not `.last` — list order is not guaranteed)
   - Otherwise → `client.createdAt`
6. Skip if `DateTime.now().difference(lastActivity).inDays <= 7`

---

## Model Changes

`missed_visit_model.dart` — two new fields added:

```dart
final MissedVisitSource source;  // missedItinerary | overdueClient
final String? itineraryId;       // non-null when source == missedItinerary
```

New enum:
```dart
enum MissedVisitSource { missedItinerary, overdueClient }
```

---

## Providers

Replace the current single `missedVisitsProvider` with:

| Provider | Type | Source |
|---|---|---|
| `missedItinerariesStreamProvider` | `StreamProvider<List<Map<String, dynamic>>>` | PowerSync `watchMissedItineraries()` |
| `overdueClientsProvider` | `Provider<List<MissedVisit>>` | Full Hive cache + future itinerary exclusion set |
| `missedVisitsProvider` | `Provider<List<MissedVisit>>` | Merges both, deduplicates by `clientId` |
| `filteredMissedVisitsProvider` | `Provider` | Priority chip filter — unchanged |
| `missedVisitsCountProvider` | `Provider` | Counts per priority — unchanged |

### Reactivity design

`missedItinerariesStreamProvider` is a `StreamProvider` — Riverpod rebuilds its dependents on every new stream event (automatic).

`overdueClientsProvider` reads from Hive, which is not a reactive stream. It must also `ref.watch(syncServiceProvider)` so that a sync-status change (e.g. sync completion) triggers a recompute. This is the same pattern used by `assignedClientsProvider`.

`missedVisitsProvider` is a plain `Provider` that:
1. Reads `missedItinerariesStreamProvider` via `ref.watch(...).valueOrNull ?? []`
2. Reads `overdueClientsProvider` via `ref.watch(...)`
3. Deduplicates by `clientId` (itinerary entries win)
4. Sorts: high priority first, then by `daysOverdue` descending

---

## Reschedule Action Fix

Current bug: inserts with status `'scheduled'` (not a valid enum value) and never cancels the original itinerary (causing duplicates).

**New behaviour:**

- **`source == missedItinerary`**: cancel the existing record, then insert a new one for the chosen date — wrapped in `db.writeTransaction()` for atomicity:
  ```dart
  await db.writeTransaction(() async {
    await db.execute(
      'UPDATE itineraries SET status = ?, updated_at = ? WHERE id = ?',
      ['cancelled', now, visit.itineraryId],
    );
    await db.execute(
      'INSERT INTO itineraries (id, user_id, client_id, scheduled_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [uuid, userId, visit.clientId, dateStr, 'pending', now, now],
    );
  });
  ```
- **`source == overdueClient`**: insert a new itinerary with `status = 'pending'`. No old record to cancel — no transaction needed.

Both use PowerSync `db.execute()` for automatic sync.

---

## UI Changes

The page layout is unchanged (filter chips + list + empty state). Card subtitle changes:

- **Missed itinerary**: "Scheduled [date that was missed]" — e.g. "Scheduled May 10"
- **Overdue client**: "Last touched [N] days ago" — e.g. "Last touched 12 days ago"

A skeleton list (using the existing `ClientSkeleton` pattern) is shown while the stream loads, replacing the immediate empty state flash.

No other UI changes. Filter chips, priority colours, Call action, and tap-to-client-detail behaviour are all unchanged.

---

## Files Affected

| File | Change |
|---|---|
| `lib/features/visits/data/models/missed_visit_model.dart` | Add `source`, `itineraryId` fields and `MissedVisitSource` enum |
| `lib/features/itineraries/data/repositories/itinerary_repository.dart` | Add `watchMissedItineraries(userId)` |
| `lib/shared/providers/app_providers.dart` | Replace `missedVisitsProvider`; add `missedItinerariesStreamProvider`, `overdueClientsProvider` |
| `lib/features/visits/presentation/pages/missed_visits_page.dart` | Update card subtitle; fix reschedule action; add skeleton loading |
