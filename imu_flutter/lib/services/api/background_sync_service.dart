import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_api_service.dart';
import 'touchpoint_api_service.dart';
import '../connectivity_service.dart';
import '../local_storage/hive_service.dart';
import '../../shared/providers/app_providers.dart';

// Re-export needed providers
export 'client_api_service.dart' show clientApiServiceProvider;
export 'touchpoint_api_service.dart' show touchpointApiServiceProvider;

/// Background sync service for automatic data synchronization
class BackgroundSyncService extends ChangeNotifier {
  final ClientApiService _clientApi;
  final TouchpointApiService _touchpointApi;
  final ConnectivityService _connectivityService;
  final HiveService _hiveService;

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  int _syncIntervalMinutes = 5; // Default 5 minutes
  int _syncAttempts = 0;
  static const int maxSyncAttempts = 3;

  BackgroundSyncService({
    required ClientApiService clientApi,
    required TouchpointApiService touchpointApi,
    required ConnectivityService connectivityService,
    required HiveService hiveService,
  })  : _clientApi = clientApi,
       _touchpointApi = touchpointApi,
       _connectivityService = connectivityService,
       _hiveService = hiveService;

  /// Start background sync
  void startBackgroundSync() {
    _syncTimer = Timer.periodic(
      Duration(minutes: _syncIntervalMinutes),
      (timer) => _performSync(),
    );
    debugPrint('BackgroundSyncService: Started with interval of $_syncIntervalMinutes minutes');
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('BackgroundSyncService: Stopped');
  }

  /// Perform sync
  Future<void> _performSync() async {
    if (_isSyncing) return;

    final isOnline = _connectivityService.isOnline;
    if (!isOnline) {
      debugPrint('BackgroundSyncService: Offline, skipping sync');
      return;
    }

    _isSyncing = true;
    _syncAttempts++;
    notifyListeners();

    try {
      // Sync clients
      await _syncClients();

      // Sync touchpoints
      await _syncTouchpoints();

      _lastSyncTime = DateTime.now();
      debugPrint('BackgroundSyncService: Sync completed successfully');
    } catch (e) {
      debugPrint('BackgroundSyncService: Sync failed: $e');
      if (_syncAttempts >= maxSyncAttempts) {
        debugPrint('BackgroundSyncService: Max attempts reached');
      }
    } finally {
    _isSyncing = false;
    notifyListeners();
  }
  }

  /// Sync clients with backend
  Future<void> _syncClients() async {
    try {
    final clients = await _clientApi.fetchClients();
    debugPrint('BackgroundSyncService: Synced ${clients.length} clients');
  } catch (e) {
    debugPrint('BackgroundSyncService: Error syncing clients: $e');
    rethrow;
  }
  }

  /// Sync touchpoints with backend
  Future<void> _syncTouchpoints() async {
    try {
    // Note: This would need a method to fetch all touchpoints
    // For now, just log that we would sync touchpoints
    debugPrint('BackgroundSyncService: Touchpoints sync placeholder');
  } catch (e) {
    debugPrint('BackgroundSyncService: Error syncing touchpoints: $e');
    rethrow;
  }
  }

  /// Get sync status
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncAttempts => _syncAttempts;
}

/// Provider for BackgroundSyncService
final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  return BackgroundSyncService(
    clientApi: ref.watch(clientApiServiceProvider),
    touchpointApi: ref.watch(touchpointApiServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
  );
});
