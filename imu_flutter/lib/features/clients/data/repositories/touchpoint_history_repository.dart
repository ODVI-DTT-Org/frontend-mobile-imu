import 'package:flutter/foundation.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

List<Touchpoint> mergeTouchpointHistory({
  required List<Touchpoint> summary,
  required List<Touchpoint> succeededLocal,
}) {
  final byId = <String, Touchpoint>{};

  for (final touchpoint in succeededLocal) {
    byId[touchpoint.id] = touchpoint;
  }
  for (final touchpoint in summary) {
    byId[touchpoint.id] = touchpoint;
  }

  final merged = byId.values.toList()
    ..sort((a, b) {
      final numberCompare = b.touchpointNumber.compareTo(a.touchpointNumber);
      if (numberCompare != 0) return numberCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

  return merged;
}

class TouchpointHistoryRepository {
  Stream<List<Touchpoint>> watchSucceededLocalTouchpoints(String clientId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final rows in db.watch(
        '''
        SELECT t.*
        FROM touchpoints t
        WHERE t.client_id = ?
          AND NOT EXISTS (
            SELECT 1
            FROM ps_crud c
            WHERE json_extract(c.data, '\$.type') = 'touchpoints'
              AND json_extract(c.data, '\$.id') = t.id
          )
        ORDER BY t.touchpoint_number DESC, COALESCE(t.created_at, t.date) DESC
        ''',
        parameters: [clientId],
      )) {
        yield rows.map(Touchpoint.fromRow).toList();
      }
    } catch (e) {
      debugPrint('[TouchpointHistoryRepository] Failed to watch touchpoints: $e');
      yield const [];
    }
  }
}
