import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/targets/data/models/target_model.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';

/// Target model for agent targets
class AgentTarget {
  final String id;
  final String agentId;
  final int month;
  final int year;
  final int targetVisits;
  final int targetCalls;
  final int targetNewClients;
  final int completedVisits;
  final int completedCalls;
  final int completedNewClients;
  final DateTime createdAt;

  AgentTarget({
    required this.id,
    required this.agentId,
    required this.month,
    required this.year,
    this.targetVisits = 0,
    this.targetCalls = 0,
    this.targetNewClients = 0,
    this.completedVisits = 0,
    this.completedCalls = 0,
    this.completedNewClients = 0,
    required this.createdAt,
  });

  double get visitsProgress => targetVisits > 0 ? completedVisits / targetVisits : 0;
  double get callsProgress => targetCalls > 0 ? completedCalls / targetCalls : 0;
  double get newClientsProgress => targetNewClients > 0 ? completedNewClients / targetNewClients : 0;
  double get overallProgress => (visitsProgress + callsProgress + newClientsProgress) / 3;

  factory AgentTarget.fromJson(Map<String, dynamic> json) {
    return AgentTarget(
      id: json['id'] ?? '',
      agentId: json['agent_id'] ?? json['caravan_id'] ?? '',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      targetVisits: json['target_visits'] ?? 0,
      targetCalls: json['target_calls'] ?? 0,
      targetNewClients: json['target_new_clients'] ?? 0,
      completedVisits: json['completed_visits'] ?? 0,
      completedCalls: json['completed_calls'] ?? 0,
      completedNewClients: json['completed_new_clients'] ?? 0,
      createdAt: json['created'] != null || json['created_at'] != null
          ? DateTime.parse(json['created'] ?? json['created_at'])
          : DateTime.now(),
    );
  }
}

/// Targets API service
class TargetsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  TargetsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  Future<AgentTarget?> getCurrentMonthTarget(String agentId) async {
    try {
      final now = DateTime.now();
      debugPrint('TargetsApiService: Getting current month target for agent $agentId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TargetsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/targets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'agent_id': agentId,
          'month': now.month,
          'year': now.year,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          final targetData = items.first as Map<String, dynamic>;
          debugPrint('TargetsApiService: Got current month target');
          return AgentTarget.fromJson(targetData);
        }
        return null;
      } else {
        debugPrint('TargetsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to get current target: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TargetsApiService: DioException - ${e.message}');
      debugPrint('TargetsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TargetsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to get current target',
        originalError: e,
      );
    }
  }

  Future<List<AgentTarget>> getTargetHistory(String agentId) async {
    try {
      debugPrint('TargetsApiService: Getting target history for agent $agentId...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TargetsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/targets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'agent_id': agentId,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('TargetsApiService: Got ${items.length} targets from API');

        return items.map((item) {
          final targetData = item as Map<String, dynamic>;
          return AgentTarget.fromJson(targetData);
        }).toList();
      } else {
        debugPrint('TargetsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to get target history: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TargetsApiService: DioException - ${e.message}');
      debugPrint('TargetsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TargetsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to get target history',
        originalError: e,
      );
    }
  }

  /// Fetch targets - returns list of Target model for compatibility with app_providers
  Future<List<Target>> fetchTargets({
    int? month,
    int? year,
    String? period,
  }) async {
    try {
      debugPrint('TargetsApiService: Fetching targets...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TargetsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/targets',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          if (month != null) 'month': month,
          if (year != null) 'year': year,
          if (period != null) 'period': period,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('TargetsApiService: Got ${items.length} targets from API');

        return items.map((item) {
          final targetData = item as Map<String, dynamic>;
          return Target.fromJson(targetData);
        }).toList();
      } else {
        debugPrint('TargetsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch targets: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TargetsApiService: DioException - ${e.message}');
      debugPrint('TargetsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TargetsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch targets',
        originalError: e,
      );
    }
  }

  /// Fetch single target by ID
  Future<Target?> fetchTarget(String id) async {
    try {
      debugPrint('TargetsApiService: Fetching target $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TargetsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/targets/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final targetData = response.data as Map<String, dynamic>;
        debugPrint('TargetsApiService: Got target: ${targetData['id']}');
        return Target.fromJson(targetData);
      } else {
        debugPrint('TargetsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch target: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TargetsApiService: DioException - ${e.message}');
      debugPrint('TargetsApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Target not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TargetsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch target',
        originalError: e,
      );
    }
  }

  /// Fetch targets by period
  Future<List<Target>> fetchTargetsByPeriod({
    required String period, // 'daily', 'weekly', 'monthly'
    int? month,
    int? year,
  }) async {
    return fetchTargets(
      month: month,
      year: year,
      period: period,
    );
  }

  TargetPeriod _parsePeriod(String? value) {
    if (value == null) return TargetPeriod.weekly;
    switch (value.toLowerCase()) {
      case 'daily':
        return TargetPeriod.daily;
      case 'monthly':
        return TargetPeriod.monthly;
      default:
        return TargetPeriod.weekly;
    }
  }
}

/// Provider for TargetsApiService
final targetsApiServiceProvider = Provider<TargetsApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return TargetsApiService(authService: jwtAuth);
});
