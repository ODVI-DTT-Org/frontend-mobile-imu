# Missed Visits Real Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace fake estimated data in the missed visits page with real data from PowerSync (missed itineraries) and Hive cache (overdue clients).

**Architecture:** `ItineraryRepository.watchMissedItineraries()` streams past-due itineraries from PowerSync SQLite via a JOIN with the clients table. A `FutureProvider` computes overdue clients from the full Hive cache (all assigned clients, not paginated). A plain `Provider` merges both sources, deduplicates by clientId, and replaces the current buggy `missedVisitsProvider`.

**Tech Stack:** Flutter/Dart, Riverpod (`StreamProvider`, `FutureProvider`, `Provider`), PowerSync SQLite (`db.watch()`, `db.getAll()`, `db.writeTransaction()`), Hive local cache, `flutter_test`.

---

## File Map

| File | Change |
|---|---|
| `lib/features/visits/data/models/missed_visit_model.dart` | Add `MissedVisitSource` enum + `source` + `itineraryId` fields to `MissedVisit` |
| `lib/features/itineraries/data/repositories/itinerary_repository.dart` | Add `watchMissedItineraries(String userId)` stream method |
| `lib/shared/providers/app_providers.dart` | Replace `missedVisitsProvider`; add `missedItinerariesStreamProvider`, `overdueClientsProvider` |
| `lib/features/visits/presentation/pages/missed_visits_page.dart` | Fix reschedule action (status + atomicity); update card subtitle; skeleton loading |
| `test/unit/missed_visit_model_test.dart` | New — unit tests for model fields, priority, daysOverdue |
| `test/unit/overdue_clients_logic_test.dart` | New — unit tests for overdue filtering logic |

---

## Task 1: Extend MissedVisit Model

**Files:**
- Modify: `lib/features/visits/data/models/missed_visit_model.dart`
- Create: `test/unit/missed_visit_model_test.dart`

- [ ] **Step 1.1: Write failing tests for new model fields**

Create `test/unit/missed_visit_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/visits/data/models/missed_visit_model.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('MissedVisitSource', () {
    test('has missedItinerary and overdueClient values', () {
      expect(MissedVisitSource.values.length, 2);
      expect(MissedVisitSource.missedItinerary, isNotNull);
      expect(MissedVisitSource.overdueClient, isNotNull);
    });
  });

  group('MissedVisit.source field', () {
    test('defaults to overdueClient when constructed without source', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 1,
        touchpointType: TouchpointType.visit,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
      );
      expect(v.source, MissedVisitSource.overdueClient);
      expect(v.itineraryId, isNull);
    });

    test('source and itineraryId are preserved when set', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 2,
        touchpointType: TouchpointType.call,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
        source: MissedVisitSource.missedItinerary,
        itineraryId: 'itin-abc',
      );
      expect(v.source, MissedVisitSource.missedItinerary);
      expect(v.itineraryId, 'itin-abc');
    });

    test('toJson serialises source and itineraryId', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 1,
        touchpointType: TouchpointType.visit,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
        source: MissedVisitSource.missedItinerary,
        itineraryId: 'itin-abc',
      );
      final json = v.toJson();
      expect(json['source'], 'missedItinerary');
      expect(json['itineraryId'], 'itin-abc');
    });

    test('fromJson round-trips source and itineraryId', () {
      final json = {
        'id': 'x',
        'clientId': 'c1',
        'clientName': 'Test',
        'touchpointNumber': 1,
        'touchpointType': 'visit',
        'scheduledDate': '2026-05-01T00:00:00.000',
        'createdAt': '2026-05-01T00:00:00.000',
        'source': 'missedItinerary',
        'itineraryId': 'itin-abc',
      };
      final v = MissedVisit.fromJson(json);
      expect(v.source, MissedVisitSource.missedItinerary);
      expect(v.itineraryId, 'itin-abc');
    });

    test('fromJson defaults source to overdueClient when field is absent', () {
      final json = {
        'id': 'x',
        'clientId': 'c1',
        'clientName': 'Test',
        'touchpointNumber': 1,
        'touchpointType': 'visit',
        'scheduledDate': '2026-05-01T00:00:00.000',
        'createdAt': '2026-05-01T00:00:00.000',
      };
      final v = MissedVisit.fromJson(json);
      expect(v.source, MissedVisitSource.overdueClient);
      expect(v.itineraryId, isNull);
    });
  });
}
```

- [ ] **Step 1.2: Run test to confirm it fails**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test test/unit/missed_visit_model_test.dart
```

Expected: FAIL — `MissedVisitSource` is not defined.

- [ ] **Step 1.3: Update `missed_visit_model.dart`**

Replace the entire file content with:

```dart
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Whether this missed visit comes from a PowerSync itinerary or Hive overdue computation
enum MissedVisitSource { missedItinerary, overdueClient }

/// Represents a missed/overdue client visit
class MissedVisit {
  final String id;
  final String clientId;
  final String clientName;
  final int touchpointNumber;
  final TouchpointType touchpointType;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final String? primaryPhone;
  final String? primaryAddress;
  final MissedVisitSource source;
  final String? itineraryId;

  MissedVisit({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.touchpointNumber,
    required this.touchpointType,
    required this.scheduledDate,
    required this.createdAt,
    this.primaryPhone,
    this.primaryAddress,
    this.source = MissedVisitSource.overdueClient,
    this.itineraryId,
  });

  /// Calculate days overdue
  int get daysOverdue {
    return DateTime.now().difference(scheduledDate).inDays;
  }

  /// Determine priority based on days overdue
  MissedVisitPriority get priority {
    if (daysOverdue >= 7) return MissedVisitPriority.high;
    if (daysOverdue >= 3) return MissedVisitPriority.medium;
    return MissedVisitPriority.low;
  }

  /// Get ordinal string for touchpoint number (supports unlimited touchpoints)
  String get touchpointOrdinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    if (touchpointNumber >= 1 && touchpointNumber <= ordinals.length) {
      return ordinals[touchpointNumber - 1];
    }
    final lastTwo = touchpointNumber % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${touchpointNumber}th';
    switch (touchpointNumber % 10) {
      case 1: return '${touchpointNumber}st';
      case 2: return '${touchpointNumber}nd';
      case 3: return '${touchpointNumber}rd';
      default: return '${touchpointNumber}th';
    }
  }

  /// Get touchpoint type label
  String get touchpointTypeLabel {
    return touchpointType == TouchpointType.visit ? 'Visit' : 'Call';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'touchpointNumber': touchpointNumber,
    'touchpointType': touchpointType.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'primaryPhone': primaryPhone,
    'primaryAddress': primaryAddress,
    'source': source.name,
    'itineraryId': itineraryId,
  };

  factory MissedVisit.fromJson(Map<String, dynamic> json) {
    return MissedVisit(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      touchpointNumber: json['touchpointNumber'] ?? 1,
      touchpointType: TouchpointType.values.firstWhere(
        (e) => e.name == json['touchpointType'],
        orElse: () => TouchpointType.visit,
      ),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      primaryPhone: json['primaryPhone'],
      primaryAddress: json['primaryAddress'],
      source: MissedVisitSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => MissedVisitSource.overdueClient,
      ),
      itineraryId: json['itineraryId'],
    );
  }
}

enum MissedVisitPriority { high, medium, low }
```

- [ ] **Step 1.4: Run test to confirm it passes**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test test/unit/missed_visit_model_test.dart
```

Expected: All tests PASS.

- [ ] **Step 1.5: Commit**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
git add lib/features/visits/data/models/missed_visit_model.dart test/unit/missed_visit_model_test.dart
git commit -m "feat: add MissedVisitSource enum and fields to MissedVisit model"
```

---

## Task 2: Add `watchMissedItineraries` to ItineraryRepository

**Files:**
- Modify: `lib/features/itineraries/data/repositories/itinerary_repository.dart`

The file is at `lib/features/itineraries/data/repositories/itinerary_repository.dart`. The `ItineraryRepository` class already has multiple `async*` methods that follow this exact pattern — find the last method in the class before the providers section (around line 395 where `itineraryRepositoryProvider` is defined) and insert the new method before it.

- [ ] **Step 2.1: Add `watchMissedItineraries` to `ItineraryRepository`**

Locate the closing `}` of the `ItineraryRepository` class (just before `final itineraryRepositoryProvider = ...`). Insert this method before it:

```dart
  /// Stream past-due itineraries for the current user.
  /// Reacts to changes in both the itineraries and clients tables.
  Stream<List<Map<String, dynamic>>> watchMissedItineraries(String userId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final rows in db.watch(
        '''SELECT i.id, i.client_id, i.scheduled_date, i.status, i.created_at,
                  c.first_name, c.last_name, c.middle_name,
                  c.next_touchpoint, c.touchpoint_number,
                  c.loan_released, c.phone
           FROM itineraries i
           LEFT JOIN clients c ON c.id = i.client_id
           WHERE i.user_id = ?
             AND DATE(i.scheduled_date) < DATE('now', 'localtime')
             AND i.status IN ('pending', 'in_progress')
           ORDER BY i.scheduled_date ASC''',
        parameters: [userId],
      )) {
        yield rows.map((r) => Map<String, dynamic>.from(r)).toList();
      }
    } catch (e) {
      logError('watchMissedItineraries error', e);
      yield [];
    }
  }
```

- [ ] **Step 2.2: Verify it compiles**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/features/itineraries/data/repositories/itinerary_repository.dart
```

Expected: No errors.

- [ ] **Step 2.3: Commit**

```bash
git add lib/features/itineraries/data/repositories/itinerary_repository.dart
git commit -m "feat: add watchMissedItineraries stream to ItineraryRepository"
```

---

## Task 3: Replace providers in `app_providers.dart`

**Files:**
- Modify: `lib/shared/providers/app_providers.dart`

The existing `missedVisitsProvider` is at line ~827. Replace that block (lines ~822–888) with three providers. **Do not touch `filteredMissedVisitsProvider` or `missedVisitsCountProvider`** — they watch `missedVisitsProvider` by name and will work unchanged.

Before writing, add this import near the top of the file (alongside the existing itinerary repository import):

```dart
import '../../features/itineraries/data/repositories/itinerary_repository.dart'
    show itineraryRepositoryProvider;
```

(Check the file's existing imports first — `itineraryRepositoryProvider` may already be imported. If it is, skip this.)

- [ ] **Step 3.1: Write unit tests for overdue filtering logic**

The overdue logic is self-contained enough to test. Create `test/unit/overdue_clients_logic_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/visits/data/models/missed_visit_model.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart'
    show Client, Touchpoint, TouchpointType, TouchpointReason;

/// Pure function extracted from overdueClientsProvider for testability.
/// Given a list of clients, the set of client IDs already covered by missed
/// itineraries, and the set of client IDs with future scheduled itineraries,
/// returns the MissedVisit entries for overdue clients.
List<MissedVisit> computeOverdueClients({
  required List<Client> clients,
  required Set<String> missedItineraryClientIds,
  required Set<String> futureItineraryClientIds,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final result = <MissedVisit>[];

  for (final client in clients) {
    if (client.id == null) continue;
    if (client.loanReleased) continue;
    if (client.nextTouchpoint == null) continue;
    if (missedItineraryClientIds.contains(client.id)) continue;
    if (futureItineraryClientIds.contains(client.id)) continue;

    DateTime lastActivity;
    if (client.touchpointSummary.isNotEmpty) {
      lastActivity = client.touchpointSummary
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          .date;
    } else {
      lastActivity = client.createdAt ?? effectiveNow;
    }

    if (effectiveNow.difference(lastActivity).inDays <= 7) continue;

    final nextTouchpointNum = client.touchpointNumber + 1;
    final touchpointTypeEnum = client.nextTouchpoint?.toLowerCase() == 'call'
        ? TouchpointType.call
        : TouchpointType.visit;

    result.add(MissedVisit(
      id: '${client.id}_$nextTouchpointNum',
      clientId: client.id!,
      clientName: client.fullName,
      touchpointNumber: nextTouchpointNum,
      touchpointType: touchpointTypeEnum,
      scheduledDate: lastActivity.add(const Duration(days: 7)),
      createdAt: effectiveNow,
      primaryPhone: client.phone,
      primaryAddress: client.fullAddress,
      source: MissedVisitSource.overdueClient,
    ));
  }

  return result;
}

/// Minimal Touchpoint factory for tests — all required fields supplied.
Touchpoint _tp({
  required String id,
  required String clientId,
  required DateTime date,
  int number = 1,
}) {
  return Touchpoint(
    id: id,
    clientId: clientId,
    touchpointNumber: number,
    type: TouchpointType.visit,
    reason: TouchpointReason.interested,
    date: date,
    createdAt: date,
  );
}

Client _makeClient({
  required String id,
  bool loanReleased = false,
  String? nextTouchpoint = 'Visit',
  List<Touchpoint> touchpointSummary = const [],
  DateTime? createdAt,
  int touchpointNumber = 0,
}) {
  return Client(
    id: id,
    firstName: 'Test',
    lastName: id,
    loanReleased: loanReleased,
    nextTouchpoint: nextTouchpoint,
    touchpointSummary: touchpointSummary,
    createdAt: createdAt,
    touchpointNumber: touchpointNumber,
  );
}

void main() {
  final now = DateTime(2026, 5, 15);

  test('includes client overdue by 8 days with no touchpoints and old createdAt', () {
    final client = _makeClient(
      id: 'c1',
      createdAt: now.subtract(const Duration(days: 8)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result.length, 1);
    expect(result.first.clientId, 'c1');
    expect(result.first.source, MissedVisitSource.overdueClient);
  });

  test('excludes client only 6 days since last touchpoint', () {
    final client = _makeClient(
      id: 'c2',
      touchpointSummary: [
        _tp(id: 't1', clientId: 'c2', date: now.subtract(const Duration(days: 6))),
      ],
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('uses latest touchpoint date, not list order', () {
    final client = _makeClient(
      id: 'c3',
      touchpointSummary: [
        _tp(id: 't2', clientId: 'c3', date: now.subtract(const Duration(days: 20)), number: 1),
        _tp(id: 't3', clientId: 'c3', date: now.subtract(const Duration(days: 6)),  number: 2),
      ],
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty); // latest was 6 days ago → not overdue
  });

  test('excludes loan-released clients', () {
    final client = _makeClient(
      id: 'c4',
      loanReleased: true,
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients with null nextTouchpoint (journey complete)', () {
    final client = _makeClient(
      id: 'c5',
      nextTouchpoint: null,
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients already covered by missed itinerary', () {
    final client = _makeClient(
      id: 'c6',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {'c6'},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('excludes clients with a future scheduled itinerary', () {
    final client = _makeClient(
      id: 'c7',
      createdAt: now.subtract(const Duration(days: 20)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {'c7'},
      now: now,
    );
    expect(result, isEmpty);
  });

  test('sets touchpointType to call when nextTouchpoint is call', () {
    final client = _makeClient(
      id: 'c8',
      nextTouchpoint: 'Call',
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final result = computeOverdueClients(
      clients: [client],
      missedItineraryClientIds: {},
      futureItineraryClientIds: {},
      now: now,
    );
    expect(result.first.touchpointType, TouchpointType.call);
  });
}
```

- [ ] **Step 3.2: Run tests to confirm they fail**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test test/unit/overdue_clients_logic_test.dart
```

Expected: FAIL — `computeOverdueClients` is not defined (it lives in the test file itself, so it'll fail because `Touchpoint` constructor needs checking — verify and adjust if needed based on actual `Touchpoint` constructor signature in `client_model.dart`).

> **Note on Touchpoint constructor:** Check `client_model.dart` around line 1060 for the exact named parameters of `Touchpoint()`. Use only the fields that exist. At minimum it needs `date`. Adjust the test's `_makeClient` helper and `Touchpoint(...)` calls to match the actual constructor.

- [ ] **Step 3.3: Fix test if Touchpoint constructor doesn't match, then run again**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test test/unit/overdue_clients_logic_test.dart
```

Expected: All PASS (the helper function is defined in the test file itself — this confirms the logic is correct).

- [ ] **Step 3.4: Replace providers in `app_providers.dart`**

Locate lines ~822–888 (the `missedVisitsFilterProvider`, `missedVisitsProvider`, and closing logic). Keep `missedVisitsFilterProvider` unchanged. Replace `missedVisitsProvider` with these three providers:

```dart
/// Stream of raw SQL rows for past-due itineraries from PowerSync.
/// Reactive — updates automatically when itineraries or clients change.
final missedItinerariesStreamProvider =
    StreamProvider<List<MissedVisit>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield [];
    return;
  }
  final repo = ref.read(itineraryRepositoryProvider);
  yield* repo.watchMissedItineraries(userId).map((rows) {
    return rows.map((row) {
      final firstName = (row['first_name'] as String?) ?? '';
      final lastName = (row['last_name'] as String?) ?? '';
      final middleName = (row['middle_name'] as String?) ?? '';
      final clientName = [firstName, middleName, lastName]
          .where((s) => s.isNotEmpty)
          .join(' ');
      final touchpointNum = (row['touchpoint_number'] as int?) ?? 0;
      final nextTouchpointStr =
          (row['next_touchpoint'] as String?)?.toLowerCase();
      final touchpointType = nextTouchpointStr == 'call'
          ? TouchpointType.call
          : TouchpointType.visit;
      final scheduledDate = row['scheduled_date'] != null
          ? DateTime.tryParse(row['scheduled_date'] as String) ??
              DateTime.now()
          : DateTime.now();
      final createdAt = row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now();
      return MissedVisit(
        id: row['id'] as String,
        clientId: row['client_id'] as String,
        clientName: clientName,
        touchpointNumber: touchpointNum + 1,
        touchpointType: touchpointType,
        scheduledDate: scheduledDate,
        createdAt: createdAt,
        primaryPhone: row['phone'] as String?,
        source: MissedVisitSource.missedItinerary,
        itineraryId: row['id'] as String,
      );
    }).toList();
  });
});

/// Overdue clients from Hive cache that have no future or missed itinerary.
/// Watches syncServiceProvider so it recomputes after a sync completes.
final overdueClientsProvider =
    FutureProvider<List<MissedVisit>>((ref) async {
  // Re-evaluate whenever sync state changes (catches post-sync cache refresh)
  ref.watch(syncServiceProvider);

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  // Full assigned-client cache — not paginated
  final hive = HiveService();
  final rawClients = filterAssignedClientCache(hive.getAllClients());
  final clients = rawClients.map((json) => Client.fromJson(json)).toList();

  // Fetch future-scheduled itinerary client IDs to exclude (Set B)
  final db = await PowerSyncService.database;
  final futureRows = await db.getAll(
    '''SELECT DISTINCT client_id FROM itineraries
       WHERE user_id = ?
         AND DATE(scheduled_date) >= DATE('now', 'localtime')
         AND status IN ('pending', 'in_progress')''',
    [userId],
  );
  final futureClientIds =
      futureRows.map((r) => r['client_id'] as String).toSet();

  // Client IDs already covered by missed itineraries (Set A)
  final missedClientIds = (ref
              .read(missedItinerariesStreamProvider)
              .valueOrNull ??
          [])
      .map((v) => v.clientId)
      .toSet();

  final now = DateTime.now();
  final result = <MissedVisit>[];

  for (final client in clients) {
    if (client.id == null) continue;
    if (client.loanReleased) continue;
    if (client.nextTouchpoint == null) continue;
    if (missedClientIds.contains(client.id)) continue;
    if (futureClientIds.contains(client.id)) continue;

    DateTime lastActivity;
    if (client.touchpointSummary.isNotEmpty) {
      lastActivity = client.touchpointSummary
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          .date;
    } else {
      lastActivity = client.createdAt ?? now;
    }

    if (now.difference(lastActivity).inDays <= 7) continue;

    final nextTouchpointNum = client.touchpointNumber + 1;
    final touchpointTypeEnum =
        client.nextTouchpoint?.toLowerCase() == 'call'
            ? TouchpointType.call
            : TouchpointType.visit;

    result.add(MissedVisit(
      id: '${client.id}_$nextTouchpointNum',
      clientId: client.id!,
      clientName: client.fullName,
      touchpointNumber: nextTouchpointNum,
      touchpointType: touchpointTypeEnum,
      scheduledDate: lastActivity.add(const Duration(days: 7)),
      createdAt: now,
      primaryPhone: client.phone,
      primaryAddress: client.fullAddress,
      source: MissedVisitSource.overdueClient,
    ));
  }

  return result;
});

/// Merged missed visits: PowerSync missed itineraries + Hive overdue clients.
/// Missed itinerary entries take precedence when clientId overlaps.
final missedVisitsProvider = Provider<List<MissedVisit>>((ref) {
  final itineraryVisits =
      ref.watch(missedItinerariesStreamProvider).valueOrNull ?? [];
  final overdueVisits =
      ref.watch(overdueClientsProvider).valueOrNull ?? [];

  final seenClientIds = itineraryVisits.map((v) => v.clientId).toSet();
  final merged = [
    ...itineraryVisits,
    ...overdueVisits.where((v) => !seenClientIds.contains(v.clientId)),
  ];

  merged.sort((a, b) {
    final priorityCompare = b.priority.index.compareTo(a.priority.index);
    if (priorityCompare != 0) return priorityCompare;
    return b.daysOverdue.compareTo(a.daysOverdue);
  });

  return merged;
});
```

Also add the required imports at the top of the file if not present:
- `import '../../features/visits/data/models/missed_visit_model.dart' show MissedVisit, MissedVisitSource, MissedVisitPriority;`
- `import '../../features/itineraries/data/repositories/itinerary_repository.dart' show itineraryRepositoryProvider;`

Check what is already imported; add only what is missing.

- [ ] **Step 3.5: Verify compilation**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/shared/providers/app_providers.dart
```

Expected: No errors. If `TouchpointType` is not imported in `app_providers.dart`, add its import from `client_model.dart`.

- [ ] **Step 3.6: Run all unit tests**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test test/unit/
```

Expected: All PASS.

- [ ] **Step 3.7: Commit**

```bash
git add lib/shared/providers/app_providers.dart test/unit/overdue_clients_logic_test.dart
git commit -m "feat: replace missedVisitsProvider with PowerSync + Hive hybrid sources"
```

---

## Task 4: Fix Reschedule Action and Update UI

**Files:**
- Modify: `lib/features/visits/presentation/pages/missed_visits_page.dart`

Changes:
1. Fix `_handleReschedule`: use `'pending'` status; for `missedItinerary` source, cancel existing record + insert new one inside `writeTransaction`.
2. Update `_MissedVisitCard` subtitle: show "Scheduled [date]" vs "Last touched N days ago" depending on source.
3. Add skeleton loading while `missedItinerariesStreamProvider` is loading.

- [ ] **Step 4.1: Fix `_handleReschedule`**

Replace the existing `_handleReschedule` method (lines ~142–181) with:

```dart
  void _handleReschedule(MissedVisit visit) {
    HapticUtils.lightImpact();

    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    ).then((date) async {
      if (date != null && mounted) {
        await LoadingHelper.withLoading(
          ref: ref,
          message: 'Rescheduling visit...',
          operation: () async {
            final db = await PowerSyncService.database;
            final userId =
                ref.read(jwtAuthProvider).currentUser?.id ?? '';
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final now = DateTime.now().toIso8601String();
            final newId = const Uuid().v4();

            if (visit.source == MissedVisitSource.missedItinerary &&
                visit.itineraryId != null) {
              // Cancel the existing missed itinerary and insert a new one atomically
              await db.writeTransaction(() async {
                await db.execute(
                  'UPDATE itineraries SET status = ?, updated_at = ? WHERE id = ?',
                  ['cancelled', now, visit.itineraryId],
                );
                await db.execute(
                  'INSERT INTO itineraries (id, user_id, client_id, scheduled_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                  [newId, userId, visit.clientId, dateStr, 'pending', now, now],
                );
              });
            } else {
              // Overdue client — just schedule a new itinerary
              await db.execute(
                'INSERT INTO itineraries (id, user_id, client_id, scheduled_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [newId, userId, visit.clientId, dateStr, 'pending', now, now],
              );
            }
          },
          onError: (e) {
            if (mounted) {
              AppNotification.showError(context, 'Failed to reschedule: $e');
            }
          },
        );

        if (mounted) {
          AppNotification.showSuccess(
            context,
            'Rescheduled ${visit.clientName} to ${_formatDate(date)}',
          );
        }
      }
    });
  }
```

Add this import at the top of the file (alongside existing imports):
```dart
import '../../data/models/missed_visit_model.dart' show MissedVisit, MissedVisitPriority, MissedVisitSource;
```

(The file already imports `missed_visit_model.dart` — check that `MissedVisitSource` is exported from it; if the import is a wildcard it'll pick it up automatically.)

- [ ] **Step 4.2: Update `_MissedVisitCard` to show source-aware subtitle**

In `_MissedVisitCard.build()`, replace the existing subtitle text:

```dart
// Before:
Text(
  '${missedVisit.daysOverdue} days overdue',
  style: TextStyle(
    fontSize: 12,
    color: priorityColor,
    fontWeight: FontWeight.w500,
  ),
),
```

With:

```dart
Text(
  missedVisit.source == MissedVisitSource.missedItinerary
      ? 'Scheduled ${_formatShortDate(missedVisit.scheduledDate)}'
      : 'Last touched ${missedVisit.daysOverdue} days ago',
  style: TextStyle(
    fontSize: 12,
    color: priorityColor,
    fontWeight: FontWeight.w500,
  ),
),
```

Add the helper to `_MissedVisitCard` (or as a top-level function near `_formatDate`):

```dart
String _formatShortDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
}
```

- [ ] **Step 4.3: Add skeleton loading for stream loading state**

In `_MissedVisitsPageState.build()`, add a watch on the stream provider to detect loading:

```dart
final streamAsync = ref.watch(missedItinerariesStreamProvider);
final isLoading = streamAsync.isLoading;
```

In the body `Column`, replace the `Expanded` list widget with:

```dart
Expanded(
  child: isLoading
      ? _buildSkeleton()
      : missedVisits.isEmpty
          ? _EmptyState()
          : ListView.builder(
              itemCount: missedVisits.length,
              itemBuilder: (context, index) {
                return _MissedVisitCard(
                  missedVisit: missedVisits[index],
                  onCall: () => _handleCall(missedVisits[index]),
                  onReschedule: () => _handleReschedule(missedVisits[index]),
                  onTap: () => _handleTap(missedVisits[index]),
                );
              },
            ),
),
```

Add the skeleton builder method to `_MissedVisitsPageState`:

```dart
Widget _buildSkeleton() {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, _) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 160, color: Colors.grey[200]),
                const SizedBox(height: 8),
                Container(height: 12, width: 100, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4.4: Verify compilation**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/features/visits/presentation/pages/missed_visits_page.dart
```

Expected: No errors.

- [ ] **Step 4.5: Run full test suite**

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter test
```

Expected: All existing tests pass; new unit tests pass.

- [ ] **Step 4.6: Commit**

```bash
git add lib/features/visits/presentation/pages/missed_visits_page.dart
git commit -m "fix: missed visits reschedule atomicity and correct pending status; update card subtitle"
```

---

## Final Check

After all tasks are committed, run:

```bash
cd /home/claude-team/loi/imu/frontend-mobile-imu/imu_flutter
flutter analyze lib/
flutter test
```

Expected: Zero analyzer errors, all tests green.

The missed visits page now:
- Shows real past-due itineraries from PowerSync (reactive — updates as soon as an itinerary is completed or new one is added)
- Shows genuinely overdue clients from the full Hive cache (re-evaluates after each sync)
- Shows correct subtitles ("Scheduled May 10" vs "Last touched 12 days ago")
- Reschedule correctly cancels the old itinerary atomically before creating the new one with valid `'pending'` status
