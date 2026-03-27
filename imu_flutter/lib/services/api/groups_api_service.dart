import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';

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
      teamLeaderId: json['team_leader_id'] ?? json['team_leader'],
      teamLeaderName: json['expand']?['team_leader']?['name'] ?? json['team_leader_name'],
      memberCount: json['member_count'] ?? 0,
      createdAt: DateTime.parse(json['created'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated'] != null || json['updated_at'] != null
          ? DateTime.parse(json['updated'] ?? json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
      if (teamLeaderName != null) 'team_leader_name': teamLeaderName,
      'member_count': memberCount,
      'created': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated': updatedAt!.toIso8601String(),
    };
  }

  ClientGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? teamLeaderId,
    String? teamLeaderName,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClientGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      teamLeaderName: teamLeaderName ?? this.teamLeaderName,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Groups API service
class GroupsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  GroupsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch all groups
  Future<List<ClientGroup>> fetchGroups({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      debugPrint('GroupsApiService: Fetching groups from REST API...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('GroupsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/groups',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('GroupsApiService: Got ${items.length} groups from API');

        return items.map((item) {
          final groupData = item as Map<String, dynamic>;
          return ClientGroup.fromJson(groupData);
        }).toList();
      } else {
        debugPrint('GroupsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch groups: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('GroupsApiService: DioException - ${e.message}');
      debugPrint('GroupsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('GroupsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch groups',
        originalError: e,
      );
    }
  }

  /// Fetch single group
  Future<ClientGroup?> fetchGroup(String id) async {
    try {
      debugPrint('GroupsApiService: Fetching group $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('GroupsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/groups/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final groupData = response.data as Map<String, dynamic>;
        debugPrint('GroupsApiService: Got group: ${groupData['name']}');
        return ClientGroup.fromJson(groupData);
      } else {
        debugPrint('GroupsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch group: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('GroupsApiService: DioException - ${e.message}');
      debugPrint('GroupsApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Group not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('GroupsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch group',
        originalError: e,
      );
    }
  }

  /// Create group
  Future<ClientGroup?> createGroup({
    required String name,
    String? description,
    String? teamLeaderId,
  }) async {
    try {
      debugPrint('GroupsApiService: Creating group $name...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('GroupsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        'name': name,
        if (description != null) 'description': description,
        if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
      };

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/groups',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201) {
        final groupData = response.data as Map<String, dynamic>;
        debugPrint('GroupsApiService: Group created successfully: ${groupData['id']}');
        return ClientGroup.fromJson(groupData);
      } else {
        debugPrint('GroupsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create group: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('GroupsApiService: DioException - ${e.message}');
      debugPrint('GroupsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('GroupsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create group',
        originalError: e,
      );
    }
  }

  /// Update group
  Future<ClientGroup?> updateGroup({
    required String id,
    required String name,
    String? description,
    String? teamLeaderId,
  }) async {
    try {
      debugPrint('GroupsApiService: Updating group $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('GroupsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final requestData = {
        'name': name,
        if (description != null) 'description': description,
        if (teamLeaderId != null) 'team_leader_id': teamLeaderId,
      };

      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/groups/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final groupData = response.data as Map<String, dynamic>;
        debugPrint('GroupsApiService: Group updated successfully: ${groupData['id']}');
        return ClientGroup.fromJson(groupData);
      } else {
        debugPrint('GroupsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update group: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('GroupsApiService: DioException - ${e.message}');
      debugPrint('GroupsApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Group not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('GroupsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update group',
        originalError: e,
      );
    }
  }

  /// Delete group
  Future<void> deleteGroup(String id) async {
    try {
      debugPrint('GroupsApiService: Deleting group $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('GroupsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/groups/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('GroupsApiService: Group deleted successfully');
      } else {
        debugPrint('GroupsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete group: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('GroupsApiService: DioException - ${e.message}');
      debugPrint('GroupsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('GroupsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete group',
        originalError: e,
      );
    }
  }
}

/// Provider for GroupsApiService
final groupsApiServiceProvider = Provider<GroupsApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return GroupsApiService(authService: jwtAuth);
});

/// Provider for groups list
final groupsProvider = FutureProvider<List<ClientGroup>>((ref) async {
  final groupsApi = ref.watch(groupsApiServiceProvider);
  return await groupsApi.fetchGroups();
});
