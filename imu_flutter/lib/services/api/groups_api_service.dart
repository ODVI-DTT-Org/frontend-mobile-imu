import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/api/pocketbase_client.dart';
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
class GroupsApiService {
  final PocketBase _pb;

  GroupsApiService({required PocketBase pb}) : _pb = pb;

  /// Fetch all groups
  Future<List<ClientGroup>> fetchGroups() async {
    try {
      debugPrint('GroupsApiService: Fetching groups');

      final result = await _pb.collection('groups').getList(
        page: 1,
        perPage: 50,
        expand: 'team_leader',
      );

      debugPrint('GroupsApiService: Fetched ${result.items.length} groups');

      return result.items.map((item) => ClientGroup.fromJson(
        item.data,
        id: item.id,
      )).toList();
    } on ClientException catch (e) {
      debugPrint('GroupsApiService: Error fetching groups - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Fetch single group
  Future<ClientGroup> fetchGroup(String id) async {
    try {
      debugPrint('GroupsApiService: Fetching group $id');
      final result = await _pb.collection('groups').getOne(
        id,
        expand: 'team_leader',
      );

      debugPrint('GroupsApiService: Fetched group ${result.id}');
      return ClientGroup.fromJson(result.data, id: result.id);
    } on ClientException catch (e) {
      debugPrint('GroupsApiService: Error fetching group - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Create group
  Future<ClientGroup> createGroup(ClientGroup group) async {
    try {
      debugPrint('GroupsApiService: Creating group ${group.name}');

      final result = await _pb.collection('groups').create(body: {
        'name': group.name,
        'description': group.description,
        'team_leader': group.teamLeaderId,
      });

      debugPrint('GroupsApiService: Created group ${result.id}');
      return ClientGroup.fromJson(result.data, id: result.id);
    } on ClientException catch (e) {
      debugPrint('GroupsApiService: Error creating group - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Update group
  Future<ClientGroup> updateGroup(ClientGroup group) async {
    try {
      debugPrint('GroupsApiService: Updating group ${group.id}');

      final result = await _pb.collection('groups').update(group.id, body: {
        'name': group.name,
        'description': group.description,
        'team_leader': group.teamLeaderId,
      });

      debugPrint('GroupsApiService: Updated group ${result.id}');
      return ClientGroup.fromJson(result.data, id: result.id);
    } on ClientException catch (e) {
      debugPrint('GroupsApiService: Error updating group - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }

  /// Delete group
  Future<void> deleteGroup(String id) async {
    try {
      debugPrint('GroupsApiService: Deleting group $id');
      await _pb.collection('groups').delete(id);
      debugPrint('GroupsApiService: Deleted group $id');
    } on ClientException catch (e) {
      debugPrint('GroupsApiService: Error deleting group - ${e.toString()}');
      throw ApiException.fromPocketBase(e);
    }
  }
}

/// Provider
final groupsApiServiceProvider = Provider<GroupsApiService>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return GroupsApiService(pb: pb);
});

final groupsProvider = FutureProvider<List<ClientGroup>>((ref) async {
  final groupsApi = ref.watch(groupsApiServiceProvider);
  return await groupsApi.fetchGroups();
});
