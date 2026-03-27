import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';

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
  final double? checkOutLatitude;
  final double? checkOutLongitude;
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
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.notes,
    required this.createdAt,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      agentId: json['user_id'] ?? json['agent_id'] ?? '',
      date: DateTime.parse(json['date']),
      status: json['status'] ?? 'present',
      checkInTime: json['time_in'] != null
          ? DateTime.parse(json['time_in'])
          : null,
      checkOutTime: json['time_out'] != null
          ? DateTime.parse(json['time_out'])
          : null,
      checkInLatitude: json['location_in_lat']?.toDouble(),
      checkInLongitude: json['location_in_lng']?.toDouble(),
      checkOutLatitude: json['location_out_lat']?.toDouble(),
      checkOutLongitude: json['location_out_lng']?.toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Whether the agent is currently checked in (checked in but not checked out)
  bool get isCheckedIn => checkInTime != null && checkOutTime == null;
}

/// Attendance API service
class AttendanceApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  AttendanceApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Check in an agent
  Future<AttendanceRecord?> checkIn({
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      debugPrint('AttendanceApiService: Checking in...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('AttendanceApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Prepare request data
      final requestData = {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
      };

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/attendance/check-in',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201) {
        final attendanceData = response.data as Map<String, dynamic>;
        debugPrint('AttendanceApiService: Checked in successfully: ${attendanceData['id']}');
        return AttendanceRecord.fromJson(attendanceData);
      } else {
        debugPrint('AttendanceApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to check in: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AttendanceApiService: DioException - ${e.message}');
      debugPrint('AttendanceApiService: Response - ${e.response?.data}');
      // Check if already checked in
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        final data = e.response?.data as Map;
        if (data['attendance'] != null) {
          debugPrint('AttendanceApiService: Already checked in today');
          return AttendanceRecord.fromJson(data['attendance'] as Map<String, dynamic>);
        }
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('AttendanceApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to check in',
        originalError: e,
      );
    }
  }

  /// Check out
  Future<AttendanceRecord?> checkOut({
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      debugPrint('AttendanceApiService: Checking out...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('AttendanceApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Prepare request data
      final requestData = {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (notes != null) 'notes': notes,
      };

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/attendance/check-out',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final attendanceData = response.data as Map<String, dynamic>;
        debugPrint('AttendanceApiService: Checked out successfully: ${attendanceData['id']}');
        return AttendanceRecord.fromJson(attendanceData);
      } else {
        debugPrint('AttendanceApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to check out: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AttendanceApiService: DioException - ${e.message}');
      debugPrint('AttendanceApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // No check-in record found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('AttendanceApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to check out',
        originalError: e,
      );
    }
  }

  /// Get today's attendance for an agent
  Future<AttendanceRecord?> getTodayAttendance() async {
    try {
      debugPrint('AttendanceApiService: Getting today attendance...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('AttendanceApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/attendance/today',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final checkedIn = data['checked_in'] as bool? ?? false;
        if (!checkedIn || data['attendance'] == null) {
          debugPrint('AttendanceApiService: No attendance record for today');
          return null;
        }
        final attendanceData = data['attendance'] as Map<String, dynamic>;
        debugPrint('AttendanceApiService: Got today attendance: ${attendanceData['id']}');
        return AttendanceRecord.fromJson(attendanceData);
      } else {
        debugPrint('AttendanceApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to get today attendance: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AttendanceApiService: DioException - ${e.message}');
      debugPrint('AttendanceApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('AttendanceApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to get today attendance',
        originalError: e,
      );
    }
  }

  /// Get attendance history for an agent
  Future<List<AttendanceRecord>> getAttendanceHistory({
    int page = 1,
    int perPage = 30,
    String? userId,
  }) async {
    try {
      debugPrint('AttendanceApiService: Getting attendance history...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('AttendanceApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/attendance/history',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (userId != null) 'user_id': userId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('AttendanceApiService: Got ${items.length} attendance records');

        return items.map((item) {
          final attendanceData = item as Map<String, dynamic>;
          // Handle both nested and flat structure
          if (attendanceData.containsKey('attendance')) {
            return AttendanceRecord.fromJson(attendanceData['attendance'] as Map<String, dynamic>);
          }
          return AttendanceRecord.fromJson(attendanceData);
        }).toList();
      } else {
        debugPrint('AttendanceApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to get attendance history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('AttendanceApiService: DioException - ${e.message}');
      debugPrint('AttendanceApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('AttendanceApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to get attendance history',
        originalError: e,
      );
    }
  }
}

/// Provider for AttendanceApiService
final attendanceApiServiceProvider = Provider<AttendanceApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return AttendanceApiService(authService: jwtAuth);
});
