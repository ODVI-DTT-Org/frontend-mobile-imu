import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage keys for offline sync queue
class _QueueStorageKeys {
  static const String queuePrefix = 'sync_queue_';
  static const String queueIndex = 'sync_queue_index';
  static const String queueSize = 'sync_queue_size';
}

/// Operation types for sync queue
enum SyncOperationType {
  /// Create a new resource
  create,

  /// Update an existing resource
  update,

  /// Delete a resource
  delete,

  /// Custom operation
  custom,
}

/// Represents a single operation in the sync queue.
class SyncOperation {
  /// Unique identifier for this operation
  final String id;

  /// Type of operation
  final SyncOperationType type;

  /// Resource type (e.g., 'client', 'touchpoint', 'itinerary')
  final String resourceType;

  /// Resource ID (null for create operations)
  final String? resourceId;

  /// Operation data (JSON string)
  final Map<String, dynamic> data;

  /// Timestamp when operation was queued
  final DateTime queuedAt;

  /// Number of retry attempts
  int retryCount;

  /// Whether this operation has been synced
  bool isSynced;

  SyncOperation({
    required this.id,
    required this.type,
    required this.resourceType,
    this.resourceId,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
    this.isSynced = false,
  });

  /// Create a SyncOperation from JSON.
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SyncOperationType.custom,
      ),
      resourceType: json['resourceType'] as String,
      resourceId: json['resourceId'] as String?,
      data: Map<String, dynamic>.from(json['data'] as Map),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      isSynced: json['isSynced'] as bool? ?? false,
    );
  }

  /// Convert to JSON for storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'data': data,
      'queuedAt': queuedAt.toIso8601String(),
      'retryCount': retryCount,
      'isSynced': isSynced,
    };
  }

  /// Create a copy of this operation with modified properties.
  SyncOperation copyWith({
    String? id,
    SyncOperationType? type,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? data,
    DateTime? queuedAt,
    int? retryCount,
    bool? isSynced,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      data: data ?? this.data,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() {
    return 'SyncOperation($type $resourceType${resourceId != null ? " #$resourceId" : ""})';
  }
}

/// Result of a sync operation.
class SyncResult {
  final bool success;
  final String? error;
  final SyncOperation? operation;

  const SyncResult({
    required this.success,
    this.error,
    this.operation,
  });

  factory SyncResult.success({SyncOperation? operation}) {
    return SyncResult(success: true, operation: operation);
  }

  factory SyncResult.failure(String error, {SyncOperation? operation}) {
    return SyncResult(success: false, error: error, operation: operation);
  }

  @override
  String toString() {
    if (success) {
      return 'SyncResult.success';
    } else {
      return 'SyncResult.failure: $error';
    }
  }
}

/// Service for managing offline sync queue.
///
/// Features:
/// - Queue operations when network is unavailable
/// - Persist queue to secure storage
/// - Retry failed operations with backoff
/// - Automatic cleanup of synced operations
/// - Queue size limits to prevent storage bloat
///
/// Usage:
/// ```dart
/// // Add operation to queue
/// await syncQueue.addOperation(SyncOperation(
///   id: 'op-123',
///   type: SyncOperationType.create,
///   resourceType: 'client',
///   data: {'name': 'John Doe'},
///   queuedAt: DateTime.now(),
/// ));
///
/// // Process queue when network is available
/// await syncQueue.processQueue((operation) async {
///   // Perform API call
///   return SyncResult.success();
/// });
/// ```
class OfflineSyncQueueService {
  /// Maximum number of operations to store in queue
  static const int maxQueueSize = 100;

  /// Maximum retry attempts for failed operations
  static const int maxRetryAttempts = 3;

  final FlutterSecureStorage _secureStorage;
  final List<SyncOperation> _memoryQueue = [];
  int _nextQueueIndex = 0;
  bool _isProcessing = false;

  OfflineSyncQueueService({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Initialize the sync queue by loading from storage.
  Future<void> initialize() async {
    await _loadQueueFromStorage();
  }

  /// Add an operation to the sync queue.
  ///
  /// Returns true if operation was added successfully.
  /// Returns false if queue is full.
  Future<bool> addOperation(SyncOperation operation) async {
    if (_memoryQueue.length >= maxQueueSize) {
      return false; // Queue is full
    }

    _memoryQueue.add(operation);
    await _saveQueueToStorage();
    return true;
  }

  /// Get all pending operations in the queue.
  List<SyncOperation> getPendingOperations() {
    return _memoryQueue.where((op) => !op.isSynced).toList();
  }

  /// Get the number of pending operations.
  int get pendingOperationCount {
    return _memoryQueue.where((op) => !op.isSynced).length;
  }

  /// Check if queue is empty.
  bool get isEmpty {
    return _memoryQueue.every((op) => op.isSynced);
  }

  /// Process all pending operations in the queue.
  ///
  /// Calls [syncFunction] for each pending operation.
  /// Stops processing if syncFunction returns failure.
  ///
  /// Returns list of sync results for each processed operation.
  Future<List<SyncResult>> processQueue(
    Future<SyncResult> Function(SyncOperation) syncFunction,
  ) async {
    if (_isProcessing) {
      return [];
    }

    _isProcessing = true;
    final results = <SyncResult>[];

    try {
      final pendingOps = getPendingOperations();

      for (final operation in pendingOps) {
        if (operation.retryCount >= maxRetryAttempts) {
          // Skip operations that have exceeded max retries
          results.add(SyncResult.failure(
            'Max retry attempts exceeded',
            operation: operation,
          ));
          continue;
        }

        // Increment retry count
        operation.retryCount++;

        try {
          final result = await syncFunction(operation);

          if (result.success) {
            // Mark as synced
            operation.isSynced = true;
            results.add(result);
          } else {
            // Sync failed, keep in queue for retry
            results.add(result);
            break; // Stop processing on first failure
          }
        } catch (e) {
          // Exception during sync
          results.add(SyncResult.failure(
            'Exception: $e',
            operation: operation,
          ));
          break; // Stop processing on exception
        }
      }

      // Remove synced operations
      _memoryQueue.removeWhere((op) => op.isSynced);

      // Save updated queue
      await _saveQueueToStorage();

      return results;
    } finally {
      _isProcessing = false;
    }
  }

  /// Clear all operations from the queue.
  Future<void> clearQueue() async {
    _memoryQueue.clear();
    await _saveQueueToStorage();
  }

  /// Remove a specific operation from the queue.
  Future<void> removeOperation(String operationId) async {
    _memoryQueue.removeWhere((op) => op.id == operationId);
    await _saveQueueToStorage();
  }

  /// Get queue statistics.
  Map<String, dynamic> getQueueStats() {
    return {
      'totalOperations': _memoryQueue.length,
      'pendingOperations': pendingOperationCount,
      'syncedOperations': _memoryQueue.where((op) => op.isSynced).length,
      'isProcessing': _isProcessing,
    };
  }

  /// Load queue from secure storage.
  Future<void> _loadQueueFromStorage() async {
    _memoryQueue.clear();

    // Load queue index
    final indexStr = await _secureStorage.read(key: _QueueStorageKeys.queueIndex);
    if (indexStr != null) {
      _nextQueueIndex = int.tryParse(indexStr) ?? 0;
    }

    // Load queue size
    final sizeStr = await _secureStorage.read(key: _QueueStorageKeys.queueSize);
    final size = sizeStr != null ? int.tryParse(sizeStr) ?? 0 : 0;

    // Load operations
    for (int i = 0; i < size; i++) {
      final key = '${_QueueStorageKeys.queuePrefix}$i';
      final opJson = await _secureStorage.read(key: key);
      if (opJson != null) {
        try {
          final json = jsonDecode(opJson) as Map<String, dynamic>;
          final operation = SyncOperation.fromJson(json);
          _memoryQueue.add(operation);
        } catch (e) {
          // Skip invalid operations
          continue;
        }
      }
    }
  }

  /// Save queue to secure storage.
  Future<void> _saveQueueToStorage() async {
    // Save queue index
    await _secureStorage.write(
      key: _QueueStorageKeys.queueIndex,
      value: _nextQueueIndex.toString(),
    );

    // Save queue size
    await _secureStorage.write(
      key: _QueueStorageKeys.queueSize,
      value: _memoryQueue.length.toString(),
    );

    // Save operations
    for (int i = 0; i < _memoryQueue.length; i++) {
      final key = '${_QueueStorageKeys.queuePrefix}$i';
      final operation = _memoryQueue[i];
      await _secureStorage.write(
        key: key,
        value: jsonEncode(operation.toJson()),
      );
    }

    // Clear old operations beyond current size
    for (int i = _memoryQueue.length; i < maxQueueSize; i++) {
      final key = '${_QueueStorageKeys.queuePrefix}$i';
      await _secureStorage.delete(key: key);
    }
  }

  /// Generate next unique operation ID.
  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_$_nextQueueIndex';
  }

  /// Dispose of resources.
  void dispose() {
    _memoryQueue.clear();
  }
}
