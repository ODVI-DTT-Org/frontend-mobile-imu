import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local_storage/hive_service.dart';

/// Sync service for managing offline/online data synchronization
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingCount = 0;

  // Getters
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get pendingCount => _pendingCount;
  bool get isOnline => _status != SyncStatus.offline;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Initialize sync service
  Future<void> init() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );

    // Update pending count
    await _updatePendingCount();

    debugPrint('SyncService initialized');
  }

  /// Dispose
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Update connectivity status
  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOffline = _status == SyncStatus.offline;

    if (result == ConnectivityResult.none) {
      _status = SyncStatus.offline;
    } else if (_status == SyncStatus.offline) {
      _status = SyncStatus.idle;
    }

    notifyListeners();

    // Auto-sync when coming back online
    if (wasOffline && _status != SyncStatus.offline && _pendingCount > 0) {
      syncNow();
    }
  }

  /// Update pending count
  Future<void> _updatePendingCount() async {
    _pendingCount = _hiveService.getPendingSyncCount();
    notifyListeners();
  }

  /// Trigger manual sync
  Future<SyncResult> syncNow() async {
    if (_status == SyncStatus.offline) {
      return SyncResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    if (_status == SyncStatus.syncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
      );
    }

    _status = SyncStatus.syncing;
    _lastSyncError = null;
    notifyListeners();

    try {
      final pendingItems = _hiveService.getPendingSyncItems();

      if (pendingItems.isEmpty) {
        _status = SyncStatus.success;
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return SyncResult(success: true);
      }

      int syncedCount = 0;
      int failedCount = 0;

      for (final item in pendingItems) {
        try {
          // Simulate API call with exponential backoff
          await _syncWithBackoff(item);
          syncedCount++;

          // Remove from pending queue
          await _hiveService.removeFromPendingSync(
            item['entityType'] as String,
            item['id'] as String,
          );
        } catch (e) {
          debugPrint('Failed to sync item ${item['id']}: $e');
          failedCount++;
        }
      }

      await _updatePendingCount();

      _status = failedCount > 0 ? SyncStatus.error : SyncStatus.success;
      _lastSyncTime = DateTime.now();

      if (failedCount > 0) {
        _lastSyncError = 'Failed to sync $failedCount items';
      }

      notifyListeners();

      return SyncResult(
        success: failedCount == 0,
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    } catch (e) {
      _status = SyncStatus.error;
      _lastSyncError = e.toString();
      notifyListeners();

      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Sync with exponential backoff
  Future<void> _syncWithBackoff(
    Map<String, dynamic> item, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        // In production, this would be an actual API call
        // For now, simulate network delay
        await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(200)));

        // Simulate occasional failure for testing
        if (Random().nextDouble() < 0.1) {
          throw Exception('Network error');
        }

        return; // Success
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;

        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: pow(2, attempt).toInt());
        await Future.delayed(delay);
      }
    }
  }

  /// Queue an item for sync
  Future<void> queueForSync({
    required String id,
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    await _hiveService.addToPendingSync(
      id: id,
      operation: operation,
      entityType: entityType,
      data: data,
    );

    await _updatePendingCount();

    // Try to sync immediately if online
    if (isOnline) {
      unawaited(syncNow());
    }
  }

  /// Get sync status message
  String get statusMessage {
    switch (_status) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.success:
        return 'Synced successfully';
      case SyncStatus.error:
        return _lastSyncError ?? 'Sync failed';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  /// Get formatted last sync time
  String get lastSyncFormatted {
    if (_lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(_lastSyncTime!);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/// Helper to unawait futures
void unawaited(Future<void>? future) {
  // Intentionally not awaiting
}
