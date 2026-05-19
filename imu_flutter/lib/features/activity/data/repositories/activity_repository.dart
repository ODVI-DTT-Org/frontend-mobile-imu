import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

class ActivityRepository {
  final String userId;
  final PendingReleaseService? pendingReleaseService;

  const ActivityRepository({
    required this.userId,
    this.pendingReleaseService,
  });

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

  static ActivityItem activityFromPendingRelease(
    Map<String, dynamic> data, {
    String? clientName,
  }) {
    final queuedAt = DateTime.tryParse(data['queuedAt'] as String? ?? '') ??
        DateTime.now();
    final udiNumber = data['udiNumber'] as String?;

    return ActivityItem(
      id: data['id'] as String,
      type: ActivityType.approval,
      subtype: ActivitySubtype.loanRelease,
      clientName: clientName,
      detail: udiNumber,
      status: ActivityStatus.pending,
      createdAt: queuedAt,
      source: ActivitySource.pendingReleaseQueue,
      metadata: Map<String, dynamic>.from(data),
    );
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
    debugPrint('[ACTIVITY][repo] fetchTouchpoints userId=$userId from=$from to=$to');
    final pending = await _pendingIds('touchpoints');
    final rows = await PowerSyncService.query(
      """
      SELECT t.id, t.type, t.notes AS reason, t.touchpoint_number, t.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM touchpoints t
      LEFT JOIN clients c ON c.id = t.client_id
      WHERE t.user_id = ?
        AND datetime(t.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY t.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    debugPrint('[ACTIVITY][repo] fetchTouchpoints — ${rows.length} rows');
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

  Future<List<ActivityItem>> fetchApprovals(DateTime from, DateTime to) async {
    debugPrint('[ACTIVITY][repo] fetchApprovals userId=$userId from=$from to=$to');
    final rows = await PowerSyncService.query(
      """
      SELECT a.id, a.type, a.status, a.reason, a.udi_number, a.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM approvals a
      LEFT JOIN clients c ON c.id = a.client_id
      WHERE a.user_id = ?
        AND datetime(a.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY a.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    debugPrint('[ACTIVITY][repo] fetchApprovals — ${rows.length} rows');
    return rows.map((r) {
      final type = r['type'] as String? ?? 'client';
      final reason = r['reason'] as String?;
      final statusStr = r['status'] as String? ?? 'pending';
      final subtype = ActivitySubtype.fromApproval(type: type, reason: reason);
      final udiNumber = r['udi_number'] as String?;
      final detail = subtype == ActivitySubtype.loanRelease && udiNumber != null
          ? udiNumber
          : reason;
      return ActivityItem(
        id: r['id'] as String,
        type: ActivityType.approval,
        subtype: subtype,
        clientName: r['client_name'] as String?,
        detail: detail,
        status: statusFromApproval(statusStr),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<String?> _clientName(String clientId) async {
    try {
      final rows = await PowerSyncService.query(
        'SELECT first_name, last_name FROM clients WHERE id = ? LIMIT 1',
        [clientId],
      );
      if (rows.isEmpty) return null;
      final firstName = rows.first['first_name'] as String? ?? '';
      final lastName = rows.first['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();
      return fullName.isEmpty ? null : fullName;
    } catch (_) {
      return null;
    }
  }

  Future<List<ActivityItem>> fetchPendingLoanReleases(DateTime from, DateTime to) async {
    final service = pendingReleaseService;
    if (service == null) return const [];

    final queued = await service.peekAll();
    final items = <ActivityItem>[];

    for (final data in queued) {
      final queuedAt = DateTime.tryParse(data['queuedAt'] as String? ?? '');
      if (queuedAt == null ||
          queuedAt.isBefore(from) ||
          queuedAt.isAfter(to)) {
        continue;
      }

      final clientId = data['clientId'] as String?;
      items.add(activityFromPendingRelease(
        data,
        clientName: clientId != null ? await _clientName(clientId) : null,
      ));
    }

    return items;
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
    if (typeFilter == null || typeFilter == ActivityType.approval) {
      futures.add(fetchApprovals(from, to));
      futures.add(fetchPendingLoanReleases(from, to));
    }

    final results = await Future.wait(futures);
    final merged = results.expand((list) => list).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}

final activityRepositoryProvider = Provider.autoDispose<ActivityRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  debugPrint('[ACTIVITY][repo] activityRepositoryProvider — userId="$userId"');
  return ActivityRepository(
    userId: userId,
    pendingReleaseService: ref.watch(pendingReleaseServiceProvider),
  );
});
