import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/background_sync_service.dart';

/// Utility class to trigger sync after data mutations
///
/// This should be called after any local data changes (create/update/delete)
/// to ensure they are synced to the server promptly.
///
/// Example usage:
/// ```dart
/// await clientRepository.createClient(client);
/// SyncTrigger.trigger(); // Trigger sync after mutation
/// ```
class SyncTrigger {
  /// Trigger sync after a data mutation
  ///
  /// This will trigger a sync after a short delay (2 seconds) to batch
  /// multiple mutations together.
  static void trigger(Ref ref) {
    final syncService = ref.read(backgroundSyncServiceProvider);
    syncService.triggerSyncAfterMutation();
  }

  /// Trigger immediate sync (no delay)
  ///
  /// Use this when you need immediate sync, such as after critical updates.
  static void triggerImmediate(Ref ref) {
    final syncService = ref.read(backgroundSyncServiceProvider);
    syncService.performSync();
  }

  /// Trigger sync if online
  ///
  /// Only triggers sync if the device is online.
  static void triggerIfOnline(Ref ref) {
    final syncService = ref.read(backgroundSyncServiceProvider);
    if (syncService.isInitialized) {
      syncService.triggerSyncAfterMutation();
    }
  }
}

/// Extension on Ref to provide convenient sync triggering methods
extension SyncTriggerRef on Ref {
  /// Trigger sync after a data mutation
  void triggerSync() {
    SyncTrigger.trigger(this);
  }

  /// Trigger immediate sync
  void triggerSyncImmediate() {
    SyncTrigger.triggerImmediate(this);
  }

  /// Trigger sync if online
  void triggerSyncIfOnline() {
    SyncTrigger.triggerIfOnline(this);
  }
}
