import 'package:hive/hive.dart';
import 'package:imu_flutter/services/client/models/pending_client_operation.dart';

class PendingClientService {
  static const String _boxName = 'pending_clients';

  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }

  Future<void> enqueue(PendingClientOperation op) async {
    final box = await _getBox();
    await box.put(op.id, op.toJson());
  }

  Future<List<PendingClientOperation>> getAll() async {
    final box = await _getBox();
    final ops = box.values
        .map((v) => PendingClientOperation.fromJson(
              Map<String, dynamic>.from(v as Map),
            ))
        .toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> remove(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<void> removeAllForClient(String clientId) async {
    final box = await _getBox();
    final keysToRemove = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw != null) {
        final map = Map<String, dynamic>.from(raw as Map);
        if (map['clientId'] == clientId) keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      await box.delete(key);
    }
  }

  Future<int> getPendingCount() async {
    final box = await _getBox();
    return box.length;
  }

  /// Collapse a sorted list of operations into the minimal set to sync.
  ///
  /// Rules per clientId:
  ///   create + delete  → cancel both (never hit server)
  ///   create + updates → single create with final data
  ///   updates only     → single update with final data
  ///   update + delete  → single delete
  ///   delete alone     → delete
  List<PendingClientOperation> collapse(List<PendingClientOperation> ops) {
    final byClient = <String, List<PendingClientOperation>>{};
    for (final op in ops) {
      byClient.putIfAbsent(op.clientId, () => []).add(op);
    }

    final result = <PendingClientOperation>[];

    for (final clientOps in byClient.values) {
      final hasCreate =
          clientOps.any((o) => o.operation == ClientOperationType.create);
      final hasDelete =
          clientOps.any((o) => o.operation == ClientOperationType.delete);

      if (hasCreate && hasDelete) {
        continue; // cancel both — temp client never existed on server
      }

      if (hasDelete) {
        result.add(clientOps.last); // last op is the delete
        continue;
      }

      if (hasCreate) {
        // merge: create with the final client data from the last op
        result.add(PendingClientOperation(
          id: clientOps.first.id,
          operation: ClientOperationType.create,
          clientId: clientOps.first.clientId,
          clientData: clientOps.last.clientData,
          createdAt: clientOps.first.createdAt,
        ));
        continue;
      }

      result.add(clientOps.last); // updates only — last wins
    }

    return result;
  }
}
