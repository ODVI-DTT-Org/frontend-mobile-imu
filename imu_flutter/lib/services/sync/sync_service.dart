import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pocketbase/pocketbase.dart';
import '../local_storage/hive_service.dart';
import '../api/pocketbase_client.dart';

// Note: SyncStatus and SyncResult are defined in hive_service.dart

/// Sync service for managing offline/online data synchronization with PocketBase
class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final HiveService _hiveService = HiveService();
  final Connectivity _connectivity = Connectivity();
  PocketBase? _pb;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
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
    // Get PocketBase instance
    try {
      final pbClient = PocketBaseClient();
      if (!pbClient.isInitialized) {
        await pbClient.initialize();
      }
      _pb = pbClient.instance;
    } catch (e) {
      debugPrint('SyncService: Failed to initialize PocketBase: $e');
    }

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

  /// Trigger full sync (pull + push)
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
      // Step 1: Push pending changes to server
      final pushResult = await _pushPendingChanges();
      _syncedCount = pushResult['synced'] as int;
      _failedCount = pushResult['failed'] as int;

      // Step 2: Pull latest data from server
      await _pullFromServer();

      await _updatePendingCount();

      _status = _failedCount > 0 ? SyncStatus.error : SyncStatus.success;
      _lastSyncTime = DateTime.now();

      if (_failedCount > 0) {
        _lastSyncError = 'Failed to sync $_failedCount items';
      }

      notifyListeners();

      return SyncResult(
        success: _failedCount == 0,
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

  /// Push pending changes to PocketBase
  Future<Map<String, int>> _pushPendingChanges() async {
    final pendingItems = _hiveService.getPendingSyncItems();

    if (pendingItems.isEmpty) {
      return {'synced': 0, 'failed': 0};
    }

    if (_pb == null) {
      debugPrint('SyncService: PocketBase not initialized');
      return {'synced': 0, 'failed': pendingItems.length};
    }

    int synced = 0;
    int failed = 0;

    for (final item in pendingItems) {
      try {
        await _syncWithBackoff(item);
        synced++;

        // Remove from pending queue after successful sync
        await _hiveService.removeFromPendingSync(
          item['entityType'] as String,
          item['id'] as String,
        );
      } catch (e) {
        debugPrint('Failed to sync item ${item['id']}: $e');
        failed++;
      }
    }

    return {'synced': synced, 'failed': failed};
  }

  /// Sync individual item with exponential backoff
  Future<void> _syncWithBackoff(
    Map<String, dynamic> item, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    final entityType = item['entityType'] as String;
    final operation = item['operation'] as String;
    final data = item['data'] as Map<String, dynamic>;
    final id = item['id'] as String;

    while (attempt < maxRetries) {
      try {
        // Map entity types to PocketBase collections
        String collection;
        switch (entityType) {
          case 'client':
            collection = 'clients';
            break;
          case 'touchpoint':
            collection = 'touchpoints';
            break;
          default:
            collection = entityType;
        }

        switch (operation) {
          case 'create':
            await _pb!.collection(collection).create(body: _mapToPocketBase(entityType, data));
            break;
          case 'update':
            await _pb!.collection(collection).update(id, body: _mapToPocketBase(entityType, data));
            break;
          case 'delete':
            await _pb!.collection(collection).delete(id);
            break;
        }

        debugPrint('Synced $operation on $entityType:$id');
        return; // Success
      } on ClientException catch (e) {
        attempt++;
        debugPrint('Sync attempt $attempt failed for $entityType:$id - ${e.response}');

        // Don't retry on 404 (already deleted) or 403 (no permission)
        if (e.statusCode == 404 || e.statusCode == 403) {
          debugPrint('Not retrying due to status ${e.statusCode}');
          rethrow;
        }

        if (attempt >= maxRetries) rethrow;

        // Exponential backoff: 1s, 2s, 4s
        final delay = Duration(seconds: pow(2, attempt).toInt());
        await Future.delayed(delay);
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) rethrow;

        final delay = Duration(seconds: pow(2, attempt).toInt());
        await Future.delayed(delay);
      }
    }
  }

  /// Map local data to PocketBase format
  Map<String, dynamic> _mapToPocketBase(String entityType, Map<String, dynamic> data) {
    switch (entityType) {
      case 'client':
        return {
          'first_name': data['firstName'],
          'last_name': data['lastName'],
          'middle_name': data['middleName'],
          'client_type': data['clientType'],
          'product_type': data['productType'],
          'market_type': data['marketType'],
          'pension_type': data['pensionType'],
          'email': data['email'],
          'phone': data['phone'],
          'is_starred': data['isStarred'] ?? false,
        };
      case 'touchpoint':
        return {
          'client_id': data['clientId'],
          'agent_id': data['agentId'],
          'touchpoint_number': data['touchpointNumber'],
          'type': data['type'],
          'reason': data['reason'],
          'date': data['date'],
          'address': data['address'],
          'time_arrival': data['timeArrival'],
          'time_departure': data['timeDeparture'],
          'odometer_start': data['odometerArrival'],
          'odometer_end': data['odometerDeparture'],
          'next_visit_date': data['nextVisitDate'],
          'notes': data['remarks'],
          'photo_path': data['photoPath'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
        };
      default:
        return data;
    }
  }

  /// Pull latest data from PocketBase
  Future<void> _pullFromServer() async {
    if (_pb == null || !_pb!.authStore.isValid) {
      debugPrint('SyncService: Not authenticated, skipping pull');
      return;
    }

    try {
      // Pull clients
      await _pullClients();

      // Pull touchpoints
      await _pullTouchpoints();

      debugPrint('Pull from server completed');
    } catch (e) {
      debugPrint('Error pulling from server: $e');
    }
  }

  /// Pull clients from PocketBase
  Future<void> _pullClients() async {
    try {
      final result = await _pb!.collection('clients').getList(
        page: 1,
        perPage: 500,
        sort: '-updated',
      );

      debugPrint('Pulled ${result.items.length} clients from server');

      for (final record in result.items) {
        final clientData = _mapFromPocketBaseClient(record);
        final existingClient = _hiveService.getClient(record.id);

        // Last-write-wins: compare updated timestamps
        if (existingClient != null) {
          final localUpdated = existingClient['updatedAt'] as String?;
          final serverUpdated = record.updated;

          // serverUpdated is never null from PocketBase, but check localUpdated
          if (localUpdated != null) {
            final serverTime = DateTime.parse(serverUpdated);
            final localTime = DateTime.parse(localUpdated);

            if (serverTime.isAfter(localTime)) {
              await _hiveService.saveClient(record.id, clientData);
            }
          } else {
            await _hiveService.saveClient(record.id, clientData);
          }
        }
      }

      // Cache last sync info
      _hiveService.cacheData('clients_last_sync', {
        'timestamp': DateTime.now().toIso8601String(),
        'count': result.items.length,
      });
    } on ClientException catch (e) {
      debugPrint('Error pulling clients: ${e.response}');
    }
  }

  /// Map PocketBase record to local client format
  Map<String, dynamic> _mapFromPocketBaseClient(RecordModel record) {
    return {
      'id': record.id,
      'firstName': record.data['first_name'],
      'lastName': record.data['last_name'],
      'middleName': record.data['middle_name'],
      'clientType': record.data['client_type'],
      'productType': record.data['product_type'],
      'marketType': record.data['market_type'],
      'pensionType': record.data['pension_type'],
      'email': record.data['email'],
      'phone': record.data['phone'],
      'isStarred': record.data['is_starred'] ?? false,
      'created': record.created,
      'updatedAt': record.updated,
    };
  }

  /// Pull touchpoints from PocketBase
  Future<void> _pullTouchpoints() async {
    try {
      final result = await _pb!.collection('touchpoints').getList(
        page: 1,
        perPage: 1000,
        sort: '-updated',
      );

      debugPrint('Pulled ${result.items.length} touchpoints from server');

      for (final record in result.items) {
        final touchpointData = _mapFromPocketBaseTouchpoint(record);
        await _hiveService.saveTouchpoint(record.id, touchpointData);
      }
    } on ClientException catch (e) {
      debugPrint('Error pulling touchpoints: ${e.response}');
    }
  }

  /// Map PocketBase record to local touchpoint format
  Map<String, dynamic> _mapFromPocketBaseTouchpoint(RecordModel record) {
    return {
      'id': record.id,
      'clientId': record.data['client_id'],
      'agentId': record.data['agent_id'],
      'touchpointNumber': record.data['touchpoint_number'],
      'type': record.data['type'],
      'reason': record.data['reason'],
      'date': record.data['date'],
      'address': record.data['address'],
      'timeArrival': record.data['time_arrival'],
      'timeDeparture': record.data['time_departure'],
      'odometerArrival': record.data['odometer_start'],
      'odometerDeparture': record.data['odometer_end'],
      'nextVisitDate': record.data['next_visit_date'],
      'remarks': record.data['notes'],
      'photoPath': record.data['photo_path'],
      'latitude': record.data['latitude'],
      'longitude': record.data['longitude'],
      'createdAt': record.created,
      'updatedAt': record.updated,
    };
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
  Future<bool> checkBackendConnection() async {
    if (_pb == null) return false;

    try {
      await _pb!.health.check();
      return true;
    } catch (e) {
      debugPrint('Backend connection check failed: $e');
      return false;
    }
  }
}

/// Helper to unawait futures
void unawaited(Future<void>? future) {
  // Intentionally not awaiting
}
