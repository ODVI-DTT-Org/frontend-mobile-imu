import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
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
class AttendanceApiService {
  final PocketBase _pb;

  AttendanceApiService({required PocketBase pb}) : _pb = pb;

  Future<AttendanceRecord> checkIn(String agentId, double latitude, double longitude) async {
    try {
      debugPrint('AttendanceApiService: Checking in agent $agentId');

      final now = DateTime.now();
      final result = await _pb.collection('attendance').create(body: {
        'agent_id': agentId,
        'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'status': 'present',
        'check_in_time': now.toIso8601String(),
        'check_in_latitude': latitude,
        'check_in_longitude': longitude,
      });

      debugPrint('AttendanceApiService: Checked in agent ${result.id}');
      return AttendanceRecord.fromJson(result.data);
    } on ClientException catch (e) {
      debugPrint('AttendanceApiService: Error checking in - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<AttendanceRecord> checkOut(String attendanceId, double latitude, double longitude) async {
    try {
      debugPrint('AttendanceApiService: Checking out attendance $attendanceId');
      final result = await _pb.collection('attendance').update(attendanceId, body: {
        'check_out_time': DateTime.now().toIso8601String(),
        'check_out_latitude': latitude,
        'check_out_longitude': longitude,
        'status': 'completed',
      });

      debugPrint('AttendanceApiService: Checked out attendance ${result.id}');
      return AttendanceRecord.fromJson(result.data);
    } on ClientException catch (e) {
      debugPrint('AttendanceApiService: Error checking out - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<AttendanceRecord?> getTodayAttendance(String agentId) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final result = await _pb.collection('attendance').getList(
        page: 1,
        perPage: 1,
        filter: 'agent_id = "$agentId" && date = "$dateStr"',
      );

      if (result.items.isEmpty) return null;
      return AttendanceRecord.fromJson(result.items.first.data);
    } on ClientException catch (e) {
      debugPrint('AttendanceApiService: Error getting today attendance - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<List<AttendanceRecord>> getAttendanceHistory(String agentId, {int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final result = await _pb.collection('attendance').getList(
        page: 1,
        perPage: days,
        filter: 'agent_id = "$agentId" && date >= "${startDate.toIso8601String().split('T')[0]}"',
        sort: '-date',
      );

      return result.items.map((item) => AttendanceRecord.fromJson(item.data)).toList();
    } on ClientException catch (e) {
      debugPrint('AttendanceApiService: Error getting attendance history - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }
}

final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return AttendanceApiService(pb: pb);
});
