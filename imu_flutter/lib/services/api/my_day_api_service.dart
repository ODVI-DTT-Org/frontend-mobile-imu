import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/api/itinerary_api_service.dart';
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
      scheduledTime: DateTime.parse(json['scheduled_time'] ?? DateTime.now().toIso8601String()),
      completedTime: json['completed_time'] != null ? DateTime.parse(json['completed_time']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created']),
    );
  }
}

/// My Day API service with mock data fallback
class MyDayApiService {
  final PocketBase _pb;
  bool _useMockData = false;

  MyDayApiService({required PocketBase pb}) : _pb = pb;

  /// Generate mock tasks for demo purposes
  List<MyDayTask> _getMockTasks() {
    final today = DateTime.now();
    return [
      MyDayTask(
        id: 'mock-1',
        title: '1st Touchpoint - Initial Visit',
        clientId: 'client-1',
        clientName: 'Juan Dela Cruz',
        taskType: 'visit',
        status: 'pending',
        priority: 1,
        scheduledTime: DateTime(today.year, today.month, today.day, 9, 0),
        createdAt: today,
      ),
      MyDayTask(
        id: 'mock-2',
        title: '2nd Touchpoint - Follow-up Call',
        clientId: 'client-2',
        clientName: 'Maria Santos',
        taskType: 'call',
        status: 'pending',
        priority: 2,
        scheduledTime: DateTime(today.year, today.month, today.day, 10, 30),
        createdAt: today,
      ),
      MyDayTask(
        id: 'mock-3',
        title: '4th Touchpoint - Site Visit',
        clientId: 'client-3',
        clientName: 'Pedro Reyes',
        taskType: 'visit',
        status: 'in_progress',
        priority: 0,
        scheduledTime: DateTime(today.year, today.month, today.day, 8, 0),
        createdAt: today,
      ),
      MyDayTask(
        id: 'mock-4',
        title: '3rd Touchpoint - Call',
        clientId: 'client-4',
        clientName: 'Ana Garcia',
        taskType: 'call',
        status: 'pending',
        priority: 3,
        scheduledTime: DateTime(today.year, today.month, today.day, 14, 0),
        createdAt: today,
      ),
      MyDayTask(
        id: 'mock-5',
        title: '5th Touchpoint - Follow-up',
        clientId: 'client-5',
        clientName: 'Jose Mendoza',
        taskType: 'call',
        status: 'completed',
        priority: 4,
        scheduledTime: DateTime(today.year, today.month, today.day, 7, 0),
        completedTime: DateTime(today.year, today.month, today.day, 7, 45),
        createdAt: today,
      ),
      MyDayTask(
        id: 'mock-6',
        title: '7th Touchpoint - Final Visit',
        clientId: 'client-6',
        clientName: 'Elena Torres',
        taskType: 'visit',
        status: 'pending',
        priority: 5,
        scheduledTime: DateTime(today.year, today.month, today.day, 15, 30),
        createdAt: today,
      ),
    ];
  }

  /// Fetch today's tasks
  Future<List<MyDayTask>> fetchTodayTasks() async {
    // If already using mock data, return mock
    if (_useMockData) {
      return _getMockTasks();
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _pb.collection('tasks').getList(
        page: 1,
        perPage: 50,
        filter: 'scheduled_time >= "${startOfDay.toIso8601String()}" && scheduled_time < "${endOfDay.toIso8601String()}"',
        sort: 'priority,scheduled_time',
        expand: 'client',
      );

      return result.items.map((item) => MyDayTask.fromJson({
        ...item.data,
        'id': item.id,
        'created': item.created,
      })).toList();
    } on ClientException catch (e) {
      // If collection doesn't exist (404), fall back to mock data
      if (e.statusCode == 404) {
        debugPrint('Tasks collection not found, using mock data');
        _useMockData = true;
        return _getMockTasks();
      }
      throw ApiException.fromPocketBase(e);
    } catch (e) {
      debugPrint('Error fetching tasks: $e, using mock data');
      _useMockData = true;
      return _getMockTasks();
    }
  }

  /// Mark task as in progress
  Future<MyDayTask> startTask(String taskId) async {
    if (_useMockData) {
      // Update mock task
      final tasks = _getMockTasks();
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex >= 0) {
        return MyDayTask(
          id: tasks[taskIndex].id,
          title: tasks[taskIndex].title,
          clientId: tasks[taskIndex].clientId,
          clientName: tasks[taskIndex].clientName,
          taskType: tasks[taskIndex].taskType,
          status: 'in_progress',
          priority: tasks[taskIndex].priority,
          scheduledTime: tasks[taskIndex].scheduledTime,
          createdAt: tasks[taskIndex].createdAt,
        );
      }
      throw Exception('Task not found');
    }

    try {
      final result = await _pb.collection('tasks').update(taskId, body: {
        'status': 'in_progress',
      });

      return MyDayTask.fromJson({
        ...result.data,
        'id': result.id,
        'created': result.created,
      });
    } on ClientException catch (e) {
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Complete task
  Future<MyDayTask> completeTask(String taskId, {String? notes}) async {
    if (_useMockData) {
      // Update mock task
      final tasks = _getMockTasks();
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex >= 0) {
        return MyDayTask(
          id: tasks[taskIndex].id,
          title: tasks[taskIndex].title,
          clientId: tasks[taskIndex].clientId,
          clientName: tasks[taskIndex].clientName,
          taskType: tasks[taskIndex].taskType,
          status: 'completed',
          priority: tasks[taskIndex].priority,
          scheduledTime: tasks[taskIndex].scheduledTime,
          completedTime: DateTime.now(),
          notes: notes,
          createdAt: tasks[taskIndex].createdAt,
        );
      }
      throw Exception('Task not found');
    }

    try {
      final result = await _pb.collection('tasks').update(taskId, body: {
        'status': 'completed',
        'completed_time': DateTime.now().toIso8601String(),
        if (notes != null) 'notes': notes,
      });

      return MyDayTask.fromJson({
        ...result.data,
        'id': result.id,
        'created': result.created,
      });
    } on ClientException catch (e) {
      throw ApiException.fromPocketBase(e);
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
      return {'total': 0, 'completed': 0, 'in_progress': 0, 'pending': 0};
    }
  }

  /// Fetch clients for My Day list
  Future<List<MyDayClient>> fetchMyDayClients(DateTime date) async {
    if (_useMockData) {
      return _getMockMyDayClients();
    }

    try {
      // TODO: Replace with actual PocketBase query
      // For now, return mock data
      return _getMockMyDayClients();
    } catch (e) {
      debugPrint('Error fetching My Day clients: $e');
      return _getMockMyDayClients();
    }
  }

  /// Generate mock My Day clients for demo
  List<MyDayClient> _getMockMyDayClients() {
    return [
      MyDayClient(
        id: 'client-1',
        fullName: 'Amagar, Mina C.',
        agencyName: 'CSC - MAIN OFFICE',
        location: 'CSC - MAIN OFFICE',
        touchpointNumber: 4,
        touchpointType: 'visit',
        isTimeIn: false,
      ),
      MyDayClient(
        id: 'client-2',
        fullName: 'Reyes, Kristine D.',
        agencyName: 'DOH - CVMC R2 TUG',
        location: 'DOH - CVMC R2 TUG',
        touchpointNumber: 2,
        touchpointType: 'call',
        isTimeIn: false,
      ),
      MyDayClient(
        id: 'client-3',
        fullName: 'DOH - CVMC R2 TUG',
        agencyName: 'DOH - CVMC R2 TUG',
        location: 'DOH - CVMC R2 TUG',
        touchpointNumber: 0,
        touchpointType: 'visit',
        isTimeIn: false,
      ),
      MyDayClient(
        id: 'client-4',
        fullName: 'San Pedro, Sharlene',
        agencyName: 'DOH - ZCMC',
        location: 'DOH - ZCMC',
        touchpointNumber: 7,
        touchpointType: 'visit',
        isTimeIn: false,
      ),
      MyDayClient(
        id: 'client-5',
        fullName: 'Aguas, Nash C.',
        agencyName: 'DOH - ZCMC',
        location: 'DOH - ZCMC',
        touchpointNumber: 4,
        touchpointType: 'visit',
        isTimeIn: false,
      ),
    ];
  }

  /// Set time-in status for a client
  Future<void> setTimeIn(String clientId, bool isTimeIn) async {
    if (_useMockData) {
      // Mock: just return success
      await Future.delayed(const Duration(milliseconds: 300));
      return;
    }

    try {
      // TODO: Replace with actual PocketBase update
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error setting time-in: $e');
      rethrow;
    }
  }

  /// Submit visit form data
  Future<void> submitVisitForm(String clientId, Map<String, dynamic> formData) async {
    if (_useMockData) {
      // Mock: just return success
      await Future.delayed(const Duration(milliseconds: 500));
      return;
    }

    try {
      // TODO: Replace with actual PocketBase create
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint('Error submitting visit form: $e');
      rethrow;
    }
  }

  /// Record selfie for a client visit
  Future<String?> uploadSelfie(String clientId, String photoPath) async {
    if (_useMockData) {
      // Mock: return a fake URL
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://mock-storage.selfie/$clientId.jpg';
    }

    try {
      // TODO: Replace with actual file upload
      await Future.delayed(const Duration(milliseconds: 500));
      return 'https://mock-storage.selfie/$clientId.jpg';
    } catch (e) {
      debugPrint('Error uploading selfie: $e');
      return null;
    }
  }
}

/// Provider for MyDayApiService
final myDayApiServiceProvider = Provider<MyDayApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return MyDayApiService(pb: pb);
});

/// Provider for today's tasks
final todayTasksProvider = FutureProvider<List<MyDayTask>>((ref) async {
  final myDayApi = ref.watch(myDayApiServiceProvider);
  return await myDayApi.fetchTodayTasks();
});

/// Provider for task summary
final taskSummaryProvider = FutureProvider<Map<String, int>>((ref) async {
  final myDayApi = ref.watch(myDayApiServiceProvider);
  return await myDayApi.getTaskSummary();
});
