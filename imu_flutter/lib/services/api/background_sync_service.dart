import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import '../connectivity_service.dart';
import '../sync/powersync_service.dart';
import '../auth/jwt_auth_service.dart';
import '../auth/auth_service.dart' show jwtAuthProvider;
import '../sync/powersync_connector.dart';
import '../error_logging_helper.dart';
import '../../core/utils/logger.dart';
import '../../core/config/app_config.dart';
import '../touchpoint/pending_touchpoint_service.dart';
import '../api/touchpoint_api_service.dart';
import '../visit/pending_visit_service.dart';
import '../visit/models/pending_visit.dart';
import '../release/pending_release_service.dart';
import '../release/models/pending_release.dart';
import '../client/pending_client_service.dart';
import '../client/client_mutation_service.dart';
import '../client/models/pending_client_operation.dart';
import 'client_api_service.dart' show ClientApiService;
import '../../features/clients/data/models/client_model.dart' show Client;
import 'visit_api_service.dart' show VisitApiService;
import 'release_api_service.dart' show ReleaseApiService;

/// Background sync service for automatic data synchronization
///
/// This service manages:
/// - App lifecycle-based sync (foreground/background)
/// - Network connectivity change-based sync
/// - Periodic interval-based sync
/// - Post-mutation sync (after create/update operations)
///
/// Integrates with PowerSync for automatic two-way sync.
class BackgroundSyncService extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final JwtAuthService _authService;

  Timer? _syncTimer;
  Timer? _pendingCheckTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  AppLifecycleState? _lifecycleState;

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingCount = 0;
  bool _isInitialized = false;

  // Configuration
  Duration _syncInterval = const Duration(minutes: 5); // Default 5 minutes
  Duration _pendingCheckInterval = const Duration(seconds: 30); // Check pending count every 30s
  static const int _maxSyncRetries = 3;
  int _currentSyncRetry = 0;

  // Sync status callbacks
  final List<Function()> _syncStartCallbacks = [];
  final List<Function(DateTime)> _syncCompleteCallbacks = [];
  final List<Function(String, dynamic)> _syncErrorCallbacks = [];

  BackgroundSyncService({
    required ConnectivityService connectivityService,
    required JwtAuthService authService,
  })  : _connectivityService = connectivityService,
        _authService = authService;

  // Getters
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  int get pendingCount => _pendingCount;
  bool get isInitialized => _isInitialized;

  /// Initialize the background sync service
  Future<void> initialize() async {
    if (_isInitialized) {
      logDebug('BackgroundSyncService: Already initialized');
      return;
    }

    logDebug('BackgroundSyncService: Initializing...');

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.statusStream.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync timer
    _startPeriodicSync();

    // Start pending count check timer
    _startPendingCheckTimer();

    // Get initial pending count
    await _updatePendingCount();

    _isInitialized = true;
    logDebug('BackgroundSyncService: Initialized with $_syncInterval interval');
  }

  /// Handle app lifecycle changes (called from WidgetsBindingObserver)
  void handleAppLifecycleChange(AppLifecycleState state) {
    _lifecycleState = state;
    logDebug('BackgroundSyncService: App lifecycle changed to $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - trigger sync
        logDebug('[LIFECYCLE] App resumed - checking storage...');
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background - just log
        logDebug('[LIFECYCLE] App paused/detached - storage may be cleared by Samsung memory management');
        break;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      if (_isOnlineAndAuthenticated()) {
        logDebug('BackgroundSyncService: Periodic sync triggered');
        performSync();
      }
    });
    logDebug('BackgroundSyncService: Periodic sync timer started (${_syncInterval.inMinutes}min interval)');
  }

  /// Stop periodic sync timer
  void _stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    logDebug('BackgroundSyncService: Periodic sync timer stopped');
  }

  /// Start pending count check timer
  void _startPendingCheckTimer() {
    _pendingCheckTimer?.cancel();
    _pendingCheckTimer = Timer.periodic(_pendingCheckInterval, (_) {
      _updatePendingCount();
    });
  }

  /// Stop pending count check timer
  void _stopPendingCheckTimer() {
    _pendingCheckTimer?.cancel();
    _pendingCheckTimer = null;
  }

  /// Handle app resumed event
  void _onAppResumed() {
    final isAuth = _authService.isAuthenticated;
    final isOnline = _connectivityService.isOnline;

    logDebug('BackgroundSyncService: App resumed - isOnline=$isOnline, isAuthenticated=$isAuth');

    if (!isAuth) {
      logDebug('BackgroundSyncService: Not authenticated, skipping sync on resume');
      return;
    }

    if (!isOnline) {
      logDebug('BackgroundSyncService: Not online, skipping sync on resume');
      return;
    }

    // Check if it's been more than 1 minute since last sync
    if (_lastSyncTime != null) {
      final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);
      if (timeSinceLastSync < const Duration(minutes: 1)) {
        logDebug('BackgroundSyncService: Recent sync (${timeSinceLastSync.inSeconds}s ago), skipping');
        return;
      }
    }

    logDebug('BackgroundSyncService: App resumed, triggering sync');
    performSync();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(ConnectivityStatus status) {
    logDebug('BackgroundSyncService: Connectivity changed to $status');

    if (status == ConnectivityStatus.online) {
      // Just came back online - trigger sync if authenticated
      if (_authService.isAuthenticated) {
        logDebug('BackgroundSyncService: Back online and authenticated, triggering sync');
        performSync();
      }
    }
  }

  /// Perform immediate sync (triggered by user or automatic events)
  Future<SyncResult> performSync() async {
    if (!_isOnlineAndAuthenticated()) {
      final result = SyncResult(
        success: false,
        errorMessage: _authService.isAuthenticated ? 'Offline' : 'Not authenticated',
      );
      return result;
    }

    if (_isSyncing) {
      logDebug('BackgroundSyncService: Sync already in progress');
      return SyncResult(
        success: false,
        errorMessage: 'Sync already in progress',
      );
    }

    if (!PowerSyncService.isConnected) {
      logDebug('BackgroundSyncService: PowerSync not connected, connecting...');
      try {
        await _connectPowerSync();
      } catch (e, stackTrace) {
        logError('BackgroundSyncService: Failed to connect PowerSync', e);
        // Log critical error - PowerSync connection blocks all sync operations
        await ErrorLoggingHelper.logCriticalError(
          operation: 'PowerSync connection',
          error: e,
          stackTrace: stackTrace,
          context: {
            'isAuthenticated': _authService.isAuthenticated,
            'isOnline': _connectivityService.isOnline,
          },
        );
        return SyncResult(
          success: false,
          errorMessage: 'Failed to connect to sync service',
        );
      }
    }

    _isSyncing = true;
    _currentSyncRetry = 0;
    notifyListeners();

    // Notify sync start
    for (final callback in _syncStartCallbacks) {
      try {
        callback();
      } catch (e) {
        logError('BackgroundSyncService: Error in sync start callback', e);
      }
    }

    logDebug('BackgroundSyncService: Starting sync...');

    try {
      // PowerSync automatically handles both upload and download
      // We just need to wait for pending uploads to complete
      await _waitForPendingUploads();

      // Sync pending touchpoints created while offline
      await _syncPendingTouchpoints();

      // Sync pending visits and releases created while offline
      await _syncPendingVisits();
      await _syncPendingReleases();

      // Sync pending client mutations created while offline
      await _syncPendingClients();

      _lastSyncTime = DateTime.now();
      _lastSyncError = null;
      _currentSyncRetry = 0;

      await _updatePendingCount();

      logDebug('BackgroundSyncService: Sync completed successfully');

      // Notify sync complete
      for (final callback in _syncCompleteCallbacks) {
        try {
          callback(_lastSyncTime!);
        } catch (e) {
          logError('BackgroundSyncService: Error in sync complete callback', e);
        }
      }

      notifyListeners();

      return SyncResult(
        success: true,
        syncedCount: _pendingCount,
      );
    } catch (e, stackTrace) {
      _lastSyncError = e.toString();
      _currentSyncRetry++;

      logError('BackgroundSyncService: Sync failed (attempt $_currentSyncRetry/$_maxSyncRetries)', e, stackTrace);

      // Retry if max retries not reached
      if (_currentSyncRetry < _maxSyncRetries) {
        logDebug('BackgroundSyncService: Retrying sync in 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        return performSync();
      }

      // Log critical error - sync failed after all retries
      await ErrorLoggingHelper.logCriticalError(
        operation: 'background sync',
        error: e,
        stackTrace: stackTrace,
        context: {
          'retryCount': _currentSyncRetry.toString(),
          'maxRetries': _maxSyncRetries.toString(),
          'pendingCount': _pendingCount.toString(),
        },
      );

      // Notify sync error
      for (final callback in _syncErrorCallbacks) {
        try {
          callback(e.toString(), e);
        } catch (err) {
          logError('BackgroundSyncService: Error in sync error callback', err);
        }
      }

      notifyListeners();

      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Wait for pending uploads to complete (with timeout)
  Future<void> _waitForPendingUploads() async {
    const maxWaitTime = Duration(seconds: 60);
    const pollInterval = Duration(milliseconds: 500);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final pending = await PowerSyncService.pendingUploadCount;
      _pendingCount = pending;

      if (pending == 0) {
        logDebug('BackgroundSyncService: All pending uploads completed');
        break;
      }

      logDebug('BackgroundSyncService: Waiting for $pending uploads to complete...');
      await Future.delayed(pollInterval);
    }

    if (DateTime.now().difference(startTime) >= maxWaitTime) {
      logWarning('BackgroundSyncService: Timeout waiting for uploads to complete');
      // Log non-critical error - timeout doesn't block workflow but indicates performance issue
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'sync timeout',
        error: Exception('Sync timeout after ${maxWaitTime.inSeconds}s with $_pendingCount pending uploads'),
        stackTrace: StackTrace.current,
        context: {
          'pendingCount': _pendingCount.toString(),
          'maxWaitTime': '${maxWaitTime.inSeconds}s',
        },
      );
    }
  }

  /// Update pending count from PowerSync
  Future<void> _updatePendingCount() async {
    try {
      final powerSyncPending = await PowerSyncService.pendingUploadCount;
      final hiveTouchpoints = await PendingTouchpointService().getPendingCount();
      final hiveVisits = await PendingVisitService().getPendingCount();
      final hiveReleases = await PendingReleaseService().getPendingCount();
      final hiveClients = await PendingClientService().getPendingCount();
      _pendingCount = powerSyncPending + hiveTouchpoints + hiveVisits + hiveReleases + hiveClients;
      if (_pendingCount > 0) {
        logDebug('BackgroundSyncService: $_pendingCount pending uploads');
      }
      notifyListeners();
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to update pending count', e);
      // Log non-critical error - pending count update doesn't block workflow
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'pending count update',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sync pending touchpoints created while offline
  ///
  /// This method:
  /// 1. Fetches all pending touchpoints from Hive storage
  /// 2. Attempts to sync each touchpoint to the backend API
  /// 3. Removes successfully synced touchpoints from pending storage
  /// 4. Handles errors for failed sync attempts
  Future<void> _syncPendingTouchpoints() async {
    try {
      logDebug('BackgroundSyncService: Checking for pending touchpoints...');

      final pendingService = PendingTouchpointService();
      final pendingTouchpoints = await pendingService.getPendingTouchpoints();

      if (pendingTouchpoints.isEmpty) {
        logDebug('BackgroundSyncService: No pending touchpoints to sync');
        return;
      }

      logDebug('BackgroundSyncService: Found ${pendingTouchpoints.length} pending touchpoints');

      // Import API service (lazy import to avoid circular dependency)
      final touchpointApi = TouchpointApiService();

      int syncedCount = 0;
      int failedCount = 0;

      for (final pending in pendingTouchpoints) {
        try {
          logDebug('BackgroundSyncService: Syncing touchpoint for client ${pending.clientId}');

          // Reconstruct File objects from saved paths if they exist
          File? photoFile;
          File? audioFile;

          if (pending.photoPath != null) {
            photoFile = File(pending.photoPath!);
            if (!await photoFile.exists()) {
              logWarning('BackgroundSyncService: Photo file not found: ${pending.photoPath}');
              photoFile = null;
            }
          }

          if (pending.audioPath != null) {
            audioFile = File(pending.audioPath!);
            if (!await audioFile.exists()) {
              logWarning('BackgroundSyncService: Audio file not found: ${pending.audioPath}');
              audioFile = null;
            }
          }

          // Call API to create touchpoint
          if (photoFile != null) {
            await touchpointApi.createTouchpointWithPhoto(
              pending.touchpoint,
              photoFile: photoFile,
            );
          } else {
            await touchpointApi.createTouchpoint(pending.touchpoint);
          }

          // Remove from pending storage after successful sync
          await pendingService.removePendingTouchpoint(pending.id);

          // Clean up saved files
          if (pending.photoPath != null) {
            try {
              await File(pending.photoPath!).delete();
              logDebug('BackgroundSyncService: Deleted saved photo: ${pending.photoPath}');
            } catch (e) {
              logWarning('BackgroundSyncService: Failed to delete saved photo: $e');
            }
          }

          if (pending.audioPath != null) {
            try {
              await File(pending.audioPath!).delete();
              logDebug('BackgroundSyncService: Deleted saved audio: ${pending.audioPath}');
            } catch (e) {
              logWarning('BackgroundSyncService: Failed to delete saved audio: $e');
            }
          }

          syncedCount++;
          logDebug('BackgroundSyncService: Successfully synced touchpoint ${pending.touchpoint.id}');
        } catch (e, stackTrace) {
          failedCount++;
          logError('BackgroundSyncService: Failed to sync pending touchpoint ${pending.id}', e, stackTrace);
          // Continue with next touchpoint instead of failing entire batch
        }
      }

      logDebug('BackgroundSyncService: Pending touchpoints sync complete - $syncedCount synced, $failedCount failed');

      if (failedCount > 0) {
        // Log non-critical error - some touchpoints failed to sync but will be retried
        await ErrorLoggingHelper.logNonCriticalError(
          operation: 'pending touchpoints sync',
          error: Exception('$failedCount of ${pendingTouchpoints.length} touchpoints failed to sync'),
          stackTrace: StackTrace.current,
          context: {
            'syncedCount': syncedCount.toString(),
            'failedCount': failedCount.toString(),
            'totalPending': pendingTouchpoints.length.toString(),
          },
        );
      }
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to sync pending touchpoints', e, stackTrace);
      // Log non-critical error - pending touchpoints sync doesn't block main sync
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'pending touchpoints sync',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sync pending visits stored while offline
  Future<void> _syncPendingVisits() async {
    try {
      final pendingService = PendingVisitService();
      final pendingVisits = await pendingService.getPendingVisits();

      if (pendingVisits.isEmpty) return;

      logDebug('BackgroundSyncService: Syncing ${pendingVisits.length} pending visits');
      final visitApi = VisitApiService();
      int syncedCount = 0;

      for (final pending in pendingVisits) {
        try {
          File? photoFile;
          if (pending.photoPath != null) {
            final f = File(pending.photoPath!);
            if (await f.exists()) photoFile = f;
          }

          await visitApi.createVisit(
            clientId: pending.clientId,
            timeIn: pending.timeIn,
            timeOut: pending.timeOut,
            odometerArrival: pending.odometerArrival,
            odometerDeparture: pending.odometerDeparture,
            photoFile: photoFile,
            notes: pending.notes,
            type: pending.type,
          );

          await pendingService.removePendingVisit(pending.id);
          if (pending.photoPath != null) {
            try { await File(pending.photoPath!).delete(); } catch (_) {}
          }
          syncedCount++;
        } catch (e) {
          logError('BackgroundSyncService: Failed to sync pending visit ${pending.id}', e);
        }
      }

      logDebug('BackgroundSyncService: Visits sync complete - $syncedCount/${pendingVisits.length} synced');
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to sync pending visits', e, stackTrace);
    }
  }

  /// Sync pending loan releases stored while offline
  Future<void> _syncPendingReleases() async {
    try {
      final pendingService = PendingReleaseService();
      final pendingReleases = await pendingService.getPendingReleases();

      if (pendingReleases.isEmpty) return;

      logDebug('BackgroundSyncService: Syncing ${pendingReleases.length} pending releases');
      final releaseApi = ReleaseApiService();
      int syncedCount = 0;

      for (final pending in pendingReleases) {
        try {
          await releaseApi.createCompleteLoanRelease(
            clientId: pending.clientId,
            timeIn: pending.timeIn,
            timeOut: pending.timeOut,
            odometerArrival: pending.odometerArrival,
            odometerDeparture: pending.odometerDeparture,
            productType: pending.productType,
            loanType: pending.loanType,
            udiNumber: pending.udiNumber,
            remarks: pending.remarks,
            photoPath: pending.photoPath,
          );

          await pendingService.removePendingRelease(pending.id);
          if (pending.photoPath != null) {
            try { await File(pending.photoPath!).delete(); } catch (_) {}
          }
          syncedCount++;
        } catch (e) {
          logError('BackgroundSyncService: Failed to sync pending release ${pending.id}', e);
        }
      }

      logDebug('BackgroundSyncService: Releases sync complete - $syncedCount/${pendingReleases.length} synced');
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to sync pending releases', e, stackTrace);
    }
  }

  /// Sync pending client mutations (create/update/delete) stored while offline
  Future<void> _syncPendingClients() async {
    try {
      final pendingService = PendingClientService();
      final allOps = await pendingService.getAll();

      if (allOps.isEmpty) return;

      final collapsed = pendingService.collapse(allOps);
      logDebug('BackgroundSyncService: Syncing ${collapsed.length} collapsed client ops (${allOps.length} raw)');

      final clientApi = ClientApiService();
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();

      for (final op in collapsed) {
        try {
          switch (op.operation) {
            case ClientOperationType.create:
              final client = Client.fromJson(op.clientData!);
              final result = await clientApi.createClient(client);
              if (result?.id != null) {
                await hiveService.deleteClient(op.clientId);
                await hiveService.saveClient(result!.id!, result.toJson());
              }
            case ClientOperationType.update:
              final client = Client.fromJson(op.clientData!);
              final result = await clientApi.updateClient(client);
              if (result != null) {
                await hiveService.saveClient(result.id!, result.toJson());
              }
            case ClientOperationType.delete:
              await clientApi.deleteClient(op.clientId);
          }
          await pendingService.removeAllForClient(op.clientId);
        } catch (e) {
          logError('BackgroundSyncService: Failed to sync client op ${op.id}', e);
        }
      }

      logDebug('BackgroundSyncService: Clients sync complete');
    } catch (e, stackTrace) {
      logError('BackgroundSyncService: Failed to sync pending clients', e, stackTrace);
    }
  }

  /// Connect to PowerSync
  Future<void> _connectPowerSync() async {
    final connector = IMUPowerSyncConnector(
      authService: _authService,
      powersyncUrl: AppConfig.powerSyncUrl,
      apiUrl: AppConfig.postgresApiUrl,
    );

    await PowerSyncService.connect(connector);
    logDebug('BackgroundSyncService: Connected to PowerSync');
  }

  /// Check if online and authenticated
  bool _isOnlineAndAuthenticated() {
    return _connectivityService.isOnline && _authService.isAuthenticated;
  }

  /// Trigger sync after a data mutation (create/update)
  ///
  /// This should be called after any local data changes to ensure
  /// they are synced to the server promptly.
  void triggerSyncAfterMutation() {
    if (!_isOnlineAndAuthenticated()) {
      logDebug('BackgroundSyncService: Not online/authenticated, mutation sync pending');
      return;
    }

    if (_isSyncing) {
      logDebug('BackgroundSyncService: Already syncing, mutation will be included');
      return;
    }

    // Trigger sync after a short delay to batch multiple mutations
    Future.delayed(const Duration(seconds: 2), () {
      if (_isOnlineAndAuthenticated() && !_isSyncing) {
        logDebug('BackgroundSyncService: Triggering sync after mutation');
        performSync();
      }
    });
  }

  /// Set sync interval
  void setSyncInterval(Duration interval) {
    if (_syncInterval != interval) {
      _syncInterval = interval;
      if (_isInitialized) {
        _startPeriodicSync(); // Restart with new interval
      }
      logDebug('BackgroundSyncService: Sync interval set to ${interval.inMinutes}min');
    }
  }

  /// Register callback for sync start
  void onSyncStart(Function() callback) {
    _syncStartCallbacks.add(callback);
  }

  /// Register callback for sync complete
  void onSyncComplete(Function(DateTime) callback) {
    _syncCompleteCallbacks.add(callback);
  }

  /// Register callback for sync error
  void onSyncError(Function(String, dynamic) callback) {
    _syncErrorCallbacks.add(callback);
  }

  /// Unregister all callbacks
  void clearCallbacks() {
    _syncStartCallbacks.clear();
    _syncCompleteCallbacks.clear();
    _syncErrorCallbacks.clear();
  }

  /// Dispose resources
  @override
  void dispose() {
    logDebug('BackgroundSyncService: Disposing...');
    _stopPeriodicSync();
    _stopPendingCheckTimer();
    _connectivitySubscription?.cancel();
    clearCallbacks();
    super.dispose();
  }
}

/// Sync result model
class SyncResult {
  final bool success;
  final int syncedCount;
  final String? errorMessage;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.errorMessage,
  });
}

/// Provider for BackgroundSyncService
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  final jwtAuth = ref.watch(jwtAuthProvider);

  final service = BackgroundSyncService(
    connectivityService: connectivityService,
    authService: jwtAuth,
  );

  ref.onDispose(() => service.dispose());

  return service;
});

/// Provider for background sync status
final backgroundSyncStatusProvider = Provider<BackgroundSyncStatus>((ref) {
  final service = ref.watch(backgroundSyncServiceProvider);
  return BackgroundSyncStatus(
    isSyncing: service.isSyncing,
    lastSyncTime: service.lastSyncTime,
    lastSyncError: service.lastSyncError,
    pendingCount: service.pendingCount,
    isInitialized: service.isInitialized,
  );
});

/// Background sync status model
class BackgroundSyncStatus {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? lastSyncError;
  final int pendingCount;
  final bool isInitialized;

  BackgroundSyncStatus({
    required this.isSyncing,
    this.lastSyncTime,
    this.lastSyncError,
    this.pendingCount = 0,
    this.isInitialized = false,
  });

  /// Get formatted last sync time
  String get lastSyncFormatted {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Get status message
  String get statusMessage {
    if (isSyncing) return 'Syncing...';
    if (lastSyncError != null) return 'Sync failed: ${lastSyncError}';
    if (pendingCount > 0) return '$pendingCount pending';
    if (lastSyncTime != null) return 'Synced ${lastSyncFormatted}';
    return 'Ready to sync';
  }
}
