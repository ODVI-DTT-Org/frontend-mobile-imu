import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

class ActivityRepository {
  final String userId;

  const ActivityRepository({required this.userId});

  // ── Static helpers (used in tests) ──────────────────────────────────────

  static ActivitySubtype subtypeFromTouchpoint(String type) {
    return type == 'Call'
        ? ActivitySubtype.touchpointCall
        : ActivitySubtype.touchpointVisit;
  }

  static ActivityStatus statusFromApproval(String status) {
    switch (status) {
      case 'approved': return ActivityStatus.approved;
      case 'rejected': return ActivityStatus.rejected;
      default:         return ActivityStatus.pending;
    }
  }

  // ── PowerSync pending upload IDs ─────────────────────────────────────────

  Future<Set<String>> _pendingIds(String table) async {
    try {
      final rows = await PowerSyncService.query(
        "SELECT json_extract(data, '\$.id') as row_id FROM ps_crud WHERE type = ?",
        [table],
      );
      return rows
          .map((r) => r['row_id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Table queries ─────────────────────────────────────────────────────────

  Future<List<ActivityItem>> fetchTouchpoints(DateTime from, DateTime to) async {
    final pending = await _pendingIds('touchpoints');
    final rows = await PowerSyncService.query(
      """
      SELECT t.id, t.type, t.reason, t.touchpoint_number, t.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM touchpoints t
      LEFT JOIN clients c ON c.id = t.client_id
      WHERE t.user_id = ?
        AND datetime(t.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY t.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      final tpNum = r['touchpoint_number'] as int? ?? 0;
      final tpType = r['type'] as String? ?? 'Visit';
      final reason = r['reason'] as String? ?? '';
      return ActivityItem(
        id: id,
        type: ActivityType.touchpoint,
        subtype: subtypeFromTouchpoint(tpType),
        clientName: r['client_name'] as String?,
        detail: 'Touchpoint #$tpNum • $tpType${reason.isNotEmpty ? ' — $reason' : ''}',
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchVisits(DateTime from, DateTime to) async {
    final pending = await _pendingIds('visits');
    final rows = await PowerSyncService.query(
      """
      SELECT v.id, v.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM visits v
      LEFT JOIN clients c ON c.id = v.client_id
      WHERE v.user_id = ?
        AND datetime(v.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY v.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      return ActivityItem(
        id: id,
        type: ActivityType.visit,
        subtype: ActivitySubtype.visit,
        clientName: r['client_name'] as String?,
        detail: null,
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchCalls(DateTime from, DateTime to) async {
    final pending = await _pendingIds('calls');
    final rows = await PowerSyncService.query(
      """
      SELECT ca.id, ca.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM calls ca
      LEFT JOIN clients c ON c.id = ca.client_id
      WHERE ca.user_id = ?
        AND datetime(ca.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY ca.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      return ActivityItem(
        id: id,
        type: ActivityType.call,
        subtype: ActivitySubtype.call,
        clientName: r['client_name'] as String?,
        detail: null,
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchApprovals(DateTime from, DateTime to) async {
    final rows = await PowerSyncService.query(
      """
      SELECT a.id, a.type, a.status, a.reason, a.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM approvals a
      LEFT JOIN clients c ON c.id = a.client_id
      WHERE a.user_id = ?
        AND datetime(a.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY a.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final type = r['type'] as String? ?? 'client';
      final reason = r['reason'] as String?;
      final statusStr = r['status'] as String? ?? 'pending';
      return ActivityItem(
        id: r['id'] as String,
        type: ActivityType.approval,
        subtype: ActivitySubtype.fromApproval(type: type, reason: reason),
        clientName: r['client_name'] as String?,
        detail: reason,
        status: statusFromApproval(statusStr),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  /// Fetch all activity types merged and sorted by createdAt DESC.
  /// Pass [typeFilter] to restrict to one type.
  Future<List<ActivityItem>> fetchAll({
    required DateTime from,
    required DateTime to,
    ActivityType? typeFilter,
  }) async {
    final futures = <Future<List<ActivityItem>>>[];

    if (typeFilter == null || typeFilter == ActivityType.touchpoint) {
      futures.add(fetchTouchpoints(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.visit) {
      futures.add(fetchVisits(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.call) {
      futures.add(fetchCalls(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.approval) {
      futures.add(fetchApprovals(from, to));
    }

    final results = await Future.wait(futures);
    final merged = results.expand((list) => list).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return ActivityRepository(userId: userId);
});
