import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'client_api_service.dart';
import 'touchpoint_api_service.dart';
import '../local_storage/hive_service.dart';
import '../../features/clients/data/models/client_model.dart';

/// Conflict resolution strategy
enum ConflictResolution {
  localWins,
  serverWins,
  merge,
  askUser,
}

/// Conflict result
class ConflictResult {
  final bool resolved;
  final String? message;
  final dynamic resolvedData;
  final ConflictResolution? resolution;

  ConflictResult({
    required this.resolved,
    this.message,
    this.resolvedData,
    this.resolution,
  });
}

/// Sync conflict
class SyncConflict {
  final String id;
  final String entityType;
  final String operation;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime detectedAt;
  final String conflictType;

  SyncConflict({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.localData,
    required this.serverData,
    required this.detectedAt,
    required this.conflictType,
  });
}

/// Conflict resolver service for handling sync conflicts
class ConflictResolverService extends ChangeNotifier {
  final HiveService _hiveService;
  final ClientApiService _clientApi;
  final TouchpointApiService _touchpointApi;

  final List<SyncConflict> _conflicts = [];
  bool _isResolving = false;

  ConflictResolverService({
    required HiveService hiveService,
    required ClientApiService clientApi,
    required TouchpointApiService touchpointApi,
  })  : _hiveService = hiveService,
        _clientApi = clientApi,
        _touchpointApi = touchpointApi;

  List<SyncConflict> get conflicts => _conflicts;
  bool get isResolving => _isResolving;
  int get conflictCount => _conflicts.length;

  /// Detect conflicts between local and server data
  Future<List<SyncConflict>> detectConflicts({
    required String entityType,
    required List<Map<String, dynamic>> localItems,
    required List<Map<String, dynamic>> serverItems,
  }) async {
    final conflicts = <SyncConflict>[];

    for (final localItem in localItems) {
      final localId = localItem['id'] as String?;
      if (localId == null) continue;

      final serverItem = serverItems.firstWhere(
        (item) => item['id'] == localId,
        orElse: () => <String, dynamic>{},
      );

      if (serverItem.isNotEmpty) {
        final localUpdatedAt = localItem['updated'] != null
            ? DateTime.tryParse(localItem['updated'])
            : null;
        final serverUpdatedAt = serverItem['updated'] != null
            ? DateTime.tryParse(serverItem['updated'])
            : null;

        if (localUpdatedAt != null && serverUpdatedAt != null) {
          if (serverUpdatedAt.isAfter(localUpdatedAt)) {
            if (_hasDataConflict(localItem, serverItem)) {
              conflicts.add(SyncConflict(
                id: localId,
                entityType: entityType,
                operation: 'update',
                localData: localItem,
                serverData: serverItem,
                detectedAt: DateTime.now(),
                conflictType: 'update_conflict',
              ));
            }
          }
        }
      }
    }

    return conflicts;
  }

  bool _hasDataConflict(Map<String, dynamic> local, Map<String, dynamic> server) {
    final ignoreKeys = ['updated', 'created', 'synced_at'];

    for (final key in local.keys) {
      if (ignoreKeys.contains(key)) continue;
      if (local[key] != server[key]) return true;
    }

    return false;
  }

  Future<ConflictResult> resolveConflict(
    SyncConflict conflict, {
    ConflictResolution strategy = ConflictResolution.serverWins,
  }) async {
    try {
      switch (strategy) {
        case ConflictResolution.localWins:
          return await _resolveWithLocal(conflict);
        case ConflictResolution.serverWins:
          return await _resolveWithServer(conflict);
        case ConflictResolution.merge:
          return await _resolveWithMerge(conflict);
        case ConflictResolution.askUser:
          return ConflictResult(
            resolved: false,
            message: 'User decision required',
            resolvedData: null,
            resolution: ConflictResolution.askUser,
          );
      }
    } catch (e) {
      debugPrint('ConflictResolverService: Error resolving conflict: $e');
      return ConflictResult(
        resolved: false,
        message: 'Error resolving conflict: $e',
        resolvedData: null,
        resolution: null,
      );
    }
  }

  Future<ConflictResult> _resolveWithLocal(SyncConflict conflict) async {
    try {
      switch (conflict.entityType) {
        case 'client':
          await _clientApi.updateClient(Client.fromJson(conflict.localData));
          break;
        case 'touchpoint':
          await _touchpointApi.updateTouchpoint(Touchpoint.fromJson(conflict.localData));
          break;
      }

      return ConflictResult(
        resolved: true,
        message: 'Local version kept',
        resolvedData: conflict.localData,
        resolution: ConflictResolution.localWins,
      );
    } catch (e) {
      return ConflictResult(
        resolved: false,
        message: 'Failed to apply local version: $e',
        resolvedData: null,
        resolution: null,
      );
    }
  }

  Future<ConflictResult> _resolveWithServer(SyncConflict conflict) async {
    try {
      switch (conflict.entityType) {
        case 'client':
          await _hiveService.updateClient(conflict.serverData);
          break;
        case 'touchpoint':
          await _hiveService.updateTouchpoint(conflict.serverData);
          break;
      }

      return ConflictResult(
        resolved: true,
        message: 'Server version applied',
        resolvedData: conflict.serverData,
        resolution: ConflictResolution.serverWins,
      );
    } catch (e) {
      return ConflictResult(
        resolved: false,
        message: 'Failed to apply server version: $e',
        resolvedData: null,
        resolution: null,
      );
    }
  }

  Future<ConflictResult> _resolveWithMerge(SyncConflict conflict) async {
    try {
      final mergedData = _mergeData(conflict.localData, conflict.serverData);

      switch (conflict.entityType) {
        case 'client':
          await _clientApi.updateClient(Client.fromJson(mergedData));
          await _hiveService.updateClient(mergedData);
          break;
        case 'touchpoint':
          await _touchpointApi.updateTouchpoint(Touchpoint.fromJson(mergedData));
          await _hiveService.updateTouchpoint(mergedData);
          break;
      }

      return ConflictResult(
        resolved: true,
        message: 'Merged successfully',
        resolvedData: mergedData,
        resolution: ConflictResolution.merge,
      );
    } catch (e) {
      return ConflictResult(
        resolved: false,
        message: 'Failed to merge: $e',
        resolvedData: null,
        resolution: null,
      );
    }
  }

  Map<String, dynamic> _mergeData(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);
    final preferLocalFields = [
      'notes',
      'address',
      'phone',
      'email',
      'first_name',
      'last_name',
      'middle_name',
    ];

    for (final field in preferLocalFields) {
      if (local.containsKey(field) && local[field] != null) {
        merged[field] = local[field];
      }
    }

    merged['updated'] = DateTime.now().toIso8601String();
    return merged;
  }

  void addConflict(SyncConflict conflict) {
    _conflicts.add(conflict);
    notifyListeners();
  }

  void removeConflict(String conflictId) {
    _conflicts.removeWhere((c) => c.id == conflictId);
    notifyListeners();
  }

  void clearConflicts() {
    _conflicts.clear();
    notifyListeners();
  }
}

/// Provider for ConflictResolverService
final conflictResolverServiceProvider = Provider<ConflictResolverService>((ref) {
  return ConflictResolverService(
    hiveService: ref.watch(hiveServiceProvider),
    clientApi: ref.watch(clientApiServiceProvider),
    touchpointApi: ref.watch(touchpointApiServiceProvider),
  );
});
