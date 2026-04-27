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
  Timer? _fastRetryTimer;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  AppLifecycleState? _lifecycleState;

  // Sync state
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  int _pendingCount = 0;
  bool _isInitialized = false;

  // Configuration
  Duration _syncInterval = const Duration(minutes: 15); // Default 15 minutes
  Duration _pendingCheckInterval = const Duration(minutes: 2); // Check pending count every 2min
  static const Duration _fastRetryInterval = Duration(seconds: 60); // Active retry while drain pending

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

  /// Start fast-retry loop — fires every 60s while pendingCount > 0.
  /// Self-terminates when the queue drains. Used after a failed sync or
  /// PowerSync connect error so stranded uploads aren't stuck waiting for
  /// the 15-minute periodic timer.
  void _startFastRetry() {
    if (_fastRetryTimer != null) return; // already running
    logDebug('BackgroundSyncService: Starting fast-retry loop ($_pendingCount pending)');
    _fastRetryTimer = Timer.periodic(_fastRetryInterval, (_) async {
      if (_pendingCount <= 0) {
        _stopFastRetry();
        return;
      }
      if (_isOnlineAndAuthenticated() && !_isSyncing) {
        logDebug('BackgroundSyncService: Fast retry fired ($_pendingCount pending)');
        performSync();
      }
    });
  }

  void _stopFastRetry() {
    if (_fastRetryTimer == null) return;
    logDebug('BackgroundSyncService: Stopping fast-retry loop');
    _fastRetryTimer?.cancel();
    _fastRetryTimer = null;
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
        _lastSyncError = 'Failed to connect to sync service';
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
        // Pending uploads are stranded — kick off the fast-retry loop so the
        // next attempt happens in 60s instead of waiting for the 15min timer.
        await _updatePendingCount();
        if (_pendingCount > 0) _startFastRetry();
        notifyListeners();
        return SyncResult(
          success: false,
          errorMessage: 'Failed to connect to sync service',
        );
      }
    }

    _isSyncing = true;
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
      await _waitForPendingUploads();

      _lastSyncTime = DateTime.now();
      _lastSyncError = null;

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

      // Drained — stop the fast-retry loop. If anything remains (timeout
      // path), keep retrying until it clears.
      if (_pendingCount == 0) {
        _stopFastRetry();
      } else {
        _startFastRetry();
      }

      notifyListeners();

      return SyncResult(
        success: true,
        syncedCount: _pendingCount,
      );
    } catch (e, stackTrace) {
      _lastSyncError = e.toString();

      logError('BackgroundSyncService: Sync failed', e, stackTrace);

      // Log critical error - sync failed
      await ErrorLoggingHelper.logCriticalError(
        operation: 'background sync',
        error: e,
        stackTrace: stackTrace,
        context: {
          'pendingCount': _pendingCount.toString(),
        },
      );

      // Pending uploads are stranded — kick off the fast-retry loop instead
      // of recursing into performSync (which the _isSyncing guard would have
      // blocked anyway, since finally hasn't fired yet).
      await _updatePendingCount();
      if (_pendingCount > 0) _startFastRetry();

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

  /// Wait for pending uploads to complete (with timeout).
  /// Returns true if all uploads cleared, false if timed out with items remaining.
  Future<bool> _waitForPendingUploads() async {
    const maxWaitTime = Duration(seconds: 60);
    const pollInterval = Duration(milliseconds: 500);
    const logInterval = Duration(seconds: 10);
    final startTime = DateTime.now();
    DateTime lastLogTime = startTime;

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final pending = await PowerSyncService.pendingUploadCount;
      _pendingCount = pending;

      if (pending == 0) {
        logDebug('BackgroundSyncService: All pending uploads completed');
        return true;
      }

      // Only log every 10 seconds instead of every poll
      if (DateTime.now().difference(lastLogTime) >= logInterval) {
        logDebug('BackgroundSyncService: Waiting for $pending uploads to complete...');
        lastLogTime = DateTime.now();
      }

      await Future.delayed(pollInterval);
    }

    // Timed out with items still pending — log to console only (NOT to
    // PowerSync error_logs: that would create new CRUD entries, stacking the queue).
    logWarning('BackgroundSyncService: Timeout waiting for uploads ($_pendingCount remaining)');
    _lastSyncError = '$_pendingCount item${_pendingCount == 1 ? '' : 's'} could not be synced. '
        'Open Sync Status to retry or remove pending items.';
    notifyListeners();
    return false;
  }

  /// Update pending count from PowerSync CRUD queue
  Future<void> _updatePendingCount() async {
    try {
      _pendingCount = await PowerSyncService.pendingUploadCount;
      if (_pendingCount > 0) {
        logDebug('BackgroundSyncService: $_pendingCount pending uploads in PowerSync queue');
      }
      notifyListeners();
    } catch (e) {
      // Log to console only — writing to error_logs via PowerSync would create
      // new CRUD entries and stack the pending queue.
      logError('BackgroundSyncService: Failed to update pending count', e);
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
    _stopFastRetry();
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
final backgroundSyncServiceProvider = ChangeNotifierProvider<BackgroundSyncService>((ref) {
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
