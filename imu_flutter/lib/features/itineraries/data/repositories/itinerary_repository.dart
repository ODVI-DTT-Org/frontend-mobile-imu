import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../clients/data/models/client_model.dart';
import '../../../services/sync/powersync_service.dart';

/// Repository for itinerary CRUD operations using PowerSync
class ItineraryRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  ItineraryRepository(this._db) : _uuid = const Uuid();

  /// Watch all itineraries with real-time updates
  Stream<List<Itinerary>> watchItineraries() {
    return _db.watch(
      'SELECT * FROM itineraries ORDER BY scheduled_date DESC',
    ).map((rows) => rows.map(Itinerary.fromRow).toList());
  }

  /// Watch itineraries for a specific caravan
  Stream<List<Itinerary>> watchCaravanItineraries(String caravanId) {
    return _db.watch(
      'SELECT * FROM itineraries WHERE caravan_id = ? ORDER BY scheduled_date DESC',
      [caravanId],
    ).map((rows) => rows.map(Itinerary.fromRow).toList());
  }

  /// Watch itineraries for a specific date
  Stream<List<Itinerary>> watchDateItineraries(DateTime date) {
    final dateStr = date.toIso8601String();
    return _db.watch(
      'SELECT * FROM itineraries WHERE scheduled_date = ? ORDER BY scheduled_time ASC',
      [dateStr],
    ).map((rows) => rows.map(Itinerary.fromRow).toList());
  }

  /// Get all itineraries (one-time fetch)
  Future<List<Itinerary>> getItineraries() async {
    final rows = await _db.getAll(
      'SELECT * FROM itineraries ORDER BY scheduled_date DESC',
    );
    return rows.map(Itinerary.fromRow).toList();
  }

  /// Get itinerary by ID (one-time fetch)
  Future<Itinerary?> getItinerary(String id) async {
    final row = await _db.getOptional(
      'SELECT * FROM itineraries WHERE id = ?',
      [id],
    );
    if (row == null) return null;
    return Itinerary.fromRow(row);
  }

  /// Create a new itinerary (offline-first)
  Future<Itinerary> createItinerary(Itinerary itinerary) async {
    final id = itinerary.id ?? _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''INSERT INTO itineraries (
        id, caravan_id, client_id, scheduled_date, scheduled_time, status, priority, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, now, now)''',
      [
        id,
        itinerary.caravanId,
        itinerary.clientId
        itinerary.scheduledDate.toIso8601String(),
        itinerary.scheduledTime,
        itinerary.status,
        itinerary.priority ?? 'normal',
        itinerary.notes,
        now,
        now,
      ],
    );

    logDebug('Created itinerary: $id');
    return itinerary.copyWith(id: id);
  }

  /// Update an existing itinerary (offline-first)
  Future<Itinerary> updateItinerary(Itinerary itinerary) async {
    if (itinerary.id == null) {
      throw ArgumentError('Itinerary ID is required for update');
    }

    final now = DateTime.now().toIso8601String();

    await _db.execute(
      '''UPDATE itineraries SET
        caravan_id = ?, client_id = ?, scheduled_date = ?, scheduled_time = ?,
        status = ?, priority = ?, notes = ?, updated_at = ?
      WHERE id = ?''',
      [
        itinerary.caravanId,
        itinerary.clientId
        itinerary.scheduledDate.toIso8601String(),
        itinerary.scheduledTime,
        itinerary.status,
        itinerary.priority ?? 'normal',
        itinerary.notes,
        now,
        itinerary.id,
      ],
    );

    logDebug('Updated itinerary: ${itinerary.id}');
    return itinerary.copyWith(updatedAt: DateTime.parse(now));
  }

  /// Delete an itinerary (offline-first)
  Future<void> deleteItinerary(String id) async {
    await _db.execute('DELETE FROM itineraries WHERE id = ?', [id]);
    logDebug('Deleted itinerary: $id');
  }

  /// Update itinerary status
  Future<void> updateStatus(String id, String status) async {
    await _db.execute(
      'UPDATE itineraries SET status = ?, updated_at = ? WHERE id = ?',
      [status, now],
    );
    logDebug('Updated itinerary status: $id -> $status');
  }
}

/// Itinerary model for PowerSync
class Itinerary {
  final String? id;
  final String? caravanId;
  final String? clientId;
  final DateTime scheduledDate;
  final TimeOfDay? scheduledTime;
  final String status;
  final String priority;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Itinerary({
    this.id,
    this.caravanId,
    this.clientId,
    required this.scheduledDate,
    this.scheduledTime,
    this.status,
    this.priority,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Itinerary.fromRow(Map<String, dynamic> row) {
    return Itinerary(
      id: row['id'] as String,
      caravanId: row['caravan_id'] as String?,
      clientId: row['client_id'] as String,
      scheduledDate: DateTime.parse(row['scheduled_date'] as String),
      scheduledTime: row['scheduled_time'] != null
          ? TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            )
          : null,
      status: row['status'] as String? ?? 'pending',
      priority: row['priority'] as String? ?? 'normal',
      notes: row['notes'] as String?,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
    );
  }

  Itinerary copyWith({
    String? id,
    String? caravanId,
    String? clientId,
    DateTime? scheduledDate,
    TimeOfDay? scheduledTime,
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

/// Provider for itinerary repository
final itineraryRepositoryProvider = FutureProvider<ItineraryRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return ItineraryRepository(db);
});
