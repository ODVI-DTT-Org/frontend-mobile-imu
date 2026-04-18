import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/groups/data/models/group_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class GroupRepository {
  /// All groups where this agent is the caravan, ordered by name.
  Stream<List<ClientGroup>> watchGroups(String userId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM groups WHERE caravan_id = ? ORDER BY name ASC',
        parameters: [userId],
      ).map((rows) => rows.map(ClientGroup.fromRow).toList());
    });
  }

  Future<List<ClientGroup>> getGroups(String userId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM groups WHERE caravan_id = ? ORDER BY name ASC',
      [userId],
    );
    return rows.map(ClientGroup.fromRow).toList();
  }

  Future<ClientGroup?> getById(String id) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll('SELECT * FROM groups WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return ClientGroup.fromRow(rows.first);
  }
}

final groupRepositoryProvider = Provider<GroupRepository>((_) => GroupRepository());
