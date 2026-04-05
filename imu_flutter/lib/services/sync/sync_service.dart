import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/sync/powersync_connector.dart';
import 'package:imu_flutter/core/utils/logger.dart';

/// Sync status enum
enum SyncStatusEnum {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Sync result model
class SyncResult {
  final bool success;
  final int syncedCount;
  final int failedCount;
  final String? errorMessage;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.errorMessage,
  });
}

/// Sync service for managing offline/online data synchronization with PowerSync
class SyncService extends ChangeNotifier {
  final Ref _ref;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription? _syncStatusSubscription;
  SyncStatusEnum _status = SyncStatusEnum.idle;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingCount = 0;

  SyncService(this._ref);

  // Getters
  SyncStatusEnum get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get pendingCount => _pendingCount;
  bool get isOnline => _status != SyncStatusEnum.offline;
  bool get isSyncing => _status == SyncStatusEnum.syncing;
  bool get isConnected => PowerSyncService.isConnected;

  /// Initialize sync service with PowerSync connector
  Future<void> init() async {
    logDebug('SyncService: Initializing with PowerSync');

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(result);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectivityStatus,
    );

    // Monitor PowerSync sync status
    _syncStatusSubscription = PowerSyncService.syncStatus.listen(
      _updateSyncStatus,
    );

    // Update pending count
    await _updatePendingCount();

    logDebug('SyncService initialized');
  }

  /// Connect to PowerSync backend
  Future<void> connectToBackend() async {
    try {
      final connector = _ref.read(powerSyncConnectorProvider);
      await PowerSyncService.connect(connector: connector);
      logDebug('SyncService: Connected to PowerSync backend');
    } catch (e) {
      logError('SyncService: Failed to connect to PowerSync backend', e);
      rethrow;
    }
  }

  /// Disconnect from PowerSync backend
  Future<void> disconnectFromBackend() async {
    await PowerSyncService.disconnect();
    logDebug('SyncService: Disconnected from PowerSync backend');
  }

  /// Dispose
  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusSubscription?.cancel();
    super.dispose();
  }

  /// Update connectivity status
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOffline = _status == SyncStatusEnum.offline;

    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      _status = SyncStatusEnum.offline;
    } else if (_status == SyncStatusEnum.offline) {
      _status = SyncStatusEnum.idle;
    }

    notifyListeners();

    // Auto-sync when coming back online
    if (wasOffline && _status != SyncStatusEnum.offline && _pendingCount > 0) {
      syncNow();
    }
  }

  /// Update sync status from PowerSync
  void _updateSyncStatus(SyncStatus status) {
    // PowerSync handles sync automatically, just update our status
    if (status.connected) {
      if (_status == SyncStatusEnum.offline) {
        _status = SyncStatusEnum.idle;
      }
    } else {
      _status = SyncStatusEnum.offline;
    }
    notifyListeners();
  }

  /// Update pending count
  Future<void> _updatePendingCount() async {
    _pendingCount = await PowerSyncService.pendingUploadCount;
    notifyListeners();
  }

  /// Trigger full sync (push pending changes)
  /// PowerSync handles pulling data automatically via the sync stream
  Future<SyncResult> syncNow() async {
    if (_status == SyncStatusEnum.offline) {
      return SyncResult(
        success: false,
        errorMessage: 'No internet connection',
      );
    }

    if (_status == SyncStatusEnum.syncing) {
      return SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
      );
    }

    if (!PowerSyncService.isConnected) {
      return SyncResult(
        success: false,
        errorMessage: 'Not connected to PowerSync',
      );
    }

    _status = SyncStatusEnum.syncing;
    _lastSyncError = null;
    notifyListeners();

    try {
      // PowerSync automatically syncs data via the connector
      // We just need to wait for pending uploads to complete
      await _waitForPendingUploads();

      await _updatePendingCount();

      _status = SyncStatusEnum.success;
      _lastSyncTime = DateTime.now();

      logDebug('SyncService: Sync completed successfully');

      notifyListeners();

      return SyncResult(
        success: true,
        syncedCount: _pendingCount,
      );
    } catch (e) {
      _status = SyncStatusEnum.error;
      _lastSyncError = e.toString();
      logError('SyncService: Sync failed', e);
      notifyListeners();

      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Wait for pending uploads to complete
  Future<void> _waitForPendingUploads() async {
    // Poll until no pending uploads or timeout
    const maxWaitTime = Duration(seconds: 30);
    const pollInterval = Duration(milliseconds: 500);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final pending = await PowerSyncService.pendingUploadCount;
      if (pending == 0) break;
      await Future.delayed(pollInterval);
    }
  }

  /// Get sync status message
  String get statusMessage {
    switch (_status) {
      case SyncStatusEnum.idle:
        return 'Ready to sync';
      case SyncStatusEnum.syncing:
        return 'Syncing...';
      case SyncStatusEnum.success:
        return 'Synced successfully';
      case SyncStatusEnum.error:
        return _lastSyncError ?? 'Sync failed';
      case SyncStatusEnum.offline:
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
  Future<bool> checkBackendConnection() async {
    return PowerSyncService.isConnected;
  }

  /// Queue an item for sync (compatibility method)
  /// With PowerSync, sync is automatic so this is a no-op
  Future<void> queueForSync({
    required String id,
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    // PowerSync handles sync automatically via the repository layer
    // This method exists for backward compatibility
    logDebug('queueForSync called for $entityType:$id (PowerSync handles sync automatically)');
  }
}

/// Provider for sync service
final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  return SyncService(ref);
});

/// Provider for sync status
final syncStatusProvider = Provider<SyncStatusEnum>((ref) {
  return ref.watch(syncServiceProvider).status;
});

/// Provider for pending count
final syncPendingCountProvider = Provider<int>((ref) {
  return ref.watch(syncServiceProvider).pendingCount;
});

/// Helper to unawait futures
void unawaited(Future<void>? future) {
  // Intentionally not awaiting
}
