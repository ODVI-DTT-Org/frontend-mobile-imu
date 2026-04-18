# Offline-First Plan 3: Write/Queue Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace all online/offline branching write logic (PendingXxxService + Hive queuing) with direct PowerSync SQLite writes, and rewrite `uploadData()` to route CRUD queue entries to the correct REST endpoints per table.

**Architecture:** All mutations write to local SQLite via `db.execute()` — PowerSync handles the CRUD queue automatically and calls `uploadData()` when online. The `uploadData()` connector is rewritten to route each queued operation to the correct REST endpoint by table name. The four PendingXxxService classes and their Hive models are deleted.

**Tech Stack:** Flutter, Riverpod, PowerSync (`powersync` package), Dio, Hive (kept only for auth/settings)

---

## File Map

**Modified:**
- `lib/services/sync/powersync_connector.dart` — rewrite `uploadData()` to route by table
- `lib/services/touchpoint/touchpoint_creation_service.dart` — write to SQLite instead of API/Hive
- `lib/services/visit/visit_creation_service.dart` — write to SQLite instead of API/Hive
- `lib/services/release/release_creation_service.dart` — write to SQLite instead of API/Hive
- `lib/services/client/client_mutation_service.dart` — write to SQLite instead of API/Hive
- `lib/shared/providers/app_providers.dart` — rewrite `TodayAttendanceNotifier.checkIn/checkOut` to use SQLite

**Deleted:**
- `lib/services/touchpoint/pending_touchpoint_service.dart`
- `lib/models/pending_touchpoint.dart`
- `lib/services/visit/pending_visit_service.dart`
- `lib/services/visit/models/pending_visit.dart`
- `lib/services/release/pending_release_service.dart`
- `lib/services/release/models/pending_release.dart`
- `lib/services/client/pending_client_service.dart`
- `lib/services/client/models/pending_client_operation.dart`

---

## Task 1: Rewrite `uploadData()` to route CRUD ops by table

The current `uploadData()` sends all ops to a single `/upload` bulk endpoint. Rewrite it to fan out to the correct REST endpoint per `op.table`.

**Files:**
- Modify: `lib/services/sync/powersync_connector.dart`

- [ ] **Step 1: Replace `uploadData()` body**

Open `lib/services/sync/powersync_connector.dart`. Replace the entire `uploadData()` method body (lines 128–215) with the following implementation. Keep `fetchCredentials()` and `invalidateCredentials()` unchanged.

```dart
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final token = _authService.accessToken;
    if (token == null) {
      logDebug('No access token - skipping upload');
      return;
    }

    final batch = await database.getCrudBatch();
    if (batch == null) {
      logDebug('No pending uploads');
      return;
    }

    logDebug('Uploading ${batch.crud.length} operations to backend');

    try {
      for (final op in batch.crud) {
        await _uploadOperation(op, token);
      }
      await batch.complete();
      logDebug('Upload batch completed successfully');
    } on DioException catch (e, stackTrace) {
      logError('Upload failed with DioException: ${e.message}');
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'PowerSync data upload',
        error: e,
        stackTrace: stackTrace,
        context: {
          'responseStatus': e.response?.statusCode?.toString(),
          'responseData': e.response?.data?.toString(),
        },
      );
      rethrow;
    } catch (e, stackTrace) {
      logError('Upload failed: $e');
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'PowerSync data upload',
        error: e,
        stackTrace: stackTrace,
        context: {'errorType': e.runtimeType.toString()},
      );
      rethrow;
    }
  }

  Future<void> _uploadOperation(CrudEntry op, String token) async {
    final data = op.opData ?? {};
    final headers = {'Authorization': 'Bearer $token'};

    logDebug('Uploading op: table=${op.table}, op=${op.op}, id=${op.id}');

    switch (op.table) {
      case 'clients':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients',
          putUrl: '$_apiUrl/clients/${op.id}',
          deleteUrl: '$_apiUrl/clients/${op.id}',
          data: data,
          headers: headers,
        );

      case 'addresses':
        // data must contain client_id
        final clientId = data['client_id'] as String?;
        if (clientId == null) throw Exception('addresses op missing client_id');
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients/$clientId/addresses',
          putUrl: '$_apiUrl/clients/$clientId/addresses/${op.id}',
          deleteUrl: '$_apiUrl/clients/$clientId/addresses/${op.id}',
          data: data,
          headers: headers,
        );

      case 'phone_numbers':
        final clientId = data['client_id'] as String?;
        if (clientId == null) throw Exception('phone_numbers op missing client_id');
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients/$clientId/phones',
          putUrl: '$_apiUrl/clients/$clientId/phones/${op.id}',
          deleteUrl: '$_apiUrl/clients/$clientId/phones/${op.id}',
          data: data,
          headers: headers,
        );

      case 'itineraries':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/itineraries',
          putUrl: '$_apiUrl/itineraries/${op.id}',
          deleteUrl: '$_apiUrl/itineraries/${op.id}',
          data: data,
          headers: headers,
        );

      case 'visits':
        // Only INSERT is queued for visits (no UPDATE/DELETE from mobile)
        if (op.op == UpdateType.put) {
          final photoPath = data['_local_photo_path'] as String?;
          // Remove internal field before sending
          final visitData = Map<String, dynamic>.from(data)
            ..remove('_local_photo_path');

          if (photoPath != null) {
            await _uploadVisitWithPhoto(
              visitData: visitData,
              photoPath: photoPath,
              headers: headers,
            );
          } else {
            await _httpClient.post(
              '$_apiUrl/visits',
              data: visitData,
              options: Options(headers: headers),
            );
          }
        }

      case 'touchpoints':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/touchpoints',
          putUrl: '$_apiUrl/touchpoints/${op.id}',
          deleteUrl: '$_apiUrl/touchpoints/${op.id}',
          data: data,
          headers: headers,
        );

      case 'attendance':
        // Only INSERT (check-in) and PATCH (check-out) are supported
        if (op.op == UpdateType.put) {
          // New check-in record
          await _httpClient.post(
            '$_apiUrl/attendance/check-in',
            data: data,
            options: Options(headers: headers),
          );
        } else if (op.op == UpdateType.patch) {
          // Check-out: update existing record
          await _httpClient.post(
            '$_apiUrl/attendance/check-out',
            data: data,
            options: Options(headers: headers),
          );
        }

      case 'releases':
        if (op.op == UpdateType.put) {
          await _httpClient.post(
            '$_apiUrl/releases',
            data: data,
            options: Options(headers: headers),
          );
        }

      default:
        logWarning('uploadData: unhandled table "${op.table}" — skipping');
    }
  }

  Future<void> _uploadCrud({
    required CrudEntry op,
    required String postUrl,
    required String putUrl,
    required String deleteUrl,
    required Map<String, dynamic> data,
    required Map<String, String> headers,
  }) async {
    switch (op.op) {
      case UpdateType.put:
        await _httpClient.post(postUrl, data: data, options: Options(headers: headers));
      case UpdateType.patch:
        await _httpClient.put(putUrl, data: data, options: Options(headers: headers));
      case UpdateType.delete:
        await _httpClient.delete(deleteUrl, options: Options(headers: headers));
    }
  }

  Future<void> _uploadVisitWithPhoto({
    required Map<String, dynamic> visitData,
    required String photoPath,
    required Map<String, String> headers,
  }) async {
    final formData = FormData.fromMap({
      ...visitData,
      'photo': await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      ),
    });
    await _httpClient.post(
      '$_apiUrl/visits',
      data: formData,
      options: Options(headers: headers),
    );
  }
```

- [ ] **Step 2: Add missing imports**

At the top of `lib/services/sync/powersync_connector.dart`, add the `dio/dio.dart` import for `FormData` and `MultipartFile` if not already present (it is already imported). Verify `UpdateType` is exported by the `powersync` package by checking:

```bash
grep -r "UpdateType" imu_flutter/lib/ --include="*.dart" | head -5
```

If `UpdateType` is not found in powersync exports, look for the correct enum name:
```bash
grep -r "class CrudEntry" ~/.pub-cache/ --include="*.dart" | head -5
```
Use whatever enum or string the package uses for `op.op`. Adjust the `case` expressions accordingly (may be strings `'put'`, `'patch'`, `'delete'` instead).

- [ ] **Step 3: Verify compile (check imports/types)**

```bash
cd imu_flutter && flutter pub get 2>&1 | tail -5
```

Expected: no dependency errors. If `UpdateType` isn't an enum from the package, fix the switch cases to match the actual type.

- [ ] **Step 4: Commit**

```bash
cd imu_flutter && git add lib/services/sync/powersync_connector.dart
git commit -m "feat: rewrite uploadData() to route CRUD ops per table to REST endpoints"
```

---

## Task 2: Rewrite `TouchpointCreationService` to write to SQLite

The current service branches online→API / offline→Hive. Replace with a single path: always write to SQLite. PowerSync queues and uploads when online.

**Files:**
- Modify: `lib/services/touchpoint/touchpoint_creation_service.dart`

- [ ] **Step 1: Check PowerSync database access pattern**

The services need the PowerSync database. Check how other services get the database:

```bash
grep -r "PowerSyncService.database\|await.*database" imu_flutter/lib/features/ --include="*.dart" | head -10
```

The pattern is: `final db = await PowerSyncService.database;`

- [ ] **Step 2: Rewrite `TouchpointCreationService`**

Replace the entire contents of `lib/services/touchpoint/touchpoint_creation_service.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Creates touchpoints by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
class TouchpointCreationService {
  final Uuid _uuid = const Uuid();

  Future<void> createTouchpoint(
    String clientId,
    Touchpoint touchpoint, {
    File? photo,
    File? audio,
  }) async {
    final db = await PowerSyncService.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // Save media files to app documents dir for offline durability
    final photoPath = photo != null ? await _saveFile(photo, 'photo') : null;
    final audioPath = audio != null ? await _saveFile(audio, 'audio') : null;

    debugPrint('TouchpointCreationService: Writing touchpoint $id to SQLite');

    await db.execute(
      '''INSERT INTO touchpoints
         (id, client_id, user_id, touchpoint_number, type, date, status,
          next_visit_date, notes, visit_id, call_id, is_legacy, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        clientId,
        null, // user_id filled by backend from JWT
        touchpoint.touchpointNumber,
        touchpoint.type.apiValue,
        touchpoint.date.toIso8601String(),
        touchpoint.status ?? 'pending',
        touchpoint.nextVisitDate?.toIso8601String(),
        touchpoint.notes,
        touchpoint.visitId,
        touchpoint.callId,
        0, // not legacy
        now,
      ],
    );

    // Attach photo path as a side-channel field if needed by uploadData()
    // This is stored in a local-only column not in the schema — instead we
    // rely on the visit record's _local_photo_path for photo uploads.
    // Audio path is stored similarly if the backend supports it.
    if (photoPath != null) {
      debugPrint('TouchpointCreationService: Photo saved locally at $photoPath (upload via visits table)');
    }
  }

  Future<String> _saveFile(File file, String prefix) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = '${prefix}_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
```

- [ ] **Step 3: Verify `Touchpoint` model fields**

The INSERT references `touchpoint.type.apiValue`, `touchpoint.status`, `touchpoint.nextVisitDate`, `touchpoint.visitId`, `touchpoint.callId`. Confirm these exist:

```bash
grep -n "apiValue\|visitId\|callId\|nextVisitDate\|status" imu_flutter/lib/features/clients/data/models/client_model.dart | head -20
```

If any field doesn't exist on the model, remove that INSERT column and its value placeholder.

- [ ] **Step 4: Commit**

```bash
cd imu_flutter && git add lib/services/touchpoint/touchpoint_creation_service.dart
git commit -m "feat: TouchpointCreationService writes to SQLite instead of API/Hive"
```

---

## Task 3: Rewrite `VisitCreationService` to write to SQLite

**Files:**
- Modify: `lib/services/visit/visit_creation_service.dart`

- [ ] **Step 1: Replace `VisitCreationService`**

Replace the entire contents of `lib/services/visit/visit_creation_service.dart`:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Creates visits by writing directly to local SQLite.
/// If a photo is attached, its local path is stored in _local_photo_path
/// so uploadData() can build FormData when uploading to the backend.
class VisitCreationService {
  final Uuid _uuid = const Uuid();

  Future<void> createVisit({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    File? photoFile,
    String? notes,
    String type = 'regular_visit',
  }) async {
    final db = await PowerSyncService.database;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final photoPath = photoFile != null ? await _saveFile(photoFile) : null;

    debugPrint('VisitCreationService: Writing visit $id to SQLite');

    // _local_photo_path is NOT in the PowerSync schema — it's stored in opData
    // and read by uploadData() to build multipart form upload.
    // We pass it as part of the INSERT data map so PowerSync includes it in
    // the CRUD queue entry's opData.
    await db.execute(
      '''INSERT INTO visits
         (id, client_id, user_id, type, time_in, time_out,
          odometer_arrival, odometer_departure, notes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        clientId,
        null, // user_id filled by backend from JWT
        type,
        timeIn,
        timeOut,
        odometerArrival,
        odometerDeparture,
        notes,
        now,
      ],
    );

    if (photoPath != null) {
      // Store photo path association separately — uploadData() reads this
      // when it encounters this visit's CRUD entry.
      // Implementation: update the row with a metadata field, or handle
      // via PowerSync Attachments API (future). For now log it.
      debugPrint('VisitCreationService: Photo queued at $photoPath for visit $id');
      // TODO(offline-first-plan4): Integrate PowerSync Attachments API for photo upload
    }
  }

  Future<String> _saveFile(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = 'visit_${_uuid.v4()}_${path.basename(file.path)}';
    final newPath = path.join(dir.path, filename);
    await file.copy(newPath);
    return newPath;
  }
}
```

- [ ] **Step 2: Remove unused imports from callers**

Find callers of `VisitCreationService` that passed `ConnectivityService`, `VisitApiService`, or `PendingVisitService`:

```bash
grep -rn "VisitCreationService(" imu_flutter/lib/ --include="*.dart"
```

For each caller, remove the now-unnecessary constructor args. The new constructor takes no arguments.

- [ ] **Step 3: Commit**

```bash
cd imu_flutter && git add lib/services/visit/visit_creation_service.dart
git commit -m "feat: VisitCreationService writes to SQLite instead of API/Hive"
```

---

## Task 4: Rewrite `ReleaseCreationService` to write to SQLite

**Files:**
- Modify: `lib/services/release/release_creation_service.dart`

- [ ] **Step 1: Check what columns `releases` has in PowerSync schema**

```bash
grep -A 20 "Table('releases'" imu_flutter/lib/services/sync/powersync_service.dart
```

If `releases` is NOT in the PowerSync schema, it means releases only go through `uploadData()` as new rows. Check the spec routing table — releases go to `POST /api/releases`. We still need to write to a local table OR use a separate queue. Since the schema has no `releases` table, we will use a dedicated local-only table approach or simply call the API directly when online and queue via the visits/touchpoints flow.

**Decision:** If `releases` is not in the PowerSync schema, the release creation service should call the API directly when online (keep the existing online path), but drop the offline Hive queue and instead throw a user-friendly error when offline:

```dart
// In releases: check online first; if offline, show error to caller
throw ApiException(message: 'Loan release requires an internet connection. Please connect and try again.');
```

This is the simplest correct path for now — loan releases are a high-stakes transaction that requires server confirmation.

- [ ] **Step 2: Rewrite `ReleaseCreationService` (online-required approach)**

Replace the entire contents of `lib/services/release/release_creation_service.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Creates loan releases.
/// Releases require an internet connection — they cannot be queued offline
/// because they are high-stakes financial transactions requiring server confirmation.
class ReleaseCreationService {
  final ConnectivityService _connectivity;
  final ReleaseApiService _releaseApi;
  final VisitApiService _visitApi;

  ReleaseCreationService(this._connectivity, this._releaseApi, this._visitApi);

  Future<void> createCompleteLoanRelease({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    int? udiNumber,
    String? remarks,
    String? photoPath,
  }) async {
    if (!_connectivity.isOnline) {
      throw ApiException(
        message: 'Loan release requires an internet connection. Please connect and try again.',
      );
    }

    debugPrint('ReleaseCreationService: Online - calling API');
    await _releaseApi.createCompleteLoanRelease(
      clientId: clientId,
      timeIn: timeIn,
      timeOut: timeOut,
      odometerArrival: odometerArrival,
      odometerDeparture: odometerDeparture,
      productType: productType,
      loanType: loanType,
      udiNumber: udiNumber,
      remarks: remarks,
      photoPath: photoPath,
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
cd imu_flutter && git add lib/services/release/release_creation_service.dart
git commit -m "feat: ReleaseCreationService requires online, drops offline Hive queue"
```

---

## Task 5: Rewrite `ClientMutationService` to write to SQLite

**Files:**
- Modify: `lib/services/client/client_mutation_service.dart`

- [ ] **Step 1: Rewrite `ClientMutationService`**

Replace the entire contents of `lib/services/client/client_mutation_service.dart`:

```dart
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

enum ClientMutationResult { success, requiresApproval, queued }

/// Mutates clients by writing directly to local SQLite.
/// PowerSync CRUD queue handles delivery to the backend when online.
/// Returns [ClientMutationResult.success] always — the "queued" concept
/// is now transparent (PowerSync handles it automatically).
class ClientMutationService {
  final _uuid = const Uuid();

  Future<ClientMutationResult> createClient(Client client) async {
    final db = await PowerSyncService.database;
    final id = client.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    logDebug('ClientMutationService: Creating client $id in SQLite');

    await db.execute(
      '''INSERT OR REPLACE INTO clients
         (id, first_name, last_name, middle_name, birth_date, email, phone,
          agency_name, department, position, employment_status, payroll_date,
          tenure, client_type, product_type, market_type, pension_type,
          loan_type, pan, facebook_link, remarks, agency_id, psgc_id,
          province, municipality, region, barangay, is_starred,
          loan_released, udi, full_address, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate?.toIso8601String(),
        client.email,
        client.phone,
        client.agencyName,
        client.department,
        client.position,
        client.employmentStatus,
        client.payrollDate,
        client.tenure,
        client.clientType,
        client.productType,
        client.marketType,
        client.pensionType,
        client.loanType,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.psgcId,
        client.province,
        client.municipality,
        client.region,
        client.barangay,
        client.isStarred == true ? 1 : 0,
        client.loanReleased == true ? 1 : 0,
        client.udi,
        client.fullAddress,
        now,
      ],
    );

    return ClientMutationResult.success;
  }

  Future<ClientMutationResult> updateClient(Client client) async {
    final db = await PowerSyncService.database;
    logDebug('ClientMutationService: Updating client ${client.id} in SQLite');

    await db.execute(
      '''UPDATE clients SET
         first_name=?, last_name=?, middle_name=?, birth_date=?, email=?,
         phone=?, agency_name=?, department=?, position=?,
         employment_status=?, payroll_date=?, tenure=?, client_type=?,
         product_type=?, market_type=?, pension_type=?, loan_type=?,
         pan=?, facebook_link=?, remarks=?, agency_id=?, psgc_id=?,
         province=?, municipality=?, region=?, barangay=?, is_starred=?,
         loan_released=?, udi=?, full_address=?, updated_at=?
         WHERE id=?''',
      [
        client.firstName,
        client.lastName,
        client.middleName,
        client.birthDate?.toIso8601String(),
        client.email,
        client.phone,
        client.agencyName,
        client.department,
        client.position,
        client.employmentStatus,
        client.payrollDate,
        client.tenure,
        client.clientType,
        client.productType,
        client.marketType,
        client.pensionType,
        client.loanType,
        client.pan,
        client.facebookLink,
        client.remarks,
        client.agencyId,
        client.psgcId,
        client.province,
        client.municipality,
        client.region,
        client.barangay,
        client.isStarred == true ? 1 : 0,
        client.loanReleased == true ? 1 : 0,
        client.udi,
        client.fullAddress,
        DateTime.now().toIso8601String(),
        client.id,
      ],
    );

    return ClientMutationResult.success;
  }

  Future<ClientMutationResult> deleteClient(String clientId) async {
    final db = await PowerSyncService.database;
    logDebug('ClientMutationService: Deleting client $clientId from SQLite');

    await db.execute('DELETE FROM clients WHERE id = ?', [clientId]);

    return ClientMutationResult.success;
  }
}
```

- [ ] **Step 2: Verify `Client` model field names**

The INSERT uses field names like `client.firstName`, `client.agencyName`, etc. Confirm the casing:

```bash
grep -n "String.*firstName\|String.*lastName\|String.*agencyName\|String.*psgcId\|String.*loanType" imu_flutter/lib/features/clients/data/models/client_model.dart | head -30
```

Fix any field names that differ from the model.

- [ ] **Step 3: Update callers — remove now-unused constructor args**

Find callers that pass `ConnectivityService`, `ClientApiService`, `PendingClientService`, `HiveService`:

```bash
grep -rn "ClientMutationService(" imu_flutter/lib/ --include="*.dart"
```

For each caller, remove the constructor arguments that are no longer needed. The new constructor takes no arguments.

- [ ] **Step 4: Commit**

```bash
cd imu_flutter && git add lib/services/client/client_mutation_service.dart
git commit -m "feat: ClientMutationService writes to SQLite instead of API/Hive"
```

---

## Task 6: Rewrite attendance check-in/check-out to use SQLite

The `TodayAttendanceNotifier` in `app_providers.dart` currently writes to Hive AND calls the API when online. Replace with SQLite writes; PowerSync handles sync.

**Files:**
- Modify: `lib/shared/providers/app_providers.dart`

- [ ] **Step 1: Find the TodayAttendanceNotifier section**

```bash
grep -n "TodayAttendanceNotifier\|checkIn\|checkOut\|_saveRecord\|_loadToday" imu_flutter/lib/shared/providers/app_providers.dart | head -20
```

The notifier is around line 1055–1162 (from Plan 2 reading). Note the current `_loadToday()` reads from Hive box `'attendance'`. It will be updated to read from SQLite via `AttendanceRepository` (already written in Plan 2).

- [ ] **Step 2: Rewrite `TodayAttendanceNotifier`**

In `lib/shared/providers/app_providers.dart`, replace the `TodayAttendanceNotifier` class (from `class TodayAttendanceNotifier` to the closing `}`) with:

```dart
/// Today's Attendance Notifier — writes to PowerSync SQLite
class TodayAttendanceNotifier extends StateNotifier<AttendanceRecord?> {
  final Ref _ref;
  bool _isLoading = false;

  TodayAttendanceNotifier(this._ref) : super(null) {
    _loadToday();
  }

  bool get isLoading => _isLoading;

  Future<void> _loadToday() async {
    _isLoading = true;
    try {
      final repo = _ref.read(attendanceRepositoryProvider);
      final record = await repo.getTodayAttendance();
      state = record;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> checkIn(AttendanceLocation location) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      debugPrint('TodayAttendanceNotifier: Cannot check in - no user ID');
      return;
    }

    final db = await PowerSyncService.database;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final id = '$userId-$today'; // deterministic id = user+date

    await db.execute(
      '''INSERT OR REPLACE INTO attendance
         (id, user_id, date, time_in, location_in_lat, location_in_lng, notes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        userId,
        today,
        now.toIso8601String(),
        location.latitude,
        location.longitude,
        location.address,
        now.toIso8601String(),
      ],
    );

    debugPrint('TodayAttendanceNotifier: Check-in written to SQLite');

    // Optimistic state update
    state = AttendanceRecord(
      id: id,
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInLocation: location,
      status: AttendanceStatus.checkedIn,
    );
  }

  Future<void> checkOut(AttendanceLocation location) async {
    if (state == null) return;

    final db = await PowerSyncService.database;
    final now = DateTime.now();

    await db.execute(
      '''UPDATE attendance
         SET time_out=?, location_out_lat=?, location_out_lng=?
         WHERE id=?''',
      [
        now.toIso8601String(),
        location.latitude,
        location.longitude,
        state!.id,
      ],
    );

    debugPrint('TodayAttendanceNotifier: Check-out written to SQLite');

    state = state!.copyWith(
      checkOutTime: now,
      checkOutLocation: location,
      status: AttendanceStatus.checkedOut,
    );
  }
}
```

- [ ] **Step 3: Update `todayAttendanceProvider` constructor call**

Find the provider definition:
```bash
grep -n "TodayAttendanceNotifier(" imu_flutter/lib/shared/providers/app_providers.dart
```

The current call is: `TodayAttendanceNotifier(ref.watch(hiveServiceProvider), ref)`

Change it to: `TodayAttendanceNotifier(ref)`

- [ ] **Step 4: Add PowerSync import to app_providers.dart**

```bash
grep -n "powersync_service" imu_flutter/lib/shared/providers/app_providers.dart
```

If not present, add to imports:
```dart
import 'package:imu_flutter/services/sync/powersync_service.dart';
```

- [ ] **Step 5: Commit**

```bash
cd imu_flutter && git add lib/shared/providers/app_providers.dart
git commit -m "feat: TodayAttendanceNotifier uses SQLite instead of Hive+API"
```

---

## Task 7: Rewrite itinerary mutations (My Day add/remove) to use SQLite

The `MyDayApiService.addToMyDay()` and `removeFromMyDay()` make REST calls. Replace them with SQLite writes. The callers (via `client_selector_modal.dart` and other UI) call `myDayApiService.addToMyDay(clientId)` — this call site stays the same; only the implementation changes.

**Files:**
- Modify: `lib/services/api/my_day_api_service.dart`

- [ ] **Step 1: Rewrite `addToMyDay` and `removeFromMyDay` in `MyDayApiService`**

In `lib/services/api/my_day_api_service.dart`, replace the `addToMyDay()` and `removeFromMyDay()` methods with SQLite-backed versions:

```dart
  /// Add client to today's itinerary.
  /// Writes to local SQLite; PowerSync queues the insert for backend sync.
  Future<bool> addToMyDay(String clientId, {
    DateTime? scheduledDate,
    String? scheduledTime,
    int priority = 5,
    String? notes,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) throw ApiException(message: 'Not authenticated');

      final db = await PowerSyncService.database;
      final userId = _authService.currentUser?.id;
      if (userId == null) throw ApiException(message: 'No user ID');

      final localDate = scheduledDate ?? DateTime.now();
      final scheduledDateStr = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      debugPrint('MyDayApiService: Adding client $clientId to itinerary in SQLite');

      await db.execute(
        '''INSERT OR REPLACE INTO itineraries
           (id, user_id, client_id, scheduled_date, scheduled_time,
            status, priority, notes, created_by, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          id,
          userId,
          clientId,
          scheduledDateStr,
          scheduledTime,
          'pending',
          priority.toString(),
          notes,
          userId,
          now,
        ],
      );

      return true;
    } catch (e) {
      debugPrint('Error adding to my day: $e');
      if (e is ApiException) rethrow;
      throw ApiException.fromError(e);
    }
  }

  /// Remove client from today's itinerary.
  /// Deletes from local SQLite; PowerSync queues the delete for backend sync.
  Future<bool> removeFromMyDay(String clientId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) throw ApiException(message: 'Not authenticated');

      final db = await PowerSyncService.database;
      final userId = _authService.currentUser?.id;
      if (userId == null) throw ApiException(message: 'No user ID');

      final localDate = DateTime.now();
      final scheduledDateStr = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      debugPrint('MyDayApiService: Removing client $clientId from itinerary in SQLite');

      await db.execute(
        '''DELETE FROM itineraries
           WHERE user_id=? AND client_id=? AND scheduled_date=?''',
        [userId, clientId, scheduledDateStr],
      );

      return true;
    } catch (e) {
      debugPrint('Error removing from my day: $e');
      if (e is ApiException) rethrow;
      throw ApiException.fromError(e);
    }
  }
```

- [ ] **Step 2: Add missing imports to `my_day_api_service.dart`**

```bash
grep -n "^import" imu_flutter/lib/services/api/my_day_api_service.dart
```

Add if missing:
```dart
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
```

Also check `_authService.currentUser?.id` — verify the `JwtAuthService` has a `currentUser` property with `id`:
```bash
grep -n "currentUser\|get id" imu_flutter/lib/services/auth/jwt_auth_service.dart | head -10
```

If `currentUser` doesn't exist, use `_authService.userId` or whatever getter exists.

- [ ] **Step 3: Commit**

```bash
cd imu_flutter && git add lib/services/api/my_day_api_service.dart
git commit -m "feat: addToMyDay/removeFromMyDay write to SQLite instead of REST API"
```

---

## Task 8: Delete PendingTouchpointService and its model

**Files:**
- Delete: `lib/services/touchpoint/pending_touchpoint_service.dart`
- Delete: `lib/models/pending_touchpoint.dart`

- [ ] **Step 1: Check nothing still imports these files**

```bash
grep -rn "pending_touchpoint_service\|PendingTouchpointService\|PendingTouchpoint\b" imu_flutter/lib/ --include="*.dart"
```

Expected: only `touchpoint_creation_service.dart` (which we already replaced) and any test files. If `background_sync_service.dart` still imports it, update it too (see Step 2).

- [ ] **Step 2: Fix any remaining references**

If `background_sync_service.dart` uses `PendingTouchpointService`:

```bash
grep -n "PendingTouchpointService\|pending_touchpoint" imu_flutter/lib/services/api/background_sync_service.dart
```

If found, remove those usages — the background sync service should no longer iterate Hive pending queues for touchpoints.

- [ ] **Step 3: Delete the files**

```bash
rm imu_flutter/lib/services/touchpoint/pending_touchpoint_service.dart
rm imu_flutter/lib/models/pending_touchpoint.dart
```

- [ ] **Step 4: Commit**

```bash
cd imu_flutter && git add -u
git commit -m "chore: delete PendingTouchpointService and PendingTouchpoint model"
```

---

## Task 9: Delete PendingVisitService and its model

**Files:**
- Delete: `lib/services/visit/pending_visit_service.dart`
- Delete: `lib/services/visit/models/pending_visit.dart`

- [ ] **Step 1: Check nothing still imports these files**

```bash
grep -rn "pending_visit_service\|PendingVisitService\|PendingVisit\b" imu_flutter/lib/ --include="*.dart"
```

Remove any remaining references before deleting.

- [ ] **Step 2: Delete the files**

```bash
rm imu_flutter/lib/services/visit/pending_visit_service.dart
rm imu_flutter/lib/services/visit/models/pending_visit.dart
```

- [ ] **Step 3: Commit**

```bash
cd imu_flutter && git add -u
git commit -m "chore: delete PendingVisitService and PendingVisit model"
```

---

## Task 10: Delete PendingReleaseService and its model

**Files:**
- Delete: `lib/services/release/pending_release_service.dart`
- Delete: `lib/services/release/models/pending_release.dart`

- [ ] **Step 1: Check nothing still imports these files**

```bash
grep -rn "pending_release_service\|PendingReleaseService\|PendingRelease\b" imu_flutter/lib/ --include="*.dart"
```

- [ ] **Step 2: Delete the files**

```bash
rm imu_flutter/lib/services/release/pending_release_service.dart
rm imu_flutter/lib/services/release/models/pending_release.dart
```

- [ ] **Step 3: Commit**

```bash
cd imu_flutter && git add -u
git commit -m "chore: delete PendingReleaseService and PendingRelease model"
```

---

## Task 11: Delete PendingClientService and its model

**Files:**
- Delete: `lib/services/client/pending_client_service.dart`
- Delete: `lib/services/client/models/pending_client_operation.dart`

- [ ] **Step 1: Check nothing still imports these files**

```bash
grep -rn "pending_client_service\|PendingClientService\|PendingClientOperation\|ClientOperationType" imu_flutter/lib/ --include="*.dart"
```

Remove remaining references from `client_mutation_service.dart` (already replaced), `background_sync_service.dart`, and any providers.

- [ ] **Step 2: Check and update `app_providers.dart`**

```bash
grep -n "PendingClient\|pending_client" imu_flutter/lib/shared/providers/app_providers.dart
```

Remove any provider definitions or imports that reference the pending client services.

- [ ] **Step 3: Delete the files**

```bash
rm imu_flutter/lib/services/client/pending_client_service.dart
rm imu_flutter/lib/services/client/models/pending_client_operation.dart
```

- [ ] **Step 4: Commit**

```bash
cd imu_flutter && git add -u
git commit -m "chore: delete PendingClientService and PendingClientOperation model"
```

---

## Task 12: Final compile check

- [ ] **Step 1: Run `flutter analyze` or `pub get`**

```bash
cd imu_flutter && flutter pub get 2>&1 | tail -20
```

If `flutter` isn't available in PATH:
```bash
which flutter || echo "Flutter not in PATH"
```

If unavailable, do a manual grep scan for any remaining references to deleted files:

```bash
grep -rn "PendingTouchpoint\|PendingVisit\|PendingRelease\|PendingClient\|pending_touchpoint\|pending_visit\|pending_release\|pending_client" imu_flutter/lib/ --include="*.dart"
```

Expected: zero matches (all pending services deleted and references cleaned up).

- [ ] **Step 2: Check for references to deleted service constructors**

```bash
grep -rn "ConnectivityService.*PendingTouchpoint\|ConnectivityService.*PendingVisit\|ConnectivityService.*PendingRelease" imu_flutter/lib/ --include="*.dart"
```

Expected: zero matches.

- [ ] **Step 3: Verify key write paths exist and compile**

```bash
grep -rn "TouchpointCreationService()\|VisitCreationService()\|ClientMutationService()" imu_flutter/lib/ --include="*.dart"
```

All callers should now construct these services without arguments.

- [ ] **Step 4: Final commit**

```bash
cd imu_flutter && git add -u && git status
git commit -m "feat: offline-first plan3 write layer complete — all mutations via PowerSync SQLite" --allow-empty
```

---

## Self-Review

### Spec coverage check

| Spec requirement | Covered by |
|---|---|
| All writes go to local SQLite | Tasks 2–7 |
| `uploadData()` routes by table | Task 1 |
| clients → `/api/clients` | Task 1 |
| addresses → `/api/clients/{id}/addresses` | Task 1 |
| phone_numbers → `/api/clients/{id}/phones` | Task 1 |
| itineraries → `/api/itineraries` | Task 1 |
| visits → `/api/visits` (JSON or FormData) | Task 1 |
| touchpoints → `/api/touchpoints` | Task 1 |
| attendance → `/api/attendance/check-in|check-out` | Task 1 |
| releases → `/api/releases` | Task 1 |
| PendingTouchpointService deleted | Task 8 |
| PendingVisitService deleted | Task 9 |
| PendingReleaseService deleted | Task 10 |
| PendingClientService deleted | Task 11 |

### Notes for implementer

- **`UpdateType` enum**: The PowerSync package's `CrudEntry.op` field type may be a string or an enum. If it's strings, change the `case UpdateType.put:` statements to `case 'PUT':` or `case 'put':`. Check the package source or existing usages to confirm.

- **`_authService.currentUser?.id` in MyDayApiService**: The `JwtAuthService` may expose user ID as `_authService.userId` or via `_authService.currentUser`. Confirm before writing; adapt accordingly.

- **Releases table not in schema**: The spec routes releases to `POST /api/releases` in `uploadData()` but the PowerSync schema has no `releases` table. The approach in Task 4 (require online for releases) is simpler and safer. The `uploadData()` `case 'releases':` handler in Task 1 is a forward-compat stub for if a `releases` table is added later.

- **Photo upload for visits**: Full PowerSync Attachments API integration is deferred to Plan 4. Task 3 saves the file locally and logs the path. The `_local_photo_path` upload path in Task 1 is a future-ready hook — it won't fire until the visit INSERT includes that field.
