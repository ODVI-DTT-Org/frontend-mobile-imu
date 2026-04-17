# Offline-First Caravan Mobile — Design Spec

**Date:** 2026-04-18
**Platform:** Flutter mobile app (Caravan role only)
**Status:** Approved

---

## Problem

Field agents (Caravan role) lose all app functionality when offline. My Day and Itinerary show errors or blank screens despite data being available locally in PowerSync. Recording activities (touchpoints), visits, and loan releases fails silently or blocks the user. The infrastructure for offline-first exists but is not wired together.

---

## Goal

All core Caravan workflows work offline. Data is saved locally first and syncs automatically when connectivity is restored — the same pattern touchpoints already attempt but don't complete.

---

## Scope

- Flutter mobile app, Caravan role only
- Features: My Day, Itinerary, Touchpoints, Record Visit, Record Loan Release
- No backend changes required
- No changes to Tele role or web admin

---

## Section 1 — Write Operations: Itinerary & My Day

**Current:** `ClientSelectorModal` calls `myDayApiService.addToMyDay()` → REST API → PostgreSQL. No local write at all.

**Fix:** Route through `itineraryRepository.createItinerary()` instead.

- Generates UUID locally
- Writes immediately to PowerSync `itineraries` SQLite table
- PowerSync `uploadData()` connector auto-syncs to PostgreSQL when online
- No changes needed to the connector — it handles all PowerSync table mutations generically

**Itinerary edits (status, notes, priority):**
- Route through `itineraryRepository.updateItinerary()` (PowerSync write) instead of current HiveService write
- Route deletes through `itineraryRepository.deleteItinerary()` instead of HiveService

**Key files:**
- `lib/shared/widgets/client_selector_modal.dart:406` — change `myDayApiService.addToMyDay()` to `itineraryRepository.createItinerary()`
- `lib/features/itineraries/data/repositories/itinerary_repository.dart` — `createItinerary()`, `updateItinerary()`, `deleteItinerary()` already implemented
- `lib/services/sync/powersync_connector.dart` — `uploadData()` unchanged

> **Implementation note:** `itineraryRepository.createItinerary()` currently uses `caravan_id` in its INSERT SQL but the PowerSync schema column is `user_id` (post-migration). Verify and align column name in the repository before use.

---

## Section 2 — Read Operations: My Day & Itinerary

**Current:** Both pages call REST API on load. Offline = error message or blank screen.

**Fix:** Both pages query PowerSync local SQLite instead of REST API.

**My Day page:**
- Replace `MyDayNotifier.loadClients()` API call with a PowerSync `db.watch()` stream
- Query: `SELECT i.*, c.first_name, c.last_name, c.client_type, c.touchpoint_summary FROM itineraries i JOIN clients c ON c.id = i.client_id WHERE i.user_id = ? AND i.scheduled_date = ? ORDER BY i.scheduled_time ASC`
- Parse `clients.touchpoint_summary` JSON locally to compute next touchpoint number and type (same data the API computes server-side — already available in PowerSync `clients` table)
- Page auto-updates reactively when data syncs in or changes locally

**Itinerary list:**
- `ItineraryRepository.watchItineraries()` PowerSync stream already exists — list page switches to use it instead of the API call

**Itinerary detail:**
- Query PowerSync by ID: `SELECT * FROM itineraries WHERE id = ?`
- Replaces current HiveService lookup
- Eliminates "Scheduled visit not found" for itineraries that exist in PowerSync but were never opened before

**Key files:**
- `lib/features/my_day/presentation/providers/my_day_provider.dart:42` — replace API call with PowerSync `db.watch()` query
- `lib/features/itineraries/presentation/pages/itinerary_detail_page.dart:16-43` — replace HiveService lookup with PowerSync query
- `lib/features/itineraries/data/repositories/itinerary_repository.dart:114` — `watchItineraries()` stream already exists

---

## Section 3 — Touchpoint Pending Queue Auto-Sync (Fix)

**Current:** `TouchpointCreationService` saves to Hive `pending_touchpoints` when offline. `BackgroundSyncService._syncPendingTouchpoints()` processes the queue. But sync is never triggered when connectivity is restored — pending touchpoints sit in Hive indefinitely.

**Fix:** Wire `ConnectivityService` to call `backgroundSyncService.syncAll()` on `offline → online` transition.

- One connection between two existing services
- No structural changes

**Key files:**
- `lib/services/connectivity_service.dart` — add listener that calls `syncAll()` on online transition
- `lib/services/api/background_sync_service.dart` — `syncAll()` already calls `_syncPendingTouchpoints()`

---

## Section 4 — Record Visit & Loan Release Offline Queue

Both follow the same Hive pending queue pattern as touchpoints.

**Record Visit:**

New Hive box: `pending_visits`

Stored fields:
```
id, clientId, timeIn, timeOut, odometerArrival, odometerDeparture,
photoPath, notes, type, createdAt
```

- Photo file already on device — store local path, re-upload on sync
- `VisitCreationService` (new, mirrors `TouchpointCreationService`): online → REST API directly; offline → save to `pending_visits`
- `BackgroundSyncService._syncPendingVisits()` (new): uploads photo + calls `POST /visits`, removes from Hive on success

**Record Loan Release:**

New Hive box: `pending_releases`

Stored fields:
```
id, clientId, visitData (nested), releaseData (nested), photoPath, createdAt
```
Both visit and release stored together as one pending record.

`BackgroundSyncService._syncPendingReleases()` (new):
1. Create visit via `POST /visits` → get `visit_id`
2. Create release via `POST /releases` with `visit_id`
3. Update client `loan_released` flag via `PUT /clients/{id}`
4. If any step fails: retry from step 1 using stored `id` (idempotent)
5. Remove from Hive on full success

**Key files:**
- `lib/services/api/visit_api_service.dart` — add offline path
- `lib/services/api/release_api_service.dart` — add offline path
- `lib/services/api/background_sync_service.dart` — add `_syncPendingVisits()` and `_syncPendingReleases()`, include in `syncAll()`
- `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart` — route through new `VisitCreationService`
- `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart` — route through new `ReleaseCreationService`

---

## Section 5 — UI/UX: Offline Banner & Sync Status

**Offline banner (`OfflineBanner` widget, new):**
- Persistent bar shown at top of My Day, Itinerary, and client detail pages when `isOnlineProvider` is false
- Text: "You're offline — changes will sync when connected"
- Dismissible per session; reappears if connectivity drops again
- Uses existing `isOnlineProvider` stream

**Pending sync badge:**
- Small count badge on sync/settings icon
- Count = pending touchpoints + pending visits + pending releases
- Tapping shows list: "3 activities, 1 visit, 1 loan release pending sync"
- No user action required — informational only

**Toast messages:**
- Offline save: "Saved locally — will sync when connected" (replaces "Saved successfully")
- Sync start: "Syncing X pending items..."
- Sync complete: "All synced"
- Sync failure: "1 item failed to sync — tap to retry"

**Write actions:**
- Itinerary/My Day add: always enabled (writes to PowerSync locally)
- Record Visit / Loan Release / Touchpoint: always enabled (saves to Hive queue)

---

## Data Flow Summary

```
[Caravan adds itinerary / My Day]
  → itineraryRepository.createItinerary()
  → PowerSync local SQLite (immediate)
  → uploadData() auto-syncs to PostgreSQL when online

[Caravan records touchpoint / visit / loan release]
  Online  → REST API directly
  Offline → Hive pending queue (pending_touchpoints / pending_visits / pending_releases)
           → ConnectivityService detects online
           → BackgroundSyncService.syncAll()
           → Upload to server, remove from Hive

[Caravan opens My Day / Itinerary]
  → PowerSync local SQLite query (always)
  → Reactive stream updates when sync completes
  → No API call needed
```

---

## What Does NOT Change

- Tele role behavior unchanged
- Web admin unchanged
- Backend API unchanged
- PowerSync schema unchanged (itineraries table already exists)
- Touchpoint creation service online path unchanged
- Authentication flow unchanged

---

## Files Changed Summary

| File | Change |
|------|--------|
| `client_selector_modal.dart` | Route create through `itineraryRepository` |
| `itinerary_detail_page.dart` | Read from PowerSync, write via repository |
| `my_day_provider.dart` | Replace API call with PowerSync `db.watch()` |
| `connectivity_service.dart` | Trigger `syncAll()` on online transition |
| `background_sync_service.dart` | Add `_syncPendingVisits()`, `_syncPendingReleases()` |
| `visit_api_service.dart` | Add offline path to Hive |
| `release_api_service.dart` | Add offline path to Hive |
| `record_visit_only_bottom_sheet.dart` | Route through `VisitCreationService` |
| `record_loan_release_bottom_sheet.dart` | Route through `ReleaseCreationService` |
| New: `VisitCreationService` | Mirror of `TouchpointCreationService` for visits |
| New: `ReleaseCreationService` | Mirror of `TouchpointCreationService` for releases |
| New: `OfflineBanner` widget | Shared offline indicator widget |
