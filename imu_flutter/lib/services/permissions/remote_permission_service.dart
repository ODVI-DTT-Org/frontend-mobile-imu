import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

/// Permission model from backend RBAC system
class RemotePermission {
  final String resource;
  final String action;
  final String? constraint;
  final String roleSlug;

  RemotePermission({
    required this.resource,
    required this.action,
    this.constraint,
    required this.roleSlug,
  });

  factory RemotePermission.fromJson(Map<String, dynamic> json) {
    return RemotePermission(
      resource: json['resource'] as String,
      action: json['action'] as String,
      constraint: json['constraint_name'] as String?,
      roleSlug: json['role_slug'] as String,
    );
  }

  /// Create permission key for caching
  String get permissionKey => '$resource.$action${constraint != null ? ":$constraint" : ""}';

  @override
  String toString() => 'RemotePermission($resource.$action${constraint != null ? ":$constraint" : ""})';
}

/// Service to fetch and cache user permissions from backend
class RemotePermissionService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _permissionsKey = 'user_permissions';
  static const _permissionsTimestampKey = 'user_permissions_timestamp';
  static const _cacheExpiry = Duration(hours: 1); // Cache permissions for 1 hour

  RemotePermissionService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.postgresApiUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _storage = storage ?? const FlutterSecureStorage();

  /// Fetch user permissions from backend
  Future<List<RemotePermission>> fetchPermissions(String accessToken) async {
    try {
      logDebug('Fetching permissions from backend...');

      final response = await _dio.get(
        '/auth/permissions',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> permissionsJson = response.data['permissions'] ?? [];
        final permissions = permissionsJson
            .map((json) => RemotePermission.fromJson(json as Map<String, dynamic>))
            .toList();

        logDebug('Fetched ${permissions.length} permissions from backend');
        await _cachePermissions(permissions);
        return permissions;
      } else {
        logError('Failed to fetch permissions: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logError('Error fetching permissions from backend', e);
      // Return cached permissions if available
      return await getCachedPermissions();
    }
  }

  /// Get cached permissions from secure storage
  Future<List<RemotePermission>> getCachedPermissions() async {
    try {
      final permissionsJson = await _storage.read(key: _permissionsKey);
      final timestampJson = await _storage.read(key: _permissionsTimestampKey);

      if (permissionsJson == null || timestampJson == null) {
        return [];
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampJson);
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        logDebug('Permissions cache expired');
        await clearCache();
        return [];
      }

      final List<dynamic> permissionsList = jsonDecode(permissionsJson) as List<dynamic>;
      return permissionsList
          .map((json) => RemotePermission.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('Error reading cached permissions', e);
      return [];
    }
  }

  /// Cache permissions in secure storage
  Future<void> _cachePermissions(List<RemotePermission> permissions) async {
    try {
      final permissionsJson = jsonEncode(
        permissions.map((p) => {
          'resource': p.resource,
          'action': p.action,
          'constraint_name': p.constraint,
          'role_slug': p.roleSlug,
        }).toList(),
      );

      final timestamp = DateTime.now().toIso8601String();

      await _storage.write(key: _permissionsKey, value: permissionsJson);
      await _storage.write(key: _permissionsTimestampKey, value: timestamp);

      logDebug('Cached ${permissions.length} permissions');
    } catch (e) {
      logError('Error caching permissions', e);
    }
  }

  /// Clear cached permissions
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _permissionsKey);
      await _storage.delete(key: _permissionsTimestampKey);
      logDebug('Cleared permissions cache');
    } catch (e) {
      logError('Error clearing permissions cache', e);
    }
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission({
    required String resource,
    required String action,
    String? constraint,
  }) async {
    final permissions = await getCachedPermissions();

    // Check for exact match with constraint
    if (constraint != null) {
      return permissions.any((p) =>
          p.resource == resource &&
          p.action == action &&
          p.constraint == constraint);
    }

    // Check for permission without constraint or with any constraint
    return permissions.any((p) =>
        p.resource == resource &&
        p.action == action);
  }

  /// Check if user can perform action on a specific resource
  Future<bool> canCreate(String resource) async =>
      hasPermission(resource: resource, action: 'create');

  Future<bool> canRead(String resource) async =>
      hasPermission(resource: resource, action: 'read');

  Future<bool> canUpdate(String resource) async =>
      hasPermission(resource: resource, action: 'update');

  Future<bool> canDelete(String resource) async =>
      hasPermission(resource: resource, action: 'delete');

  /// Check if user can manage their own resources
  Future<bool> canManageOwn(String resource) async =>
      hasPermission(resource: resource, action: 'update', constraint: 'own');

  /// Get all permissions for a specific resource
  Future<List<String>> getActionsForResource(String resource) async {
    final permissions = await getCachedPermissions();
    final actions = permissions
        .where((p) => p.resource == resource)
        .map((p) => p.action)
        .toSet()
        .toList();

    return actions;
  }
}
