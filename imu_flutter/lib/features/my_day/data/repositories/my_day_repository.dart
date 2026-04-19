import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/services/local_storage/hive_service.dart';

/// Merges Hive client data into a PowerSync itinerary row.
/// Itineraries only stores scheduling fields — all client fields come from Hive.
Map<String, dynamic> _enrichRowFromHive(Map<String, dynamic> row) {
  final clientId = row['client_id'] as String?;
  debugPrint('[MyDayRepo] Row client_id=$clientId, raw keys=${row.keys.toList()}');

  if (clientId == null) {
    debugPrint('[MyDayRepo] No client_id in row — skipping Hive enrichment');
    return row;
  }

  final hiveCount = HiveService().cachedClientCount;
  debugPrint('[MyDayRepo] Hive cache size: $hiveCount');

  final cached = HiveService().getClient(clientId);
  if (cached == null) {
    debugPrint('[MyDayRepo] client_id=$clientId NOT found in Hive');
    return row;
  }

  debugPrint('[MyDayRepo] client_id=$clientId found in Hive: first_name=${cached['first_name']}, last_name=${cached['last_name']}');

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
  // Only select actual itinerary table columns — client fields come from Hive
  static const String _sql = '''
    SELECT id, client_id, scheduled_date, scheduled_time,
           status, priority, notes, time_in, time_out
    FROM itineraries
  ''';

  /// Stream of today's My Day clients for this user, ordered by scheduled time.
  Stream<List<MyDayClient>> watchTodayClients(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        "$_sql WHERE user_id = ? AND DATE(scheduled_date) = ? AND status != 'cancelled' ORDER BY scheduled_time ASC",
        parameters: [userId, today],
      ).map((rows) {
        debugPrint('[MyDayRepo] watchTodayClients: ${rows.length} rows from PowerSync');
        return rows.map((r) => MyDayClient.fromRow(_enrichRowFromHive(r))).toList();
      });
    });
  }

  Future<List<MyDayClient>> getTodayClients(String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      "$_sql WHERE user_id = ? AND DATE(scheduled_date) = ? AND status != 'cancelled' ORDER BY scheduled_time ASC",
      [userId, today],
    );
    debugPrint('[MyDayRepo] getTodayClients: ${rows.length} rows from PowerSync');
    return rows.map((r) => MyDayClient.fromRow(_enrichRowFromHive(r))).toList();
  }

  Future<List<MyDayClient>> getClientsByDate(String userId, DateTime date) async {
    final dateStr = date.toIso8601String().substring(0, 10);
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      '$_sql WHERE user_id = ? AND DATE(scheduled_date) = ? ORDER BY scheduled_time ASC',
      [userId, dateStr],
    );
    debugPrint('[MyDayRepo] getClientsByDate: ${rows.length} rows from PowerSync');
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
