import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';

/// Enriches a PowerSync row with client name from Hive when the JOIN returns null.
/// This happens when the PowerSync clients table is empty (sync rules don't include it).
Map<String, dynamic> _enrichRowFromHive(Map<String, dynamic> row) {
  final firstName = row['first_name'] as String?;
  final lastName = row['last_name'] as String?;
  if ((firstName == null || firstName.isEmpty) && (lastName == null || lastName.isEmpty)) {
    final clientId = row['client_id'] as String?;
    if (clientId != null) {
      final cached = HiveService().getClient(clientId);
      if (cached != null) {
        final enriched = Map<String, dynamic>.from(row);
        enriched['first_name'] = cached['first_name'];
        enriched['last_name'] = cached['last_name'];
        return enriched;
      }
    }
  }
  return row;
}

class MyDayRepository {
  static const String _joinSql = '''
    SELECT i.id, i.client_id, i.scheduled_date, i.scheduled_time,
           i.status, i.priority, i.notes, i.time_in, i.time_out,
           c.first_name, c.last_name, c.agency_name, c.municipality,
           c.touchpoint_number, c.next_touchpoint, c.touchpoint_summary
    FROM itineraries i
    LEFT JOIN clients c ON c.id = i.client_id
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
