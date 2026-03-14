import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/targets/data/models/target_model.dart';

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
      agentId: json['agent_id'] ?? '',
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      targetVisits: json['target_visits'] ?? 0,
      targetCalls: json['target_calls'] ?? 0,
      targetNewClients: json['target_new_clients'] ?? 0,
      completedVisits: json['completed_visits'] ?? 0,
      completedCalls: json['completed_calls'] ?? 0,
      completedNewClients: json['completed_new_clients'] ?? 0,
      createdAt: json['created'] != null ? DateTime.parse(json['created']) : DateTime.now(),
    );
  }
}

/// Targets API service
class TargetsApiService {
  final PocketBase _pb;

  TargetsApiService({required PocketBase pb}) : _pb = pb;

  Future<AgentTarget?> getCurrentMonthTarget(String agentId) async {
    try {
      final now = DateTime.now();
      final result = await _pb.collection('targets').getList(
        page: 1,
        perPage: 1,
        filter: 'agent_id = "$agentId" && month = ${now.month} && year = ${now.year}',
      );

      if (result.items.isEmpty) return null;
      return AgentTarget.fromJson(result.items.first.data);
    } on ClientException catch (e) {
      debugPrint('TargetsApiService: Error fetching current target - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  Future<List<AgentTarget>> getTargetHistory(String agentId) async {
    try {
      final result = await _pb.collection('targets').getList(
        page: 1,
        perPage: 12,
        filter: 'agent_id = "$agentId"',
        sort: '-year,-month',
      );

      return result.items.map((item) => AgentTarget.fromJson(item.data)).toList();
    } on ClientException catch (e) {
      debugPrint('TargetsApiService: Error fetching target history - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Fetch targets - returns list of Target model for compatibility with app_providers
  Future<List<Target>> fetchTargets() async {
    try {
      final result = await _pb.collection('targets').getList(
        page: 1,
        perPage: 50,
      );

      return result.items.map((item) {
        final data = item.data;
        return Target(
          id: item.id,
          userId: data['agent_id'] ?? '',
          periodStart: DateTime.now(),
          periodEnd: DateTime.now().add(const Duration(days: 7)),
          period: _parsePeriod(data['period']),
          clientVisitsTarget: data['target_visits'] ?? 0,
          clientVisitsCompleted: data['completed_visits'] ?? 0,
          touchpointsTarget: data['target_calls'] ?? 0,
          touchpointsCompleted: data['completed_calls'] ?? 0,
          newClientsTarget: data['target_new_clients'] ?? 0,
          newClientsAdded: data['completed_new_clients'] ?? 0,
          createdAt: data['created'] != null
              ? DateTime.parse(data['created'])
              : DateTime.now(),
        );
      }).toList();
    } on ClientException catch (e) {
      debugPrint('TargetsApiService: Error fetching targets - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
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

final targetsApiServiceProvider = Provider<TargetsApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return TargetsApiService(pb: pb);
});
