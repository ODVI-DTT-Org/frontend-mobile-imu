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
