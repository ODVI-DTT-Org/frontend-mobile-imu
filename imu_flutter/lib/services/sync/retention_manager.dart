import 'package:hive_flutter/hive_flutter.dart';

/// Manages data retention for synced data with a 7-day cleanup policy
class RetentionManager {
  /// Default retention period of 7 days for synced data
  static const Duration retentionPeriod = Duration(days: 7);

  /// Cleans up synced data older than the retention period
  ///
  /// This method removes records from the 'synced_data' box that have
  /// a 'syncedAt' timestamp older than [retentionPeriod].
  Future<void> cleanupSyncedData() async {
    final cutoff = DateTime.now().subtract(retentionPeriod);
    final syncBox = Hive.box('synced_data');

    final keysToDelete = <dynamic>[];

    for (final key in syncBox.keys) {
      final record = syncBox.get(key);
      if (record != null && record is Map) {
        final syncedAt = record['syncedAt'];
        if (syncedAt != null && DateTime.parse(syncedAt).isBefore(cutoff)) {
          keysToDelete.add(key);
        }
      }
    }

    for (final key in keysToDelete) {
      await syncBox.delete(key);
    }
  }
}
