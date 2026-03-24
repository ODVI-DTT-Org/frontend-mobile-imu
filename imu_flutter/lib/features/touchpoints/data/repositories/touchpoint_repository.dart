import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import '../../../../core/utils/logger.dart';

/// Repository for touchpoint operations using PowerSync
class TouchpointRepository {
  final _uuid = const Uuid();

  /// Watch all touchpoints for a client with real-time updates
  Stream<List<Touchpoint>> watchTouchpoints(String clientId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM touchpoints WHERE client_id = ? ORDER BY touchpoint_number ASC',
        parameters: [clientId],
      )) {
        yield row.map(_mapRowToTouchpoint).toList();
      }
    } catch (e) {
      logError('Error watching touchpoints for client $clientId', e);
      yield [];
    }
  }

  /// Watch a single touchpoint by ID
  Stream<Touchpoint?> watchTouchpoint(String touchpointId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM touchpoints WHERE id = ?',
        parameters: [touchpointId],
      )) {
        yield row.isNotEmpty ? _mapRowToTouchpoint(row.first) : null;
      }
    } catch (e) {
      logError('Error watching touchpoint $touchpointId', e);
      yield null;
    }
  }

  /// Get touchpoints for a client (one-time fetch)
  Future<List<Touchpoint>> getTouchpoints(String clientId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM touchpoints WHERE client_id = ? ORDER BY touchpoint_number ASC',
        [clientId],
      );
      return results.map(_mapRowToTouchpoint).toList();
    } catch (e) {
      logError('Error getting touchpoints for client $clientId', e);
      return [];
    }
  }

  /// Get a single touchpoint by ID
  Future<Touchpoint?> getTouchpoint(String touchpointId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM touchpoints WHERE id = ?',
        [touchpointId],
      );
      return results.isNotEmpty ? _mapRowToTouchpoint(results.first) : null;
    } catch (e) {
      logError('Error getting touchpoint $touchpointId', e);
      return null;
    }
  }

  /// Get the next touchpoint number for a client
  Future<int> getNextTouchpointNumber(String clientId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.get(
        'SELECT MAX(touchpoint_number) as max_num FROM touchpoints WHERE client_id = ?',
        [clientId],
      );
      final maxNum = results?['max_num'] as int?;
      return (maxNum ?? 0) + 1;
    } catch (e) {
      logError('Error getting next touchpoint number', e);
      return 1;
    }
  }

  /// Create a new touchpoint
  Future<Touchpoint> createTouchpoint(Touchpoint touchpoint) async {
    try {
      final db = await PowerSyncService.database;
      final id = touchpoint.id.isEmpty ? _uuid.v4() : touchpoint.id;

      await db.execute(
        '''INSERT INTO touchpoints (
          id, client_id, caravan_id, touchpoint_number, type, date, address,
          time_arrival, time_departure, odometer_arrival, odometer_departure,
          reason, next_visit_date, notes, photo_url, audio_url, latitude, longitude
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          id,
          touchpoint.clientId,
          touchpoint.agentId,
          touchpoint.touchpointNumber,
          touchpoint.type.apiValue,
          touchpoint.date.toIso8601String(),
          touchpoint.address,
          touchpoint.timeArrival != null
              ? '${touchpoint.timeArrival!.hour.toString().padLeft(2, '0')}:${touchpoint.timeArrival!.minute.toString().padLeft(2, '0')}'
              : null,
          touchpoint.timeDeparture != null
              ? '${touchpoint.timeDeparture!.hour.toString().padLeft(2, '0')}:${touchpoint.timeDeparture!.minute.toString().padLeft(2, '0')}'
              : null,
          touchpoint.odometerArrival,
          touchpoint.odometerDeparture,
          touchpoint.reason.apiValue,
          touchpoint.nextVisitDate?.toIso8601String(),
          touchpoint.remarks,
          touchpoint.photoPath,
          null, // audio_url - not currently used in model
          touchpoint.latitude,
          touchpoint.longitude,
        ],
      );

      logDebug('Created touchpoint: $id');
      // Return a new Touchpoint with the generated ID
      return Touchpoint(
        id: id,
        clientId: touchpoint.clientId,
        agentId: touchpoint.agentId,
        touchpointNumber: touchpoint.touchpointNumber,
        type: touchpoint.type,
        date: touchpoint.date,
        address: touchpoint.address,
        timeArrival: touchpoint.timeArrival,
        timeDeparture: touchpoint.timeDeparture,
        odometerArrival: touchpoint.odometerArrival,
        odometerDeparture: touchpoint.odometerDeparture,
        reason: touchpoint.reason,
        nextVisitDate: touchpoint.nextVisitDate,
        remarks: touchpoint.remarks,
        photoPath: touchpoint.photoPath,
        latitude: touchpoint.latitude,
        longitude: touchpoint.longitude,
        createdAt: touchpoint.createdAt,
      );
    } catch (e) {
      logError('Error creating touchpoint', e);
      rethrow;
    }
  }

  /// Update an existing touchpoint
  Future<Touchpoint> updateTouchpoint(Touchpoint touchpoint) async {
    try {
      final db = await PowerSyncService.database;

      await db.execute(
        '''UPDATE touchpoints SET
          client_id = ?, caravan_id = ?, touchpoint_number = ?, type = ?,
          date = ?, address = ?, time_arrival = ?, time_departure = ?,
          odometer_arrival = ?, odometer_departure = ?, reason = ?,
          next_visit_date = ?, notes = ?, photo_url = ?, audio_url = ?,
          latitude = ?, longitude = ?
        WHERE id = ?''',
        [
          touchpoint.clientId,
          touchpoint.agentId,
          touchpoint.touchpointNumber,
          touchpoint.type.apiValue,
          touchpoint.date.toIso8601String(),
          touchpoint.address,
          touchpoint.timeArrival != null
              ? '${touchpoint.timeArrival!.hour.toString().padLeft(2, '0')}:${touchpoint.timeArrival!.minute.toString().padLeft(2, '0')}'
              : null,
          touchpoint.timeDeparture != null
              ? '${touchpoint.timeDeparture!.hour.toString().padLeft(2, '0')}:${touchpoint.timeDeparture!.minute.toString().padLeft(2, '0')}'
              : null,
          touchpoint.odometerArrival,
          touchpoint.odometerDeparture,
          touchpoint.reason.apiValue,
          touchpoint.nextVisitDate?.toIso8601String(),
          touchpoint.remarks,
          touchpoint.photoPath,
          null, // audio_url - not currently used in model
          touchpoint.latitude,
          touchpoint.longitude,
          touchpoint.id,
        ],
      );

      logDebug('Updated touchpoint: ${touchpoint.id}');
      return touchpoint;
    } catch (e) {
      logError('Error updating touchpoint', e);
      rethrow;
    }
  }

  /// Delete a touchpoint
  Future<void> deleteTouchpoint(String clientId, String touchpointId) async {
    try {
      final db = await PowerSyncService.database;
      await db.execute(
        'DELETE FROM touchpoints WHERE id = ? AND client_id = ?',
        [touchpointId, clientId],
      );
      logDebug('Deleted touchpoint: $touchpointId');
    } catch (e) {
      logError('Error deleting touchpoint', e);
      rethrow;
    }
  }

  /// Get touchpoints count for a client
  Future<int> getTouchpointsCount(String clientId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.get(
        'SELECT COUNT(*) as count FROM touchpoints WHERE client_id = ?',
        [clientId],
      );
      return results?['count'] as int? ?? 0;
    } catch (e) {
      logError('Error getting touchpoints count', e);
      return 0;
    }
  }

  /// Map database row to Touchpoint model
  Touchpoint _mapRowToTouchpoint(Map<String, dynamic> row) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Touchpoint(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      agentId: row['caravan_id'] as String?,
      touchpointNumber: row['touchpoint_number'] as int,
      type: TouchpointType.fromApi(row['type'] as String? ?? 'VISIT'),
      date: row['date'] != null ? DateTime.parse(row['date'] as String) : DateTime.now(),
      address: row['address'] as String?,
      timeArrival: parseTime(row['time_arrival'] as String?),
      timeDeparture: parseTime(row['time_departure'] as String?),
      odometerArrival: row['odometer_arrival'] as String?,
      odometerDeparture: row['odometer_departure'] as String?,
      reason: TouchpointReason.fromApi(row['reason'] as String? ?? 'INTERESTED'),
      nextVisitDate: row['next_visit_date'] != null
          ? DateTime.parse(row['next_visit_date'] as String)
          : null,
      remarks: row['notes'] as String?,
      photoPath: row['photo_url'] as String?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Provider for touchpoint repository
final touchpointRepositoryProvider = Provider<TouchpointRepository>((ref) {
  return TouchpointRepository();
});
