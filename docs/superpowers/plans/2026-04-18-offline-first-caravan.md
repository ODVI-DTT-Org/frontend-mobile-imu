# Offline-First Caravan Mobile — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make My Day, Itinerary, Record Visit, and Record Loan Release work offline for the Caravan role — data saves locally first and auto-syncs when connectivity is restored.

**Architecture:** Itinerary/My Day reads and writes go through PowerSync local SQLite (already synced); Record Visit and Loan Release use a new Hive pending queue pattern that mirrors the existing touchpoint offline flow; a connectivity listener triggers `BackgroundSyncService.performSync()` when the device goes back online.

**Tech Stack:** Flutter, Riverpod 2.0, PowerSync, Hive, connectivity_plus, dart:convert

**Spec:** `docs/superpowers/specs/2026-04-18-offline-first-caravan-design.md`

---

## File Map

**Modified:**
- `lib/features/itineraries/data/repositories/itinerary_repository.dart` — fix SQL column `caravan_id` → `user_id`
- `lib/features/my_day/data/models/my_day_client.dart` — add `fromPowerSync` factory
- `lib/features/my_day/presentation/providers/my_day_provider.dart` — replace API call with PowerSync `db.watch()` stream
- `lib/features/itineraries/presentation/pages/itinerary_page.dart` — switch to `itineraryRepositoryProvider` stream
- `lib/features/itineraries/presentation/pages/itinerary_detail_page.dart` — replace HiveService lookup with PowerSync query
- `lib/shared/widgets/client_selector_modal.dart` — route create through `itineraryRepository`
- `lib/services/connectivity_service.dart` — trigger `performSync()` on online transition
- `lib/services/api/background_sync_service.dart` — add `_syncPendingVisits()` and `_syncPendingReleases()`
- `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart` — use `VisitCreationService`
- `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart` — use `ReleaseCreationService`
- `lib/shared/providers/app_providers.dart` — register new service providers
- `lib/features/my_day/presentation/pages/my_day_page.dart` — add `OfflineBanner`
- `lib/features/itineraries/presentation/pages/itinerary_page.dart` — add `OfflineBanner`

**New:**
- `lib/services/visit/models/pending_visit.dart` — pending visit data model
- `lib/services/visit/pending_visit_service.dart` — Hive queue for offline visits
- `lib/services/visit/visit_creation_service.dart` — online/offline routing for visit creation
- `lib/services/release/models/pending_release.dart` — pending release data model
- `lib/services/release/pending_release_service.dart` — Hive queue for offline releases
- `lib/services/release/release_creation_service.dart` — online/offline routing for release creation
- `lib/shared/widgets/offline_banner.dart` — reusable offline indicator widget

**Tests:**
- `test/services/visit/pending_visit_service_test.dart`
- `test/services/visit/visit_creation_service_test.dart`
- `test/services/release/pending_release_service_test.dart`
- `test/services/release/release_creation_service_test.dart`
- `test/features/my_day/my_day_client_test.dart`
- `test/widgets/offline_banner_test.dart`

---

## Task 1: Fix itinerary_repository.dart SQL column name

The PowerSync `itineraries` table uses `user_id` but the repository INSERT/UPDATE uses `caravan_id`. Fix the SQL to match the schema.

**Files:**
- Modify: `lib/features/itineraries/data/repositories/itinerary_repository.dart`

- [ ] **Step 1: Open the repository and find the SQL**

Read `lib/features/itineraries/data/repositories/itinerary_repository.dart`.
Find the `createItinerary()` method INSERT statement and the `updateItinerary()` UPDATE statement. Both use `caravan_id`.

- [ ] **Step 2: Fix createItinerary SQL**

In `createItinerary()`, change:
```dart
// Before:
await db.execute(
  '''INSERT INTO itineraries (
    id, caravan_id, client_id, scheduled_date, scheduled_date_time,
    status, priority, notes
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
  [id, itinerary.caravanId, itinerary.clientId, ...],
);

// After — only change the column name, keep the value source:
await db.execute(
  '''INSERT INTO itineraries (
    id, user_id, client_id, scheduled_date, scheduled_time,
    status, priority, notes
  ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
  [id, itinerary.caravanId ?? '', itinerary.clientId ?? '', ...],
);
```

Note: `scheduled_date_time` may not exist in the PowerSync schema — check and use `scheduled_time` if so.

- [ ] **Step 3: Fix updateItinerary SQL**

Find `updateItinerary()` and change any `caravan_id = ?` to `user_id = ?` while keeping `itinerary.caravanId` as the value.

- [ ] **Step 4: Run Flutter analyze**

```bash
cd /home/claude-team/loi/imu3/frontend-mobile-imu/imu_flutter
flutter analyze lib/features/itineraries/data/repositories/itinerary_repository.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/itineraries/data/repositories/itinerary_repository.dart
git commit -m "fix: align itinerary_repository SQL column caravan_id → user_id"
```

---

## Task 2: Add MyDayClient.fromPowerSync factory

My Day will query PowerSync locally. The result rows need to map to `MyDayClient`. Add a `fromPowerSync` factory that parses the `touchpoint_summary` JSON from the `clients` table.

**Files:**
- Modify: `lib/features/my_day/data/models/my_day_client.dart`
- Test: `test/features/my_day/my_day_client_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/my_day/my_day_client_test.dart`:

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';

void main() {
  group('MyDayClient.fromPowerSync', () {
    test('maps basic row fields correctly', () {
      final row = {
        'id': 'itin-1',
        'client_id': 'client-1',
        'first_name': 'Juan',
        'last_name': 'Dela Cruz',
        'client_type': 'EXISTING',
        'scheduled_date': '2026-04-18',
        'scheduled_time': '09:00',
        'status': 'pending',
        'priority': 'high',
        'notes': 'Bring forms',
        'touchpoint_summary': null,
      };
      final client = MyDayClient.fromPowerSync(row);
      expect(client.id, equals('itin-1'));
      expect(client.clientId, equals('client-1'));
      expect(client.fullName, equals('Juan Dela Cruz'));
      expect(client.scheduledTime, equals('09:00'));
      expect(client.status, equals('pending'));
      expect(client.priority, equals('high'));
      expect(client.notes, equals('Bring forms'));
      expect(client.touchpointNumber, equals(1));
      expect(client.touchpointType, equals('visit'));
      expect(client.nextTouchpointNumber, equals(1));
      expect(client.nextTouchpointType, equals('Visit'));
    });

    test('computes next touchpoint from touchpoint_summary', () {
      final summary = jsonEncode([
        {'touchpoint_number': 1, 'type': 'Visit', 'reason': 'Initial', 'status': 'completed', 'date': '2026-04-01'},
        {'touchpoint_number': 2, 'type': 'Call', 'reason': 'Follow-up', 'status': 'completed', 'date': '2026-04-05'},
      ]);
      final row = {
        'id': 'itin-2',
        'client_id': 'client-2',
        'first_name': 'Maria',
        'last_name': 'Santos',
        'client_type': 'POTENTIAL',
        'scheduled_date': '2026-04-18',
        'scheduled_time': null,
        'status': 'pending',
        'priority': 'normal',
        'notes': null,
        'touchpoint_summary': summary,
      };
      final client = MyDayClient.fromPowerSync(row);
      expect(client.touchpointNumber, equals(3));
      expect(client.touchpointType, equals('call'));
      expect(client.nextTouchpointNumber, equals(3));
      expect(client.nextTouchpointType, equals('Call'));
      expect(client.previousTouchpointNumber, equals(2));
      expect(client.previousTouchpointType, equals('Call'));
    });

    test('returns null next touchpoint when all 7 are complete', () {
      final summary = jsonEncode(List.generate(7, (i) => {
        'touchpoint_number': i + 1,
        'type': i % 3 == 0 ? 'Visit' : 'Call',
        'reason': 'Done',
        'status': 'completed',
        'date': '2026-04-01',
      }));
      final row = {
        'id': 'itin-3',
        'client_id': 'client-3',
        'first_name': 'Pedro',
        'last_name': 'Reyes',
        'client_type': 'EXISTING',
        'scheduled_date': '2026-04-18',
        'scheduled_time': null,
        'status': 'completed',
        'priority': 'normal',
        'notes': null,
        'touchpoint_summary': summary,
      };
      final client = MyDayClient.fromPowerSync(row);
      expect(client.nextTouchpointNumber, isNull);
      expect(client.nextTouchpointType, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /home/claude-team/loi/imu3/frontend-mobile-imu/imu_flutter
flutter test test/features/my_day/my_day_client_test.dart
```
Expected: FAIL — `fromPowerSync` not defined.

- [ ] **Step 3: Add fromPowerSync factory to MyDayClient**

In `lib/features/my_day/data/models/my_day_client.dart`, add after the existing `fromJson` factory:

```dart
static const List<String> _sequence = [
  'Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'
];

factory MyDayClient.fromPowerSync(Map<String, dynamic> row) {
  // Parse touchpoint_summary JSON
  final summaryJson = row['touchpoint_summary'] as String?;
  List<Map<String, dynamic>> touchpoints = [];
  if (summaryJson != null && summaryJson.isNotEmpty && summaryJson != 'null') {
    final decoded = jsonDecode(summaryJson);
    if (decoded is List) {
      touchpoints = decoded.whereType<Map<String, dynamic>>().toList();
    }
  }

  // Find completed touchpoint numbers
  final completedNumbers = touchpoints
      .map((t) => (t['touchpoint_number'] as num?)?.toInt() ?? 0)
      .where((n) => n > 0)
      .toSet();

  // Find next touchpoint number (lowest 1-7 not yet completed)
  int? nextNum;
  for (int i = 1; i <= 7; i++) {
    if (!completedNumbers.contains(i)) {
      nextNum = i;
      break;
    }
  }

  final nextType = nextNum != null ? _sequence[nextNum - 1] : null;
  final currentNum = nextNum ?? 0;
  final currentType = nextNum != null ? nextType!.toLowerCase() : 'visit';

  // Extract previous touchpoint info from last completed
  Map<String, dynamic>? lastTouchpoint;
  if (touchpoints.isNotEmpty) {
    touchpoints.sort((a, b) =>
        ((b['touchpoint_number'] as num?)?.toInt() ?? 0)
            .compareTo((a['touchpoint_number'] as num?)?.toInt() ?? 0));
    lastTouchpoint = touchpoints.first;
  }

  DateTime? previousDate;
  if (lastTouchpoint?['date'] != null) {
    try {
      previousDate = DateTime.parse(lastTouchpoint!['date'] as String);
    } catch (_) {}
  }

  return MyDayClient(
    id: row['id'] as String,
    clientId: row['client_id'] as String,
    fullName: '${row['first_name'] ?? ''} ${row['last_name'] ?? ''}'.trim(),
    agencyName: null, // agencies table not in PowerSync schema
    location: null,
    touchpointNumber: currentNum,
    touchpointType: currentType,
    priority: row['priority'] as String? ?? 'normal',
    notes: row['notes'] as String?,
    status: row['status'] as String?,
    scheduledTime: row['scheduled_time'] as String?,
    nextTouchpointNumber: nextNum,
    nextTouchpointType: nextType,
    previousTouchpointNumber:
        (lastTouchpoint?['touchpoint_number'] as num?)?.toInt(),
    previousTouchpointReason: lastTouchpoint?['reason'] as String?,
    previousTouchpointType: lastTouchpoint?['type'] as String?,
    previousTouchpointDate: previousDate,
  );
}
```

Add `import 'dart:convert';` at the top if not already present.

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/my_day/my_day_client_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/my_day/data/models/my_day_client.dart \
        test/features/my_day/my_day_client_test.dart
git commit -m "feat: add MyDayClient.fromPowerSync factory for local SQLite mapping"
```

---

## Task 3: Replace My Day API call with PowerSync stream

`MyDayNotifier.loadClients()` currently calls the REST API. Replace it with a `db.watch()` stream so the page works offline and stays reactive.

**Files:**
- Modify: `lib/features/my_day/presentation/providers/my_day_provider.dart`

- [ ] **Step 1: Read the current provider**

Read `lib/features/my_day/presentation/providers/my_day_provider.dart` in full to understand the current state shape and all methods before editing.

- [ ] **Step 2: Replace loadClients with PowerSync stream**

Replace the `MyDayNotifier` class body. Keep `MyDayState` unchanged:

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

// Keep MyDayState class exactly as-is

class MyDayNotifier extends StateNotifier<MyDayState> {
  final Ref _ref;
  StreamSubscription? _subscription;

  MyDayNotifier(this._ref) : super(MyDayState()) {
    _watchFromLocal();
  }

  void _watchFromLocal() {
    _subscription?.cancel();
    final userId = _ref.read(currentUserIdProvider) ?? '';
    final dateStr = state.selectedDate.toIso8601String().substring(0, 10);

    state = state.copyWith(isLoading: true, error: null);

    PowerSyncService.database.then((db) {
      _subscription = db.watch(
        '''SELECT i.id, i.client_id, i.scheduled_date, i.scheduled_time,
                  i.status, i.priority, i.notes,
                  c.first_name, c.last_name, c.client_type,
                  c.touchpoint_summary
           FROM itineraries i
           JOIN clients c ON c.id = i.client_id
           WHERE i.user_id = ? AND i.scheduled_date = ?
           ORDER BY i.scheduled_time ASC NULLS LAST''',
        parameters: [userId, dateStr],
      ).listen(
        (results) {
          final clients = results
              .map((row) => MyDayClient.fromPowerSync(row))
              .toList();
          if (mounted) {
            state = state.copyWith(clients: clients, isLoading: false, error: null);
          }
        },
        onError: (e) {
          if (mounted) {
            state = state.copyWith(isLoading: false, error: e.toString());
          }
        },
      );
    }).catchError((e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    });
  }

  void changeDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _watchFromLocal();
  }

  Future<void> refresh() async {
    _watchFromLocal();
  }

  // Keep setTimeIn exactly as-is — it only updates local UI state

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

- [ ] **Step 3: Check if PowerSyncService.database returns a Future or is synchronous**

Read `lib/services/sync/powersync_service.dart` and verify the return type of `database`. If it's already a synchronous getter (returns `PowerSyncDatabase` directly), change `PowerSyncService.database.then((db) { ... })` to use the database directly:

```dart
// If database is synchronous:
final db = PowerSyncService.database;
_subscription = db.watch(...).listen(...);
```

Adjust accordingly.

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/features/my_day/presentation/providers/my_day_provider.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/my_day/presentation/providers/my_day_provider.dart
git commit -m "feat: replace My Day API call with PowerSync local stream"
```

---

## Task 4: Replace Itinerary detail HiveService lookup with PowerSync query, verify list uses repository stream

`ItineraryDetailPage` uses HiveService and misses items not previously cached. Replace with a direct PowerSync query. Also confirm the list page uses `itineraryRepositoryProvider.watchItineraries()` (the PowerSync stream) rather than an API call — check `todayItineraryProvider` and update if needed.

**Files:**
- Modify: `lib/features/itineraries/presentation/pages/itinerary_detail_page.dart`

- [ ] **Step 1: Read the current detail page provider**

Read `lib/features/itineraries/presentation/pages/itinerary_detail_page.dart` lines 1-80 to understand the `itineraryDetailProvider` FutureProvider and `_loadItinerary()` structure.

- [ ] **Step 2: Replace the FutureProvider**

Replace `itineraryDetailProvider` (the provider at the top of the file):

```dart
final itineraryDetailProvider = FutureProvider.family<Itinerary?, String>(
  (ref, itineraryId) async {
    final db = await PowerSyncService.database;
    final results = await db.getAll(
      'SELECT * FROM itineraries WHERE id = ?',
      [itineraryId],
    );
    if (results.isEmpty) return null;
    final row = results.first;
    return Itinerary(
      id: row['id'] as String,
      caravanId: row['user_id'] as String?,
      clientId: row['client_id'] as String?,
      scheduledDate: row['scheduled_date'] != null
          ? DateTime.tryParse(row['scheduled_date'] as String)
          : null,
      scheduledTime: row['scheduled_time'] as String?,
      status: row['status'] as String?,
      priority: row['priority'] as String?,
      notes: row['notes'] as String?,
    );
  },
);
```

- [ ] **Step 3: Remove HiveService usage from _loadItinerary**

Find the `_loadItinerary()` method in the page's `State` class. Remove the `HiveService` calls — the provider now handles data loading. If `_loadItinerary` is still needed for the edit/delete callbacks, update it to call `ref.invalidate(itineraryDetailProvider(widget.itineraryId))` instead of writing to Hive.

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/features/itineraries/presentation/pages/itinerary_detail_page.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/itineraries/presentation/pages/itinerary_detail_page.dart
git commit -m "feat: replace HiveService lookup with PowerSync query in itinerary detail"
```

---

## Task 5: Route ClientSelectorModal create through itineraryRepository

Currently "Add to My Day" calls the REST API. Route it through `itineraryRepository.createItinerary()` so it writes locally and auto-syncs.

**Files:**
- Modify: `lib/shared/widgets/client_selector_modal.dart`

- [ ] **Step 1: Read the current _addClientToItinerary method**

Read `lib/shared/widgets/client_selector_modal.dart` around line 357–432 to see the full `_addClientToItinerary` method.

- [ ] **Step 2: Replace the API call with itineraryRepository**

Replace the call to `myDayApiService.addToMyDay()` with:

```dart
Future<void> _addClientToItinerary(Client client, DateTime targetDate) async {
  try {
    final itineraryRepo = ref.read(itineraryRepositoryProvider);
    final userId = ref.read(currentUserIdProvider) ?? '';

    await itineraryRepo.createItinerary(Itinerary(
      id: '',  // Repository generates UUID if empty
      caravanId: userId,
      clientId: client.id,
      scheduledDate: targetDate,
      scheduledTime: null,
      status: 'pending',
      priority: 'normal',
      notes: null,
    ));

    if (mounted) {
      // Show success and mark client as added
      _markClientAdded(client.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to itinerary')),
      );
    }

    // Refresh My Day and itinerary providers
    ref.invalidate(todayItineraryProvider);
    ref.invalidate(myDayStateProvider);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }
}
```

Add imports for `itineraryRepositoryProvider`, `currentUserIdProvider`, and `Itinerary` model at the top of the file.

- [ ] **Step 3: Run Flutter analyze**

```bash
flutter analyze lib/shared/widgets/client_selector_modal.dart
```
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/client_selector_modal.dart
git commit -m "feat: route Add to My Day through itineraryRepository for offline support"
```

---

## Task 6: Route itinerary edit/delete through itineraryRepository

Currently edits and deletes write to HiveService (not synced). Route them through `itineraryRepository` (PowerSync auto-syncs).

**Files:**
- Modify: `lib/features/itineraries/presentation/pages/itinerary_detail_page.dart`

- [ ] **Step 1: Find edit and delete methods**

In `itinerary_detail_page.dart`, find the methods that call `_hiveService.updateItinerary(...)` and `_hiveService.deleteItinerary(...)`. Note their signatures.

- [ ] **Step 2: Replace HiveService edit with repository**

Replace the update call:
```dart
// Before:
await _hiveService.updateItinerary(itineraryId, updatedData);

// After:
final repo = ref.read(itineraryRepositoryProvider);
await repo.updateItinerary(Itinerary(
  id: widget.itineraryId,
  caravanId: ref.read(currentUserIdProvider) ?? '',
  clientId: _itinerary?.clientId,
  scheduledDate: _itinerary?.scheduledDate,
  scheduledTime: _itinerary?.scheduledTime,
  status: newStatus,    // or whichever field changed
  priority: newPriority,
  notes: newNotes,
));
ref.invalidate(itineraryDetailProvider(widget.itineraryId));
ref.invalidate(todayItineraryProvider);
```

- [ ] **Step 3: Replace HiveService delete with repository**

Replace the delete call:
```dart
// Before:
await _hiveService.deleteItinerary(itineraryId);

// After:
final repo = ref.read(itineraryRepositoryProvider);
await repo.deleteItinerary(widget.itineraryId);
ref.invalidate(todayItineraryProvider);
if (mounted) Navigator.of(context).pop();
```

- [ ] **Step 4: Remove HiveService dependency from detail page**

Remove any remaining `_hiveService` initialization that is now unused. Run `flutter analyze` to confirm.

```bash
flutter analyze lib/features/itineraries/presentation/pages/itinerary_detail_page.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/itineraries/presentation/pages/itinerary_detail_page.dart
git commit -m "feat: route itinerary edit/delete through PowerSync repository"
```

---

## Task 7: Wire ConnectivityService → BackgroundSyncService.performSync()

Pending items (touchpoints, and soon visits/releases) sit in Hive indefinitely because nothing triggers sync on reconnect. Fix this by listening to the connectivity stream.

**Files:**
- Modify: `lib/services/connectivity_service.dart`

- [ ] **Step 1: Read ConnectivityService**

Read `lib/services/connectivity_service.dart` in full to understand the `initialize()` method and `statusStream`.

- [ ] **Step 2: Add sync trigger to ConnectivityService**

In `ConnectivityService`, inject `BackgroundSyncService` and trigger sync on `offline → online`:

```dart
class ConnectivityService {
  final BackgroundSyncService? _syncService; // nullable to avoid circular dep
  ConnectivityStatus _previousStatus = ConnectivityStatus.unknown;

  ConnectivityService({BackgroundSyncService? syncService})
      : _syncService = syncService;

  // In your existing connectivity listener (inside initialize() or _setupListener()):
  void _onStatusChanged(ConnectivityStatus newStatus) {
    if (_previousStatus == ConnectivityStatus.offline &&
        newStatus == ConnectivityStatus.online) {
      _syncService?.performSync();
    }
    _previousStatus = newStatus;
    // ... existing logic
  }
}
```

If `ConnectivityService` doesn't accept constructor injection, add a `setSyncService(BackgroundSyncService service)` method and call it from the provider setup.

- [ ] **Step 3: Update connectivityServiceProvider to inject BackgroundSyncService**

In `lib/shared/providers/app_providers.dart`, update the provider:

```dart
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final syncService = ref.read(backgroundSyncServiceProvider);
  return ConnectivityService(syncService: syncService);
});
```

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/services/connectivity_service.dart \
               lib/shared/providers/app_providers.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/services/connectivity_service.dart \
        lib/shared/providers/app_providers.dart
git commit -m "feat: trigger BackgroundSyncService.performSync() on connectivity restored"
```

---

## Task 8: PendingVisit model and PendingVisitService

Create the Hive queue for offline visit records, mirroring `PendingTouchpointService`.

**Files:**
- Create: `lib/services/visit/models/pending_visit.dart`
- Create: `lib/services/visit/pending_visit_service.dart`
- Test: `test/services/visit/pending_visit_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/visit/pending_visit_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/visit/models/pending_visit.dart';
import 'package:imu_flutter/services/visit/pending_visit_service.dart';

void main() {
  late PendingVisitService service;

  setUp(() async {
    Hive.init('/tmp/hive_test_visits');
    service = PendingVisitService();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('pending_visits');
  });

  group('PendingVisitService', () {
    test('adds and retrieves a pending visit', () async {
      final visit = PendingVisit(
        id: 'v-1',
        clientId: 'c-1',
        timeIn: DateTime(2026, 4, 18, 9, 0),
        timeOut: DateTime(2026, 4, 18, 10, 0),
        odometerArrival: 1500.0,
        odometerDeparture: 1510.0,
        photoPath: null,
        notes: 'Test visit',
        type: 'regular_visit',
        createdAt: DateTime(2026, 4, 18),
      );

      await service.addPendingVisit(visit);
      final results = await service.getPendingVisits();

      expect(results.length, equals(1));
      expect(results.first.id, equals('v-1'));
      expect(results.first.clientId, equals('c-1'));
      expect(results.first.notes, equals('Test visit'));
    });

    test('removes a pending visit by id', () async {
      final visit = PendingVisit(
        id: 'v-2',
        clientId: 'c-2',
        timeIn: DateTime(2026, 4, 18, 9, 0),
        timeOut: DateTime(2026, 4, 18, 10, 0),
        odometerArrival: null,
        odometerDeparture: null,
        photoPath: null,
        notes: null,
        type: 'regular_visit',
        createdAt: DateTime(2026, 4, 18),
      );
      await service.addPendingVisit(visit);
      await service.removePendingVisit('v-2');
      final results = await service.getPendingVisits();
      expect(results, isEmpty);
    });

    test('getPendingCount returns correct count', () async {
      await service.addPendingVisit(PendingVisit(
        id: 'v-3', clientId: 'c-3',
        timeIn: DateTime.now(), timeOut: DateTime.now(),
        odometerArrival: null, odometerDeparture: null,
        photoPath: null, notes: null, type: 'regular_visit',
        createdAt: DateTime.now(),
      ));
      expect(await service.getPendingCount(), equals(1));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/visit/pending_visit_service_test.dart
```
Expected: FAIL — files not found.

- [ ] **Step 3: Create PendingVisit model**

Create `lib/services/visit/models/pending_visit.dart`:

```dart
import 'dart:convert';

class PendingVisit {
  final String id;
  final String clientId;
  final DateTime timeIn;
  final DateTime timeOut;
  final double? odometerArrival;
  final double? odometerDeparture;
  final String? photoPath;
  final String? notes;
  final String type;
  final DateTime createdAt;

  const PendingVisit({
    required this.id,
    required this.clientId,
    required this.timeIn,
    required this.timeOut,
    this.odometerArrival,
    this.odometerDeparture,
    this.photoPath,
    this.notes,
    required this.type,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'time_in': timeIn.toIso8601String(),
        'time_out': timeOut.toIso8601String(),
        'odometer_arrival': odometerArrival,
        'odometer_departure': odometerDeparture,
        'photo_path': photoPath,
        'notes': notes,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };

  factory PendingVisit.fromJson(Map<String, dynamic> json) => PendingVisit(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        timeIn: DateTime.parse(json['time_in'] as String),
        timeOut: DateTime.parse(json['time_out'] as String),
        odometerArrival: (json['odometer_arrival'] as num?)?.toDouble(),
        odometerDeparture: (json['odometer_departure'] as num?)?.toDouble(),
        photoPath: json['photo_path'] as String?,
        notes: json['notes'] as String?,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

- [ ] **Step 4: Create PendingVisitService**

Create `lib/services/visit/pending_visit_service.dart`:

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/visit/models/pending_visit.dart';

class PendingVisitService {
  static const String _boxName = 'pending_visits';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<void> addPendingVisit(PendingVisit visit) async {
    final box = await _openBox();
    await box.put(visit.id, jsonEncode(visit.toJson()));
  }

  Future<List<PendingVisit>> getPendingVisits() async {
    final box = await _openBox();
    return box.values
        .map((v) => PendingVisit.fromJson(
            jsonDecode(v as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> removePendingVisit(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<int> getPendingCount() async {
    final box = await _openBox();
    return box.length;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/services/visit/pending_visit_service_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/services/visit/ test/services/visit/pending_visit_service_test.dart
git commit -m "feat: add PendingVisit model and PendingVisitService for offline queue"
```

---

## Task 9: VisitCreationService

Routes visit creation online → REST API, offline → `PendingVisitService`.

**Files:**
- Create: `lib/services/visit/visit_creation_service.dart`
- Test: `test/services/visit/visit_creation_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/visit/visit_creation_service_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/visit/pending_visit_service.dart';
import 'package:imu_flutter/services/visit/visit_creation_service.dart';
import 'package:imu_flutter/services/visit/models/pending_visit.dart';

// Minimal fakes — no mockito needed
class _FakeConnectivity implements ConnectivityService {
  bool online;
  _FakeConnectivity(this.online);
  @override bool get isOnline => online;
  @override bool get isOffline => !online;
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeVisitApi implements VisitApiService {
  bool called = false;
  @override
  Future<void> createVisit(VisitData data, {File? photo}) async {
    called = true;
  }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late PendingVisitService pendingService;
  late _FakeVisitApi fakeApi;
  late VisitCreationService service;

  setUp(() async {
    Hive.init('/tmp/hive_test_vc');
    pendingService = PendingVisitService();
    fakeApi = _FakeVisitApi();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('pending_visits');
  });

  group('VisitCreationService', () {
    test('calls API directly when online', () async {
      service = VisitCreationService(
        _FakeConnectivity(true), fakeApi, pendingService,
      );
      await service.createVisit(
        clientId: 'c-1',
        timeIn: DateTime.now(),
        timeOut: DateTime.now(),
        notes: 'Online visit',
        type: 'regular_visit',
      );
      expect(fakeApi.called, isTrue);
      expect(await pendingService.getPendingCount(), equals(0));
    });

    test('saves to pending queue when offline', () async {
      service = VisitCreationService(
        _FakeConnectivity(false), fakeApi, pendingService,
      );
      await service.createVisit(
        clientId: 'c-2',
        timeIn: DateTime.now(),
        timeOut: DateTime.now(),
        notes: 'Offline visit',
        type: 'regular_visit',
      );
      expect(fakeApi.called, isFalse);
      expect(await pendingService.getPendingCount(), equals(1));
      final pending = await pendingService.getPendingVisits();
      expect(pending.first.notes, equals('Offline visit'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/visit/visit_creation_service_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create VisitCreationService**

Create `lib/services/visit/visit_creation_service.dart`:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/visit/pending_visit_service.dart';
import 'package:imu_flutter/services/visit/models/pending_visit.dart';

class VisitCreationService {
  final ConnectivityService _connectivity;
  final VisitApiService _api;
  final PendingVisitService _pending;

  VisitCreationService(this._connectivity, this._api, this._pending);

  Future<void> createVisit({
    required String clientId,
    required DateTime timeIn,
    required DateTime timeOut,
    double? odometerArrival,
    double? odometerDeparture,
    File? photo,
    String? notes,
    required String type,
  }) async {
    if (_connectivity.isOnline) {
      await _api.createVisit(
        VisitData(
          clientId: clientId,
          timeIn: timeIn,
          timeOut: timeOut,
          odometerArrival: odometerArrival,
          odometerDeparture: odometerDeparture,
          notes: notes,
          type: type,
        ),
        photo: photo,
      );
    } else {
      String? savedPhotoPath;
      if (photo != null) {
        savedPhotoPath = await _saveFileForOffline(photo);
      }
      await _pending.addPendingVisit(PendingVisit(
        id: const Uuid().v4(),
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photoPath: savedPhotoPath,
        notes: notes,
        type: type,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<String> _saveFileForOffline(File file) async {
    final dir = await getTemporaryDirectory();
    final id = const Uuid().v4();
    final ext = file.path.split('.').last;
    final dest = '${dir.path}/${id}_offline.$ext';
    await file.copy(dest);
    return dest;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/services/visit/visit_creation_service_test.dart
```
Expected: Both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/services/visit/visit_creation_service.dart \
        test/services/visit/visit_creation_service_test.dart
git commit -m "feat: add VisitCreationService with online/offline routing"
```

---

## Task 10: Add _syncPendingVisits to BackgroundSyncService

Wire `PendingVisitService` into the background sync loop so visits upload when online.

**Files:**
- Modify: `lib/services/api/background_sync_service.dart`
- Modify: `lib/shared/providers/app_providers.dart`

- [ ] **Step 1: Read BackgroundSyncService.performSync()**

Read `lib/services/api/background_sync_service.dart` in full. Find `performSync()` and `_syncPendingTouchpoints()` to understand the pattern.

- [ ] **Step 2: Add _syncPendingVisits method**

In `BackgroundSyncService`, add the `PendingVisitService` dependency and the sync method. Add to the constructor and inject via the provider:

```dart
// Add field:
final PendingVisitService _pendingVisitService;
final VisitApiService _visitApiService;

// Add to performSync() — call after _syncPendingTouchpoints():
await _syncPendingVisits();

// New method:
Future<void> _syncPendingVisits() async {
  final visits = await _pendingVisitService.getPendingVisits();
  for (final visit in visits) {
    try {
      File? photo;
      if (visit.photoPath != null) {
        final file = File(visit.photoPath!);
        if (await file.exists()) photo = file;
      }
      await _visitApiService.createVisit(
        VisitData(
          clientId: visit.clientId,
          timeIn: visit.timeIn,
          timeOut: visit.timeOut,
          odometerArrival: visit.odometerArrival,
          odometerDeparture: visit.odometerDeparture,
          notes: visit.notes,
          type: visit.type,
        ),
        photo: photo,
      );
      await _pendingVisitService.removePendingVisit(visit.id);
      // Clean up temp file
      if (visit.photoPath != null) {
        final file = File(visit.photoPath!);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to sync visit ${visit.id}: $e');
      // Continue to next item — don't abort the sync loop
    }
  }
}
```

- [ ] **Step 3: Update backgroundSyncServiceProvider**

In `lib/shared/providers/app_providers.dart`, update the provider to inject the new services:

```dart
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final pendingTouchpoints = ref.read(pendingTouchpointServiceProvider);
  final touchpointApi = ref.read(touchpointApiServiceProvider);
  final pendingVisits = ref.read(pendingVisitServiceProvider);
  final visitApi = ref.read(visitApiServiceProvider);
  return BackgroundSyncService(
    pendingTouchpointService: pendingTouchpoints,
    touchpointApiService: touchpointApi,
    pendingVisitService: pendingVisits,
    visitApiService: visitApi,
  );
});

// Add new providers:
final pendingVisitServiceProvider = Provider<PendingVisitService>(
  (_) => PendingVisitService(),
);

final visitCreationServiceProvider = Provider<VisitCreationService>((ref) {
  return VisitCreationService(
    ref.read(connectivityServiceProvider),
    ref.read(visitApiServiceProvider),
    ref.read(pendingVisitServiceProvider),
  );
});
```

Note: `visitApiServiceProvider` may already exist — check and reuse if so.

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/services/api/background_sync_service.dart \
               lib/shared/providers/app_providers.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/api/background_sync_service.dart \
        lib/shared/providers/app_providers.dart
git commit -m "feat: add _syncPendingVisits to BackgroundSyncService"
```

---

## Task 11: Route RecordVisitBottomSheet through VisitCreationService

Replace the direct API call in the visit bottom sheet with `VisitCreationService`.

**Files:**
- Modify: `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart`

- [ ] **Step 1: Read the bottom sheet submit method**

Read `lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart` lines 100–200. Find the submit handler that calls `visitApi.createVisit()`.

- [ ] **Step 2: Replace with VisitCreationService**

```dart
// Before:
final visitApi = ref.read(visitApiServiceProvider);
await visitApi.createVisit(visitData, photo: _photo);
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Visit recorded')),
);

// After:
final visitService = ref.read(visitCreationServiceProvider);
final isOnline = ref.read(isOnlineProvider);
await visitService.createVisit(
  clientId: widget.clientId,
  timeIn: _timeIn!,
  timeOut: _timeOut!,
  odometerArrival: double.tryParse(_odometerArrivalController.text),
  odometerDeparture: double.tryParse(_odometerDepartureController.text),
  photo: _photo,
  notes: _notesController.text.isNotEmpty ? _notesController.text : null,
  type: 'regular_visit',
);
final message = isOnline
    ? 'Visit recorded'
    : 'Saved locally — will sync when connected';
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  Navigator.of(context).pop();
}
```

Adjust field/controller names to match what's in the actual file.

- [ ] **Step 3: Run Flutter analyze**

```bash
flutter analyze lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart
git commit -m "feat: route RecordVisit through VisitCreationService for offline support"
```

---

## Task 12: PendingRelease model and PendingReleaseService

Create the Hive queue for offline loan releases (stores visit + release data together).

**Files:**
- Create: `lib/services/release/models/pending_release.dart`
- Create: `lib/services/release/pending_release_service.dart`
- Test: `test/services/release/pending_release_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/release/pending_release_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/release/models/pending_release.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';

void main() {
  late PendingReleaseService service;

  setUp(() async {
    Hive.init('/tmp/hive_test_releases');
    service = PendingReleaseService();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('pending_releases');
  });

  group('PendingReleaseService', () {
    PendingRelease _makeRelease(String id) => PendingRelease(
          id: id,
          clientId: 'c-1',
          timeIn: DateTime(2026, 4, 18, 9, 0),
          timeOut: DateTime(2026, 4, 18, 10, 0),
          odometerArrival: 1500.0,
          odometerDeparture: 1510.0,
          photoPath: null,
          visitNotes: 'Visit note',
          udiNumber: 'UDI-001',
          productType: 'PUSU',
          loanType: 'NEW',
          amount: 50000.0,
          approvalNotes: null,
          createdAt: DateTime(2026, 4, 18),
        );

    test('adds and retrieves a pending release', () async {
      await service.addPendingRelease(_makeRelease('r-1'));
      final results = await service.getPendingReleases();
      expect(results.length, equals(1));
      expect(results.first.id, equals('r-1'));
      expect(results.first.udiNumber, equals('UDI-001'));
      expect(results.first.productType, equals('PUSU'));
    });

    test('removes by id', () async {
      await service.addPendingRelease(_makeRelease('r-2'));
      await service.removePendingRelease('r-2');
      expect(await service.getPendingCount(), equals(0));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/release/pending_release_service_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create PendingRelease model**

Create `lib/services/release/models/pending_release.dart`:

```dart
class PendingRelease {
  final String id;
  final String clientId;
  // Visit data
  final DateTime timeIn;
  final DateTime timeOut;
  final double? odometerArrival;
  final double? odometerDeparture;
  final String? photoPath;
  final String? visitNotes;
  // Release data
  final String udiNumber;
  final String productType;
  final String loanType;
  final double amount;
  final String? approvalNotes;

  final DateTime createdAt;

  const PendingRelease({
    required this.id,
    required this.clientId,
    required this.timeIn,
    required this.timeOut,
    this.odometerArrival,
    this.odometerDeparture,
    this.photoPath,
    this.visitNotes,
    required this.udiNumber,
    required this.productType,
    required this.loanType,
    required this.amount,
    this.approvalNotes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'time_in': timeIn.toIso8601String(),
        'time_out': timeOut.toIso8601String(),
        'odometer_arrival': odometerArrival,
        'odometer_departure': odometerDeparture,
        'photo_path': photoPath,
        'visit_notes': visitNotes,
        'udi_number': udiNumber,
        'product_type': productType,
        'loan_type': loanType,
        'amount': amount,
        'approval_notes': approvalNotes,
        'created_at': createdAt.toIso8601String(),
      };

  factory PendingRelease.fromJson(Map<String, dynamic> json) => PendingRelease(
        id: json['id'] as String,
        clientId: json['client_id'] as String,
        timeIn: DateTime.parse(json['time_in'] as String),
        timeOut: DateTime.parse(json['time_out'] as String),
        odometerArrival: (json['odometer_arrival'] as num?)?.toDouble(),
        odometerDeparture: (json['odometer_departure'] as num?)?.toDouble(),
        photoPath: json['photo_path'] as String?,
        visitNotes: json['visit_notes'] as String?,
        udiNumber: json['udi_number'] as String,
        productType: json['product_type'] as String,
        loanType: json['loan_type'] as String,
        amount: (json['amount'] as num).toDouble(),
        approvalNotes: json['approval_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
```

- [ ] **Step 4: Create PendingReleaseService**

Create `lib/services/release/pending_release_service.dart`:

```dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/release/models/pending_release.dart';

class PendingReleaseService {
  static const String _boxName = 'pending_releases';

  Future<Box> _openBox() => Hive.openBox(_boxName);

  Future<void> addPendingRelease(PendingRelease release) async {
    final box = await _openBox();
    await box.put(release.id, jsonEncode(release.toJson()));
  }

  Future<List<PendingRelease>> getPendingReleases() async {
    final box = await _openBox();
    return box.values
        .map((v) => PendingRelease.fromJson(
            jsonDecode(v as String) as Map<String, dynamic>))
        .toList();
  }

  Future<void> removePendingRelease(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  Future<int> getPendingCount() async {
    final box = await _openBox();
    return box.length;
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
flutter test test/services/release/pending_release_service_test.dart
```
Expected: Both tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/services/release/ test/services/release/pending_release_service_test.dart
git commit -m "feat: add PendingRelease model and PendingReleaseService"
```

---

## Task 13: ReleaseCreationService and _syncPendingReleases

Routes loan release creation online → 3-step REST API, offline → `PendingReleaseService`. Adds sync to `BackgroundSyncService`.

**Files:**
- Create: `lib/services/release/release_creation_service.dart`
- Modify: `lib/services/api/background_sync_service.dart`
- Modify: `lib/shared/providers/app_providers.dart`
- Test: `test/services/release/release_creation_service_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/services/release/release_creation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';
import 'package:imu_flutter/services/release/release_creation_service.dart';

class _FakeConnectivity implements ConnectivityService {
  final bool online;
  _FakeConnectivity(this.online);
  @override bool get isOnline => online;
  @override bool get isOffline => !online;
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeReleaseApi implements ReleaseApiService {
  bool called = false;
  @override
  Future<void> createCompleteLoanRelease(dynamic data) async { called = true; }
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late PendingReleaseService pendingService;
  late _FakeReleaseApi fakeApi;
  late ReleaseCreationService service;

  setUp(() async {
    Hive.init('/tmp/hive_test_rc');
    pendingService = PendingReleaseService();
    fakeApi = _FakeReleaseApi();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('pending_releases');
  });

  group('ReleaseCreationService', () {
    test('calls API when online', () async {
      service = ReleaseCreationService(_FakeConnectivity(true), fakeApi, pendingService);
      await service.createLoanRelease(
        clientId: 'c-1',
        timeIn: DateTime.now(), timeOut: DateTime.now(),
        udiNumber: 'UDI-001', productType: 'PUSU',
        loanType: 'NEW', amount: 50000.0,
      );
      expect(fakeApi.called, isTrue);
      expect(await pendingService.getPendingCount(), equals(0));
    });

    test('saves to queue when offline', () async {
      service = ReleaseCreationService(_FakeConnectivity(false), fakeApi, pendingService);
      await service.createLoanRelease(
        clientId: 'c-2',
        timeIn: DateTime.now(), timeOut: DateTime.now(),
        udiNumber: 'UDI-002', productType: 'LIKA',
        loanType: 'RENEWAL', amount: 30000.0,
      );
      expect(fakeApi.called, isFalse);
      expect(await pendingService.getPendingCount(), equals(1));
      final pending = await pendingService.getPendingReleases();
      expect(pending.first.udiNumber, equals('UDI-002'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/services/release/release_creation_service_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create ReleaseCreationService**

Create `lib/services/release/release_creation_service.dart`:

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';
import 'package:imu_flutter/services/release/models/pending_release.dart';

class ReleaseCreationService {
  final ConnectivityService _connectivity;
  final ReleaseApiService _api;
  final PendingReleaseService _pending;

  ReleaseCreationService(this._connectivity, this._api, this._pending);

  Future<void> createLoanRelease({
    required String clientId,
    required DateTime timeIn,
    required DateTime timeOut,
    double? odometerArrival,
    double? odometerDeparture,
    File? photo,
    String? visitNotes,
    required String udiNumber,
    required String productType,
    required String loanType,
    required double amount,
    String? approvalNotes,
  }) async {
    if (_connectivity.isOnline) {
      await _api.createCompleteLoanRelease(LoanReleaseData(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photo: photo,
        visitNotes: visitNotes,
        udiNumber: udiNumber,
        productType: productType,
        loanType: loanType,
        amount: amount,
        approvalNotes: approvalNotes,
      ));
    } else {
      String? savedPhotoPath;
      if (photo != null) {
        savedPhotoPath = await _saveFileForOffline(photo);
      }
      await _pending.addPendingRelease(PendingRelease(
        id: const Uuid().v4(),
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photoPath: savedPhotoPath,
        visitNotes: visitNotes,
        udiNumber: udiNumber,
        productType: productType,
        loanType: loanType,
        amount: amount,
        approvalNotes: approvalNotes,
        createdAt: DateTime.now(),
      ));
    }
  }

  Future<String> _saveFileForOffline(File file) async {
    final dir = await getTemporaryDirectory();
    final id = const Uuid().v4();
    final ext = file.path.split('.').last;
    final dest = '${dir.path}/${id}_offline_release.$ext';
    await file.copy(dest);
    return dest;
  }
}
```

Note: `LoanReleaseData` is whatever data class `ReleaseApiService.createCompleteLoanRelease()` currently accepts. Read that file and adjust accordingly.

- [ ] **Step 4: Add _syncPendingReleases to BackgroundSyncService**

```dart
// Add fields:
final PendingReleaseService _pendingReleaseService;
final ReleaseApiService _releaseApiService;

// In performSync(), after _syncPendingVisits():
await _syncPendingReleases();

// New method:
Future<void> _syncPendingReleases() async {
  final releases = await _pendingReleaseService.getPendingReleases();
  for (final release in releases) {
    try {
      File? photo;
      if (release.photoPath != null) {
        final file = File(release.photoPath!);
        if (await file.exists()) photo = file;
      }
      await _releaseApiService.createCompleteLoanRelease(LoanReleaseData(
        clientId: release.clientId,
        timeIn: release.timeIn,
        timeOut: release.timeOut,
        odometerArrival: release.odometerArrival,
        odometerDeparture: release.odometerDeparture,
        photo: photo,
        visitNotes: release.visitNotes,
        udiNumber: release.udiNumber,
        productType: release.productType,
        loanType: release.loanType,
        amount: release.amount,
        approvalNotes: release.approvalNotes,
      ));
      await _pendingReleaseService.removePendingRelease(release.id);
      if (release.photoPath != null) {
        final file = File(release.photoPath!);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Failed to sync release ${release.id}: $e');
    }
  }
}
```

- [ ] **Step 5: Register providers in app_providers.dart**

```dart
final pendingReleaseServiceProvider = Provider<PendingReleaseService>(
  (_) => PendingReleaseService(),
);

final releaseCreationServiceProvider = Provider<ReleaseCreationService>((ref) {
  return ReleaseCreationService(
    ref.read(connectivityServiceProvider),
    ref.read(releaseApiServiceProvider),
    ref.read(pendingReleaseServiceProvider),
  );
});
```

Also update `backgroundSyncServiceProvider` to inject `pendingReleaseService` and `releaseApiService`.

- [ ] **Step 6: Run tests**

```bash
flutter test test/services/release/release_creation_service_test.dart
```
Expected: Both tests PASS.

- [ ] **Step 7: Run Flutter analyze**

```bash
flutter analyze lib/services/release/ lib/services/api/background_sync_service.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/services/release/ \
        lib/services/api/background_sync_service.dart \
        lib/shared/providers/app_providers.dart \
        test/services/release/release_creation_service_test.dart
git commit -m "feat: add ReleaseCreationService and _syncPendingReleases for offline support"
```

---

## Task 14: Route RecordLoanReleaseBottomSheet through ReleaseCreationService

**Files:**
- Modify: `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart`

- [ ] **Step 1: Read the submit handler**

Read `lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart` lines 115–200. Find the submit method that calls `releaseApi.createCompleteLoanRelease()`.

- [ ] **Step 2: Replace with ReleaseCreationService**

```dart
// Before:
final releaseApi = ref.read(releaseApiServiceProvider);
await releaseApi.createCompleteLoanRelease(data);

// After:
final releaseService = ref.read(releaseCreationServiceProvider);
final isOnline = ref.read(isOnlineProvider);
await releaseService.createLoanRelease(
  clientId: widget.clientId,
  timeIn: _timeIn!,
  timeOut: _timeOut!,
  odometerArrival: double.tryParse(_odometerArrivalController.text),
  odometerDeparture: double.tryParse(_odometerDepartureController.text),
  photo: _photo,
  visitNotes: _visitNotesController.text.isNotEmpty
      ? _visitNotesController.text : null,
  udiNumber: _udiNumberController.text,
  productType: _selectedProductType!,
  loanType: _selectedLoanType!,
  amount: double.parse(_amountController.text),
  approvalNotes: _approvalNotesController.text.isNotEmpty
      ? _approvalNotesController.text : null,
);
final message = isOnline
    ? 'Loan release recorded'
    : 'Saved locally — will sync when connected';
if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
  Navigator.of(context).pop();
}
```

Adjust field/controller names to match the actual file.

- [ ] **Step 3: Run Flutter analyze**

```bash
flutter analyze lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart
git commit -m "feat: route RecordLoanRelease through ReleaseCreationService for offline support"
```

---

## Task 15: OfflineBanner widget and integration

A reusable banner shown when the device is offline.

**Files:**
- Create: `lib/shared/widgets/offline_banner.dart`
- Modify: `lib/features/my_day/presentation/pages/my_day_page.dart`
- Modify: `lib/features/itineraries/presentation/pages/itinerary_page.dart`
- Test: `test/widgets/offline_banner_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/widgets/offline_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/offline_banner.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

Widget _buildWithOnline(bool isOnline) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWithValue(isOnline),
    ],
    child: const MaterialApp(
      home: Scaffold(body: OfflineBanner()),
    ),
  );
}

void main() {
  testWidgets('shows banner when offline', (tester) async {
    await tester.pumpWidget(_buildWithOnline(false));
    expect(find.text("You're offline — changes will sync when connected"),
        findsOneWidget);
  });

  testWidgets('hides banner when online', (tester) async {
    await tester.pumpWidget(_buildWithOnline(true));
    expect(find.text("You're offline — changes will sync when connected"),
        findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widgets/offline_banner_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Create OfflineBanner widget**

Create `lib/shared/widgets/offline_banner.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "You're offline — changes will sync when connected",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widgets/offline_banner_test.dart
```
Expected: Both tests PASS.

- [ ] **Step 5: Add OfflineBanner to My Day page**

In `lib/features/my_day/presentation/pages/my_day_page.dart`, find the main `Scaffold` or `Column` body. Add `OfflineBanner()` at the top:

```dart
// In the body/column of the scaffold:
Column(
  children: [
    const OfflineBanner(),  // Add this line
    Expanded(child: /* existing content */),
  ],
)
```

Add `import 'package:imu_flutter/shared/widgets/offline_banner.dart';` at top.

- [ ] **Step 6: Add OfflineBanner to Itinerary page**

Same pattern in `lib/features/itineraries/presentation/pages/itinerary_page.dart`.

- [ ] **Step 7: Run Flutter analyze**

```bash
flutter analyze lib/shared/widgets/offline_banner.dart \
               lib/features/my_day/presentation/pages/my_day_page.dart \
               lib/features/itineraries/presentation/pages/itinerary_page.dart
```

- [ ] **Step 8: Commit**

```bash
git add lib/shared/widgets/offline_banner.dart \
        lib/features/my_day/presentation/pages/my_day_page.dart \
        lib/features/itineraries/presentation/pages/itinerary_page.dart \
        test/widgets/offline_banner_test.dart
git commit -m "feat: add OfflineBanner widget to My Day and Itinerary pages"
```

---

## Task 16: Pending sync count badge

Show count of pending items (touchpoints + visits + releases) in the UI.

**Files:**
- Modify: `lib/shared/providers/app_providers.dart`
- Modify: wherever the sync/settings icon lives (check `lib/shared/widgets/main_shell.dart` or navigation bar)

- [ ] **Step 1: Add totalPendingCountProvider**

In `lib/shared/providers/app_providers.dart`:

```dart
final totalPendingCountProvider = FutureProvider<int>((ref) async {
  final touchpoints = await ref.read(pendingTouchpointServiceProvider).getPendingCount();
  final visits = await ref.read(pendingVisitServiceProvider).getPendingCount();
  final releases = await ref.read(pendingReleaseServiceProvider).getPendingCount();
  return touchpoints + visits + releases;
});
```

- [ ] **Step 2: Find where the sync icon is rendered**

Read `lib/shared/widgets/main_shell.dart` to find the navigation bar or sync icon. Find which widget/tab shows the sync or settings button.

- [ ] **Step 3: Add badge to sync icon**

Wrap the sync icon with a `Badge` widget showing the count:

```dart
Consumer(
  builder: (context, ref, _) {
    final countAsync = ref.watch(totalPendingCountProvider);
    final count = countAsync.valueOrNull ?? 0;
    if (count == 0) return const Icon(Icons.sync);
    return Badge.count(
      count: count,
      child: const Icon(Icons.sync),
    );
  },
)
```

- [ ] **Step 4: Run Flutter analyze**

```bash
flutter analyze lib/shared/providers/app_providers.dart \
               lib/shared/widgets/main_shell.dart
```

- [ ] **Step 5: Final full test run**

```bash
cd /home/claude-team/loi/imu3/frontend-mobile-imu/imu_flutter
flutter test
```
Expected: All tests pass.

- [ ] **Step 6: Commit and push**

```bash
git add lib/shared/providers/app_providers.dart lib/shared/widgets/main_shell.dart
git commit -m "feat: add pending sync count badge to navigation"
git push origin main
```

---

## Verification

After all tasks, run full analysis:

```bash
cd /home/claude-team/loi/imu3/frontend-mobile-imu/imu_flutter
flutter analyze
flutter test
```

Expected:
- `flutter analyze`: No errors (warnings for unused imports acceptable)
- `flutter test`: All tests pass

Manual verification checklist:
- [ ] Open app with wifi off → My Day shows itinerary items (not error)
- [ ] Open app with wifi off → Itinerary list shows items
- [ ] Tap itinerary item with wifi off → Detail page loads (not "Not found")
- [ ] Add client to My Day with wifi off → Item appears in list, syncs when wifi restored
- [ ] Record visit with wifi off → "Saved locally" toast shown, appears in sync badge
- [ ] Record loan release with wifi off → "Saved locally" toast, sync badge increments
- [ ] Turn wifi back on → all pending items sync, badge clears
- [ ] Orange offline banner appears/disappears with connectivity changes
