import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/logger.dart';

/// Service for managing sync preferences and timing
class SyncPreferencesService {
  static final SyncPreferencesService _instance = SyncPreferencesService._internal();
  factory SyncPreferencesService() => _instance;
  SyncPreferencesService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _lastSyncHashKey = 'last_sync_hash';

  /// Default sync interval - sync if last sync was more than this long ago
  static const Duration defaultSyncInterval = Duration(minutes: 30);

  /// Get the last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timeStr = await _storage.read(key: _lastSyncTimeKey);
      if (timeStr == null) return null;

      final timestamp = int.tryParse(timeStr);
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      logError('Failed to get last sync time', e);
      return null;
    }
  }

  /// Save the last sync time
  Future<void> saveLastSyncTime() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _storage.write(key: _lastSyncTimeKey, value: timestamp.toString());
      logDebug('Saved last sync time: ${DateTime.now()}');
    } catch (e) {
      logError('Failed to save last sync time', e);
    }
  }

  /// Get the last sync hash (for detecting data changes)
  Future<String?> getLastSyncHash() async {
    try {
      return await _storage.read(key: _lastSyncHashKey);
    } catch (e) {
      logError('Failed to get last sync hash', e);
      return null;
    }
  }

  /// Save the current sync hash
  Future<void> saveSyncHash(String hash) async {
    try {
      await _storage.write(key: _lastSyncHashKey, value: hash);
      logDebug('Saved sync hash: $hash');
    } catch (e) {
      logError('Failed to save sync hash', e);
    }
  }

  /// Check if sync is needed based on time elapsed
  Future<bool> shouldSync({Duration? interval}) async {
    final syncInterval = interval ?? defaultSyncInterval;

    final lastSyncTime = await getLastSyncTime();
    if (lastSyncTime == null) {
      logDebug('No previous sync found - sync needed');
      return true;
    }

    final timeSinceLastSync = DateTime.now().difference(lastSyncTime);

    if (timeSinceLastSync > syncInterval) {
      logDebug('Sync needed - last sync was ${timeSinceLastSync.inMinutes} minutes ago');
      return true;
    }

    logDebug('Sync not needed - last sync was ${timeSinceLastSync.inMinutes} minutes ago');
    return false;
  }

  /// Force sync to be needed on next check (for testing or manual sync requests)
  Future<void> clearLastSyncTime() async {
    try {
      await _storage.delete(key: _lastSyncTimeKey);
      logDebug('Cleared last sync time - sync will be needed on next check');
    } catch (e) {
      logError('Failed to clear last sync time', e);
    }
  }

  /// Get time since last sync in a human-readable format
  Future<String> getTimeSinceLastSync() async {
    final lastSyncTime = await getLastSyncTime();
    if (lastSyncTime == null) return 'Never';

    final diff = DateTime.now().difference(lastSyncTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Check if this is the first sync ever
  Future<bool> isFirstSync() async {
    final lastSyncTime = await getLastSyncTime();
    return lastSyncTime == null;
  }
}
