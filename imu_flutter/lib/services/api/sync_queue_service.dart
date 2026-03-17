import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending operation in sync queue
class PendingOperation {
  final String id;
  final String operation; // CREATE, UPDATE, DELETE
  final String entityType; // client, touchpoint, itinerary, etc.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  PendingOperation({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'],
      operation: json['operation'],
      entityType: json['entityType'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      retryCount: json['retryCount'] ?? 0,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation': operation,
      'entityType': entityType,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'error': error,
    };
  }

  PendingOperation copyWith({
    int? retryCount,
    String? error,
  }) {
    return PendingOperation(
      id: id,
      operation: operation,
      entityType: entityType,
      data: data,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }
}

/// Sync queue service for offline operations
/// TODO: Phase 2 - Will be updated to work with PowerSync
class SyncQueueService extends ChangeNotifier {
  static const String _boxName = 'sync_queue';
  static const int _maxRetries = 3;

  late Box<String> _box;
  bool _isInitialized = false;
  bool _isSyncing = false;
  List<PendingOperation> _pendingOperations = [];

  List<PendingOperation> get pendingOperations => _pendingOperations;
  int get pendingCount => _pendingOperations.length;
  bool get isSyncing => _isSyncing;
  bool get hasPending => _pendingOperations.isNotEmpty;

  Future<void> init() async {
    if (_isInitialized) return;

    _box = await Hive.openBox<String>(_boxName);
    _loadPendingOperations();
    _isInitialized = true;
    debugPrint('SyncQueueService: Initialized with ${_pendingOperations.length} pending operations');
  }

  void _loadPendingOperations() {
    _pendingOperations = _box.values.map((json) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return PendingOperation.fromJson(data);
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> queueOperation({
    required String id,
    required String operation,
    required String entityType,
    required Map<String, dynamic> data,
  }) async {
    if (!_isInitialized) await init();

    final pendingOp = PendingOperation(
      id: id,
      operation: operation,
      entityType: entityType,
      data: data,
      createdAt: DateTime.now(),
    );

    await _box.put(id, jsonEncode(pendingOp.toJson()));
    _pendingOperations.add(pendingOp);
    notifyListeners();

    debugPrint('SyncQueueService: Queued $operation for $entityType ($id)');
  }

  Future<void> removeOperation(String id) async {
    if (!_isInitialized) await init();

    await _box.delete(id);
    _pendingOperations.removeWhere((op) => op.id == id);
    notifyListeners();

    debugPrint('SyncQueueService: Removed operation $id');
  }

  Future<void> updateOperation(PendingOperation operation) async {
    if (!_isInitialized) await init();

    await _box.put(operation.id, jsonEncode(operation.toJson()));
    final index = _pendingOperations.indexWhere((op) => op.id == operation.id);
    if (index != -1) {
      _pendingOperations[index] = operation;
    }
    notifyListeners();
  }

  /// Process queue with backend client
  /// TODO: Phase 2 - Implement with PowerSync
  Future<void> processQueue() async {
    if (!_isInitialized) await init();
    if (_isSyncing) return;
    if (_pendingOperations.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    debugPrint('SyncQueueService: Processing ${_pendingOperations.length} operations (PowerSync integration pending)');

    // TODO: Phase 2 - Implement PowerSync sync
    // For now, operations stay in queue until PowerSync is connected

    _isSyncing = false;
    notifyListeners();
  }

  String _getCollectionName(String entityType) {
    switch (entityType) {
      case 'client':
        return 'clients';
      case 'touchpoint':
        return 'touchpoints';
      case 'itinerary':
        return 'itinerary';
      case 'attendance':
        return 'attendance';
      case 'group':
        return 'groups';
      default:
        return entityType;
    }
  }

  Future<void> clearQueue() async {
    if (!_isInitialized) await init();

    await _box.clear();
    _pendingOperations.clear();
    notifyListeners();

    debugPrint('SyncQueueService: Queue cleared');
  }
}

/// Provider for SyncQueueService
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final service = SyncQueueService();
  ref.onDispose(() {
    // Cleanup if needed
  });
  return service;
});

/// Provider for pending operations count
final pendingOperationsCountProvider = Provider<int>((ref) {
  final syncQueue = ref.watch(syncQueueServiceProvider);
  return syncQueue.pendingCount;
});

/// Provider for checking if there are pending operations
final hasPendingOperationsProvider = Provider<bool>((ref) {
  final syncQueue = ref.watch(syncQueueServiceProvider);
  return syncQueue.hasPending;
});
