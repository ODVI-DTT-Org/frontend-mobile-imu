import 'package:flutter/foundation.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/data/models/history_item.dart';
import 'package:imu_flutter/features/approvals/data/models/approval_model.dart';
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

List<HistoryItem> mergeHistoryItems({
  required List<Touchpoint> summary,
  required List<Touchpoint> succeededLocal,
  required List<Approval> loanReleases,
}) {
  final touchpointsById = <String, Touchpoint>{};

  for (final touchpoint in succeededLocal) {
    touchpointsById[touchpoint.id] = touchpoint;
  }
  for (final touchpoint in summary) {
    touchpointsById[touchpoint.id] = touchpoint;
  }

  final items = <HistoryItem>[
    ...touchpointsById.values.map((tp) => TouchpointHistoryItem(tp)),
    ...loanReleases.map((lr) => LoanReleaseHistoryItem(lr)),
  ];

  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return items;
}

class TouchpointHistoryRepository {
  Stream<List<Touchpoint>> watchSucceededLocalTouchpoints(String clientId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final rows in db.watch(
        '''
        SELECT t.id, t.client_id, t.user_id, t.touchpoint_number, t.type, t.date,
               t.status, t.next_visit_date, t.notes, t.is_legacy, t.latitude,
               t.longitude, t.address, t.visit_id, t.call_id, t.created_at,
               t.updated_at, t.rejected_at, t.rejection_reason,
               v.reason AS visit_reason, v.status AS visit_status,
               v.notes AS visit_notes, v.time_in, v.time_out,
               v.odometer_arrival, v.odometer_departure, v.photo_url AS visit_photo_url,
               v.address AS visit_address, v.latitude AS visit_latitude,
               v.longitude AS visit_longitude,
               c.reason AS call_reason, c.status AS call_status,
               c.notes AS call_notes, c.phone_number, c.dial_time, c.duration,
               c.photo_url AS call_photo_url
        FROM touchpoints t
        LEFT JOIN visits v ON t.visit_id = v.id
        LEFT JOIN calls c ON t.call_id = c.id
        WHERE t.client_id = ?
          AND NOT EXISTS (
            SELECT 1
            FROM ps_crud cr
            WHERE json_extract(cr.data, '\$.type') = 'touchpoints'
              AND json_extract(cr.data, '\$.id') = t.id
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

  Future<List<Approval>> fetchClientLoanReleases(String clientId) async {
    try {
      final db = await PowerSyncService.database;
      final rows = await db.getAll(
        '''
        SELECT a.id, a.type, a.status, a.reason, a.notes, a.udi_number,
               a.updated_udi, a.approved_at, a.rejected_at, a.rejection_reason,
               a.created_at, a.updated_at
        FROM approvals a
        WHERE a.client_id = ?
          AND a.type = 'udi'
        ORDER BY a.created_at DESC
        ''',
        [clientId],
      );
      return rows.map((row) {
        return Approval(
          id: row['id'] as String,
          type: ApprovalType.udi,
          status: ApprovalStatus.fromString(row['status'] as String? ?? 'pending'),
          clientId: clientId,
          reason: row['reason'] as String?,
          notes: row['notes'] as String?,
          udiNumber: row['udi_number'] as String?,
          updatedUdi: row['updated_udi'] as String?,
          approvedAt: row['approved_at'] != null ? DateTime.parse(row['approved_at'] as String) : null,
          rejectedAt: row['rejected_at'] != null ? DateTime.parse(row['rejected_at'] as String) : null,
          rejectionReason: row['rejection_reason'] as String?,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.parse(row['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('[TouchpointHistoryRepository] Failed to fetch loan releases: $e');
      return [];
    }
  }
}
