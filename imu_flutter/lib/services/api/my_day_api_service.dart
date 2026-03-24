import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
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
/// Uses PowerSync/Supabase backend for data
class MyDayApiService {
  /// Fetch today's tasks from backend
  /// TODO: Phase 1 - Implement PowerSync/Supabase fetch
  Future<List<MyDayTask>> fetchTodayTasks() async {
    try {
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      debugPrint('MyDayApiService: fetchTodayTasks (PowerSync integration pending)');
      return [];
    } catch (e) {
      debugPrint('Error fetching today tasks: $e');
      return [];
    }
  }

  /// Complete task
  /// TODO: Phase 1 - Implement PowerSync/Supabase update
  Future<MyDayTask?> completeTask(String taskId, {String? notes}) async {
    try {
      // TODO: Phase 1 - Implement PowerSync/Supabase update
      debugPrint('MyDayApiService: completeTask (PowerSync integration pending)');
      return null;
    } catch (e) {
      debugPrint('Error completing task: $e');
      throw ApiException.fromError(e);
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
  /// TODO: Phase 1 - Implement PowerSync/Supabase fetch
  Future<List<MyDayClient>> fetchMyDayClients(DateTime date) async {
    try {
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      debugPrint('MyDayApiService: fetchMyDayClients (PowerSync integration pending)');
      return [];
    } catch (e) {
      debugPrint('Error fetching my day clients: $e');
      return [];
    }
  }

  /// Set time in for a client
  Future<bool> setTimeIn(String clientId, bool isTimeIn) async {
    try {
      debugPrint('MyDayApiService: setTimeIn(clientId, isTimeIn)');
      return true;
    } catch (e) {
      debugPrint('Error setting time in: $e');
      throw ApiException.fromError(e);
    }
  }

  /// Set timeOut for a client
  Future<bool> setTimeOut(String clientId, bool isTimeOut) async {
    try {
      debugPrint('MyDayApiService: setTimeOut(clientId, isTimeOut)');
      return true;
    } catch (e) {
      debugPrint('Error setting time out: $e');
      throw ApiException.fromError(e);
    }
  }

  /// Upload selfie for time in
  Future<String?> uploadSelfie(String clientId, String photoPath) async {
    try {
      debugPrint('MyDayApiService: uploadSelfie (PowerSync integration pending)');
      return null;
    } catch (e) {
      debugPrint('Error uploading selfie: $e');
      return null;
    }
  }

  /// Submit visit form
  Future<Map<String, dynamic>?> submitVisitForm(String clientId, Map<String, dynamic> formData) async {
    try {
      debugPrint('MyDayApiService: submitVisitForm($clientId, formData)');
      return {};
    } catch (e) {
      debugPrint('Error submitting visit form: $e');
      return null;
    }
  }
}

/// Provider for MyDayApiService
final myDayApiServiceProvider = Provider<MyDayApiService>((ref) {
  return MyDayApiService();
});
