import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/targets/data/models/target_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class TargetRepository {
  /// Current month's target for the given user.
  Future<Target?> getCurrentMonthTarget(String userId) async {
    final now = DateTime.now();
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "SELECT * FROM targets WHERE user_id = ? AND period = 'monthly' AND year = ? AND month = ? LIMIT 1",
      [userId, now.year, now.month],
    );
    if (rows.isEmpty) return null;
    return Target.fromRow(rows.first);
  }

  Stream<Target?> watchCurrentMonthTarget(String userId) {
    final now = DateTime.now();
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        "SELECT * FROM targets WHERE user_id = ? AND period = 'monthly' AND year = ? AND month = ? LIMIT 1",
        parameters: [userId, now.year, now.month],
      ).map((rows) => rows.isEmpty ? null : Target.fromRow(rows.first));
    });
  }

  Future<List<Target>> getAllTargets(String userId) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM targets WHERE user_id = ? ORDER BY year DESC, month DESC',
      [userId],
    );
    return rows.map(Target.fromRow).toList();
  }

  Stream<List<Target>> watchAllTargets(String userId) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM targets WHERE user_id = ? ORDER BY year DESC, month DESC',
        parameters: [userId],
      ).map((rows) => rows.map(Target.fromRow).toList());
    });
  }
}

final targetRepositoryProvider = Provider<TargetRepository>((_) => TargetRepository());
