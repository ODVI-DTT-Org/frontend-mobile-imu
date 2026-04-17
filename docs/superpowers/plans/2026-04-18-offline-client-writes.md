# Offline Client Writes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Hive-backed pending queue for offline client creates, updates, and deletes — routing all client writes through a new `ClientMutationService` that syncs automatically when connectivity is restored.

**Architecture:** Three new files (`PendingClientOperation` model, `PendingClientService`, `ClientMutationService`) follow the exact pattern as the existing `PendingVisit`/`VisitCreationService`. Pages (`AddClientPage`, `EditClientPage`, `ClientDetailPage`) replace inline `isOnline` branching with a single `ClientMutationService` call. `BackgroundSyncService` gains `_syncPendingClients()` alongside `_syncPendingVisits()` and `_syncPendingReleases()`.

**Tech Stack:** Dart, Flutter, Hive (offline queue), Riverpod (providers), `ConnectivityService`, `ClientApiService`, `HiveService`, `uuid`.

---

### Task 1: PendingClientOperation model

**Files:**
- Create: `imu_flutter/lib/services/client/models/pending_client_operation.dart`

- [ ] **Step 1: Create the file**

```dart
import 'dart:convert';

enum ClientOperationType { create, update, delete }

class PendingClientOperation {
  final String id;
  final ClientOperationType operation;
  final String clientId;
  final Map<String, dynamic>? clientData;
  final DateTime createdAt;

  PendingClientOperation({
    required this.id,
    required this.operation,
    required this.clientId,
    this.clientData,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation.name,
    'clientId': clientId,
    'clientData': clientData != null ? jsonEncode(clientData) : null,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PendingClientOperation.fromJson(Map<String, dynamic> json) =>
      PendingClientOperation(
        id: json['id'] as String,
        operation: ClientOperationType.values.firstWhere(
          (e) => e.name == json['operation'] as String,
        ),
        clientId: json['clientId'] as String,
        clientData: json['clientData'] != null
            ? Map<String, dynamic>.from(
                jsonDecode(json['clientData'] as String) as Map,
              )
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
```

- [ ] **Step 2: Verify round-trip serialization by inspection**

Check that `toJson()` serializes `clientData` as a JSON string (not a nested Map) — this avoids Hive type issues since Hive only stores plain Maps at top level. Confirm `fromJson()` uses `jsonDecode` to reverse it.

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/services/client/models/pending_client_operation.dart
git commit -m "feat: add PendingClientOperation model for offline client queue"
```

---

### Task 2: PendingClientService

**Files:**
- Create: `imu_flutter/lib/services/client/pending_client_service.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:hive/hive.dart';
import 'package:imu_flutter/services/client/models/pending_client_operation.dart';

class PendingClientService {
  static const String _boxName = 'pending_clients';

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<void> enqueue(PendingClientOperation op) async {
    final box = await _getBox();
    await box.put(op.id, op.toJson());
  }

  Future<List<PendingClientOperation>> getAll() async {
    final box = await _getBox();
    final ops = box.values
        .map((v) => PendingClientOperation.fromJson(
              Map<String, dynamic>.from(v as Map),
            ))
        .toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> remove(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> removeAllForClient(String clientId) async {
    final box = await _getBox();
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['clientId'] == clientId) keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }

  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }

  /// Collapse a sorted list of operations into the minimal set to sync.
  ///
  /// Rules per clientId:
  ///   create + delete  → cancel both (never hit server)
  ///   create + updates → single create with final data
  ///   updates only     → single update with final data
  ///   update + delete  → single delete
  ///   delete alone     → delete
  List<PendingClientOperation> collapse(List<PendingClientOperation> ops) {
    final byClient = <String, List<PendingClientOperation>>{};
    for (final op in ops) {
      byClient.putIfAbsent(op.clientId, () => []).add(op);
    }

    final result = <PendingClientOperation>[];

    for (final clientOps in byClient.values) {
      final hasCreate =
          clientOps.any((o) => o.operation == ClientOperationType.create);
      final hasDelete =
          clientOps.any((o) => o.operation == ClientOperationType.delete);

      if (hasCreate && hasDelete) {
        continue; // cancel both — temp client never existed on server
      }

      if (hasDelete) {
        result.add(clientOps.last); // last op is the delete
        continue;
      }

      if (hasCreate) {
        // merge: create with the final client data from the last op
        result.add(PendingClientOperation(
          id: clientOps.first.id,
          operation: ClientOperationType.create,
          clientId: clientOps.first.clientId,
          clientData: clientOps.last.clientData,
          createdAt: clientOps.first.createdAt,
        ));
        continue;
      }

      result.add(clientOps.last); // updates only — last wins
    }

    return result;
  }
}
```

- [ ] **Step 2: Verify collapse logic by reading through the cases**

Walk through each branch manually:
- `[create, update, delete]` for same clientId → `hasCreate=true, hasDelete=true` → skipped ✓
- `[create, update]` → `hasCreate=true, hasDelete=false` → single create with last data ✓
- `[update, update]` → `hasCreate=false, hasDelete=false` → last update ✓
- `[update, delete]` → `hasDelete=true` → last op (the delete) ✓
- `[delete]` → `hasDelete=true` → last op (the delete) ✓

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/services/client/pending_client_service.dart
git commit -m "feat: add PendingClientService with Hive queue and collapse logic"
```

---

### Task 3: ClientMutationService

**Files:**
- Create: `imu_flutter/lib/services/client/client_mutation_service.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/client/models/pending_client_operation.dart';
import 'package:imu_flutter/services/client/pending_client_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';

enum ClientMutationResult { success, requiresApproval, queued }

class ClientMutationService {
  final ConnectivityService _connectivity;
  final ClientApiService _api;
  final PendingClientService _pending;
  final HiveService _hive;
  final _uuid = const Uuid();

  ClientMutationService(
    this._connectivity,
    this._api,
    this._pending,
    this._hive,
  );

  Future<ClientMutationResult> createClient(Client client) async {
    if (_connectivity.isOnline) {
      final result = await _api.createClient(client);
      if (result != null) {
        await _hive.saveClient(result.id!, result.toJson());
        return ClientMutationResult.success;
      }
      return ClientMutationResult.requiresApproval;
    }

    final tempId = _uuid.v4();
    final clientData = <String, dynamic>{...client.toJson(), 'id': tempId};
    await _hive.saveClient(tempId, clientData);
    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.create,
      clientId: tempId,
      clientData: clientData,
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued create for temp client $tempId');
    return ClientMutationResult.queued;
  }

  Future<ClientMutationResult> updateClient(Client client) async {
    // Optimistic update: persist to Hive immediately so UI stays current
    await _hive.saveClient(client.id!, client.toJson());

    if (_connectivity.isOnline) {
      final result = await _api.updateClient(client);
      if (result != null) {
        await _hive.saveClient(result.id!, result.toJson());
        return ClientMutationResult.success;
      }
      return ClientMutationResult.requiresApproval;
    }

    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.update,
      clientId: client.id!,
      clientData: client.toJson(),
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued update for client ${client.id}');
    return ClientMutationResult.queued;
  }

  Future<void> deleteClient(String clientId) async {
    // Remove from Hive immediately so it disappears from UI
    await _hive.deleteClient(clientId);

    if (_connectivity.isOnline) {
      await _api.deleteClient(clientId);
      return;
    }

    await _pending.enqueue(PendingClientOperation(
      id: _uuid.v4(),
      operation: ClientOperationType.delete,
      clientId: clientId,
      clientData: null,
      createdAt: DateTime.now(),
    ));
    logDebug('ClientMutationService: queued delete for client $clientId');
  }
}
```

- [ ] **Step 2: Check the import path for ConnectivityService**

Open `imu_flutter/lib/services/api/background_sync_service.dart` line 7.
It reads: `import '../connectivity_service.dart';`
From `services/api/`, `..` = `services/`, so `ConnectivityService` is at `services/connectivity_service.dart`.

Our file is at `services/client/client_mutation_service.dart`, so `..` = `services/`. The import `package:imu_flutter/services/connectivity_service.dart` is correct.

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/services/client/client_mutation_service.dart
git commit -m "feat: add ClientMutationService — online/offline routing for client writes"
```

---

### Task 4: Register providers in app_providers.dart

**Files:**
- Modify: `imu_flutter/lib/shared/providers/app_providers.dart`

Context: Providers for pending visits/releases live at lines 658–683. Add client providers in the same block.

- [ ] **Step 1: Add imports at the top of app_providers.dart**

Find the imports section. Add these two lines alongside the existing pending service imports:

```dart
import '../services/client/pending_client_service.dart';
import '../services/client/client_mutation_service.dart';
```

- [ ] **Step 2: Add providers after line 683 (after `releaseCreationServiceProvider`)**

```dart
/// Pending client service provider
final pendingClientServiceProvider = Provider<PendingClientService>((ref) {
  return PendingClientService();
});

/// Client mutation service provider — online → API, offline → Hive queue
final clientMutationServiceProvider = Provider<ClientMutationService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final api = ref.watch(clientApiServiceProvider);
  final pending = ref.watch(pendingClientServiceProvider);
  final hive = ref.watch(hiveServiceProvider);
  return ClientMutationService(connectivity, api, pending, hive);
});
```

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/shared/providers/app_providers.dart
git commit -m "feat: register pendingClientServiceProvider and clientMutationServiceProvider"
```

---

### Task 5: Update AddClientPage

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/add_client_page.dart`

The current `_handleSubmit` (around line 234) has an inline `isOnline` branch. Replace it entirely with a `ClientMutationService` call.

- [ ] **Step 1: Replace the online/offline branching block**

Find this block (lines 232–269):

```dart
      debugPrint('[AddClientPage] Submitting new client');

      final isOnline = ref.read(isOnlineProvider);

      if (isOnline) {
        debugPrint('[AddClientPage] Online - submitting to backend API');
        final clientApi = ref.read(clientApiServiceProvider);
        final result = await clientApi.createClient(newClient);

        if (result != null) {
          // Admin direct creation - client created immediately
          debugPrint('[AddClientPage] Client created successfully');
          // Save to local storage
          if (result.id != null) {
            await _hiveService.saveClient(result.id!, result.toJson());
          }

          if (mounted) {
            _showSuccessSnackBar('Client added successfully');
            context.pop(true);
          }
        } else {
          // Caravan/Tele - approval required
          debugPrint('[AddClientPage] Client creation requires approval');
          if (mounted) {
            _showSuccessSnackBar('Client submitted for approval');
            context.pop(true);
          }
        }
      } else {
        debugPrint('[AddClientPage] Offline - saving to local storage only');
        await _hiveService.saveClient(tempId, newClient.toJson());

        if (mounted) {
          _showWarningSnackBar('Offline: Client will sync when connected');
          context.pop(true);
        }
      }
```

Replace with:

```dart
      debugPrint('[AddClientPage] Submitting new client');

      final mutationService = ref.read(clientMutationServiceProvider);
      final result = await mutationService.createClient(newClient);

      if (mounted) {
        switch (result) {
          case ClientMutationResult.success:
            _showSuccessSnackBar('Client added successfully');
          case ClientMutationResult.requiresApproval:
            _showSuccessSnackBar('Client submitted for approval');
          case ClientMutationResult.queued:
            _showWarningSnackBar('Offline: Client will sync when connected');
        }
        context.pop(true);
      }
```

- [ ] **Step 2: Remove unused `tempId` variable**

Search `_handleSubmit` for any line defining `tempId` (e.g., `final tempId = 'temp_${DateTime.now()...}'`). Delete it — `ClientMutationService` generates the temp ID internally.

Also remove `final _hiveService = HiveService();` at the top of the class if it's no longer used elsewhere in the file. Check first — `_hiveService` may be used in `initState` or other methods.

- [ ] **Step 3: Verify imports**

`app_providers.dart` is already imported at line 9 as a wildcard: `import '../../../../shared/providers/app_providers.dart';`
`ClientMutationResult` is defined in `client_mutation_service.dart` which is re-exported via `app_providers.dart`. If it's not re-exported, add a direct import:

```dart
import '../../../../services/client/client_mutation_service.dart' show ClientMutationResult;
```

- [ ] **Step 4: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/add_client_page.dart
git commit -m "feat: route AddClientPage through ClientMutationService for offline support"
```

---

### Task 6: Update EditClientPage

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart`

Two changes: the save handler (lines 409–435) and the delete handler (lines 445–493).

- [ ] **Step 1: Replace the save branching block (lines 409–435)**

Find this block:

```dart
      final isOnline = ref.read(isOnlineProvider);

      if (isOnline) {
        final clientApi = ref.read(clientApiServiceProvider);
        final result = await clientApi.updateClient(updatedClient);

        if (result != null) {
          await _hiveService.saveClient(widget.clientId, result.toJson());
          ref.invalidate(assignedClientsProvider);
          if (mounted) {
            AppNotification.showSuccess(context, 'Client updated successfully');
            context.pop(true);
          }
        } else {
          if (mounted) {
            AppNotification.showSuccess(context, 'Client edit submitted for approval');
            context.pop(true);
          }
        }
      } else {
        await _hiveService.saveClient(widget.clientId, updatedClient.toJson());
        ref.invalidate(assignedClientsProvider);
        if (mounted) {
          AppNotification.showWarning(context, 'Offline: Changes will sync when connected');
          context.pop(true);
        }
      }
```

Replace with:

```dart
      final mutationService = ref.read(clientMutationServiceProvider);
      final result = await mutationService.updateClient(updatedClient);
      ref.invalidate(assignedClientsProvider);

      if (mounted) {
        switch (result) {
          case ClientMutationResult.success:
            AppNotification.showSuccess(context, 'Client updated successfully');
          case ClientMutationResult.requiresApproval:
            AppNotification.showSuccess(context, 'Client edit submitted for approval');
          case ClientMutationResult.queued:
            AppNotification.showWarning(context, 'Offline: Changes will sync when connected');
        }
        context.pop(true);
      }
```

- [ ] **Step 2: Replace the delete handler (lines 445–493)**

Find `_handleDelete()`. Replace its body after the confirmation dialog with:

```dart
  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text(
          'Are you sure you want to delete ${_client?.firstName ?? ''} ${_client?.lastName ?? ''}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    HapticUtils.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final mutationService = ref.read(clientMutationServiceProvider);
      await mutationService.deleteClient(widget.clientId);
      ref.invalidate(assignedClientsProvider);

      if (mounted) {
        AppNotification.showSuccess(context, 'Client deleted');
        context.pop(true);
      }
    } catch (e) {
      debugPrint('[EditClientPage] Delete error: $e');
      HapticUtils.error();
      if (mounted) AppNotification.showError(context, 'Failed to delete client: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
```

Note: the old code blocked delete when offline (`if (!isOnline) { showError; return; }`). The new code queues it instead — no online check needed.

- [ ] **Step 3: Verify imports**

Same as Task 5 Step 3 — `app_providers.dart` is already imported at line 9. Add direct import for `ClientMutationResult` if not re-exported:

```dart
import '../../../../services/client/client_mutation_service.dart' show ClientMutationResult;
```

- [ ] **Step 4: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/edit_client_page.dart
git commit -m "feat: route EditClientPage save and delete through ClientMutationService"
```

---

### Task 7: Update ClientDetailPage delete

**Files:**
- Modify: `imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart`

The current delete (lines 417–439) only calls `_hiveService.deleteClient()` — it never calls the API. This is a bug. Fix it by routing through `ClientMutationService`.

- [ ] **Step 1: Replace the delete operation block (lines 417–439)**

Find this block:

```dart
    if (confirmed == true && mounted) {
      HapticUtils.delete();

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting client...',
        operation: () async {
          await _hiveService.deleteClient(widget.clientId);
          // PowerSync handles sync automatically via the repository
          ref.invalidate(assignedClientsProvider);
        },
        onError: (e) {
          if (mounted) {
            AppNotification.showError(context, 'Failed to delete client: $e');
          }
        },
      );

      if (mounted) {
        AppNotification.showSuccess(context, 'Client deleted');
        context.pop();
      }
    }
```

Replace with:

```dart
    if (confirmed == true && mounted) {
      HapticUtils.delete();

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting client...',
        operation: () async {
          final mutationService = ref.read(clientMutationServiceProvider);
          await mutationService.deleteClient(widget.clientId);
          ref.invalidate(assignedClientsProvider);
        },
        onError: (e) {
          if (mounted) {
            AppNotification.showError(context, 'Failed to delete client: $e');
          }
        },
      );

      if (mounted) {
        AppNotification.showSuccess(context, 'Client deleted');
        context.pop();
      }
    }
```

- [ ] **Step 2: Add `clientMutationServiceProvider` to the `show` clause of the app_providers import**

The current import at line 13 is:

```dart
import '../../../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    isOnlineProvider,
    touchpointApiServiceProvider,
    authNotifierProvider,
    addressRepositoryProvider,
    phoneNumberRepositoryProvider;
```

Add `clientMutationServiceProvider` to the list:

```dart
import '../../../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    isOnlineProvider,
    touchpointApiServiceProvider,
    authNotifierProvider,
    addressRepositoryProvider,
    phoneNumberRepositoryProvider,
    clientMutationServiceProvider;
```

- [ ] **Step 3: Commit**

```bash
git add imu_flutter/lib/features/clients/presentation/pages/client_detail_page.dart
git commit -m "fix: route ClientDetailPage delete through ClientMutationService (was Hive-only)"
```

---

### Task 8: Update BackgroundSyncService

**Files:**
- Modify: `imu_flutter/lib/services/api/background_sync_service.dart`

Three changes: add imports, add `_syncPendingClients()` method, update `_updatePendingCount()` and `performSync()`.

- [ ] **Step 1: Add imports after line 22**

After the existing `release_api_service.dart` import (line 22), add:

```dart
import '../client/pending_client_service.dart';
import '../client/models/pending_client_operation.dart';
import 'client_api_service.dart' show ClientApiService;
import '../local_storage/hive_service.dart';
import '../../features/clients/data/models/client_model.dart';
```

- [ ] **Step 2: Update `_updatePendingCount()` (line 375)**

Find this line:

```dart
      _pendingCount = powerSyncPending + hiveTouchpoints + hiveVisits + hiveReleases;
```

Replace with:

```dart
      final hiveClients = await PendingClientService().getPendingCount();
      _pendingCount = powerSyncPending + hiveTouchpoints + hiveVisits + hiveReleases + hiveClients;
```

- [ ] **Step 3: Update `performSync()` (line 263)**

Find this block:

```dart
      // Sync pending visits and releases created while offline
      await _syncPendingVisits();
      await _syncPendingReleases();
```

Replace with:

```dart
      // Sync pending visits, releases, and client writes created while offline
      await _syncPendingVisits();
      await _syncPendingReleases();
      await _syncPendingClients();
```

- [ ] **Step 4: Add `_syncPendingClients()` method after `_syncPendingReleases()`**

Find the closing `}` of `_syncPendingReleases()` (around line 597). Add this method immediately after:

```dart
  /// Sync pending client creates, updates, and deletes stored while offline
  Future<void> _syncPendingClients() async {
    try {
      final pendingService = PendingClientService();
      final all = await pendingService.getAll();
      if (all.isEmpty) return;

      final collapsed = pendingService.collapse(all);
      logDebug('BackgroundSyncService: Syncing ${collapsed.length} pending client operations');

      final clientApi = ClientApiService();
      final hiveService = HiveService();
      int syncedCount = 0;

      for (final op in collapsed) {
        try {
          switch (op.operation) {
            case ClientOperationType.create:
              final client = Client.fromJson(op.clientData!);
              final result = await clientApi.createClient(client);
              // Always remove the temp Hive entry
              await hiveService.deleteClient(op.clientId);
              if (result != null) {
                // Admin path: server assigned a real ID — save it
                await hiveService.saveClient(result.id!, result.toJson());
              }
              // Caravan path: result == null (requires_approval)
              // PowerSync will bring the real record in after admin approves
              await pendingService.removeAllForClient(op.clientId);
              syncedCount++;
              break;

            case ClientOperationType.update:
              final client = Client.fromJson(op.clientData!);
              final result = await clientApi.updateClient(client);
              if (result != null) {
                await hiveService.saveClient(result.id!, result.toJson());
              }
              await pendingService.removeAllForClient(op.clientId);
              syncedCount++;
              break;

            case ClientOperationType.delete:
              try {
                await clientApi.deleteClient(op.clientId);
              } on DioException catch (e) {
                if (e.response?.statusCode != 404) rethrow;
                // 404 = already gone on server — treat as success
              }
              await hiveService.deleteClient(op.clientId);
              await pendingService.removeAllForClient(op.clientId);
              syncedCount++;
              break;
          }
        } catch (e) {
          logError(
            'BackgroundSyncService: Failed to sync pending client op ${op.id} (${op.operation.name})',
            e,
          );
          // Leave in queue for next sync attempt
        }
      }

      logDebug(
        'BackgroundSyncService: Client ops sync complete — $syncedCount/${collapsed.length} synced',
      );
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to sync pending clients', e, stackTrace);
    }
  }
```

- [ ] **Step 5: Add missing `DioException` import if not already present**

Check line 1–25 of the file for `import 'package:dio/dio.dart';`. If not present, add it alongside the other imports.

- [ ] **Step 6: Commit**

```bash
git add imu_flutter/lib/services/api/background_sync_service.dart
git commit -m "feat: sync pending client operations in BackgroundSyncService"
```

---

## Self-Review Checklist

After completing all tasks, verify:

- [ ] `PendingClientService.collapse()` is called before sync in `_syncPendingClients()` ✓
- [ ] `removeAllForClient()` is used (not `remove()`) in sync, so merged create+update entries are all cleaned up ✓
- [ ] `ClientDetailPage` now actually calls the API on delete (was Hive-only before) ✓
- [ ] Offline delete no longer blocks with "Cannot delete while offline" in `EditClientPage` ✓
- [ ] Pending count badge includes client ops ✓
- [ ] No `tempId` or inline `isOnline` checks left in `AddClientPage` or `EditClientPage` ✓
