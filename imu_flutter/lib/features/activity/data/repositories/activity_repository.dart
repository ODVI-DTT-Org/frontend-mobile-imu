import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/services/api/release_api_service.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

class ActivityRepository {
  final String userId;
  final PendingReleaseService? pendingReleaseService;
  final ReleaseApiService? releaseApiService;
  final bool isOnline;

  const ActivityRepository({
    required this.userId,
    this.pendingReleaseService,
    this.releaseApiService,
    this.isOnline = true,
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

  static ActivityStatus statusFromRelease(String status) {
    switch (status) {
      case 'approved': return ActivityStatus.approved;
      case 'disbursed':
      case 'completed': return ActivityStatus.completed;
      case 'rejected': return ActivityStatus.rejected;
      default: return ActivityStatus.pending;
    }
  }

  static String? _stringValue(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, dynamic> touchpointMetadataFromRow(Map<String, dynamic> r) {
    final tpType = _stringValue(r, 'type') ?? 'Visit';
    final isCall = tpType == 'Call';
    final reason = _stringValue(r, isCall ? 'call_reason' : 'visit_reason') ??
        _stringValue(r, 'touchpoint_notes') ??
        _stringValue(r, 'reason');
    final notes = _stringValue(r, isCall ? 'call_notes' : 'visit_notes') ??
        _stringValue(r, 'touchpoint_notes');

    return {
      'touchpointNumber': r['touchpoint_number'],
      'touchpointType': tpType,
      'date': _stringValue(r, 'date'),
      'reason': reason,
      'status': _stringValue(r, isCall ? 'call_status' : 'visit_status') ??
          _stringValue(r, 'status'),
      'notes': notes,
      'timeIn': _stringValue(r, 'time_in'),
      'timeOut': _stringValue(r, 'time_out'),
      'odometerArrival': _stringValue(r, 'odometer_arrival'),
      'odometerDeparture': _stringValue(r, 'odometer_departure'),
      'phoneNumber': _stringValue(r, 'phone_number'),
      'dialTime': _stringValue(r, 'dial_time'),
      'duration': r['duration'],
      'address': _stringValue(r, 'visit_address') ?? _stringValue(r, 'address'),
      'latitude': r['visit_latitude'] ?? r['latitude'],
      'longitude': r['visit_longitude'] ?? r['longitude'],
      'photoUrl': _stringValue(r, isCall ? 'call_photo_url' : 'photo_url'),
      'visitId': _stringValue(r, 'visit_id'),
      'callId': _stringValue(r, 'call_id'),
    }..removeWhere((_, value) => value == null || value == '');
  }

  static Map<String, dynamic> approvalMetadataFromRow(Map<String, dynamic> r) {
    return {
      'approvalType': _stringValue(r, 'type'),
      'reason': _stringValue(r, 'reason'),
      'notes': _stringValue(r, 'notes'),
      'udiNumber': _stringValue(r, 'udi_number'),
      'updatedUdi': _stringValue(r, 'updated_udi'),
      'approvedAt': _stringValue(r, 'approved_at'),
      'rejectedAt': _stringValue(r, 'rejected_at'),
      'rejectionReason': _stringValue(r, 'rejection_reason'),
    }..removeWhere((_, value) => value == null || value == '');
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

  static ActivityItem activityFromRelease(
    Map<String, dynamic> data, {
    String? clientName,
    Map<String, dynamic> visitMetadata = const {},
  }) {
    final createdAt = DateTime.tryParse('${data['created_at'] ?? ''}') ??
        DateTime.now();
    final udiNumber = data['udi_number']?.toString();
    final metadata = <String, dynamic>{
      'clientId': _stringValue(data, 'client_id'),
      'visitId': _stringValue(data, 'visit_id'),
      'productType': _stringValue(data, 'product_type'),
      'loanType': _stringValue(data, 'loan_type'),
      'udiNumber': udiNumber,
      'remarks': _stringValue(data, 'remarks'),
      'approvalNotes': _stringValue(data, 'approval_notes'),
      'approvedAt': _stringValue(data, 'approved_at'),
      ...visitMetadata,
    }..removeWhere((_, value) => value == null || value == '');

    return ActivityItem(
      id: data['id'] as String,
      type: ActivityType.approval,
      subtype: ActivitySubtype.loanRelease,
      clientName: clientName,
      detail: udiNumber,
      status: statusFromRelease(_stringValue(data, 'status') ?? 'completed'),
      createdAt: createdAt,
      metadata: metadata,
    );
  }

  /// Parse a timestamp that may have been written by the device (Dart
  /// ISO8601) OR replicated from Postgres by PowerSync. PowerSync can emit a
  /// timestamptz with a bare `+00` offset, which SQLite's `datetime()` fails
  /// to parse (returns NULL) — Dart's parser handles both shapes.
  static DateTime? parseTimestamp(Object? raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  static bool isWithinWindow(DateTime? createdAt, DateTime from, DateTime to) {
    if (createdAt == null) return false;
    return !createdAt.isBefore(from) && !createdAt.isAfter(to);
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
      SELECT t.id, t.type, t.notes AS touchpoint_notes, t.touchpoint_number,
             t.date, t.status, t.next_visit_date, t.visit_id, t.call_id,
             t.latitude, t.longitude, t.address, t.created_at,
             c.first_name || ' ' || c.last_name AS client_name,
             v.reason AS visit_reason, v.notes AS visit_notes, v.status AS visit_status,
             v.time_in, v.time_out, v.odometer_arrival, v.odometer_departure,
             v.photo_url, v.address AS visit_address, v.latitude AS visit_latitude,
             v.longitude AS visit_longitude,
             ca.reason AS call_reason, ca.notes AS call_notes, ca.status AS call_status,
             ca.phone_number, ca.dial_time, ca.duration, ca.photo_url AS call_photo_url
      FROM touchpoints t
      LEFT JOIN clients c ON c.id = t.client_id
      LEFT JOIN visits v ON v.id = t.visit_id
      LEFT JOIN calls ca ON ca.id = t.call_id
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
      final metadata = touchpointMetadataFromRow(r);
      final reason = metadata['reason'] as String? ?? '';
      return ActivityItem(
        id: id,
        type: ActivityType.touchpoint,
        subtype: subtypeFromTouchpoint(tpType),
        clientName: r['client_name'] as String?,
        detail: 'Touchpoint #$tpNum • $tpType${reason.isNotEmpty ? ' — $reason' : ''}',
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
        metadata: metadata,
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchApprovals(DateTime from, DateTime to) async {
    debugPrint('[ACTIVITY][repo] fetchApprovals userId=$userId from=$from to=$to');
    // Date window is filtered in Dart, not SQLite. `approvals.created_at` is
    // server-set and replicated by PowerSync; its timestamp text can be a form
    // SQLite's `datetime()` returns NULL for, which silently dropped pending
    // approvals (incl. loan releases) from the feed. See [isWithinWindow].
    final rows = await PowerSyncService.query(
      """
      SELECT a.id, a.type, a.status, a.reason, a.notes, a.udi_number,
             a.updated_udi, a.approved_at, a.rejected_at, a.rejection_reason,
             a.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM approvals a
      LEFT JOIN clients c ON c.id = a.client_id
      WHERE a.user_id = ?
      ORDER BY a.created_at DESC
      """,
      [userId],
    );

    debugPrint('[ACTIVITY][repo] fetchApprovals — ${rows.length} rows');
    final items = <ActivityItem>[];
    for (final r in rows) {
      final createdAt = parseTimestamp(r['created_at']);
      if (!isWithinWindow(createdAt, from, to)) continue;
      final type = r['type'] as String? ?? 'client';
      final reason = r['reason'] as String?;
      final statusStr = r['status'] as String? ?? 'pending';
      final subtype = ActivitySubtype.fromApproval(type: type, reason: reason);
      final udiNumber = r['udi_number'] as String?;
      final detail = subtype == ActivitySubtype.loanRelease && udiNumber != null
          ? udiNumber
          : reason;
      items.add(ActivityItem(
        id: r['id'] as String,
        type: ActivityType.approval,
        subtype: subtype,
        clientName: r['client_name'] as String?,
        detail: detail,
        status: statusFromApproval(statusStr),
        createdAt: createdAt,
        metadata: approvalMetadataFromRow(r),
      ));
    }
    return items;
  }

  Future<Map<String, dynamic>> _visitMetadata(String? visitId) async {
    if (visitId == null || visitId.isEmpty) return const {};
    try {
      final rows = await PowerSyncService.query(
        """
        SELECT time_in, time_out, odometer_arrival, odometer_departure,
               notes, reason, status, address, latitude, longitude, photo_url
        FROM visits
        WHERE id = ?
        LIMIT 1
        """,
        [visitId],
      );
      if (rows.isEmpty) return const {};
      final row = rows.first;
      return {
        'timeIn': _stringValue(row, 'time_in'),
        'timeOut': _stringValue(row, 'time_out'),
        'odometerArrival': _stringValue(row, 'odometer_arrival'),
        'odometerDeparture': _stringValue(row, 'odometer_departure'),
        'reason': _stringValue(row, 'reason'),
        'notes': _stringValue(row, 'notes'),
        'status': _stringValue(row, 'status'),
        'address': _stringValue(row, 'address'),
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'photoUrl': _stringValue(row, 'photo_url'),
      }..removeWhere((_, value) => value == null || value == '');
    } catch (_) {
      return const {};
    }
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

  Future<List<ActivityItem>> fetchCompletedLoanReleases(DateTime from, DateTime to) async {
    final service = releaseApiService;
    if (service == null || !isOnline) return const [];

    try {
      final rows = await service.fetchReleases(from: from, to: to);
      final items = <ActivityItem>[];
      for (final row in rows) {
        final status = _stringValue(row, 'status') ?? '';
        if (status == 'pending') continue;
        final clientId = _stringValue(row, 'client_id');
        final visitId = _stringValue(row, 'visit_id');
        items.add(activityFromRelease(
          row,
          clientName: clientId != null ? await _clientName(clientId) : null,
          visitMetadata: await _visitMetadata(visitId),
        ));
      }
      return items;
    } catch (e) {
      debugPrint('[ACTIVITY][repo] fetchCompletedLoanReleases failed: $e');
      return const [];
    }
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
      futures.add(fetchCompletedLoanReleases(from, to));
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
    releaseApiService: ref.watch(releaseApiServiceProvider),
    isOnline: ref.watch(isOnlineProvider),
  );
});
