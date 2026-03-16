import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';
import 'powersync_service.dart';

/// Represents a single sync operation that can be undone
class SyncOperation {
  final String id;
  final String tableName;
  final String operationType; // INSERT, UPDATE, DELETE
  final String recordId;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final DateTime timestamp;
  final bool canUndo;

  SyncOperation({
    required this.id,
    required this.tableName,
    required this.operationType,
    required this.recordId,
    this.beforeData,
    this.afterData,
    required this.timestamp,
    this.canUndo = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableName': tableName,
    'operationType': operationType,
    'recordId': recordId,
    'beforeData': beforeData,
    'afterData': afterData,
    'timestamp': timestamp.toIso8601String(),
    'canUndo': canUndo,
  };

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      tableName: json['tableName'] as String,
      operationType: json['operationType'] as String,
      recordId: json['recordId'] as String,
      beforeData: json['beforeData'] as Map<String, dynamic>?,
      afterData: json['afterData'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      canUndo: json['canUndo'] as bool? ?? true,
    );
  }
}

/// Service for tracking and undoing sync operations
class UndoSyncService {
  final PowerSyncService _powerSyncService;
  final List<SyncOperation> _operationHistory = [];
  final StreamController<List<SyncOperation>> _historyController =
      StreamController<List<SyncOperation>>.broadcast();

  static const int _maxHistorySize = 50;
  static const Duration _undoWindow = Duration(minutes: 5);

  UndoSyncService(this._powerSyncService);

  /// Stream of operation history changes
  Stream<List<SyncOperation>> get historyStream => _historyController.stream;

  /// Current operation history
  List<SyncOperation> get history => List.unmodifiable(_operationHistory);

  /// Track a new operation for potential undo
  void trackOperation({
    required String tableName,
    required String operationType,
    required String recordId,
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
  }) {
    final operation = SyncOperation(
      id: '${tableName}_${recordId}_${DateTime.now().millisecondsSinceEpoch}',
      tableName: tableName,
      operationType: operationType,
      recordId: recordId,
      beforeData: beforeData,
      afterData: afterData,
      timestamp: DateTime.now(),
      canUndo: beforeData != null || operationType == 'DELETE',
    );

    _operationHistory.insert(0, operation);

    // Trim history if too large
    if (_operationHistory.length > _maxHistorySize) {
      _operationHistory.removeRange(_maxHistorySize, _operationHistory.length);
    }

    // Remove expired operations
    _cleanupExpiredOperations();

    _historyController.add(List.from(_operationHistory));
    logDebug('Tracked sync operation: $operationType on $tableName/$recordId');
  }

  /// Undo the most recent operation
  Future<bool> undoLast() async {
    if (_operationHistory.isEmpty) {
      logDebug('No operations to undo');
      return false;
    }

    final operation = _operationHistory.first;
    return await undoOperation(operation.id);
  }

  /// Undo a specific operation by ID
  Future<bool> undoOperation(String operationId) async {
    final index = _operationHistory.indexWhere((op) => op.id == operationId);
    if (index == -1) {
      logDebug('Operation not found: $operationId');
      return false;
    }

    final operation = _operationHistory[index];

    // Check if within undo window
    if (DateTime.now().difference(operation.timestamp) > _undoWindow) {
      logDebug('Operation outside undo window: $operationId');
      return false;
    }

    if (!operation.canUndo) {
      logDebug('Operation cannot be undone: $operationId');
      return false;
    }

    try {
      final db = await _powerSyncService.database;

      switch (operation.operationType) {
        case 'INSERT':
          // Undo insert by deleting the record
          await db.execute(
            'DELETE FROM ${operation.tableName} WHERE id = ?',
            [operation.recordId],
          );
          break;

        case 'UPDATE':
          // Undo update by restoring beforeData
          if (operation.beforeData != null) {
            final setClauses = operation.beforeData!.keys
                .map((key) => '$key = ?')
                .join(', ');
            final values = operation.beforeData!.values.toList()
              ..add(operation.recordId);

            await db.execute(
              'UPDATE ${operation.tableName} SET $setClauses WHERE id = ?',
              values,
            );
          }
          break;

        case 'DELETE':
          // Undo delete by re-inserting the record
          if (operation.beforeData != null) {
            final columns = operation.beforeData!.keys.join(', ');
            final placeholders = operation.beforeData!.keys.map((_) => '?').join(', ');
            final values = operation.beforeData!.values.toList();

            await db.execute(
              'INSERT INTO ${operation.tableName} ($columns) VALUES ($placeholders)',
              values,
            );
          }
          break;
      }

      // Remove from history
      _operationHistory.removeAt(index);
      _historyController.add(List.from(_operationHistory));

      logDebug('Undone operation: ${operation.operationType} on ${operation.tableName}/${operation.recordId}');
      return true;
    } catch (e) {
      logError('Failed to undo operation', e);
      return false;
    }
  }

  /// Undo multiple operations
  Future<int> undoOperations(List<String> operationIds) async {
    int undone = 0;
    for (final id in operationIds) {
      if (await undoOperation(id)) {
        undone++;
      }
    }
    return undone;
  }

  /// Undo all operations in a time range
  Future<int> undoInTimeRange(DateTime start, DateTime end) async {
    final operations = _operationHistory
        .where((op) =>
            op.timestamp.isAfter(start) &&
            op.timestamp.isBefore(end) &&
            op.canUndo)
        .toList();

    int undone = 0;
    for (final op in operations) {
      if (await undoOperation(op.id)) {
        undone++;
      }
    }
    return undone;
  }

  /// Clear operation history
  void clearHistory() {
    _operationHistory.clear();
    _historyController.add([]);
    logDebug('Cleared sync operation history');
  }

  /// Remove expired operations from history
  void _cleanupExpiredOperations() {
    _operationHistory.removeWhere(
      (op) => DateTime.now().difference(op.timestamp) > _undoWindow,
    );
  }

  /// Get operations for a specific table
  List<SyncOperation> getOperationsForTable(String tableName) {
    return _operationHistory
        .where((op) => op.tableName == tableName)
        .toList();
  }

  /// Get operations for a specific record
  List<SyncOperation> getOperationsForRecord(String tableName, String recordId) {
    return _operationHistory
        .where((op) => op.tableName == tableName && op.recordId == recordId)
        .toList();
  }

  /// Dispose resources
  void dispose() {
    _historyController.close();
  }
}

/// Provider for undo sync service
final undoSyncServiceProvider = Provider<UndoSyncService>((ref) {
  final powerSyncService = ref.watch(powerSyncServiceProvider);
  final service = UndoSyncService(powerSyncService);
  ref.onDispose(() => service.dispose());
  return service;
});
