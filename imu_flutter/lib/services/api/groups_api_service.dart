import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/api_exception.dart';

/// Group model for client groups
class ClientGroup {
  final String id;
  final String name;
  final String? description;
  final String? teamLeaderId;
  final String? teamLeaderName;
  final int memberCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClientGroup({
    required this.id,
    required this.name,
    this.description,
    this.teamLeaderId,
    this.teamLeaderName,
    this.memberCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClientGroup.fromJson(Map<String, dynamic> json, {String? id}) {
    return ClientGroup(
      id: id ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      teamLeaderId: json['team_leader'],
      teamLeaderName: json['expand']?['team_leader']?['name'],
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(json['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }
}

/// Groups API service
/// TODO: Phase 1 - Will be updated to work with PowerSync/Supabase backend
class GroupsApiService {
  /// Fetch all groups
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<List<ClientGroup>> fetchGroups() async {
    try {
      debugPrint('GroupsApiService: fetchGroups called (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return [];
    } catch (e) {
      debugPrint('GroupsApiService: Error fetching groups - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Fetch single group
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<ClientGroup?> fetchGroup(String id) async {
    try {
      debugPrint('GroupsApiService: fetchGroup called for $id (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase fetch
      return null;
    } catch (e) {
      debugPrint('GroupsApiService: Error fetching group - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Create group
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<ClientGroup?> createGroup(ClientGroup group) async {
    try {
      debugPrint('GroupsApiService: createGroup called for ${group.name} (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase create
      return null;
    } catch (e) {
      debugPrint('GroupsApiService: Error creating group - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Update group
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<ClientGroup?> updateGroup(ClientGroup group) async {
    try {
      debugPrint('GroupsApiService: updateGroup called for ${group.id} (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase update
      return null;
    } catch (e) {
      debugPrint('GroupsApiService: Error updating group - $e');
      throw ApiException.fromError(e);
    }
  }

  /// Delete group
  /// TODO: Phase 1 - Implement with PowerSync/Supabase
  Future<void> deleteGroup(String id) async {
    try {
      debugPrint('GroupsApiService: deleteGroup called for $id (PowerSync integration pending)');
      // TODO: Phase 1 - Implement PowerSync/Supabase delete
    } catch (e) {
      debugPrint('GroupsApiService: Error deleting group - $e');
      throw ApiException.fromError(e);
    }
  }
}

/// Provider for GroupsApiService
final groupsApiServiceProvider = Provider<GroupsApiService>((ref) {
  return GroupsApiService();
});

/// Provider for groups list
final groupsProvider = FutureProvider<List<ClientGroup>>((ref) async {
  final groupsApi = ref.watch(groupsApiServiceProvider);
  return await groupsApi.fetchGroups();
});
