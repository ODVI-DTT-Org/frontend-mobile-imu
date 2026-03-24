import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_api_service.dart';
import 'touchpoint_api_service.dart';
import '../connectivity_service.dart';
import '../local_storage/hive_service.dart';
import 'sync_queue_service.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../shared/providers/app_providers.dart';

// Re-export needed providers from their source files
export 'touchpoint_api_service.dart' show touchpointApiServiceProvider;
export 'sync_queue_service.dart' show syncQueueServiceProvider;

/// Offline touchpoint service for managing touchpoints without network
class OfflineTouchpointService extends ChangeNotifier {
  final TouchpointApiService _touchpointApi;
  final HiveService _hiveService;
  final ConnectivityService _connectivityService;
  final SyncQueueService _syncQueue;

  OfflineTouchpointService({
    required TouchpointApiService touchpointApi,
    required HiveService hiveService,
    required ConnectivityService connectivityService,
    required SyncQueueService syncQueue,
  })  : _touchpointApi = touchpointApi,
        _hiveService = hiveService,
        _connectivityService = connectivityService,
        _syncQueue = syncQueue;

  /// Create touchpoint offline (queues operation)
  Future<Touchpoint> createTouchpointOffline(Touchpoint touchpoint) async {
    if (_connectivityService.isOnline) {
      // If online, try to sync directly
      final result = await _touchpointApi.createTouchpoint(touchpoint);
      return result ?? touchpoint;
    }

    // Queue for offline sync
    await _syncQueue.queueOperation(
      id: touchpoint.id,
      operation: 'create',
      entityType: 'touchpoint',
      data: touchpoint.toJson(),
    );

    // Save to local storage
    await _hiveService.addTouchpoint(touchpoint.toJson());
    return touchpoint;
  }

  /// Update touchpoint offline (queues operation)
  Future<Touchpoint> updateTouchpointOffline(Touchpoint touchpoint) async {
    if (_connectivityService.isOnline) {
      // If online, try to sync directly
      final result = await _touchpointApi.updateTouchpoint(touchpoint);
      return result ?? touchpoint;
    }

    // Queue for offline sync
    await _syncQueue.queueOperation(
      id: touchpoint.id,
      operation: 'update',
      entityType: 'touchpoint',
      data: touchpoint.toJson(),
    );

    // Update in local storage
    await _hiveService.updateTouchpoint(touchpoint.toJson());
    return touchpoint;
  }

  /// Delete touchpoint offline (queues operation)
  Future<void> deleteTouchpointOffline(String touchpointId) async {
    if (_connectivityService.isOnline) {
      // If online, try to sync directly
      return await _touchpointApi.deleteTouchpoint(touchpointId);
    }

    // Queue for offline sync
    await _syncQueue.queueOperation(
      id: touchpointId,
      operation: 'delete',
      entityType: 'touchpoint',
      data: {'id': touchpointId},
    );

    // Remove from local storage
    await _hiveService.deleteTouchpoint(touchpointId);
  }

  /// Fetch touchpoints for client from local storage (offline)
  Future<List<Touchpoint>> fetchTouchpointsForClientOffline(String clientId) async {
    final touchpointsData = _hiveService.getTouchpointsForClient(clientId);
    return touchpointsData.map((data) {
      try {
        return Touchpoint.fromJson(data);
      } catch (e) {
        debugPrint('OfflineTouchpointService: Error parsing touchpoint: $e');
        // Return a default touchpoint if parsing fails
        return Touchpoint.fromJson({
          ...data,
          'type': TouchpointType.visit.name,
        });
      }
    }).toList();
  }
}

/// Provider for OfflineTouchpointService
final offlineTouchpointServiceProvider = Provider<OfflineTouchpointService>((ref) {
  return OfflineTouchpointService(
    touchpointApi: ref.watch(touchpointApiServiceProvider),
    hiveService: ref.watch(hiveServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    syncQueue: ref.watch(syncQueueServiceProvider),
  );
});
