# Offline-First Plan 1: PowerSync Schema + Sync Rules

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add visits, calls, groups, targets, and attendance to the PowerSync sync layer so all agent data flows to the device automatically.

**Architecture:** PostgreSQL publishes the new tables via the `powersync` publication. The PowerSync sync-config.yaml defines what each agent receives (scoped by their assigned province + municipality). The Flutter app's PowerSync schema is updated to match so the local SQLite database can receive and store the new data.

**Tech Stack:** PostgreSQL (publication), PowerSync sync-config.yaml (sync rules), Flutter/Dart (local SQLite schema via `powersync_service.dart`)

**Spec:** `docs/superpowers/specs/2026-04-18-offline-first-architecture-design.md`

---

## File Map

| File | Change |
|---|---|
| `backend-imu/src/migrations/080_add_tables_to_powersync_publication.sql` | CREATE — adds groups, targets, attendance to powersync publication |
| `backend-imu/powersync-cli/powersync/sync-config.yaml` | MODIFY — scope clients by user_locations; add visits, calls, groups, targets, attendance streams |
| `backend-imu/migrations/COMPLETE_SCHEMA.sql` | MODIFY — add groups, targets, attendance to publication block |
| `backend-imu/src/schema.sql` | MODIFY — add source columns to visits/calls, update group_members FK |
| `frontend-mobile-imu/imu_flutter/lib/services/sync/powersync_service.dart` | MODIFY — add visits, calls, groups, targets, attendance tables to `_powerSyncSchema` |

---

## Task 1: Create migration to add tables to PowerSync publication

**Files:**
- Create: `backend-imu/src/migrations/080_add_tables_to_powersync_publication.sql`

- [ ] **Step 1: Create the migration file**

```sql
-- Add groups, targets, and attendance to the PowerSync publication
-- These tables need to sync to mobile devices for offline access

ALTER PUBLICATION powersync ADD TABLE groups;
ALTER PUBLICATION powersync ADD TABLE targets;
ALTER PUBLICATION powersync ADD TABLE attendance;
```

Save to: `backend-imu/src/migrations/080_add_tables_to_powersync_publication.sql`

- [ ] **Step 2: Run the migration on qa2**

```bash
psql "postgresql://doadmin:<REDACTED>@imu-do-user-21438450-0.j.db.ondigitalocean.com:25060/qa2?sslmode=require" \
  -f backend-imu/src/migrations/080_add_tables_to_powersync_publication.sql
```

Expected output:
```
ALTER PUBLICATION
ALTER PUBLICATION
ALTER PUBLICATION
```

- [ ] **Step 3: Verify all required tables are in the publication**

```bash
psql "postgresql://doadmin:<REDACTED>@imu-do-user-21438450-0.j.db.ondigitalocean.com:25060/qa2?sslmode=require" \
  -c "SELECT tablename FROM pg_publication_tables WHERE pubname = 'powersync' ORDER BY tablename;"
```

Expected — these tables must all appear:
```
addresses, approvals, attendance, calls, clients, groups, itineraries,
phone_numbers, psgc, targets, touchpoint_reasons, touchpoints,
user_locations, user_profiles, visits
```

- [ ] **Step 4: Commit**

```bash
cd backend-imu
git add src/migrations/080_add_tables_to_powersync_publication.sql
git commit -m "feat: add groups, targets, attendance to powersync publication"
```

---

## Task 2: Update sync-config.yaml — scope clients + add new streams

**Files:**
- Modify: `backend-imu/powersync-cli/powersync/sync-config.yaml`

- [ ] **Step 1: Replace the full file content**

Replace `backend-imu/powersync-cli/powersync/sync-config.yaml` with:

```yaml
# PowerSync Sync Configuration for IMU
# Docs: https://docs.powersync.com/sync/streams/overview
#
# ARCHITECTURE: Agents only receive data for their assigned territory (province + municipality)
# All streams are scoped to auth.user_id() for user-specific data

config:
  edition: 3

streams:
  # ============================================================
  # USER-SPECIFIC DATA
  # ============================================================

  # User profile - agent's own profile only
  user_profile:
    auto_subscribe: true
    query: |
      SELECT id, user_id, name, email, role, avatar_url, updated_at
      FROM user_profiles
      WHERE user_id = auth.user_id()

  # User location assignments - agent's assigned territory
  user_municipalities:
    auto_subscribe: true
    query: |
      SELECT id, user_id, province, municipality, assigned_at, assigned_by, deleted_at,
        created_at, updated_at
      FROM user_locations
      WHERE user_id = auth.user_id() AND deleted_at IS NULL

  # ============================================================
  # CLIENT DATA - scoped to agent's assigned province + municipality
  # ============================================================

  clients:
    auto_subscribe: true
    query: |
      SELECT c.id, c.first_name, c.last_name, c.middle_name, c.birth_date,
        c.email, c.phone, c.agency_name, c.department, c.position,
        c.employment_status, c.payroll_date, c.tenure, c.client_type,
        c.product_type, c.market_type, c.pension_type, c.pan, c.facebook_link,
        c.remarks, c.agency_id, c.is_starred, c.psgc_id, c.region, c.province,
        c.municipality, c.barangay, c.udi, c.loan_released, c.loan_released_at,
        c.created_at, c.updated_at, c.deleted_at, c.ext_name, c.full_address,
        c.account_code, c.account_number, c.rank, c.monthly_pension_amount,
        c.monthly_pension_gross, c.atm_number, c.applicable_republic_act,
        c.unit_code, c.pcni_acct_code, c.dob, c.g_company, c.g_status,
        c.status, c.dmval_code, c.dmval_name, c.loan_type, c.created_by,
        c.deleted_by, c.touchpoint_summary, c.touchpoint_number, c.next_touchpoint
      FROM clients c
      WHERE c.deleted_at IS NULL
        AND c.municipality IN (
          SELECT ul.municipality FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )
        AND c.province IN (
          SELECT ul.province FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )

  # Client addresses - scoped to synced clients
  client_addresses:
    auto_subscribe: true
    query: |
      SELECT a.id, a.client_id, a.label, a.street, a.barangay, a.city,
        a.province, a.postal_code, a.latitude, a.longitude, a.is_primary,
        a.created_at, a.deleted_at, a.psgc_id, a.street_address, a.updated_at
      FROM addresses a
      JOIN clients c ON c.id = a.client_id
      WHERE a.deleted_at IS NULL
        AND c.deleted_at IS NULL
        AND c.municipality IN (
          SELECT ul.municipality FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )
        AND c.province IN (
          SELECT ul.province FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )

  # Phone numbers - scoped to synced clients
  phone_numbers:
    auto_subscribe: true
    query: |
      SELECT p.id, p.client_id, p.number, p.label, p.is_primary,
        p.created_at, p.deleted_at, p.updated_at
      FROM phone_numbers p
      JOIN clients c ON c.id = p.client_id
      WHERE p.deleted_at IS NULL
        AND c.deleted_at IS NULL
        AND c.municipality IN (
          SELECT ul.municipality FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )
        AND c.province IN (
          SELECT ul.province FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )

  # Visits - full history for synced clients
  visits:
    auto_subscribe: true
    query: |
      SELECT v.id, v.client_id, v.user_id, v.type, v.odometer_arrival,
        v.odometer_departure, v.photo_url, v.notes, v.reason, v.status,
        v.address, v.latitude, v.longitude, v.created_at, v.updated_at,
        v.time_arrival, v.time_departure, v.time_in, v.time_out, v.source
      FROM visits v
      JOIN clients c ON c.id = v.client_id
      WHERE c.deleted_at IS NULL
        AND c.municipality IN (
          SELECT ul.municipality FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )
        AND c.province IN (
          SELECT ul.province FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )

  # Calls - full history for synced clients
  calls:
    auto_subscribe: true
    query: |
      SELECT ca.id, ca.client_id, ca.user_id, ca.phone_number, ca.dial_time,
        ca.duration, ca.notes, ca.reason, ca.status, ca.created_at, ca.updated_at,
        ca.type, ca.photo_url, ca.source
      FROM calls ca
      JOIN clients c ON c.id = ca.client_id
      WHERE c.deleted_at IS NULL
        AND c.municipality IN (
          SELECT ul.municipality FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )
        AND c.province IN (
          SELECT ul.province FROM user_locations ul
          WHERE ul.user_id = auth.user_id() AND ul.deleted_at IS NULL
        )

  # ============================================================
  # AGENT-SPECIFIC DATA
  # ============================================================

  # Itineraries - agent's own schedule only
  itineraries:
    auto_subscribe: true
    query: |
      SELECT id, user_id, client_id, scheduled_date, scheduled_time,
        status, priority, notes, created_by, created_at, updated_at
      FROM itineraries
      WHERE user_id = auth.user_id()

  # Groups - groups where agent is the caravan
  groups:
    auto_subscribe: true
    query: |
      SELECT id, name, description, area_manager_id, assistant_area_manager_id,
        caravan_id, created_at
      FROM groups
      WHERE caravan_id = auth.user_id()

  # Targets - agent's own targets only
  targets:
    auto_subscribe: true
    query: |
      SELECT id, user_id, period, year, month, quarter, week,
        target_clients, target_touchpoints, target_visits, target_calls,
        created_at, updated_at, created_by
      FROM targets
      WHERE user_id = auth.user_id()

  # Attendance - agent's own attendance records only
  attendance:
    auto_subscribe: true
    query: |
      SELECT id, user_id, date, time_in, time_out,
        location_in_lat, location_in_lng, location_out_lat, location_out_lng,
        notes, created_at
      FROM attendance
      WHERE user_id = auth.user_id()
```

- [ ] **Step 2: Commit**

```bash
cd backend-imu
git add powersync-cli/powersync/sync-config.yaml
git commit -m "feat: scope clients to user territory, add visits/calls/groups/targets/attendance streams"
```

---

## Task 3: Update COMPLETE_SCHEMA.sql publication block

**Files:**
- Modify: `backend-imu/migrations/COMPLETE_SCHEMA.sql` (lines 1283–1310)

- [ ] **Step 1: Replace the publication block**

Find this block (around line 1283):
```sql
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR TABLE
    -- Core data tables
    clients,
    itineraries,
    touchpoints,
    visits,      -- NEW
    calls,       -- NEW
    releases,    -- NEW

    -- Related data tables
    addresses,
    phone_numbers,

    -- User profile table (for PowerSync sync metadata)
    user_profiles,

    -- User location assignments (for municipality-based filtering)
    user_locations,

    -- Approvals (for caravan/tele approval workflow)
    approvals,

    -- PSGC geographic data (for location picker)
    psgc,

    -- Touchpoint reasons (global data for touchpoint form dropdowns)
    touchpoint_reasons;
```

Replace with:
```sql
DROP PUBLICATION IF EXISTS powersync;
CREATE PUBLICATION powersync FOR TABLE
    -- Core client data
    clients,
    addresses,
    phone_numbers,

    -- Activity data
    visits,
    calls,
    itineraries,
    touchpoints,
    releases,

    -- Agent-specific data
    groups,
    targets,
    attendance,

    -- User data
    user_profiles,
    user_locations,

    -- Legacy (kept for backward compatibility during migration)
    approvals,
    psgc,
    touchpoint_reasons;
```

- [ ] **Step 2: Commit**

```bash
cd backend-imu
git add migrations/COMPLETE_SCHEMA.sql
git commit -m "docs: update COMPLETE_SCHEMA publication block to include groups, targets, attendance"
```

---

## Task 4: Update schema.sql — fix group_members FK + add missing columns

`src/schema.sql` is a quick-start reference schema. It does not have visits or calls (those are in migrations). Update it to match the actual DB state.

**Files:**
- Modify: `backend-imu/src/schema.sql` (lines ~178–193 for groups/group_members, lines ~164–175 for targets)

- [ ] **Step 1: Fix group_members FK in schema.sql**

Find this block (around line 186):
```sql
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, client_id)
);
```

Replace with:
```sql
CREATE TABLE IF NOT EXISTS group_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    client_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, client_id)
);
```

- [ ] **Step 2: Fix groups table — add missing manager columns**

Find the groups table (around line 178):
```sql
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    caravan_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Replace with:
```sql
CREATE TABLE IF NOT EXISTS groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    area_manager_id UUID REFERENCES users(id),
    assistant_area_manager_id UUID REFERENCES users(id),
    caravan_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

- [ ] **Step 3: Fix targets table — add missing columns**

Find the targets table (around line 164):
```sql
CREATE TABLE IF NOT EXISTS targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    period TEXT NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER,
    week INTEGER,
    target_clients INTEGER DEFAULT 0,
    target_touchpoints INTEGER DEFAULT 0,
    target_visits INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Replace with:
```sql
CREATE TABLE IF NOT EXISTS targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    period TEXT NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER,
    quarter INTEGER,
    week INTEGER,
    target_clients INTEGER DEFAULT 0,
    target_touchpoints INTEGER DEFAULT 0,
    target_visits INTEGER DEFAULT 0,
    target_calls INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID
);
```

- [ ] **Step 4: Commit**

```bash
cd backend-imu
git add src/schema.sql
git commit -m "fix: sync schema.sql with actual DB — group_members FK, groups manager cols, targets columns"
```

---

## Task 5: Add new tables to Flutter PowerSync schema

**Files:**
- Modify: `frontend-mobile-imu/imu_flutter/lib/services/sync/powersync_service.dart` (lines 12–172)

- [ ] **Step 1: Add visits, calls, groups, targets, attendance tables to `_powerSyncSchema`**

In `powersync_service.dart`, find `const Schema _powerSyncSchema = Schema([` and add these tables **after** the existing `user_locations` table (before `approvals`):

```dart
  Table('visits', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('type'),
    Column.text('odometer_arrival'),
    Column.text('odometer_departure'),
    Column.text('photo_url'),
    Column.text('notes'),
    Column.text('reason'),
    Column.text('status'),
    Column.text('address'),
    Column.real('latitude'),
    Column.real('longitude'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('time_arrival'),
    Column.text('time_departure'),
    Column.text('time_in'),
    Column.text('time_out'),
    Column.text('source'),
  ]),
  Table('calls', [
    Column.text('client_id'),
    Column.text('user_id'),
    Column.text('phone_number'),
    Column.text('dial_time'),
    Column.integer('duration'),
    Column.text('notes'),
    Column.text('reason'),
    Column.text('status'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('type'),
    Column.text('photo_url'),
    Column.text('source'),
  ]),
  Table('groups', [
    Column.text('name'),
    Column.text('description'),
    Column.text('area_manager_id'),
    Column.text('assistant_area_manager_id'),
    Column.text('caravan_id'),
    Column.text('created_at'),
  ]),
  Table('targets', [
    Column.text('user_id'),
    Column.text('period'),
    Column.integer('year'),
    Column.integer('month'),
    Column.integer('quarter'),
    Column.integer('week'),
    Column.integer('target_clients'),
    Column.integer('target_touchpoints'),
    Column.integer('target_visits'),
    Column.integer('target_calls'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('created_by'),
  ]),
  Table('attendance', [
    Column.text('user_id'),
    Column.text('date'),
    Column.text('time_in'),
    Column.text('time_out'),
    Column.real('location_in_lat'),
    Column.real('location_in_lng'),
    Column.real('location_out_lat'),
    Column.real('location_out_lng'),
    Column.text('notes'),
    Column.text('created_at'),
  ]),
```

- [ ] **Step 2: Verify the app compiles**

```bash
cd frontend-mobile-imu/imu_flutter
flutter analyze lib/services/sync/powersync_service.dart
```

Expected: No errors.

- [ ] **Step 3: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/services/sync/powersync_service.dart
git commit -m "feat: add visits, calls, groups, targets, attendance to PowerSync local schema"
```

---

## Task 6: Deploy sync-config to PowerSync service

The sync-config.yaml must be deployed to the PowerSync service for the new rules to take effect.

- [ ] **Step 1: Deploy using PowerSync CLI**

```bash
cd backend-imu/powersync-cli
npx powersync-cli deploy --config powersync/sync-config.yaml
```

If the CLI requires authentication, check `backend-imu/.env` for `POWERSYNC_URL` and follow the PowerSync dashboard deployment steps.

- [ ] **Step 2: Verify in PowerSync dashboard**

Log into the PowerSync dashboard and confirm:
- `clients` stream now shows the `user_locations` WHERE filter
- `visits`, `calls`, `groups`, `targets`, `attendance` streams appear

---

## Verification

After all tasks are complete, verify end-to-end:

- [ ] Log into the mobile app on a test device
- [ ] Go to Settings → scroll to PowerSync debug info — confirm sync status shows "Connected"
- [ ] Check that client list shows only clients from the agent's assigned municipality
- [ ] Open a client detail — visit history and call history should load (from local SQLite, no network request)
- [ ] Check My Day / Itinerary screen loads offline (airplane mode)
- [ ] Confirm no errors in Flutter debug console related to missing PowerSync tables
