import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../clients/data/models/client_model.dart';
import '../../../../services/sync/powersync_service.dart';

/// Repository for touchpoint CRUD operations using PowerSync
class TouchpointRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  TouchpointRepository(this._db) : _uuid = const Uuid();

  /// Watch all touchpoints for a client with real-time updates
  Stream<List<Touchpoint>> watchTouchpoints() {
    return _db.watch(
      'SELECT * FROM touchpoints ORDER BY date DESC',
    ).map((rows) => rows.map(Touchpoint.fromRow).toList());
  }

  /// Watch touchpoints for a specific client
  Stream<List<Touchpoint>> watchClientTouchpoints(String clientId) {
    return _db.watch(
      'SELECT * FROM touchpoints WHERE client_id = ? ORDER BY date DESC',
      [clientId],
    ).map((rows) => rows.map(Touchpoint.fromRow).toList());
  }

  /// Get touchpoints for a client (one-time fetch)
  Future<List<Touchpoint>> getClientTouchpoints(String clientId) async {
    final rows = await _db.getAll(
      'SELECT * FROM touchpoints WHERE client_id = ? ORDER BY date DESC',
      [clientId],
    );
    return rows.map(Touchpoint.fromRow).toList();
  }

  /// Create a new touchpoint (offline-first)
  Future<Touchpoint> createTouchpoint(Touchpoint touchpoint) async {
    final id = touchpoint.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''INSERT INTO touchpoints (
        id, client_id, caravan_id, touchpoint_number, type, date,
        address, time_arrival, time_departure, odometer_arrival, odometer_departure,
        reason, next_visit_date, notes, photo_url, audio_url,
        latitude, longitude, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, now, now)''',
      [
        id,
        touchpoint.clientId,
        touchpoint.caravanId,
        touchpoint.touchpointNumber,
        touchpoint.type.name.toUpperCase(),
        touchpoint.date.toIso8601String(),
        touchpoint.address,
        touchpoint.timeArrival?.format(),
        touchpoint.timeDeparture?.format(),
        touchpoint.odometerArrival,
        touchpoint.odometerDeparture,
        touchpoint.reason.name.toUpperCase(),
        touchpoint.nextVisitDate?.toIso8601String(),
        touchpoint.notes,
        touchpoint.photoUrl,
        touchpoint.audioUrl,
        touchpoint.latitude,
        touchpoint.longitude,
        now,
        now,
      ],
    );

    logDebug('Created touchpoint: $id');
    return touchpoint.copyWith(id: id);
  }

  /// Update an existing touchpoint (offline-first)
  Future<Touchpoint> updateTouchpoint(Touchpoint touchpoint) async {
    if (touchpoint.id == null) {
      throw ArgumentError('Touchpoint ID is required for update');
    }

    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''UPDATE touchpoints SET
        client_id = ?, caravan_id = ?, touchpoint_number = ?, type = ?,
        date = ?, address = ?, time_arrival = ?, time_departure = ?,
        odometer_arrival = ?, odometer_departure = ?, reason = ?,
        next_visit_date = ?, notes = ?, photo_url = ?, audio_url = ?,
        latitude = ?, longitude = ?, updated_at = ?
      WHERE id = ?''',
      [
        touchpoint.clientId,
        touchpoint.caravanId,
        touchpoint.touchpointNumber,
        touchpoint.type.name.toUpperCase(),
        touchpoint.date.toIso8601String(),
        touchpoint.address,
        touchpoint.timeArrival?.format(),
        touchpoint.timeDeparture?.format(),
        touchpoint.odometerArrival,
        touchpoint.odometerDeparture,
        touchpoint.reason.name.toUpperCase(),
        touchpoint.nextVisitDate?.toIso8601String(),
        touchpoint.notes,
        touchpoint.photoUrl,
        touchpoint.audioUrl,
        touchpoint.latitude
        touchpoint.longitude
        now,
        touchpoint.id,
      ],
    );

    logDebug('Updated touchpoint: ${touchpoint.id}');
    return touchpoint.copyWith(updatedAt: DateTime.parse(now));
  }

  /// Delete a touchpoint (offline-first)
  Future<void> deleteTouchpoint(String id) async {
    await _db.execute('DELETE FROM touchpoints WHERE id = ?', [id]);
    logDebug('Deleted touchpoint: $id');
  }

  /// Get next touchpoint number for a client
  Future<int> getNextTouchpointNumber(String clientId) async {
    final result = await _db.getOptional(
      'SELECT MAX(touchpoint_number) as max_num FROM touchpoints WHERE client_id = ?',
      [clientId],
    );
    return (result?['max_num'] as int? ?? 0) + 1;
  }

  /// Watch touchpoints by date range
  Stream<List<Touchpoint>> watchTouchpointsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _db.watch(
      'SELECT * FROM touchpoints WHERE date >= ? AND date <= ? ORDER BY date DESC',
      [startDate.toIso8601String(),      endDate.toIso8601String(),
    ).map((rows) => rows.map(Touchpoint.fromRow).toList());
  }
}

/// Provider for touchpoint repository
final touchpointRepositoryProvider = FutureProvider<TouchpointRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return TouchpointRepository(db);
});
