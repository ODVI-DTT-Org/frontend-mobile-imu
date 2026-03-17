import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local_storage/hive_service.dart';

// Note: SyncStatus and SyncResult are defined in hive_service.dart

/// Sync service for managing offline/online data synchronization
/// TODO: Phase 2 - Will be updated to work with PowerSync
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();
  // TODO: Replace with PowerSync client in Phase 2
  // dynamic _powerSyncClient;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingCount = 0;
  int _syncedCount = 0;
  int _failedCount = 0;

  // Getters
  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get pendingCount => _pendingCount;
  int get syncedCount => _syncedCount;
  int get failedCount => _failedCount;
  bool get isOnline => _status != SyncStatus.offline;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// Initialize sync service
  Future<void> init() async {
    // TODO: Phase 2 - Initialize PowerSync client here
    debugPrint('SyncService: PowerSync initialization will be added in Phase 2');

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
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOffline = _status == SyncStatus.offline;

    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
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

  /// Trigger full sync (pull + push)
  /// TODO: Phase 2 - Implement with PowerSync
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
    _syncedCount = 0;
    _failedCount = 0;
    notifyListeners();

    try {
      // TODO: Phase 2 - Implement PowerSync push/pull
      // Step 1: Push pending changes to server via PowerSync
      // final pushResult = await _pushPendingChanges();
      // _syncedCount = pushResult['synced'] as int;
      // _failedCount = pushResult['failed'] as int;

      // Step 2: Pull latest data from server via PowerSync
      // await _pullFromServer();

      await _updatePendingCount();

      // For now, just mark as success since PowerSync isn't connected yet
      _status = SyncStatus.success;
      _lastSyncTime = DateTime.now();

      debugPrint('SyncService: Sync completed (PowerSync integration pending)');

      notifyListeners();

      return SyncResult(
        success: true,
        syncedCount: _syncedCount,
        failedCount: _failedCount,
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

  /// Push pending changes to server
  /// TODO: Phase 2 - Implement with PowerSync
  Future<Map<String, int>> _pushPendingChanges() async {
    final pendingItems = _hiveService.getPendingSyncItems();

    if (pendingItems.isEmpty) {
      return {'synced': 0, 'failed': 0};
    }

    // TODO: Phase 2 - Implement PowerSync push
    debugPrint('SyncService: Push via PowerSync will be implemented in Phase 2');

    return {'synced': 0, 'failed': pendingItems.length};
  }

  /// Pull latest data from server
  /// TODO: Phase 2 - Implement with PowerSync
  Future<void> _pullFromServer() async {
    // TODO: Phase 2 - Implement PowerSync pull
    debugPrint('SyncService: Pull via PowerSync will be implemented in Phase 2');
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

  /// Check if backend is reachable
  /// TODO: Phase 2 - Implement with PowerSync health check
  Future<bool> checkBackendConnection() async {
    // TODO: Phase 2 - Check PowerSync connection
    debugPrint('SyncService: Backend check will use PowerSync in Phase 2');
    return false;
  }
}

/// Helper to unawait futures
void unawaited(Future<void>? future) {
  // Intentionally not awaiting
}
