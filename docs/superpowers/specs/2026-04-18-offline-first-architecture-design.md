# Offline-First Architecture Design

**Date:** 2026-04-18
**Status:** Approved

---

## Goal

Rebuild the IMU Flutter mobile app's data layer to be truly offline-first: all reads come from local PowerSync SQLite, all writes are queued locally and synced to the backend when online. Remove the fragmented dual-storage system (Hive + PowerSync) and replace it with a single, clean architecture.

## Problem Statement

The current app has two competing local storage systems running in parallel:

- **Hive** is the de-facto primary cache for most data (clients, touchpoints, itineraries)
- **PowerSync SQLite** is connected and schema-defined but mostly bypassed
- **4 separate pending services** handle offline queuing per entity type (PendingTouchpointService, PendingVisitService, PendingClientService, PendingReleaseService) — none unified
- **Many REST GET calls** hit the backend for data that should be read locally
- **OfflineSyncQueueService** — the intended unified queue — is completely stubbed with `UnimplementedError`

The result: offline "works" partially but is fragile, inconsistent, and unmaintainable.

---

## Architecture

### Core Rule

> **Reads come from local SQLite. Writes go to the PowerSync CRUD queue.**

```
PostgreSQL (backend)
    │
    │  PowerSync Service (real-time sync)
    ▼
Local SQLite (on device)  ← ALL reads come from here
    │
    │  PowerSync CRUD queue (automatic)
    ▼
uploadData() connector  ──→  REST API (POST/PUT/DELETE only)
                                  │
                         Local file storage
                         (photos/audio queued
                          until online)
```

The app never makes a GET request to the backend for data the agent owns. REST calls are limited to:
- `POST /auth/login` — must be online
- `POST /powersync/token` — sync authentication
- `POST/PUT/DELETE` mutations — queued, sent when online
- `POST /upload/file` — photo/audio, queued with local file path
- `GET /clients` — all-clients search (online only, full DB)
- `GET /clients/search/unassigned` — unassigned client search (online only)
- `GET /auth/permissions` — must be fresh from server

---

## Local Storage

### PowerSync SQLite — all app data

Single source of truth for all data the agent reads.

### Hive — settings and auth only

| Hive box | Kept? | Reason |
|---|---|---|
| `settings` | ✅ Keep | App preferences, theme, notifications |
| `auth` / secure storage | ✅ Keep | JWT tokens, PIN, session data |
| `clients` | ❌ Remove | Replaced by PowerSync SQLite |
| `touchpoints` | ❌ Remove | Embedded in clients.touchpoint_summary |
| `attendance` | ❌ Remove | Replaced by PowerSync SQLite |
| `agencies` | ❌ Remove | Replaced by PowerSync SQLite |
| `groups` | ❌ Remove | Replaced by PowerSync SQLite |
| `itineraries` | ❌ Remove | Replaced by PowerSync SQLite |
| `cache` | ❌ Remove | Replaced by PowerSync SQLite |
| `pending_sync` | ❌ Remove | Replaced by PowerSync CRUD queue |

---

## Sync Layer

### Tables synced to device

| Table | Sync scope |
|---|---|
| `clients` | Clients where municipality + province match agent's `user_locations` |
| `addresses` | Only addresses linked to synced clients |
| `phone_numbers` | Only phones linked to synced clients |
| `itineraries` | Only itineraries where `user_id = agent` |
| `user_profiles` | Only the agent's own profile |
| `user_locations` | Only the agent's own assigned locations |
| `visits` | All visits for synced clients (full history) |
| `calls` | All calls for synced clients (full history) |
| `groups` | Only groups where agent is a member |
| `targets` | Only targets where `user_id = agent` |
| `attendance` | Only attendance records where `user_id = agent` |

### Removed from sync schema

| Table | Replacement |
|---|---|
| `psgc` | Bundled as local JSON asset in the app (~2MB, never changes) |
| `touchpoint_reasons` | Hardcoded list in Dart |
| `error_logs` | Fire-and-forget POST when online, no sync |
| `approvals` | Agents submit via write queue; no offline read needed |

### Initial sync flow

1. Agent logs in → receives JWT
2. App requests PowerSync token → connects to PowerSync service
3. PowerSync downloads all 11 tables scoped to that agent's territory
4. App is ready for full offline use

### Sync scope definition (backend PowerSync rules)

```sql
-- clients bucket: sync by agent's assigned province + municipality
SELECT id FROM clients
WHERE municipality IN (
  SELECT municipality FROM user_locations WHERE user_id = agent_id
)
AND province IN (
  SELECT province FROM user_locations WHERE user_id = agent_id
)

-- visits + calls: scoped to synced clients
SELECT id FROM visits WHERE client_id IN (synced_client_ids)
SELECT id FROM calls WHERE client_id IN (synced_client_ids)
```

---

## Write / Queue Layer

### How mutations work

All writes go to local SQLite first. UI updates instantly. PowerSync CRUD queue handles delivery to the backend when online.

```
Agent action (online or offline)
    │
    ▼
Write to local SQLite  ←  UI updates instantly (optimistic)
    │
    ▼
PowerSync CRUD queue (automatic)
    │  (when back online)
    ▼
uploadData() → REST API (POST/PUT/DELETE)
    │
    ▼
Backend updates PostgreSQL
    │
    ▼
PowerSync syncs confirmation back to device
```

### Mutations that go through the queue

**Client:**
- Create client
- Edit/update client
- Delete client

**Address:**
- Add address to client
- Edit address
- Delete address

**Phone number:**
- Add phone number to client
- Edit phone number
- Delete phone number

**Field activity:**
- Record touchpoint / visit
- Time in / time out
- Attendance check-in / check-out
- Add/remove client from My Day
- Loan release

### Photo and audio handling

Photos and audio cannot be stored in SQLite. They use local file storage with a path reference in the queue.

```
Agent records visit + photo (offline)
    │
    ├── Save photo to app local storage (path_provider documents dir)
    └── Write visit data + file path to SQLite CRUD queue
            │
            │  (back online)
            ▼
    uploadData() reads queue entry
    → Loads file from local path
    → Builds FormData (visit data + file bytes)
    → POST /visits (multipart/form-data)
    → On success: delete local file + mark queue entry complete
```

PowerSync Attachments API manages the file lifecycle (save, upload, delete on success, retry on failure).

### uploadData() connector routing

The single `uploadData()` connector reads the CRUD queue and routes by table name:

| Queue entry table | REST endpoint |
|---|---|
| `clients` | POST/PUT/DELETE `/api/clients` |
| `addresses` | POST/PUT/DELETE `/api/clients/{id}/addresses` |
| `phone_numbers` | POST/PUT/DELETE `/api/clients/{id}/phones` |
| `itineraries` | POST/PUT/DELETE `/api/itineraries` |
| `visits` (with photo) | POST `/api/visits` (FormData) |
| `visits` (no photo) | POST `/api/visits` (JSON) |
| `touchpoints` | POST/PUT/DELETE `/api/touchpoints` |
| `attendance` | POST `/api/attendance/check-in` or `/check-out` |
| `releases` | POST `/api/releases` |

---

## REST GET Calls Removed from Mobile

These REST GET calls are removed and replaced with local SQLite reads:

| Removed REST call | Replaced with |
|---|---|
| `GET /clients` (assigned) | PowerSync SQLite query |
| `GET /clients/{id}` | PowerSync SQLite query |
| `GET /touchpoints` | Embedded in `clients.touchpoint_summary` |
| `GET /itineraries` | PowerSync SQLite query |
| `GET /my-day/tasks` | PowerSync SQLite query |
| `GET /my-day/status/{clientId}` | PowerSync SQLite query |
| `GET /visits` (assigned clients) | PowerSync SQLite query |
| `GET /calls` (assigned clients) | PowerSync SQLite query |
| `GET /attendance/today` | PowerSync SQLite query |
| `GET /attendance/history` | PowerSync SQLite query |
| `GET /groups` | PowerSync SQLite query |
| `GET /targets` | PowerSync SQLite query |
| `GET /psgc/*` | Bundled local JSON asset |
| `GET /touchpoint-reasons` | Hardcoded Dart list |

---

## Services Deleted

These are replaced entirely by the PowerSync CRUD queue:

- `PendingTouchpointService`
- `PendingVisitService`
- `PendingClientService`
- `PendingReleaseService`
- `SyncQueueService` (Hive-based)
- `OfflineSyncQueueService` (stubbed)
- `UnifiedSyncService` (Phase 2 stub)

---

## Backend Changes Required

### PowerSync sync rules (backend)
- Define bucket rules for all 8 sync tables scoped to agent's territory
- `clients` scoped by `user_locations` (province + municipality)
- `visits` + `calls` scoped to synced client IDs

### Backend routes to deprecate
These are unused by both mobile and web admin:
- `GET /api/search` — unused anywhere
- `GET /api/cache` — internal admin only
- `GET /api/debug-audit` — dev only

---

## Screen-by-Screen Read Source After Refactor

| Screen | Read source |
|---|---|
| Home | PowerSync SQLite (user_profiles, user_locations) |
| Clients — Assigned | PowerSync SQLite |
| Clients — All | REST API (online only, province+municipality filter) |
| Client Detail | PowerSync SQLite (client + addresses + phones + visits + calls) |
| My Day | PowerSync SQLite (itineraries JOIN clients) |
| Itinerary | PowerSync SQLite |
| Touchpoint history | Embedded in clients.touchpoint_summary |
| Visit history (CMS) | PowerSync SQLite (visits where source='CMS') |
| Call history (CMS) | PowerSync SQLite (calls where source='CMS') |
| Settings | Hive (preferences) |
| Auth | REST API (login) + Hive (offline grace period) |

---

## What Does NOT Change

- Auth flow (login, PIN, biometric, session timeout)
- UI/UX of all screens
- Backend API structure (endpoints stay the same, mobile just stops calling GET ones)
- PowerSync connector authentication flow
- Background sync trigger logic (on resume, on connectivity restore, periodic)
