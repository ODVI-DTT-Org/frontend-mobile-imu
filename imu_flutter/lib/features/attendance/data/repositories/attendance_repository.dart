import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/attendance/data/models/attendance_record.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class AttendanceRepository {
  /// Today's attendance record for the given user, or null if not checked in.
  Future<AttendanceRecord?> getTodayAttendance(String userId) async {
    final db = await PowerSyncService.database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await db.getAll(
      'SELECT * FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
      [userId, today],
    );
    if (rows.isEmpty) return null;
    return AttendanceRecord.fromRow(rows.first);
  }

  /// Stream of today's attendance — updates in real time when synced.
  Stream<AttendanceRecord?> watchTodayAttendance(String userId) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM attendance WHERE user_id = ? AND date = ? LIMIT 1',
        parameters: [userId, today],
      ).map((rows) => rows.isEmpty ? null : AttendanceRecord.fromRow(rows.first));
    });
  }

  /// Attendance history for the user, newest first.
  Future<List<AttendanceRecord>> getHistory(String userId, {int limit = 30}) async {
    final db = await PowerSyncService.database;
    final rows = await db.getAll(
      'SELECT * FROM attendance WHERE user_id = ? ORDER BY date DESC LIMIT ?',
      [userId, limit],
    );
    return rows.map(AttendanceRecord.fromRow).toList();
  }

  Stream<List<AttendanceRecord>> watchHistory(String userId, {int limit = 30}) {
    return PowerSyncService.database.asStream().asyncExpand((db) {
      return db.watch(
        'SELECT * FROM attendance WHERE user_id = ? ORDER BY date DESC LIMIT ?',
        parameters: [userId, limit],
      ).map((rows) => rows.map(AttendanceRecord.fromRow).toList());
    });
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((_) => AttendanceRepository());
