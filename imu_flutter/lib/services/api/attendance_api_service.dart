import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Attendance record model
class AttendanceRecord {
  final String id;
  final String agentId;
  final DateTime date;
  final String status; // present, absent, late, on_leave
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String? notes;
  final DateTime createdAt;

  AttendanceRecord({
    required this.id,
    required this.agentId,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.notes,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      agentId: json['agent_id'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'present',
      checkInTime: json['check_in_time'] != null
          ? DateTime.parse(json['check_in_time'])
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.parse(json['check_out_time'])
          : null,
      checkInLatitude: json['check_in_latitude']?.toDouble(),
      checkInLongitude: json['check_in_longitude']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Attendance API service
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class AttendanceApiService {
  /// Check in an agent
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<AttendanceRecord?> checkIn(String agentId, double latitude, double longitude) async {
    try {
      debugPrint('AttendanceApiService: checkIn called for agent $agentId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase check-in
      return null;
    } catch (e) {
      debugPrint('AttendanceApiService: Error checking in - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Check out
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<AttendanceRecord?> checkOut(String attendanceId, double latitude, double longitude) async {
    try {
      debugPrint('AttendanceApiService: checkOut called for attendance $attendanceId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase check-out
      return null;
    } catch (e) {
      debugPrint('AttendanceApiService: Error checking out - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Get today's attendance for an agent
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<AttendanceRecord?> getTodayAttendance(String agentId) async {
    try {
      debugPrint('AttendanceApiService: getTodayAttendance called for agent $agentId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return null;
    } catch (e) {
      debugPrint('AttendanceApiService: Error getting today attendance - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Get attendance history for an agent
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<List<AttendanceRecord>> getAttendanceHistory(String agentId, {int days = 30}) async {
    try {
      debugPrint('AttendanceApiService: getAttendanceHistory called for agent $agentId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
    } catch (e) {
      debugPrint('AttendanceApiService: Error getting attendance history - $e');
      throw ApiException.fromError(e);
    }
  }
}

/// Provider for AttendanceApiService
final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  return AttendanceApiService();
});
