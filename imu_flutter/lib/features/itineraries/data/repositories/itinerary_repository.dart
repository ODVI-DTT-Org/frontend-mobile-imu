import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/core/utils/logger.dart';
import 'package:imu_flutter/services/api/itinerary_api_service.dart' show ItineraryItem;
import 'package:imu_flutter/shared/providers/app_providers.dart' show currentUserIdProvider;
import 'package:imu_flutter/services/local_storage/hive_service.dart';

/// Itinerary model for scheduled visits
class Itinerary {
  final String id;
  final String? caravanId;
  final String? clientId;
  final DateTime? scheduledDate;
  final String? scheduledTime;
  final String? status;
  final String? priority;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Itinerary({
    required this.id,
    this.caravanId,
    this.clientId,
    this.scheduledDate,
    this.scheduledTime,
    this.status,
    this.priority,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from API format
  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] ?? '',
      caravanId: json['user_id'] ?? json['caravan_id'] ?? json['caravanId'],
      clientId: json['client_id'] ?? json['clientId'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : json['scheduledDate'] != null
              ? DateTime.parse(json['scheduledDate'])
              : null,
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'],
      status: json['status'],
      priority: json['priority'],
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : null,
    );
  }

  /// Convert to API format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caravan_id': caravanId,
      'client_id': clientId,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'scheduled_time': scheduledTime,
      'status': status,
      'priority': priority,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields
  Itinerary copyWith({
    String? id,
    String? caravanId,
    String? clientId,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? status,
    String? priority,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Itinerary(
      id: id ?? this.id,
      caravanId: caravanId ?? this.caravanId,
      clientId: clientId ?? this.clientId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Repository for itinerary operations using PowerSync
class ItineraryRepository {
  final _uuid = const Uuid();

  /// Watch all itineraries with real-time updates
  Stream<List<Itinerary>> watchItineraries() async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM itineraries ORDER BY scheduled_date ASC, scheduled_time ASC',
      )) {
        yield row.map(Itinerary.fromJson).toList();
      }
    } catch (e) {
      logError('Error watching itineraries', e);
      yield [];
    }
  }

  /// Watch itineraries for a specific caravan
  Stream<List<Itinerary>> watchCaravanItineraries(String caravanId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM itineraries WHERE user_id = ? ORDER BY scheduled_date ASC, scheduled_time ASC',
        parameters: [caravanId],
      )) {
        yield row.map(Itinerary.fromJson).toList();
      }
    } catch (e) {
      logError('Error watching itineraries for caravan $caravanId', e);
      yield [];
    }
  }

  /// Watch itineraries for a specific date
  Stream<List<Itinerary>> watchDateItineraries(DateTime date) async* {
    try {
      final db = await PowerSyncService.database;
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await for (final row in db.watch(
        'SELECT * FROM itineraries WHERE DATE(scheduled_date) = ? ORDER BY scheduled_time ASC',
        parameters: [dateStr],
      )) {
        yield row.map(Itinerary.fromJson).toList();
      }
    } catch (e) {
      logError('Error watching itineraries for date $date', e);
      yield [];
    }
  }

  /// Watch a single itinerary by ID
  Stream<Itinerary?> watchItinerary(String itineraryId) async* {
    try {
      final db = await PowerSyncService.database;
      await for (final row in db.watch(
        'SELECT * FROM itineraries WHERE id = ?',
        parameters: [itineraryId],
      )) {
        yield row.isNotEmpty ? Itinerary.fromJson(row.first) : null;
      }
    } catch (e) {
      logError('Error watching itinerary $itineraryId', e);
      yield null;
    }
  }

  /// Get all itineraries (one-time fetch)
  Future<List<Itinerary>> getItineraries() async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM itineraries ORDER BY scheduled_date ASC, scheduled_time ASC',
      );
      return results.map(Itinerary.fromJson).toList();
    } catch (e) {
      logError('Error getting itineraries', e);
      return [];
    }
  }

  /// Get itineraries for a specific caravan
  Future<List<Itinerary>> getCaravanItineraries(String caravanId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM itineraries WHERE user_id = ? ORDER BY scheduled_date ASC, scheduled_time ASC',
        [caravanId],
      );
      return results.map(Itinerary.fromJson).toList();
    } catch (e) {
      logError('Error getting itineraries for caravan $caravanId', e);
      return [];
    }
  }

  /// Get itineraries for a specific date
  Future<List<Itinerary>> getDateItineraries(DateTime date) async {
    try {
      final db = await PowerSyncService.database;
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final results = await db.getAll(
        'SELECT * FROM itineraries WHERE DATE(scheduled_date) = ? ORDER BY scheduled_time ASC',
        [dateStr],
      );
      return results.map(Itinerary.fromJson).toList();
    } catch (e) {
      logError('Error getting itineraries for date $date', e);
      return [];
    }
  }

  /// Get a single itinerary by ID
  Future<Itinerary?> getItinerary(String itineraryId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.getAll(
        'SELECT * FROM itineraries WHERE id = ?',
        [itineraryId],
      );
      return results.isNotEmpty ? Itinerary.fromJson(results.first) : null;
    } catch (e) {
      logError('Error getting itinerary $itineraryId', e);
      return null;
    }
  }

  /// Create a new itinerary
  Future<Itinerary> createItinerary(Itinerary itinerary) async {
    try {
      final db = await PowerSyncService.database;
      final id = itinerary.id.isEmpty ? _uuid.v4() : itinerary.id;
      final now = DateTime.now().toIso8601String();

      await db.execute(
        '''INSERT INTO itineraries (
          id, user_id, client_id, scheduled_date, scheduled_time,
          status, priority, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          id,
          itinerary.caravanId,
          itinerary.clientId,
          itinerary.scheduledDate?.toIso8601String(),
          itinerary.scheduledTime,
          itinerary.status ?? 'pending',
          itinerary.priority ?? 'normal',
          itinerary.notes,
        ],
      );

      logDebug('Created itinerary: $id');
      return itinerary.copyWith(id: id, createdAt: DateTime.parse(now));
    } catch (e) {
      logError('Error creating itinerary', e);
      rethrow;
    }
  }

  /// Update an existing itinerary
  Future<void> updateItinerary(Itinerary itinerary) async {
    try {
      final db = await PowerSyncService.database;

      await db.execute(
        '''UPDATE itineraries SET
          user_id = ?, client_id = ?, scheduled_date = ?,
          scheduled_time = ?, status = ?, priority = ?, notes = ?
        WHERE id = ?''',
        [
          itinerary.caravanId,
          itinerary.clientId,
          itinerary.scheduledDate?.toIso8601String(),
          itinerary.scheduledTime,
          itinerary.status,
          itinerary.priority,
          itinerary.notes,
          itinerary.id,
        ],
      );

      logDebug('Updated itinerary: ${itinerary.id}');
    } catch (e) {
      logError('Error updating itinerary', e);
      rethrow;
    }
  }

  /// Delete an itinerary
  Future<void> deleteItinerary(String itineraryId) async {
    try {
      final db = await PowerSyncService.database;
      await db.execute('DELETE FROM itineraries WHERE id = ?', [itineraryId]);
      logDebug('Deleted itinerary: $itineraryId');
    } catch (e) {
      logError('Error deleting itinerary', e);
      rethrow;
    }
  }

  /// Update itinerary status
  Future<void> updateStatus(String itineraryId, String status) async {
    try {
      final db = await PowerSyncService.database;
      await db.execute(
        'UPDATE itineraries SET status = ? WHERE id = ?',
        [status, itineraryId],
      );
      logDebug('Updated itinerary status: $itineraryId -> $status');
    } catch (e) {
      logError('Error updating itinerary status', e);
      rethrow;
    }
  }

  /// Get itineraries count for a caravan
  Future<int> getCaravanItinerariesCount(String caravanId) async {
    try {
      final db = await PowerSyncService.database;
      final results = await db.get(
        'SELECT COUNT(*) as count FROM itineraries WHERE user_id = ?',
        [caravanId],
      );
      return results?['count'] as int? ?? 0;
    } catch (e) {
      logError('Error getting itineraries count', e);
      return 0;
    }
  }
}

/// Provider for itinerary repository
final itineraryRepositoryProvider = Provider<ItineraryRepository>((ref) {
  return ItineraryRepository();
});

/// Merges Hive client data into a PowerSync itinerary row.
Map<String, dynamic> _enrichItineraryRowFromHive(Map<String, dynamic> row) {
  final clientId = row['client_id'] as String?;
  debugPrint('[ItineraryRepo] Row client_id=$clientId');
  if (clientId == null) return row;

  final hiveCount = HiveService().cachedClientCount;
  debugPrint('[ItineraryRepo] Hive cache size: $hiveCount');

  final cached = HiveService().getClient(clientId);
  if (cached == null) {
    debugPrint('[ItineraryRepo] client_id=$clientId NOT found in Hive');
    return row;
  }

  debugPrint('[ItineraryRepo] client_id=$clientId found: firstName=${cached['firstName']}, lastName=${cached['lastName']}');
  final enriched = Map<String, dynamic>.from(row);
  enriched['first_name'] = cached['firstName'] ?? cached['first_name'];
  enriched['last_name'] = cached['lastName'] ?? cached['last_name'];
  enriched['middle_name'] = cached['middleName'] ?? cached['middle_name'];
  enriched['municipality'] = cached['municipality'];
  enriched['province'] = cached['province'];
  return enriched;
}

/// Stream provider for itineraries on a specific date — queries PowerSync local SQLite
/// Returns items for the current user, ordered by scheduled_time.
final itineraryByDateProvider = StreamProvider.family<List<ItineraryItem>, DateTime>((ref, date) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield [];
    return;
  }
  final dateStr =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  try {
    final db = await PowerSyncService.database;
    await for (final rows in db.watch(
      '''SELECT * FROM itineraries i
         WHERE i.user_id = ? AND DATE(i.scheduled_date) = ?
         ORDER BY i.scheduled_time ASC''',
      parameters: [userId, dateStr],
    )) {
      debugPrint('[ItineraryRepo] itineraryByDateProvider: ${rows.length} rows from PowerSync');
      yield rows.map((r) => ItineraryItem.fromPowerSync(_enrichItineraryRowFromHive(r))).toList();
    }
  } catch (e) {
    logError('itineraryByDateProvider error', e);
    yield [];
  }
});
