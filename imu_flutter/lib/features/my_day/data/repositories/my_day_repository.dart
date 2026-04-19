import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';

/// Merges Hive client data into a PowerSync itinerary row.
/// Itineraries only stores scheduling fields — all client fields come from Hive.
Map<String, dynamic> _enrichRowFromHive(Map<String, dynamic> row) {
  final clientId = row['client_id'] as String?;
  if (clientId == null) return row;
  final cached = HiveService().getClient(clientId);
  if (cached == null) return row;
  final enriched = Map<String, dynamic>.from(row);
  enriched['first_name'] = cached['first_name'];
  enriched['last_name'] = cached['last_name'];
  enriched['municipality'] = cached['municipality'];
  enriched['province'] = cached['province'];
  enriched['product_type'] = cached['product_type'];
  enriched['pension_type'] = cached['pension_type'];
  enriched['loan_type'] = cached['loan_type'];
  enriched['touchpoint_number'] = cached['touchpoint_number'];
  enriched['next_touchpoint'] = cached['next_touchpoint'];
  enriched['touchpoint_summary'] = cached['touchpoint_summary'];
  return enriched;
}

class MyDayRepository {
  static const String _joinSql = '''
    SELECT i.id, i.client_id, i.scheduled_date, i.scheduled_time,
           i.status, i.priority, i.notes, i.time_in, i.time_out,
           i.touchpoint_number, i.next_touchpoint, i.touchpoint_summary
    FROM itineraries i
  ''';

  /// Stream of today's My Day clients for this user, ordered by scheduled time.
  Stream<List<MyDayClient>> watchTodayClients(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        "$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? AND i.status != 'cancelled' ORDER BY i.scheduled_time ASC",
        parameters: [userId, today],
      ).map((rows) => rows.map((r) => MyDayClient.fromRow(_enrichRowFromHive(r))).toList());
    });
  }

  Future<List<MyDayClient>> getTodayClients(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? AND i.status != 'cancelled' ORDER BY i.scheduled_time ASC",
      [userId, today],
    );
    return rows.map((r) => MyDayClient.fromRow(_enrichRowFromHive(r))).toList();
  }

  Future<List<MyDayClient>> getClientsByDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      '$_joinSql WHERE i.user_id = ? AND DATE(i.scheduled_date) = ? ORDER BY i.scheduled_time ASC',
      [userId, dateStr],
    );
    return rows.map((r) => MyDayClient.fromRow(_enrichRowFromHive(r))).toList();
  }

  /// Returns true if the client has an itinerary entry for today.
  Future<bool> isInMyDay(String userId, String clientId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "SELECT id FROM itineraries WHERE user_id = ? AND client_id = ? AND DATE(scheduled_date) = ? AND status != 'cancelled' LIMIT 1",
      [userId, clientId, today],
    );
    return rows.isNotEmpty;
  }
}

final myDayRepositoryProvider = Provider<MyDayRepository>((_) => MyDayRepository());
