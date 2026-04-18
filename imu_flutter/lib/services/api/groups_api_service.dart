import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/groups/data/models/group_model.dart';

export 'package:imu_flutter/features/groups/data/models/group_model.dart' show ClientGroup;

/// Groups API service
class GroupsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  GroupsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

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

// groupsProvider has been removed — use groupRepositoryProvider.getGroups(userId)
// or the stream providers in app_providers.dart instead.
