import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class TargetsApiService {
  Future<AgentTarget?> getCurrentMonthTarget(String agentId) async {
    try {
      debugPrint('TargetsApiService: getCurrentMonthTarget for agent $agentId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return null;
    } catch (e) {
      debugPrint('TargetsApiService: Error fetching current target - $e');
      throw ApiException.fromError(e);
    }
  }

  Future<List<AgentTarget>> getTargetHistory(String agentId) async {
    try {
      debugPrint('TargetsApiService: getTargetHistory for agent $agentId (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
    } catch (e) {
      debugPrint('TargetsApiService: Error fetching target history - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Fetch targets - returns list of Target model for compatibility with app_providers
  Future<List<Target>> fetchTargets() async {
    try {
      debugPrint('TargetsApiService: fetchTargets (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
    } catch (e) {
      debugPrint('TargetsApiService: Error fetching targets - $e');
      throw ApiException.fromError(e);
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

/// Provider for TargetsApiService
final targetsApiServiceProvider = Provider<TargetsApiService>((ref) {
  return TargetsApiService();
});
