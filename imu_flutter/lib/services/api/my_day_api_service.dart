import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

/// Task status for My Day
enum TaskStatus { pending, inProgress, completed, cancelled }

/// My Day Task model
class MyDayTask {
  final String id;
  final String title;
  final String clientId;
  final String clientName;
  final String taskType; // visit, call, follow_up, document
  final String status;
  final int priority;
  final DateTime scheduledTime;
  final DateTime? completedTime;
  final String? notes;
  final DateTime createdAt;

  MyDayTask({
    required this.id,
    required this.title,
    required this.clientId,
    required this.clientName,
    required this.taskType,
    required this.status,
    required this.priority,
    required this.scheduledTime,
    this.completedTime,
    this.notes,
    required this.createdAt,
  });

  factory MyDayTask.fromJson(Map<String, dynamic> json) {
    return MyDayTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      clientId: json['client_id'] ?? '',
      clientName: json['expand']?['client']?['first_name'] ?? json['client_name'] ?? '',
      taskType: json['task_type'] ?? 'visit',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 0,
      scheduledTime: DateTime.parse(json['scheduled_time'] ?? DateTime.now()),
      completedTime: json['completed_time'] != null
          ? DateTime.tryParse(json['completed_time']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created']),
    );
  }
}

/// My Day API service
/// Uses REST API backend for data
class MyDayApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  MyDayApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Add client to today's itinerary.
  /// Writes to local SQLite; PowerSync queues the insert for backend sync.
  Future<bool> addToMyDay(String clientId, {
    DateTime? scheduledDate,
    String? scheduledTime,
    int priority = 5,
    String? notes,
  }) async {
    try {
      if (_authService.accessToken == null) throw ApiException(message: 'Not authenticated');

      final userId = _authService.currentUser?.id;
      if (userId == null) throw ApiException(message: 'No user ID');

      final db = await PowerSyncService.database;
      final localDate = scheduledDate ?? DateTime.now();
      final scheduledDateStr = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
      final id = const Uuid().v4();
      final now = DateTime.now().toIso8601String();

      debugPrint('MyDayApiService: Adding client $clientId to itinerary in SQLite ($scheduledDateStr)');

      await db.execute(
        '''INSERT OR REPLACE INTO itineraries
           (id, user_id, client_id, scheduled_date, scheduled_time,
            status, priority, notes, created_by, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          id,
          userId,
          clientId,
          scheduledDateStr,
          scheduledTime,
          'pending',
          priority.toString(),
          notes,
          userId,
          now,
        ],
      );

      return true;
    } catch (e) {
      debugPrint('Error adding to my day: $e');
      if (e is ApiException) rethrow;
      throw ApiException.fromError(e);
    }
  }

  /// Remove client from today's itinerary.
  /// Deletes from local SQLite; PowerSync queues the delete for backend sync.
  Future<bool> removeFromMyDay(String clientId) async {
    try {
      if (_authService.accessToken == null) throw ApiException(message: 'Not authenticated');

      final userId = _authService.currentUser?.id;
      if (userId == null) throw ApiException(message: 'No user ID');

      final db = await PowerSyncService.database;
      final localDate = DateTime.now();
      final scheduledDateStr = '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      debugPrint('MyDayApiService: Removing client $clientId from itinerary in SQLite');

      await db.execute(
        '''DELETE FROM itineraries
           WHERE user_id=? AND client_id=? AND scheduled_date=?''',
        [userId, clientId, scheduledDateStr],
      );

      return true;
    } catch (e) {
      debugPrint('Error removing from my day: $e');
      if (e is ApiException) rethrow;
      throw ApiException.fromError(e);
    }
  }

  /// Complete task
  Future<MyDayTask?> completeTask(String taskId, {String? notes}) async {
    try {
      debugPrint('MyDayApiService: Completing task $taskId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/tasks/$taskId/complete',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          if (notes != null) 'notes': notes,
        },
      );

      if (response.statusCode == 200) {
        final taskData = response.data['task'] as Map<String, dynamic>?;
        debugPrint('MyDayApiService: Task completed successfully');
        return taskData != null ? MyDayTask.fromJson(taskData) : null;
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to complete task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('MyDayApiService: DioException - ${e.message}');
      debugPrint('MyDayApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('MyDayApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to complete task',
        originalError: e,
      );
    }
  }

  /// Set time in for a client
  Future<bool> setTimeIn(String clientId, {double? latitude, double? longitude}) async {
    try {
      debugPrint('MyDayApiService: Setting time in for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/clients/$clientId/time-in',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('MyDayApiService: Time in recorded successfully');
        return true;
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to set time in: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('MyDayApiService: DioException - ${e.message}');
      debugPrint('MyDayApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('MyDayApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to set time in',
        originalError: e,
      );
    }
  }

  /// Set timeOut for a client
  Future<bool> setTimeOut(String clientId, {double? latitude, double? longitude}) async {
    try {
      debugPrint('MyDayApiService: Setting time out for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/clients/$clientId/time-out',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        },
      );

      if (response.statusCode == 200) {
        debugPrint('MyDayApiService: Time out recorded successfully');
        return true;
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to set time out: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('MyDayApiService: DioException - ${e.message}');
      debugPrint('MyDayApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('MyDayApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to set time out',
        originalError: e,
      );
    }
  }

  /// Upload selfie for time in
  Future<String?> uploadSelfie(String clientId, String photoPath) async {
    try {
      debugPrint('MyDayApiService: Uploading selfie for client $clientId...');
      // TODO: Implement photo upload to S3 or similar
      return null;
    } catch (e) {
      debugPrint('Error uploading selfie: $e');
      return null;
    }
  }

  /// Complete visit - unified endpoint that handles touchpoint creation and itinerary completion
  Future<Map<String, dynamic>> completeVisit({
    required String clientId,
    required int touchpointNumber,
    required String type,
    required String reason,
    String? status,
    String? address,
    String? timeArrival,
    String? timeDeparture,
    String? odometerArrival,
    String? odometerDeparture,
    String? nextVisitDate,
    String? notes,
    double? latitude,
    double? longitude,
    String? scheduledTime,
    String? photoPath,
    String? audioPath,
  }) async {
    try {
      debugPrint('MyDayApiService: Completing visit for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Create multipart form data
      final formData = FormData();
      formData.fields.add(MapEntry('client_id', clientId));
      formData.fields.add(MapEntry('touchpoint_number', touchpointNumber.toString()));
      formData.fields.add(MapEntry('type', type));
      formData.fields.add(MapEntry('reason', reason));
      if (status != null) formData.fields.add(MapEntry('status', status));
      if (address != null) formData.fields.add(MapEntry('address', address));
      if (timeArrival != null) formData.fields.add(MapEntry('time_arrival', timeArrival));
      if (timeDeparture != null) formData.fields.add(MapEntry('time_departure', timeDeparture));
      if (odometerArrival != null) formData.fields.add(MapEntry('odometer_arrival', odometerArrival));
      if (odometerDeparture != null) formData.fields.add(MapEntry('odometer_departure', odometerDeparture));
      if (nextVisitDate != null) formData.fields.add(MapEntry('next_visit_date', nextVisitDate));
      if (notes != null) formData.fields.add(MapEntry('notes', notes));
      if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
      if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));
      if (scheduledTime != null) formData.fields.add(MapEntry('scheduled_time', scheduledTime));

      // Attach files if provided
      if (photoPath != null) {
        final photoFile = await MultipartFile.fromFile(photoPath, filename: photoPath.split('/').last);
        formData.files.add(MapEntry('photo', photoFile));
      }
      if (audioPath != null) {
        final audioFile = await MultipartFile.fromFile(audioPath, filename: audioPath.split('/').last);
        formData.files.add(MapEntry('audio', audioFile));
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/complete-visit',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            // Don't set Content-Type - Dio sets it automatically with boundary
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('MyDayApiService: Visit completed successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to complete visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('MyDayApiService: DioException - ${e.message}');
      debugPrint('MyDayApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('MyDayApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to complete visit',
        originalError: e,
      );
    }
  }
}

/// Provider for MyDayApiService
final myDayApiServiceProvider = Provider<MyDayApiService>((ref) {
  return MyDayApiService();
});
