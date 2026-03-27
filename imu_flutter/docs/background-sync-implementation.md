# Background Sync Implementation

## Overview

The IMU Flutter app now has comprehensive background sync functionality that automatically synchronizes data with the backend using PowerSync. The implementation handles multiple sync triggers and provides user-friendly status indicators.

## Architecture

### Components

1. **BackgroundSyncService** (`lib/services/api/background_sync_service.dart`)
   - Main service managing all background sync operations
   - Handles app lifecycle, connectivity changes, and periodic syncs
   - Integrates with PowerSync for automatic two-way sync

2. **PowerSync Integration** (`lib/services/sync/powersync_service.dart`)
   - Local SQLite database with automatic sync
   - Handles offline-first operations
   - Uploads pending changes when online

3. **Sync Status Indicators** (`lib/shared/widgets/background_sync_indicator.dart`)
   - Visual indicators showing sync status
   - Bottom sheet with detailed sync information
   - User-friendly error messages

4. **Sync Trigger Utilities**
   - `SyncTrigger` class: Trigger sync after mutations
   - `PowerSyncRepositoryMixin`: Mixin for repositories
   - Automatic sync batching

## Sync Triggers

### 1. App Lifecycle Changes

When the app returns to the foreground, sync is triggered automatically (if authenticated and online).

**Implementation**: `app.dart` line 88-106
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  _backgroundSyncService?.handleAppLifecycleChange(state);
  // ...
}
```

### 2. Network Connectivity Changes

When the device comes back online, sync is triggered automatically.

**Implementation**: `background_sync_service.dart` line 161-172
```dart
void _onConnectivityChanged(ConnectivityStatus status) {
  if (status == ConnectivityStatus.online && _authService.isAuthenticated) {
    performSync();
  }
}
```

### 3. Periodic Intervals

Background sync runs every 5 minutes (configurable) when the app is in the foreground.

**Configuration**: `background_sync_service.dart` line 38
```dart
Duration _syncInterval = const Duration(minutes: 5);
```

**Change interval**:
```dart
final syncService = ref.read(backgroundSyncServiceProvider);
syncService.setSyncInterval(const Duration(minutes: 10));
```

### 4. Post-Mutation Sync

After any local data changes (create/update/delete), sync is triggered after a 2-second delay to batch multiple mutations.

**Usage**: `lib/services/sync/sync_trigger.dart`
```dart
// After creating a client
await clientRepository.createClient(client);
SyncTrigger.trigger(ref); // Trigger sync
```

## Usage Examples

### Basic Usage in Widgets

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(backgroundSyncStatusProvider);

    return Column(
      children: [
        Text('Status: ${syncStatus.statusMessage}'),
        Text('Pending: ${syncStatus.pendingCount}'),
        Text('Last sync: ${syncStatus.lastSyncFormatted}'),
      ],
    );
  }
}
```

### Manual Sync Trigger

```dart
final syncService = ref.read(backgroundSyncServiceProvider);
final result = await syncService.performSync();

if (result.success) {
  print('Synced ${result.syncedCount} items');
} else {
  print('Sync failed: ${result.errorMessage}');
}
```

### Using SyncTrigger in Repositories

```dart
class ClientRepository {
  Future<void> createClient(Client client, Ref ref) async {
    // Insert into PowerSync
    await PowerSyncService.execute('INSERT INTO clients ...');

    // Trigger sync after mutation
    SyncTrigger.trigger(ref);
  }
}
```

### Using PowerSyncRepositoryMixin

```dart
class ClientRepository with PowerSyncRepositoryMixin {
  Future<void> createClient(Client client, Ref ref) async {
    // Automatically triggers sync after insert
    await executeInsert('clients', client.toJson(), ref: ref);
  }

  Future<void> updateClient(String id, Map<String, dynamic> data, Ref ref) async {
    // Automatically triggers sync after update
    await executeUpdate('clients', id, data, ref: ref);
  }

  Future<void> deleteClient(String id, Ref ref) async {
    // Automatically triggers sync after delete
    await executeDelete('clients', id, ref: ref);
  }

  Future<List<Client>> getClients() async {
    final results = await executeQuery('SELECT * FROM clients');
    return results.map((r) => Client.fromJson(r)).toList();
  }
}
```

### Batch Operations

```dart
class ClientRepository with PowerSyncRepositoryMixin {
  Future<void> batchUpdateClients(List<Client> clients, Ref ref) async {
    final operations = clients.map((client) =>
      DatabaseOperation.update('clients', client.id!, client.toJson())
    ).toList();

    // Execute batch and trigger sync once
    await executeBatch(operations, ref: ref);
  }
}
```

## UI Integration

### Sync Indicator in Bottom Nav

The sync indicator is automatically displayed in the bottom navigation bar showing:
- Spinning icon when syncing
- Pending count when items are waiting
- Checkmark when synced
- Error icon when sync fails

**File**: `lib/shared/widgets/main_shell.dart` line 112-117

### Sync Status Sheet

Tap the sync indicator to show detailed sync status:

```dart
// Show sync status sheet
showModalBottomSheet(
  context: context,
  builder: (context) => const BackgroundSyncSheet(),
);
```

### Standalone Sync Indicator

```dart
BackgroundSyncIndicator(
  showLabel: true,
  showPendingCount: true,
  onTap: () => print('Show sync details'),
)
```

## Sync Status Properties

### BackgroundSyncStatus

```dart
class BackgroundSyncStatus {
  final bool isSyncing;         // Currently syncing
  final DateTime? lastSyncTime;  // Last successful sync
  final String? lastSyncError;   // Error message if failed
  final int pendingCount;        // Number of pending uploads
  final bool isInitialized;      // Service initialized

  String get lastSyncFormatted;  // "2m ago", "1h ago", etc.
  String get statusMessage;      // Human-readable status
}
```

## Configuration

### Sync Interval

```dart
final syncService = ref.read(backgroundSyncServiceProvider);
syncService.setSyncInterval(const Duration(minutes: 10)); // 10 minutes
```

### Sync Callbacks

```dart
final syncService = ref.read(backgroundSyncServiceProvider);

// Sync started callback
syncService.onSyncStart(() {
  print('Sync started');
  // Show loading indicator
});

// Sync completed callback
syncService.onSyncComplete((DateTime syncTime) {
  print('Sync completed at $syncTime');
  // Hide loading indicator
  // Refresh UI
});

// Sync error callback
syncService.onSyncError((String error, dynamic e) {
  print('Sync failed: $error');
  // Show error message
});
```

## Error Handling

### Sync Retry Logic

The background sync service automatically retries failed sync attempts up to 3 times with a 5-second delay between retries.

**Configuration**: `background_sync_service.dart` line 40
```dart
static const int _maxSyncRetries = 3;
```

### User-Friendly Error Messages

Error messages are displayed in:
1. Sync status indicator (error icon)
2. Sync status bottom sheet
3. Optional sync callbacks

## Best Practices

### 1. Always Use PowerSync for Data Operations

```dart
// Good - uses PowerSync
await PowerSyncService.execute('INSERT INTO clients ...');

// Bad - doesn't use PowerSync
await apiClient.createClient(data);
```

### 2. Trigger Sync After Mutations

```dart
// After creating data
await createClient(client);
SyncTrigger.trigger(ref);

// After updating data
await updateClient(id, data);
SyncTrigger.trigger(ref);

// After deleting data
await deleteClient(id);
SyncTrigger.trigger(ref);
```

### 3. Use Batch Operations for Multiple Changes

```dart
// Good - single sync trigger
await executeBatch(operations, ref: ref);

// Less efficient - multiple sync triggers
for (final op in operations) {
  await executeUpdate(...);
  SyncTrigger.trigger(ref);
}
```

### 4. Check Sync Status Before Critical Operations

```dart
final syncStatus = ref.read(backgroundSyncStatusProvider);

if (syncStatus.pendingCount > 0) {
  // Warn user about pending changes
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Pending Changes'),
      content: Text('You have ${syncStatus.pendingCount} unsynced changes. Continue?'),
      actions: [...],
    ),
  );
}
```

## Troubleshooting

### Sync Not Triggering

1. Check if device is online: `ref.watch(isOnlineProvider)`
2. Check if authenticated: `ref.watch(isAuthenticatedProvider)`
3. Check if service initialized: `syncStatus.isInitialized`
4. Check logs for errors

### Pending Count Not Decreasing

1. Check PowerSync connection: `PowerSyncService.isConnected`
2. Check for sync errors: `syncStatus.lastSyncError`
3. Manually trigger sync: `syncService.performSync()`

### High Battery Usage

Increase sync interval to reduce frequency:
```dart
syncService.setSyncInterval(const Duration(minutes: 15));
```

## File Locations

| File | Purpose |
|------|---------|
| `lib/services/api/background_sync_service.dart` | Main background sync service |
| `lib/services/sync/powersync_service.dart` | PowerSync database wrapper |
| `lib/services/sync/powersync_connector.dart` | PowerSync backend connector |
| `lib/services/sync/sync_trigger.dart` | Sync trigger utilities |
| `lib/services/sync/sync_repository_mixin.dart` | Repository mixin for auto-sync |
| `lib/shared/widgets/background_sync_indicator.dart` | Sync status UI components |
| `lib/shared/widgets/main_shell.dart` | Bottom nav with sync indicator |
| `lib/app.dart` | App lifecycle integration |
| `lib/shared/providers/app_providers.dart` | Provider exports |

## Testing

### Manual Sync Test

```dart
// Test manual sync
final syncService = ref.read(backgroundSyncServiceProvider);
final result = await syncService.performSync();
print('Sync result: ${result.success}, ${result.syncedCount}');
```

### Mutation Trigger Test

```dart
// Create test data
await testRepository.createTestClient(data, ref);

// Check pending count increased
final syncStatus = ref.read(backgroundSyncStatusProvider);
assert(syncStatus.pendingCount > 0);

// Wait for sync (2s delay + sync time)
await Future.delayed(const Duration(seconds: 10));

// Check pending count decreased
final newStatus = ref.read(backgroundSyncStatusProvider);
assert(newStatus.pendingCount == 0);
```

## Migration Notes

### From Old BackgroundSyncService

The old `BackgroundSyncService` has been completely rewritten to integrate with PowerSync. Key changes:

1. **No manual API calls**: PowerSync handles sync automatically
2. **No offline queue**: PowerSync manages pending operations
3. **Simpler API**: Just call `performSync()` or use `SyncTrigger`
4. **Better status tracking**: Real-time pending count from PowerSync

### From SyncQueueService

The old `SyncQueueService` is now managed by PowerSync's internal CRUD queue. No manual queue management needed.

## Future Enhancements

1. **Background tasks**: Run sync even when app is terminated (iOS BGTaskScheduler, Android WorkManager)
2. **Conflict resolution**: Advanced conflict resolution UI
3. **Selective sync**: Sync only specific tables on demand
4. **Sync analytics**: Track sync performance and issues
5. **Data retention**: Automatic cleanup of old local data
