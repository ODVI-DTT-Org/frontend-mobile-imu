import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'retention_manager.dart';
import '../../core/utils/logger.dart';

/// Types of sync operations supported by the unified sync service
enum SyncOperationType { create, update, delete }

/// Conflict resolution strategies for sync operations
enum ConflictStrategy { localWins, serverWins, merge }

/// Represents a single sync operation in the queue
class SyncOperation {
  final String id;
  final SyncOperationType type;
  final String collection;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.collection,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
  });

  /// Creates a SyncOperation from a JSON map
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.create,
      ),
      collection: json['collection'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  /// Converts the SyncOperation to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'collection': collection,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
    };
  }
}

/// Unified sync service that replaces the existing dual sync systems
///
/// This service provides:
/// - Offline-first operation queueing
/// - Automatic sync when online
/// - 7-day data retention with automatic cleanup
/// - Retry logic with configurable max retries
class UnifiedSyncService {
  final RetentionManager _retentionManager = RetentionManager();
  Box? _queueBox;
  bool _isOnline = true;
  bool _isSyncing = false;

  /// Maximum number of retry attempts for failed operations
  static const int maxRetries = 3;

  /// Gets whether the service is currently syncing
  bool get isSyncing => _isSyncing;

  /// Gets whether the service is online
  bool get isOnline => _isOnline;

  /// Initializes the sync service and opens the queue box
  Future<void> initialize() async {
    _queueBox = await Hive.openBox('unified_sync_queue');
    logDebug('UnifiedSyncService initialized');
  }

  /// Queues an operation for sync
  ///
  /// If online and not currently syncing, will attempt to process
  /// the queue immediately after adding the operation.
  Future<void> queueOperation(SyncOperation operation) async {
    await _queueBox?.put(operation.id, operation.toJson());
    logDebug('Queued sync operation: ${operation.type.name} ${operation.collection}');

    if (_isOnline && !_isSyncing) {
      await _processQueue();
    }
  }

  /// Processes all pending operations in the queue
  Future<void> _processQueue() async {
    if (_isSyncing || !_isOnline || _queueBox == null) return;

    _isSyncing = true;
    try {
      final keys = _queueBox!.keys.toList();
      for (final key in keys) {
        final data = _queueBox!.get(key);
        if (data != null) {
          await _processOperation(
            key.toString(),
            Map<String, dynamic>.from(data),
          );
        }
      }
      await _retentionManager.cleanupSyncedData();
    } finally {
      _isSyncing = false;
    }
  }

  /// Processes a single sync operation
  Future<void> _processOperation(String id, Map<String, dynamic> data) async {
    try {
      // Process based on operation type
      // TODO: Phase 2 - This will integrate with PowerSync client
      logDebug('Processing operation: $id');
      await _queueBox?.delete(id);
    } catch (e) {
      logError('Failed to process operation', e);
      final retryCount = (data['retryCount'] as int? ?? 0) + 1;
      if (retryCount >= maxRetries) {
        await _queueBox?.delete(id);
        logError('Operation failed after $maxRetries retries: $id');
      } else {
        await _queueBox?.put(id, {...data, 'retryCount': retryCount});
      }
    }
  }

  /// Updates the online status and triggers sync if coming back online
  void setOnlineStatus(bool isOnline) {
    _isOnline = isOnline;
    if (isOnline) {
      _processQueue();
    }
  }

  /// Gets the count of pending operations in the queue
  int get pendingCount => _queueBox?.keys.length ?? 0;

  /// Checks if there are any pending operations
  bool get hasPendingOperations => pendingCount > 0;

  /// Clears all pending operations from the queue
  Future<void> clearQueue() async {
    await _queueBox?.clear();
    logDebug('Sync queue cleared');
  }

  /// Disposes of resources used by the service
  Future<void> dispose() async {
    await _queueBox?.close();
    logDebug('UnifiedSyncService disposed');
  }
}
