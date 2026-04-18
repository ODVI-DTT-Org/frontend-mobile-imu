import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/visits/data/models/visit_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class VisitRepository {
  /// All visits for a given client, newest first.
  Stream<List<Visit>> watchByClientId(String clientId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM visits WHERE client_id = ? ORDER BY created_at DESC',
        parameters: [clientId],
      ).map((rows) => rows.map(Visit.fromRow).toList());
    });
  }

  Future<List<Visit>> getByClientId(String clientId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM visits WHERE client_id = ? ORDER BY created_at DESC',
      [clientId],
    );
    return rows.map(Visit.fromRow).toList();
  }

  Future<Visit?> getById(String id) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll('SELECT * FROM visits WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Visit.fromRow(rows.first);
  }
}

final visitRepositoryProvider = Provider<VisitRepository>((_) => VisitRepository());
