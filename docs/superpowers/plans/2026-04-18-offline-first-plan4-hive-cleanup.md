# Offline-First Plan 4: Hive Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all Hive data-box usage from feature pages and strip `HiveService` down to settings-only, leaving PowerSync SQLite as the sole local data store.

**Architecture:** Plans 1–3 established PowerSync as the write+read layer. This plan removes the last remaining Hive reads in UI pages. Each page that calls `hiveService.getClient()`, `hiveService.getGroup()`, etc. is updated to call the corresponding PowerSync repository instead. `HiveService` is then trimmed to only its `settings` box. `psgc` and `touchpoint_reasons` tables are removed from the PowerSync schema (they are unused — PSGC still lives in its own table and TouchpointReason is a Dart enum).

**Tech Stack:** Flutter/Dart, Riverpod, PowerSync, `ClientRepository`, `AttendanceRepository`, `GroupRepository`

---

### Task 1: Remove `psgc` and `touchpoint_reasons` tables from PowerSync schema

**Files:**
- Modify: `imu_flutter/lib/services/sync/powersync_service.dart:220-241`

The `psgc` and `touchpoint_reasons` tables are never used by any read path after Plan 2. Removing them from the schema stops PowerSync from syncing them and frees storage.

- [ ] **Step 1: Remove both table definitions**

In `powersync_service.dart`, delete the two Table blocks. Find:

```dart
  // PSGC geographic data (single table with all locations)
  // Note: PowerSync automatically adds an 'id' column, so we don't define it here
  Table('psgc', [
    Column.text('region'),
    Column.text('province'),
    Column.text('mun_city_kind'),
    Column.text('mun_city'),
    Column.text('barangay'),
    Column.text('pin_location'),
    Column.text('zip_code'),
  ]),
  // Touchpoint reasons (global data)
  // Note: PowerSync automatically adds an 'id' column, so we don't define it here
  Table('touchpoint_reasons', [
    Column.text('reason_code'),
    Column.text('label'),
    Column.text('touchpoint_type'),
    Column.text('role'),
    Column.text('category'),
    Column.integer('sort_order'),
    Column.integer('is_active'),
  ]),
```

Replace with: *(delete both blocks entirely — nothing replaces them)*

- [ ] **Step 2: Verify schema compiles**

```bash
cd imu_flutter && flutter analyze lib/services/sync/powersync_service.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/services/sync/powersync_service.dart
git commit -m "feat: remove psgc and touchpoint_reasons from PowerSync schema"
```

---

### Task 2: Fix `sync_loading_page.dart` — remove dead table names and fix local-data check

**Files:**
- Modify: `imu_flutter/lib/features/sync/presentation/pages/sync_loading_page.dart:91-99,183-214`

The table map shows `psgc` and `touchpoint_reasons` which no longer sync. The `_checkForLocalData()` method opens a Hive `clients` box — clients now live in PowerSync SQLite.

- [ ] **Step 1: Remove `psgc` and `touchpoint_reasons` from `_tableDisplayNames`**

Find:

```dart
const Map<String, String> _tableDisplayNames = {
  'psgc': 'PSGC (Locations)',
  'touchpoint_reasons': 'Touchpoint Reasons',
  'user_locations': 'User Locations',
  'itineraries': 'Itineraries',
  'approvals': 'Approvals',
  // NOTE: Clients and touchpoints removed from PowerSync sync
  // Clients are synced via REST API (/clients/assigned) and stored in Hive cache
  // Touchpoint data is available via clients.touchpoint_summary (denormalized JSON array)
};
```

Replace with:

```dart
const Map<String, String> _tableDisplayNames = {
  'clients': 'Clients',
  'user_locations': 'User Locations',
  'itineraries': 'Itineraries',
  'approvals': 'Approvals',
};
```

- [ ] **Step 2: Rewrite `_checkForLocalData()` to use PowerSync**

Find the entire `_checkForLocalData()` method body (inside the try block):

```dart
      logDebug('[LOCAL-DATA-CHECK] Checking for local data in Hive storage...');

      // NOTE: PowerSync clients table removed - clients are now synced via REST API
      // Check Hive storage for clients (REST API sync)
      int hiveClientCount = 0;
      try {
        await Hive.initFlutter();
        final clientsBox = await Hive.openBox<String>('clients');
        hiveClientCount = clientsBox.length;
        logDebug('[LOCAL-DATA-CHECK] Hive clients: $hiveClientCount');
      } catch (e) {
        logWarning('[LOCAL-DATA-CHECK] Failed to check Hive storage: $e');
      }

      final hasData = hiveClientCount > 0;
```

Replace with:

```dart
      logDebug('[LOCAL-DATA-CHECK] Checking for local data in PowerSync SQLite...');

      int clientCount = 0;
      try {
        final result = await _powerSyncDb.getAll('SELECT COUNT(*) as cnt FROM clients');
        clientCount = (result.first['cnt'] as int?) ?? 0;
        logDebug('[LOCAL-DATA-CHECK] PowerSync clients: $clientCount');
      } catch (e) {
        logWarning('[LOCAL-DATA-CHECK] Failed to check PowerSync storage: $e');
      }

      final hasData = clientCount > 0;
```

- [ ] **Step 3: Remove Hive import from `sync_loading_page.dart`**

Find:

```dart
import 'package:hive_flutter/hive_flutter.dart';
```

Delete that line.

Also remove the `HiveService` import:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 4: Verify**

```bash
cd imu_flutter && flutter analyze lib/features/sync/presentation/pages/sync_loading_page.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add imu_flutter/lib/features/sync/presentation/pages/sync_loading_page.dart
git commit -m "feat: remove Hive from sync_loading_page; use PowerSync for local-data check"
```

---

### Task 3: Fix `attendanceHistoryProvider` — replace Hive box reads with `AttendanceRepository`

**Files:**
- Modify: `imu_flutter/lib/shared/providers/app_providers.dart:947-985`

`attendanceHistoryProvider` currently opens a Hive `attendance` box. Attendance is now in PowerSync SQLite. `AttendanceRepository.getHistory()` already exists and reads from the `attendance` table.

- [ ] **Step 1: Rewrite `attendanceHistoryProvider`**

Find:

```dart
/// Attendance records box name
const _attendanceBox = 'attendance';

/// Today's attendance record
final todayAttendanceProvider = StateNotifierProvider<TodayAttendanceNotifier, AttendanceRecord?>((ref) {
  return TodayAttendanceNotifier(ref);
});
```

Replace with:

```dart
/// Today's attendance record
final todayAttendanceProvider = StateNotifierProvider<TodayAttendanceNotifier, AttendanceRecord?>((ref) {
  return TodayAttendanceNotifier(ref);
});
```

(removes the unused `_attendanceBox` constant)

- [ ] **Step 2: Rewrite `attendanceHistoryProvider` body**

Find:

```dart
/// Attendance history (last 14 days)
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);
  if (!hiveService.isInitialized) await hiveService.init();

  final records = <AttendanceRecord>[];
  final box = Hive.box<String>(_attendanceBox);

  final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

  for (final key in box.keys) {
    final data = box.get(key);
    if (data != null) {
      final record = AttendanceRecord.fromJson(
        Map<String, dynamic>.from(const JsonDecoder().convert(data)),
      );
      if (record.date.isAfter(twoWeeksAgo)) {
        records.add(record);
      }
    }
  }

  records.sort((a, b) => b.date.compareTo(a.date));
  return records;
});
```

Replace with:

```dart
/// Attendance history (last 30 days)
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return [];
  return repo.getHistory(userId, limit: 30);
});
```

- [ ] **Step 3: Verify `app_providers.dart` imports include `attendanceRepositoryProvider`**

Check that `app_providers.dart` already exports or imports `attendanceRepositoryProvider`. Run:

```bash
grep -n "attendanceRepository" imu_flutter/lib/shared/providers/app_providers.dart
```

If not present, add the import near the other attendance-related imports:

```dart
import '../features/attendance/data/repositories/attendance_repository.dart';
```

- [ ] **Step 4: Check for stale `Hive.box` call**

```bash
grep -n "Hive\.box.*attendance\|_attendanceBox" imu_flutter/lib/shared/providers/app_providers.dart
```

Expected: no matches.

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/shared/providers/app_providers.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/shared/providers/app_providers.dart
git commit -m "feat: replace Hive attendance history with AttendanceRepository"
```

---

### Task 4: Fix `group_detail_page.dart` — remove Hive fallback

**Files:**
- Modify: `imu_flutter/lib/features/groups/presentation/pages/group_detail_page.dart`

The `groupDetailProvider` tries PowerSync first, then falls back to Hive. The Hive fallback is legacy — if the group isn't in PowerSync SQLite, it isn't cached anywhere meaningful. Remove the fallback.

- [ ] **Step 1: Rewrite `groupDetailProvider` — remove Hive fallback**

Find:

```dart
/// Group detail provider — reads from local PowerSync SQLite with Hive fallback.
final groupDetailProvider = FutureProvider.family<ClientGroup?, String>((ref, groupId) async {
  // Try PowerSync first (works offline after initial sync)
  final repo = ref.read(groupRepositoryProvider);
  final group = await repo.getById(groupId);
  if (group != null) return group;

  // Fall back to Hive cache (pre-PowerSync legacy)
  final hiveService = HiveService();
  if (!hiveService.isInitialized) await hiveService.init();
  final localGroup = await hiveService.getGroup(groupId);
  if (localGroup != null) return ClientGroup.fromJson(localGroup);
  return null;
});
```

Replace with:

```dart
final groupDetailProvider = FutureProvider.family<ClientGroup?, String>((ref, groupId) async {
  final repo = ref.read(groupRepositoryProvider);
  return repo.getById(groupId);
});
```

- [ ] **Step 2: Rewrite `_loadGroup()` in `_GroupDetailPageState` — remove Hive fallback**

Find the full `_loadGroup()` method body inside `LoadingHelper.withLoading`:

```dart
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        // Try PowerSync first
        final repo = ref.read(groupRepositoryProvider);
        final group = await repo.getById(widget.groupId);
        if (group != null && mounted) {
          setState(() {
            _group = group;
            _members = _loadMembers();
            _isLoading = false;
          });
          return;
        }

        // Fall back to Hive cache
        final groupData = await _hiveService.getGroup(widget.groupId);
        if (groupData != null && mounted) {
          setState(() {
            _group = ClientGroup.fromJson(groupData);
            _members = _loadMembers();
```

Replace with:

```dart
        final repo = ref.read(groupRepositoryProvider);
        final group = await repo.getById(widget.groupId);
        if (group != null && mounted) {
          setState(() {
            _group = group;
            _members = _loadMembers();
            _isLoading = false;
          });
          return;
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
```

- [ ] **Step 3: Remove the `_hiveService` field declaration**

Find:

```dart
  final _hiveService = HiveService();
```

Delete that line.

- [ ] **Step 4: Remove the Hive import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/groups/presentation/pages/group_detail_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/groups/presentation/pages/group_detail_page.dart
git commit -m "feat: remove Hive fallback from group_detail_page"
```

---

### Task 5: Fix `client_detail_page.dart` — replace Hive reads with PowerSync

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart:42-94`

Two providers (`clientDetailProvider`, `clientTouchpointsProvider`) fall back to Hive when offline or on API error. Replace with `ClientRepository`.

- [ ] **Step 1: Rewrite `clientDetailProvider`**

Find:

```dart
// Client detail provider
final clientDetailProvider = FutureProvider.family<Client?, String>((ref, clientId) async {
  final clientApi = ref.watch(clientApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await clientApi.fetchClient(clientId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localClient = hiveService.getClient(clientId);
      if (localClient != null) {
        return Client.fromJson(localClient);
      }
      return null;
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localClient = hiveService.getClient(clientId);
    if (localClient != null) {
      return Client.fromJson(localClient);
    }
    return null;
  }
});
```

Replace with:

```dart
final clientDetailProvider = FutureProvider.family<Client?, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  return clientRepo.getClient(clientId);
});
```

- [ ] **Step 2: Rewrite `clientTouchpointsProvider`**

Find:

```dart
// Touchpoints for client provider
final clientTouchpointsProvider = FutureProvider.family<List<Touchpoint>, String>((ref, clientId) async {
  final touchpointApi = ref.watch(touchpointApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await touchpointApi.fetchTouchpoints(clientId: clientId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localTouchpoints = hiveService.getTouchpointsForClient(clientId);
      return localTouchpoints.map((data) => Touchpoint.fromJson(data)).toList();
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localTouchpoints = hiveService.getTouchpointsForClient(clientId);
    return localTouchpoints.map((data) => Touchpoint.fromJson(data)).toList();
  }
});
```

Replace with:

```dart
final clientTouchpointsProvider = FutureProvider.family<List<Touchpoint>, String>((ref, clientId) async {
  final clientRepo = ref.watch(clientRepositoryProvider);
  final client = await clientRepo.getClient(clientId);
  return client?.touchpointSummary ?? [];
});
```

- [ ] **Step 3: Remove `HiveService` import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 4: Add `clientRepositoryProvider` import if missing**

Check:

```bash
grep -n "clientRepositoryProvider" imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart
```

If not found, add to the imports:

```dart
import '../../data/repositories/client_repository.dart' show clientRepositoryProvider;
```

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/clients/presentation/pages/client_detail_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "feat: replace Hive client/touchpoint reads with PowerSync in client_detail_page"
```

---

### Task 6: Fix `edit_client_page.dart` — replace `_hiveService.getClient()` with `ClientRepository`

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart:105-130`

`_loadClient()` reads the client from Hive. Replace with `ClientRepository.getClient()`.

- [ ] **Step 1: Rewrite the client-load block inside `_loadClient()`**

Find:

```dart
      Client? client;
      final clientData = _hiveService.getClient(widget.clientId);
      if (clientData != null) {
        try {
          client = Client.fromRow(clientData);
        } catch (e) {
          debugPrint('[EditClientPage] fromRow failed, trying fromJson: $e');
          client = Client.fromJson(clientData);
        }
      }

      final isOnline = ref.read(isOnlineProvider);
      if (client == null && isOnline) {
        final clientApi = ref.read(clientApiServiceProvider);
```

Replace with:

```dart
      final clientRepo = ref.read(clientRepositoryProvider);
      Client? client = await clientRepo.getClient(widget.clientId);

      final isOnline = ref.read(isOnlineProvider);
      if (client == null && isOnline) {
        final clientApi = ref.read(clientApiServiceProvider);
```

- [ ] **Step 2: Remove `_hiveService` field**

Find:

```dart
  final _hiveService = HiveService();
```

Delete that line.

- [ ] **Step 3: Remove Hive import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 4: Add `clientRepositoryProvider` import if missing**

```bash
grep -n "clientRepositoryProvider" imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart
```

If not found, add:

```dart
import '../../data/repositories/client_repository.dart' show clientRepositoryProvider;
```

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/clients/presentation/pages/edit_client_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart
git commit -m "feat: replace Hive client read with ClientRepository in edit_client_page"
```

---

### Task 7: Fix `itinerary_page.dart` — replace `hiveService.getClient()` with `ClientRepository`

**Files:**
- Modify: `imu_flutter/lib/features/itinerary/presentation/pages/itinerary_page.dart:336-414`

Three methods (`_handleRecordTouchpoint`, `_handleRecordVisitOnly`, `_handleReleaseLoan`) call `hiveService.getClient()`. Replace with async `ClientRepository.getClient()`.

- [ ] **Step 1: Rewrite `_handleRecordTouchpoint`**

Find:

```dart
  Future<void> _handleRecordTouchpoint(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleRecordTouchpoint(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(visit.clientId);
    if (fullClient == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
```

- [ ] **Step 2: Rewrite `_handleRecordVisitOnly`**

Find:

```dart
  Future<void> _handleRecordVisitOnly(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleRecordVisitOnly(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(visit.clientId);
    if (fullClient == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
```

- [ ] **Step 3: Rewrite `_handleReleaseLoan`**

Find:

```dart
  Future<void> _handleReleaseLoan(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleReleaseLoan(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(visit.clientId);
    if (fullClient == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
```

- [ ] **Step 4: Remove `hiveServiceProvider` from imports and add `clientRepositoryProvider`**

Find in the import block:

```dart
import '../../../../shared/providers/app_providers.dart' show
    authNotifierProvider,
    hiveServiceProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
```

Replace with:

```dart
import '../../../../shared/providers/app_providers.dart' show
    authNotifierProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
import '../../../../features/clients/data/repositories/client_repository.dart' show clientRepositoryProvider;
```

- [ ] **Step 5: Remove Hive import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 6: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/itinerary/presentation/pages/itinerary_page.dart
```

Expected: no errors.

- [ ] **Step 7: Commit**

```bash
git add imu_flutter/lib/features/itinerary/presentation/pages/itinerary_page.dart
git commit -m "feat: replace Hive client reads with ClientRepository in itinerary_page"
```

---

### Task 8: Fix `my_day_page.dart` — replace `hiveService.getClient()` with `ClientRepository`

**Files:**
- Modify: `imu_flutter/lib/features/my_day/presentation/pages/my_day_page.dart:418-494`

Same pattern as `itinerary_page.dart` — three handler methods call `hiveService.getClient()`.

- [ ] **Step 1: Rewrite `_handleRecordTouchpoint`**

Find:

```dart
  Future<void> _handleRecordTouchpoint(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleRecordTouchpoint(MyDayClient client) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(client.clientId);
    if (fullClient == null) {
      if (mounted) showToast('Client not found');
      return;
    }
```

- [ ] **Step 2: Rewrite `_handleRecordVisitOnly`**

Find:

```dart
  Future<void> _handleRecordVisitOnly(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleRecordVisitOnly(MyDayClient client) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(client.clientId);
    if (fullClient == null) {
      if (mounted) showToast('Client not found');
      return;
    }
```

- [ ] **Step 3: Rewrite `_handleReleaseLoan`**

Find:

```dart
  Future<void> _handleReleaseLoan(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);
```

Replace with:

```dart
  Future<void> _handleReleaseLoan(MyDayClient client) async {
    HapticUtils.lightImpact();

    final clientRepo = ref.read(clientRepositoryProvider);
    final fullClient = await clientRepo.getClient(client.clientId);
    if (fullClient == null) {
      if (mounted) showToast('Client not found');
      return;
    }
```

- [ ] **Step 4: Remove `hiveServiceProvider` and `HiveService` imports, add `clientRepositoryProvider`**

Find:

```dart
import '../../../../shared/providers/app_providers.dart' show
    authNotifierProvider,
    hiveServiceProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
import '../../../../services/local_storage/hive_service.dart';
```

Replace with:

```dart
import '../../../../shared/providers/app_providers.dart' show
    authNotifierProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
import '../../../../features/clients/data/repositories/client_repository.dart' show clientRepositoryProvider;
```

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/my_day/presentation/pages/my_day_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/my_day/presentation/pages/my_day_page.dart
git commit -m "feat: replace Hive client reads with ClientRepository in my_day_page"
```

---

### Task 9: Fix `add_prospect_client_page.dart` — remove dead Hive write

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/add_prospect_client_page.dart`

After Plan 3, `ClientMutationService` handles all writes to SQLite. The `_hiveService.saveClient()` call in this page is dead code — it writes to a Hive box that nothing reads from anymore.

- [ ] **Step 1: Find the saveClient call and its surrounding context**

```bash
grep -n "saveClient\|_hiveService\|HiveService" imu_flutter/lib/features/clients/presentation/pages/add_prospect_client_page.dart
```

- [ ] **Step 2: Remove the `_hiveService.saveClient(clientId, clientData)` call**

The call is inside a block that builds a `clientData` map and then saves it. Find the block starting with:

```dart
          await _hiveService.saveClient(clientId, clientData);
```

Delete only that single `await _hiveService.saveClient(clientId, clientData);` line.

- [ ] **Step 3: Remove `_hiveService` field**

Find:

```dart
  final _hiveService = HiveService();
```

Delete that line.

- [ ] **Step 4: Remove Hive import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/clients/presentation/pages/add_prospect_client_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/add_prospect_client_page.dart
git commit -m "feat: remove dead Hive write from add_prospect_client_page"
```

---

### Task 10: Fix `agency_detail_page.dart` — remove Hive, use mock only

**Files:**
- Modify: `imu_flutter/lib/features/agencies/presentation/pages/agency_detail_page.dart`

Agencies are not in the PowerSync schema. The page currently reads from Hive, then falls back to a mock. Since the Hive agencies box is never populated (no write path exists post-Plan 3), remove Hive and go directly to mock.

- [ ] **Step 1: Rewrite `agencyDetailProvider`**

Find:

```dart
/// Agency detail provider
final agencyDetailProvider = FutureProvider.family<Agency?, String>((ref, agencyId) async {
  final hiveService = HiveService();
  if (!hiveService.isInitialized) await hiveService.init();

  // Try to get from local storage
  final agencyData = await hiveService.getAgency(agencyId);
  if (agencyData != null) {
    return Agency.fromJson(agencyData);
  }

  // Return mock data for demonstration
  return _getMockAgency(agencyId);
});
```

Replace with:

```dart
final agencyDetailProvider = FutureProvider.family<Agency?, String>((ref, agencyId) async {
  return _getMockAgency(agencyId);
});
```

- [ ] **Step 2: Rewrite `_loadAgency()` in `_AgencyDetailPageState`**

Find:

```dart
  Future<void> _loadAgency() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading agency...',
      operation: () async {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        final agencyData = await _hiveService.getAgency(widget.agencyId);
        if (agencyData != null && mounted) {
          setState(() {
            _agency = Agency.fromJson(agencyData);
            _isLoading = false;
          });
        } else {
```

Replace with:

```dart
  Future<void> _loadAgency() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading agency...',
      operation: () async {
        final agency = _getMockAgency(widget.agencyId);
        if (mounted) {
          setState(() {
            _agency = agency;
            _isLoading = false;
          });
        }
```

Check if there's a closing `}` block after the else that needs updating too. Read the rest of `_loadAgency`:

```bash
grep -n -A 20 "_loadAgency" imu_flutter/lib/features/agencies/presentation/pages/agency_detail_page.dart | head -40
```

Make sure the method closes cleanly after the setState block.

- [ ] **Step 3: Remove `_hiveService` field**

Find:

```dart
  final _hiveService = HiveService();
```

Delete that line.

- [ ] **Step 4: Remove Hive import**

Find:

```dart
import '../../../../services/local_storage/hive_service.dart';
```

Delete that line.

- [ ] **Step 5: Analyze**

```bash
cd imu_flutter && flutter analyze lib/features/agencies/presentation/pages/agency_detail_page.dart
```

Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/features/agencies/presentation/pages/agency_detail_page.dart
git commit -m "feat: remove Hive from agency_detail_page; use mock data directly"
```

---

### Task 11: Strip `HiveService` to settings-only

**Files:**
- Modify: `imu_flutter/lib/services/local_storage/hive_service.dart`

At this point all Hive data-box call sites have been removed. Strip everything except the `settings` box (and the `init()` + `isInitialized` plumbing).

- [ ] **Step 1: Verify no remaining usages of data methods**

```bash
grep -rn "hiveService\.\(getClient\|saveClient\|addClient\|updateClient\|deleteClient\|getAllClients\|searchClients\|filterClients\|getTouchpoints\|saveTouchpoint\|addTouchpoint\|updateTouchpoint\|deleteTouchpoint\|getGroup\|saveGroup\|addGroup\|updateGroup\|deleteGroup\|getAgency\|saveAgency\|addAgency\|updateAgency\|deleteAgency\|getItinerary\|saveItinerary\|addItinerary\|updateItinerary\|deleteItinerary\|addToPendingSync\|getPendingSync\|removeFromPendingSync\|clearPendingSync\|getPendingSyncCount\|cacheData\|getCachedData\|clearCache\|getCacheSize\|clearAllData\)" imu_flutter/lib/
```

Expected: zero matches. Fix any that remain before continuing.

- [ ] **Step 2: Rewrite `HiveService` to settings-only**

Replace the entire file content of `imu_flutter/lib/services/local_storage/hive_service.dart` with:

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  static const String _settingsBox = 'settings';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    await Hive.openBox<String>(_settingsBox);
    _isInitialized = true;
    debugPrint('HiveService initialized');
  }

  bool get isInitialized => _isInitialized;

  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box<String>(_settingsBox);
    await box.put(key, jsonEncode({'value': value}));
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = Hive.box<String>(_settingsBox);
    final data = box.get(key);
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return decoded['value'] as T?;
    }
    return defaultValue;
  }
}

/// Sync status enum — kept for compatibility with existing UI references
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}
```

Note: `SyncResult` class is also defined in `background_sync_service.dart`. If it was only in `hive_service.dart`, any references to `hive_service.SyncResult` need to be updated to use the one from `background_sync_service.dart`. Check first:

```bash
grep -rn "hive_service.*SyncResult\|SyncResult.*hive" imu_flutter/lib/
```

If matches found, update those imports.

- [ ] **Step 3: Verify `HiveService` usages that remain are settings-only**

```bash
grep -rn "HiveService\|hiveService" imu_flutter/lib/ | grep -v "saveSetting\|getSetting\|isInitialized\|init()\|hiveServiceProvider\|import.*hive_service"
```

Expected: only provider declarations and `init()` / `isInitialized` calls.

- [ ] **Step 4: Analyze**

```bash
cd imu_flutter && flutter analyze lib/services/local_storage/hive_service.dart
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add imu_flutter/lib/services/local_storage/hive_service.dart
git commit -m "feat: strip HiveService to settings-only; remove all data box methods"
```

---

### Task 12: Final analysis and cleanup

**Files:**
- Check all modified files compile together

- [ ] **Step 1: Run full analysis**

```bash
cd imu_flutter && flutter analyze lib/
```

Fix any errors that appear. Common fixes:
- Missing imports: add the correct repository import
- `Client.fromJson` calls on non-nullable `Client?`: add a null check
- Remaining `_attendanceBox` references: remove them

- [ ] **Step 2: Check for any remaining Hive data-box opens in `main.dart` or app startup**

```bash
grep -rn "Hive\.openBox.*clients\|Hive\.openBox.*touchpoints\|Hive\.openBox.*attendance\|Hive\.openBox.*agencies\|Hive\.openBox.*groups\|Hive\.openBox.*itineraries\|Hive\.openBox.*pending_sync\|Hive\.openBox.*cache" imu_flutter/lib/
```

Expected: zero matches. The only Hive box opened should be `settings` (inside `HiveService.init()`).

- [ ] **Step 3: Verify `hive_flutter` package is still needed (for settings)**

```bash
grep -rn "hive_flutter\|hive/hive" imu_flutter/pubspec.yaml imu_flutter/lib/
```

Expected: still referenced by `hive_service.dart` and `pubspec.yaml`. Do NOT remove the dependency — settings still use it.

- [ ] **Step 4: Final commit**

```bash
git add -u
git commit -m "feat: complete Hive cleanup — all data reads now use PowerSync SQLite"
```
