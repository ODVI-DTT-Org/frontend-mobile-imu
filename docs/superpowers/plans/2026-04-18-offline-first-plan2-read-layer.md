# Offline-First Plan 2: Read Layer Refactor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all REST GET calls for agent-owned data with local PowerSync SQLite queries so the app reads zero network data after initial sync.

**Architecture:** Each feature gets a repository that queries the local SQLite database via `PowerSyncService`. Models get a `fromRow()` factory to parse SQLite results. Riverpod providers are updated or created to use the repositories instead of API services. API service GET methods are deleted once replaced.

**Tech Stack:** Flutter/Dart, PowerSync SQLite (`db.getAll()` / `db.watch()`), Riverpod, existing feature-based directory structure.

**Spec:** `docs/superpowers/specs/2026-04-18-offline-first-architecture-design.md`

---

## File Map

| File | Change |
|---|---|
| `imu_flutter/lib/features/visits/data/models/visit_model.dart` | CREATE — typed `Visit` model with `fromRow()` |
| `imu_flutter/lib/features/visits/data/repositories/visit_repository.dart` | CREATE — queries visits from SQLite |
| `imu_flutter/lib/features/attendance/data/models/attendance_record.dart` | MODIFY — add `fromRow()` factory |
| `imu_flutter/lib/features/attendance/data/repositories/attendance_repository.dart` | CREATE — queries attendance from SQLite |
| `imu_flutter/lib/features/groups/data/models/group_model.dart` | MODIFY — replace re-export stub with real `ClientGroup.fromRow()` |
| `imu_flutter/lib/features/groups/data/repositories/group_repository.dart` | CREATE — queries groups from SQLite |
| `imu_flutter/lib/features/targets/data/models/target_model.dart` | MODIFY — add `fromRow()` factory |
| `imu_flutter/lib/features/targets/data/repositories/target_repository.dart` | CREATE — queries targets from SQLite |
| `imu_flutter/lib/features/my_day/data/models/my_day_client.dart` | MODIFY — add `fromRow()` factory (JOIN of itineraries + clients) |
| `imu_flutter/lib/features/my_day/data/repositories/my_day_repository.dart` | CREATE — queries itineraries+clients JOIN from SQLite |
| `imu_flutter/lib/shared/providers/app_providers.dart` | MODIFY — add providers for new repositories |
| `imu_flutter/lib/services/api/attendance_api_service.dart` | MODIFY — delete `getTodayAttendance()` and `getAttendanceHistory()` |
| `imu_flutter/lib/services/api/groups_api_service.dart` | MODIFY — delete `fetchGroups()` and `fetchGroup()` |
| `imu_flutter/lib/services/api/targets_api_service.dart` | MODIFY — delete all GET methods |
| `imu_flutter/lib/services/api/my_day_api_service.dart` | MODIFY — delete `fetchMyDayClients()`, `fetchTodayTasks()`, `isInMyDay()` |
| `imu_flutter/lib/services/api/visit_api_service.dart` | MODIFY — delete `getVisitsByClientId()` |

---

## Task 1: Create Visit model

**Files:**
- Create: `imu_flutter/lib/features/visits/data/models/visit_model.dart`

- [ ] **Step 1: Create the file**

```dart
// imu_flutter/lib/features/visits/data/models/visit_model.dart

class Visit {
  final String id;
  final String clientId;
  final String userId;
  final String type; // 'regular_visit' | 'release_loan'
  final String? odometerArrival;
  final String? odometerDeparture;
  final String? photoUrl;
  final String? notes;
  final String? reason;
  final String? status;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? source; // 'IMU' | 'CMS'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Visit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.type,
    this.odometerArrival,
    this.odometerDeparture,
    this.photoUrl,
    this.notes,
    this.reason,
    this.status,
    this.address,
    this.latitude,
    this.longitude,
    this.timeIn,
    this.timeOut,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReleaseVisit => type == 'release_loan';
  bool get isCmsRecord => source == 'CMS';

  factory Visit.fromRow(Map<String, dynamic> row) {
    return Visit(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      type: row['type'] as String? ?? 'regular_visit',
      odometerArrival: row['odometer_arrival'] as String?,
      odometerDeparture: row['odometer_departure'] as String?,
      photoUrl: row['photo_url'] as String?,
      notes: row['notes'] as String?,
      reason: row['reason'] as String?,
      status: row['status'] as String?,
      address: row['address'] as String?,
      latitude: row['latitude'] != null ? (row['latitude'] as num).toDouble() : null,
      longitude: row['longitude'] != null ? (row['longitude'] as num).toDouble() : null,
      timeIn: row['time_in'] != null ? DateTime.tryParse(row['time_in'] as String) : null,
      timeOut: row['time_out'] != null ? DateTime.tryParse(row['time_out'] as String) : null,
      source: row['source'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/visits/data/models/visit_model.dart
git commit -m "feat: add Visit model with fromRow() for PowerSync SQLite"
```

---

## Task 2: Create VisitRepository

**Files:**
- Create: `imu_flutter/lib/features/visits/data/repositories/visit_repository.dart`

- [ ] **Step 1: Create the file**

```dart
// imu_flutter/lib/features/visits/data/repositories/visit_repository.dart

import 'package:imu_flutter/features/visits/data/models/visit_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class VisitRepository {
  /// All visits for a given client, newest first.
  Stream<List<Visit>> watchByClientId(String clientId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM visits WHERE client_id = ? ORDER BY created_at DESC',
        parameters: [clientId],
      ).map((rows) => rows.map(Visit.fromRow).toList());
    });
  }

  Future<List<Visit>> getByClientId(String clientId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM visits WHERE client_id = ? ORDER BY created_at DESC',
      [clientId],
    );
    return rows.map(Visit.fromRow).toList();
  }

  /// Only IMU-source visits (created in the mobile app).
  Future<List<Visit>> getImuVisitsByClientId(String clientId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "SELECT * FROM visits WHERE client_id = ? AND source = 'IMU' ORDER BY created_at DESC",
      [clientId],
    );
    return rows.map(Visit.fromRow).toList();
  }

  /// Only CMS-source visits (imported from legacy system).
  Future<List<Visit>> getCmsVisitsByClientId(String clientId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "SELECT * FROM visits WHERE client_id = ? AND source = 'CMS' ORDER BY created_at DESC",
      [clientId],
    );
    return rows.map(Visit.fromRow).toList();
  }

  Future<Visit?> getById(String id) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll('SELECT * FROM visits WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Visit.fromRow(rows.first);
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/visits/data/repositories/visit_repository.dart
git commit -m "feat: add VisitRepository querying local PowerSync SQLite"
```

---

## Task 3: Add `fromRow()` to AttendanceRecord + create AttendanceRepository

**Files:**
- Modify: `imu_flutter/lib/features/attendance/data/models/attendance_record.dart`
- Create: `imu_flutter/lib/features/attendance/data/repositories/attendance_repository.dart`

- [ ] **Step 1: Add `fromRow()` to AttendanceRecord**

In `attendance_record.dart`, add this factory after `fromJson()`:

```dart
  factory AttendanceRecord.fromRow(Map<String, dynamic> row) {
    DateTime? checkInTime;
    DateTime? checkOutTime;

    if (row['time_in'] != null) {
      checkInTime = DateTime.tryParse(row['time_in'] as String);
    }
    if (row['time_out'] != null) {
      checkOutTime = DateTime.tryParse(row['time_out'] as String);
    }

    final inLat = row['location_in_lat'] != null ? (row['location_in_lat'] as num).toDouble() : null;
    final inLng = row['location_in_lng'] != null ? (row['location_in_lng'] as num).toDouble() : null;
    final outLat = row['location_out_lat'] != null ? (row['location_out_lat'] as num).toDouble() : null;
    final outLng = row['location_out_lng'] != null ? (row['location_out_lng'] as num).toDouble() : null;

    AttendanceStatus status;
    if (checkInTime != null && checkOutTime != null) {
      status = AttendanceStatus.checkedOut;
    } else if (checkInTime != null) {
      status = AttendanceStatus.checkedIn;
    } else {
      status = AttendanceStatus.absent;
    }

    return AttendanceRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      date: DateTime.parse(row['date'] as String),
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      checkInLocation: (inLat != null && inLng != null)
          ? AttendanceLocation(
              latitude: inLat,
              longitude: inLng,
              timestamp: checkInTime ?? DateTime.now(),
            )
          : null,
      checkOutLocation: (outLat != null && outLng != null)
          ? AttendanceLocation(
              latitude: outLat,
              longitude: outLng,
              timestamp: checkOutTime ?? DateTime.now(),
            )
          : null,
      status: status,
    );
  }
```

- [ ] **Step 2: Create AttendanceRepository**

```dart
// imu_flutter/lib/features/attendance/data/repositories/attendance_repository.dart

import 'package:imu_flutter/features/attendance/data/models/attendance_record.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class AttendanceRepository {
  /// Today's attendance record for the given user, or null if not checked in.
  Future<AttendanceRecord?> getTodayAttendance(String userId) async {
    final db = await PowerSyncService.database;
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final rows = await db.getAll(
      'SELECT * FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, today],
    );
    if (rows.isEmpty) return null;
    return AttendanceRecord.fromRow(rows.first);
  }

  /// Stream of today's attendance — updates in real time when synced.
  Stream<AttendanceRecord?> watchTodayAttendance(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
        parameters: [userId, today],
      ).map((rows) => rows.isEmpty ? null : AttendanceRecord.fromRow(rows.first));
    });
  }

  /// Attendance history for the user, newest first.
  Future<List<AttendanceRecord>> getHistory(String userId, {int limit = 30}) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM attendance WHERE user_id = ? ORDER BY date DESC LIMIT ?',
      [userId, limit],
    );
    return rows.map(AttendanceRecord.fromRow).toList();
  }

  Stream<List<AttendanceRecord>> watchHistory(String userId, {int limit = 30}) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM attendance WHERE user_id = ? ORDER BY date DESC LIMIT ?',
        parameters: [userId, limit],
      ).map((rows) => rows.map(AttendanceRecord.fromRow).toList());
    });
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/attendance/data/models/attendance_record.dart \
        imu_flutter/lib/features/attendance/data/repositories/attendance_repository.dart
git commit -m "feat: add AttendanceRecord.fromRow() and AttendanceRepository"
```

---

## Task 4: Create proper ClientGroup model + GroupRepository

The current `group_model.dart` is just a re-export stub. Replace it with a real model.

**Files:**
- Modify: `imu_flutter/lib/features/groups/data/models/group_model.dart`
- Create: `imu_flutter/lib/features/groups/data/repositories/group_repository.dart`

- [ ] **Step 1: Replace group_model.dart with real model**

Replace the entire content of `features/groups/data/models/group_model.dart` with:

```dart
// imu_flutter/lib/features/groups/data/models/group_model.dart

class ClientGroup {
  final String id;
  final String name;
  final String? description;
  final String? areaManagerId;
  final String? assistantAreaManagerId;
  final String? caravanId;
  final DateTime createdAt;

  const ClientGroup({
    required this.id,
    required this.name,
    this.description,
    this.areaManagerId,
    this.assistantAreaManagerId,
    this.caravanId,
    required this.createdAt,
  });

  factory ClientGroup.fromRow(Map<String, dynamic> row) {
    return ClientGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      areaManagerId: row['area_manager_id'] as String?,
      assistantAreaManagerId: row['assistant_area_manager_id'] as String?,
      caravanId: row['caravan_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  factory ClientGroup.fromJson(Map<String, dynamic> json) {
    return ClientGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      areaManagerId: json['area_manager_id'] as String?,
      assistantAreaManagerId: json['assistant_area_manager_id'] as String?,
      caravanId: json['caravan_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
```

- [ ] **Step 2: Create GroupRepository**

```dart
// imu_flutter/lib/features/groups/data/repositories/group_repository.dart

import 'package:imu_flutter/features/groups/data/models/group_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class GroupRepository {
  /// All groups where this agent is the caravan.
  Stream<List<ClientGroup>> watchGroups(String userId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM groups WHERE caravan_id = ? ORDER BY name ASC',
        parameters: [userId],
      ).map((rows) => rows.map(ClientGroup.fromRow).toList());
    });
  }

  Future<List<ClientGroup>> getGroups(String userId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM groups WHERE caravan_id = ? ORDER BY name ASC',
      [userId],
    );
    return rows.map(ClientGroup.fromRow).toList();
  }

  Future<ClientGroup?> getById(String id) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll('SELECT * FROM groups WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return ClientGroup.fromRow(rows.first);
  }
}
```

- [ ] **Step 3: Update any import of the old re-export**

Search for any imports of `groups_api_service.dart` that were pulling `ClientGroup`:

```bash
cd frontend-mobile-imu
grep -r "groups_api_service" imu_flutter/lib --include="*.dart" -l
```

For each file found, change:
```dart
import 'package:imu_flutter/services/api/groups_api_service.dart' show ClientGroup;
```
to:
```dart
import 'package:imu_flutter/features/groups/data/models/group_model.dart';
```

- [ ] **Step 4: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/groups/data/models/group_model.dart \
        imu_flutter/lib/features/groups/data/repositories/group_repository.dart
git commit -m "feat: add proper ClientGroup model and GroupRepository"
```

---

## Task 5: Add `fromRow()` to Target model + create TargetRepository

The existing `Target` model in `target_model.dart` uses `periodStart`/`periodEnd` datetime objects that don't map directly to the SQLite schema. We need a `fromRow()` that maps the actual DB columns (`period`, `year`, `month`, `quarter`, `week`, `target_clients`, etc.).

**Files:**
- Modify: `imu_flutter/lib/features/targets/data/models/target_model.dart`
- Create: `imu_flutter/lib/features/targets/data/repositories/target_repository.dart`

- [ ] **Step 1: Add `fromRow()` to target_model.dart**

Add this factory after the existing `fromJson()` in `target_model.dart`:

```dart
  factory Target.fromRow(Map<String, dynamic> row) {
    final period = TargetPeriod.values.firstWhere(
      (e) => e.name == (row['period'] as String? ?? 'monthly'),
      orElse: () => TargetPeriod.monthly,
    );
    final year = (row['year'] as num).toInt();
    final month = row['month'] != null ? (row['month'] as num).toInt() : DateTime.now().month;

    // Compute periodStart/periodEnd from year/month for compatibility with existing UI
    final periodStart = DateTime(year, month, 1);
    final periodEnd = DateTime(year, month + 1, 0); // last day of month

    return Target(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      periodStart: periodStart,
      periodEnd: periodEnd,
      period: period,
      clientVisitsTarget: (row['target_visits'] as num?)?.toInt() ?? 0,
      touchpointsTarget: (row['target_touchpoints'] as num?)?.toInt() ?? 0,
      newClientsTarget: (row['target_clients'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.tryParse(row['updated_at'] as String)
          : null,
    );
  }
```

- [ ] **Step 2: Create TargetRepository**

```dart
// imu_flutter/lib/features/targets/data/repositories/target_repository.dart

import 'package:imu_flutter/features/targets/data/models/target_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class TargetRepository {
  /// Current month's target for the given user.
  Future<Target?> getCurrentMonthTarget(String userId) async {
    final now = DateTime.now();
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "SELECT * FROM targets WHERE user_id = ? AND period = 'monthly' AND year = ? AND month = ? LIMIT 1",
      [userId, now.year, now.month],
    );
    if (rows.isEmpty) return null;
    return Target.fromRow(rows.first);
  }

  Stream<Target?> watchCurrentMonthTarget(String userId) {
    final now = DateTime.now();
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        "SELECT * FROM targets WHERE user_id = ? AND period = 'monthly' AND year = ? AND month = ? LIMIT 1",
        parameters: [userId, now.year, now.month],
      ).map((rows) => rows.isEmpty ? null : Target.fromRow(rows.first));
    });
  }

  Future<List<Target>> getAllTargets(String userId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM targets WHERE user_id = ? ORDER BY year DESC, month DESC',
      [userId],
    );
    return rows.map(Target.fromRow).toList();
  }

  Stream<List<Target>> watchAllTargets(String userId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM targets WHERE user_id = ? ORDER BY year DESC, month DESC',
        parameters: [userId],
      ).map((rows) => rows.map(Target.fromRow).toList());
    });
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/targets/data/models/target_model.dart \
        imu_flutter/lib/features/targets/data/repositories/target_repository.dart
git commit -m "feat: add Target.fromRow() and TargetRepository"
```

---

## Task 6: Add `fromRow()` to MyDayClient + create MyDayRepository

**Files:**
- Modify: `imu_flutter/lib/features/my_day/data/models/my_day_client.dart`
- Create: `imu_flutter/lib/features/my_day/data/repositories/my_day_repository.dart`

- [ ] **Step 1: Add `fromRow()` to MyDayClient**

Add this factory after `fromJson()` in `my_day_client.dart`. The row comes from a JOIN of `itineraries` + `clients`:

```dart
  /// Constructs from a row returned by:
  /// SELECT i.*, c.first_name, c.last_name, c.agency_name,
  ///        c.municipality, c.touchpoint_number, c.next_touchpoint,
  ///        c.touchpoint_summary
  /// FROM itineraries i JOIN clients c ON c.id = i.client_id
  /// WHERE i.user_id = ? AND DATE(i.scheduled_date) = ?
  factory MyDayClient.fromRow(Map<String, dynamic> row) {
    final firstName = row['first_name'] as String? ?? '';
    final lastName = row['last_name'] as String? ?? '';
    final fullName = '$firstName $lastName'.trim();
    final touchpointNumber = (row['touchpoint_number'] as num?)?.toInt() ?? 1;
    final nextTouchpoint = row['next_touchpoint'] as String? ?? 'Visit';

    return MyDayClient(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      fullName: fullName,
      agencyName: row['agency_name'] as String?,
      location: row['municipality'] as String?,
      touchpointNumber: touchpointNumber,
      touchpointType: nextTouchpoint.toLowerCase(),
      isTimeIn: row['time_in'] != null,
      priority: row['priority'] as String? ?? 'normal',
      notes: row['notes'] as String?,
      status: row['status'] as String?,
      scheduledTime: row['scheduled_time'] as String?,
      nextTouchpointNumber: touchpointNumber,
      nextTouchpointType: nextTouchpoint,
    );
  }
```

- [ ] **Step 2: Create MyDayRepository**

```dart
// imu_flutter/lib/features/my_day/data/repositories/my_day_repository.dart

import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class MyDayRepository {
  static const String _joinSql = '''
    SELECT i.id, i.client_id, i.scheduled_date, i.scheduled_time,
           i.status, i.priority, i.notes, i.time_in, i.time_out,
           c.first_name, c.last_name, c.agency_name, c.municipality,
           c.touchpoint_number, c.next_touchpoint
    FROM itineraries i
    JOIN clients c ON c.id = i.client_id
  ''';

  /// Stream of today's My Day clients for this user, ordered by scheduled time.
  Stream<List<MyDayClient>> watchTodayClients(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        '$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? AND i.status != ? ORDER BY i.scheduled_time ASC',
        parameters: [userId, today, 'cancelled'],
      ).map((rows) => rows.map(MyDayClient.fromRow).toList());
    });
  }

  Future<List<MyDayClient>> getTodayClients(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      '$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? AND i.status != ? ORDER BY i.scheduled_time ASC',
      [userId, today, 'cancelled'],
    );
    return rows.map(MyDayClient.fromRow).toList();
  }

  Future<List<MyDayClient>> getClientsByDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      '$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? ORDER BY i.scheduled_time ASC',
      [userId, dateStr],
    );
    return rows.map(MyDayClient.fromRow).toList();
  }

  /// Returns true if the client has an itinerary entry for today.
  Future<bool> isInMyDay(String userId, String clientId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT id FROM itineraries WHERE user_id = ? AND client_id = ? AND DATE(scheduled_date) = ? AND status != ? LIMIT 1',
      [userId, clientId, today, 'cancelled'],
    );
    return rows.isNotEmpty;
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/features/my_day/data/models/my_day_client.dart \
        imu_flutter/lib/features/my_day/data/repositories/my_day_repository.dart
git commit -m "feat: add MyDayClient.fromRow() and MyDayRepository for local SQLite"
```

---

## Task 7: Create Riverpod providers for new repositories

**Files:**
- Modify: `imu_flutter/lib/shared/providers/app_providers.dart`

- [ ] **Step 1: Find the current userId provider pattern**

Run to see what the current app_providers.dart exports:

```bash
grep -n "Provider\|userId\|user_id\|userProfile" \
  imu_flutter/lib/shared/providers/app_providers.dart | head -30
```

- [ ] **Step 2: Add repository providers and userId helper**

Add the following to `app_providers.dart` (after existing provider imports):

```dart
import 'package:imu_flutter/features/visits/data/repositories/visit_repository.dart';
import 'package:imu_flutter/features/attendance/data/repositories/attendance_repository.dart';
import 'package:imu_flutter/features/groups/data/repositories/group_repository.dart';
import 'package:imu_flutter/features/targets/data/repositories/target_repository.dart';
import 'package:imu_flutter/features/my_day/data/repositories/my_day_repository.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

// ── Repository providers ─────────────────────────────────────────────────────

final visitRepositoryProvider = Provider<VisitRepository>((_) => VisitRepository());
final attendanceRepositoryProvider = Provider<AttendanceRepository>((_) => AttendanceRepository());
final groupRepositoryProvider = Provider<GroupRepository>((_) => GroupRepository());
final targetRepositoryProvider = Provider<TargetRepository>((_) => TargetRepository());
final myDayRepositoryProvider = Provider<MyDayRepository>((_) => MyDayRepository());

// ── Current user ID from PowerSync user_profiles ─────────────────────────────

final currentUserIdProvider = FutureProvider<String?>((ref) async {
  final db = await PowerSyncService.database;
  final rows = await db.getAll('SELECT user_id FROM user_profiles LIMIT 1');
  if (rows.isEmpty) return null;
  return rows.first['user_id'] as String?;
});

// ── Today's attendance ────────────────────────────────────────────────────────

final todayAttendanceProvider = StreamProvider((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) { yield null; return; }
  final repo = ref.watch(attendanceRepositoryProvider);
  yield* repo.watchTodayAttendance(userId);
});

// ── Attendance history ────────────────────────────────────────────────────────

final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) return [];
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getHistory(userId);
});

// ── Groups ────────────────────────────────────────────────────────────────────

final groupsProvider = StreamProvider((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) { yield <ClientGroup>[]; return; }
  final repo = ref.watch(groupRepositoryProvider);
  yield* repo.watchGroups(userId);
});

// ── Current month target ──────────────────────────────────────────────────────

final currentMonthTargetProvider = StreamProvider((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) { yield null; return; }
  final repo = ref.watch(targetRepositoryProvider);
  yield* repo.watchCurrentMonthTarget(userId);
});

// ── My Day clients (today) ────────────────────────────────────────────────────

final myDayClientsProvider = StreamProvider((ref) async* {
  final userId = await ref.watch(currentUserIdProvider.future);
  if (userId == null) { yield <MyDayClient>[]; return; }
  final repo = ref.watch(myDayRepositoryProvider);
  yield* repo.watchTodayClients(userId);
});

// ── Visits by client ─────────────────────────────────────────────────────────

final visitsByClientProvider = StreamProvider.family<List<Visit>, String>((ref, clientId) {
  final repo = ref.watch(visitRepositoryProvider);
  return repo.watchByClientId(clientId);
});
```

- [ ] **Step 3: Add missing imports to app_providers.dart**

Ensure these type imports are present at the top of the file (add any that are missing):

```dart
import 'package:imu_flutter/features/attendance/data/models/attendance_record.dart';
import 'package:imu_flutter/features/groups/data/models/group_model.dart';
import 'package:imu_flutter/features/targets/data/models/target_model.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/features/visits/data/models/visit_model.dart';
```

- [ ] **Step 4: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/shared/providers/app_providers.dart
git commit -m "feat: add Riverpod providers for visit, attendance, group, target, myDay repos"
```

---

## Task 8: Remove REST GET calls from API services

Now that repositories cover all local reads, delete the GET methods from API services so nothing accidentally calls the network for data we own.

**Files:**
- Modify: `imu_flutter/lib/services/api/visit_api_service.dart`
- Modify: `imu_flutter/lib/services/api/attendance_api_service.dart`
- Modify: `imu_flutter/lib/services/api/my_day_api_service.dart`
- Modify: `imu_flutter/lib/services/api/groups_api_service.dart`
- Modify: `imu_flutter/lib/services/api/targets_api_service.dart`

- [ ] **Step 1: Delete `getVisitsByClientId()` from visit_api_service.dart**

Find and delete the entire `getVisitsByClientId()` method. This is replaced by `VisitRepository.getByClientId()`.

Find any callers first:
```bash
grep -rn "getVisitsByClientId" imu_flutter/lib --include="*.dart"
```
Update each caller to use `ref.watch(visitsByClientProvider(clientId))` instead.

- [ ] **Step 2: Delete GET methods from attendance_api_service.dart**

Delete these two methods (keep `checkIn()` and `checkOut()` — those are writes):
- `getTodayAttendance()`
- `getAttendanceHistory()`

Find any callers:
```bash
grep -rn "getTodayAttendance\|getAttendanceHistory" imu_flutter/lib --include="*.dart"
```
Update each caller to use `ref.watch(todayAttendanceProvider)` or `ref.watch(attendanceHistoryProvider)`.

- [ ] **Step 3: Delete GET methods from my_day_api_service.dart**

Delete these methods (keep `addToMyDay()`, `removeFromMyDay()`, `setTimeIn()`, `setTimeOut()`, `completeVisit()` — those are writes):
- `fetchTodayTasks()`
- `fetchMyDayClients(date)`
- `isInMyDay(clientId)`
- `getTaskSummary()`

Find any callers:
```bash
grep -rn "fetchTodayTasks\|fetchMyDayClients\|isInMyDay\|getTaskSummary" imu_flutter/lib --include="*.dart"
```
Update each caller:
- `fetchMyDayClients(date)` → `ref.watch(myDayClientsProvider)` or `ref.read(myDayRepositoryProvider).getClientsByDate(userId, date)`
- `isInMyDay(clientId)` → `ref.read(myDayRepositoryProvider).isInMyDay(userId, clientId)`
- `fetchTodayTasks()` → `ref.watch(myDayClientsProvider)`

- [ ] **Step 4: Delete GET methods from groups_api_service.dart**

Delete:
- `fetchGroups()`
- `fetchGroup(id)`

Keep any POST/PUT/DELETE methods (write operations).

Find callers:
```bash
grep -rn "fetchGroups\|fetchGroup" imu_flutter/lib --include="*.dart"
```
Update each to use `ref.watch(groupsProvider)` or `ref.read(groupRepositoryProvider).getById(id)`.

- [ ] **Step 5: Delete GET methods from targets_api_service.dart**

Delete:
- `getCurrentMonthTarget(agentId)`
- `getTargetHistory(agentId)`
- `fetchTargets()`
- `fetchTarget(id)`
- `fetchTargetsByPeriod()`

Keep any POST/PUT methods.

Find callers:
```bash
grep -rn "getCurrentMonthTarget\|getTargetHistory\|fetchTargets\|fetchTarget\b" imu_flutter/lib --include="*.dart"
```
Update each to use `ref.watch(currentMonthTargetProvider)` or `ref.read(targetRepositoryProvider).getAllTargets(userId)`.

- [ ] **Step 6: Commit**

```bash
cd frontend-mobile-imu
git add imu_flutter/lib/services/api/
git commit -m "refactor: remove REST GET calls replaced by local PowerSync SQLite repos"
```

---

## Verification

After all tasks complete:

- [ ] Run `flutter analyze imu_flutter/lib` — zero errors expected
- [ ] Launch the app on a device/emulator
- [ ] Disable network (airplane mode) after initial sync
- [ ] Verify My Day screen loads client list offline
- [ ] Open a client detail — visit history shows (source may be CMS for existing records)
- [ ] Check Attendance screen — today's status shows without network
- [ ] Check Groups screen — groups load from local SQLite
- [ ] Check Targets screen — current month target shows offline
- [ ] Re-enable network — confirm data stays consistent (no duplicates, same counts)
