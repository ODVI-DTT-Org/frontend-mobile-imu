import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';

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

  /// Add client to today's itinerary or custom date
  Future<bool> addToMyDay(String clientId, {
    DateTime? scheduledDate,
    String? scheduledTime,
    int priority = 5,
    String? notes,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final scheduledDateStr = scheduledDate != null
          ? '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}'
          : null;

      debugPrint('MyDayApiService: Adding client $clientId to my day');
      debugPrint('MyDayApiService: scheduledDate (local): $scheduledDate');
      debugPrint('MyDayApiService: scheduledDate (string): $scheduledDateStr');
      debugPrint('MyDayApiService: scheduledDate (toIso8601String): ${scheduledDate?.toIso8601String()}');

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/add-client',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'client_id': clientId,
          if (scheduledDateStr != null) 'scheduled_date': scheduledDateStr,
          if (scheduledTime != null) 'scheduled_time': scheduledTime,
          'priority': priority,
          if (notes != null) 'notes': notes,
        },
      );

      return response.data['message'] == 'Client added to My Day';
    } on DioException catch (e) {
      debugPrint('Error adding to my day: ${e.message}');
      debugPrint('Error adding to my day: Response - ${e.response?.data}');

      // Extract error message from backend response
      String errorMessage = 'Network error: ${e.message}';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    } catch (e) {
      debugPrint('Error adding to my day: $e');
      throw ApiException.fromError(e);
    }
  }

  /// Remove client from today's itinerary
  Future<bool> removeFromMyDay(String clientId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/my-day/remove-client/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data['message'] == 'Client removed from My Day';
    } on DioException catch (e) {
      debugPrint('Error removing from my day: ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('Error removing from my day: $e');
      throw ApiException.fromError(e);
    }
  }

  /// Check if client is in today's itinerary
  Future<bool> isInMyDay(String clientId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return false;
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/my-day/status/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data['in_my_day'] ?? false;
    } catch (e) {
      debugPrint('Error checking my day status: $e');
      return false;
    }
  }

  /// Fetch today's tasks from backend
  Future<List<MyDayTask>> fetchTodayTasks() async {
    try {
      debugPrint('MyDayApiService: Fetching today tasks from REST API...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/my-day/tasks',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tasksData = data['tasks'] as List<dynamic>? ?? [];
        debugPrint('MyDayApiService: Got ${tasksData.length} tasks from API');

        return tasksData.map((item) {
          final taskData = item as Map<String, dynamic>;
          return MyDayTask.fromJson(taskData);
        }).toList();
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch tasks: ${response.statusCode}');
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
        message: 'Failed to fetch today tasks',
        originalError: e,
      );
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

  /// Get task progress summary
  Future<Map<String, int>> getTaskSummary() async {
    try {
      final tasks = await fetchTodayTasks();

      return {
        'total': tasks.length,
        'completed': tasks.where((t) => t.status == 'completed').length,
        'in_progress': tasks.where((t) => t.status == 'in_progress').length,
        'pending': tasks.where((t) => t.status == 'pending').length,
      };
    } catch (e) {
      debugPrint('Error fetching my day task: $e');
      return {'total': 0, 'completed': 0, 'in_progress': 0, 'pending': 0};
    }
  }

  /// Fetch clients for My Day list
  Future<List<MyDayClient>> fetchMyDayClients(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      debugPrint('MyDayApiService: Fetching my day clients for $dateStr...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/my-day/tasks',
        queryParameters: {'date': dateStr},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final tasksData = data['tasks'] as List<dynamic>? ?? [];
        debugPrint('MyDayApiService: Got ${tasksData.length} tasks from API');

        // Filter out completed clients - they should not appear in My Day after visit is recorded
        const completedStatus = 'completed';
        final activeTasks = tasksData.where((item) {
          final taskData = item as Map<String, dynamic>;
          final status = taskData['status'] as String?;
          if (status == null) {
            debugPrint('Warning: Task ${taskData['id']} has null status, including in list');
            return true; // Include tasks with null status for visibility
          }
          return status != completedStatus;
        }).toList();

        debugPrint('MyDayApiService: Filtered to ${activeTasks.length} active tasks (excluding completed)');

        return activeTasks.map((item) {
          final taskData = item as Map<String, dynamic>;
          final clientData = taskData['client'] as Map<String, dynamic>? ?? {};

          // Get clientId from task data (preferred) or client data (fallback)
          final clientId = taskData['client_id'] as String? ??
                          (clientData['id'] as String?);

          if (clientId == null || clientId.isEmpty) {
            debugPrint('Warning: Task ${taskData['id']} has missing or empty clientId, skipping');
            return null; // Skip this task
          }

          return MyDayClient(
            id: taskData['id'] ?? '',
            clientId: clientId,
            fullName: '${clientData['first_name'] ?? ''} ${clientData['last_name'] ?? ''}'.trim(),
            agencyName: clientData['agency']?['name'],
            location: clientData['addresses'] != null && (clientData['addresses'] as List).isNotEmpty
                ? (clientData['addresses'] as List).first['street']
                : null,
            touchpointNumber: taskData['touchpoint_number'] ?? 0,
            touchpointType: taskData['touchpoint_type'] ?? 'visit',
            isTimeIn: taskData['time_in'] != null,
            priority: taskData['priority'] ?? 'normal',
            notes: taskData['notes'],
          );
        }).where((client) => client != null).cast<MyDayClient>().toList();
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch my day clients: ${response.statusCode}');
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
        message: 'Failed to fetch my day clients',
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

  /// Submit visit form
  Future<Map<String, dynamic>?> submitVisitForm(String clientId, Map<String, dynamic> formData) async {
    try {
      debugPrint('MyDayApiService: Submitting visit form for client $clientId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('MyDayApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/visits',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('MyDayApiService: Visit form submitted successfully');
        return response.data as Map<String, dynamic>;
      } else {
        debugPrint('MyDayApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to submit visit form: ${response.statusCode}');
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
        message: 'Failed to submit visit form',
        originalError: e,
      );
    }
  }

  /// Complete visit - unified endpoint that handles touchpoint creation and itinerary completion
  /// This replaces the separate submitVisitForm + itinerary update calls
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
            'Content-Type': 'multipart/form-data',
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
