import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permissions/remote_permission_service.dart';

/// Provider for RemotePermissionService
///
/// Usage:
/// ```dart
/// final permissionService = ref.watch(permissionServiceProvider);
/// final hasPermission = await permissionService.hasPermission(
///   resource: 'clients',
///   action: 'create',
/// );
/// ```
final permissionServiceProvider = Provider<RemotePermissionService>((ref) {
  return RemotePermissionService();
});

/// Provider for cached permissions
///
/// Usage:
/// ```dart
/// final permissions = ref.watch(cachedPermissionsProvider);
/// ```
final cachedPermissionsProvider = FutureProvider<List<RemotePermission>>((ref) async {
  final service = ref.watch(permissionServiceProvider);
  return await service.getCachedPermissions();
});

/// Provider to check if user has specific permission
///
/// Usage:
/// ```dart
/// final canCreate = ref.watch(hasPermissionProvider('clients', 'create'));
/// ```
final hasPermissionProvider = Provider.family<bool, ({String resource, String action, String? constraint})>((ref, params) {
  final service = ref.watch(permissionServiceProvider);

  // This is a synchronous check that uses cached permissions
  // For fresh check, use service.hasPermission() directly
  final permissions = ref.watch(cachedPermissionsProvider).value ?? [];

  return permissions.any((p) =>
    p.resource == params.resource &&
    p.action == params.action &&
    (params.constraint == null || p.constraint == params.constraint)
  );
});

/// Provider to check if user can create resource
final canCreateProvider = Provider.family<bool, String>((ref, resource) {
  return ref.watch(hasPermissionProvider((resource: resource, action: 'create', constraint: null)));
});

/// Provider to check if user can read resource
final canReadProvider = Provider.family<bool, String>((ref, resource) {
  return ref.watch(hasPermissionProvider((resource: resource, action: 'read', constraint: null)));
});

/// Provider to check if user can update resource
final canUpdateProvider = Provider.family<bool, String>((ref, resource) {
  return ref.watch(hasPermissionProvider((resource: resource, action: 'update', constraint: null)));
});

/// Provider to check if user can delete resource
final canDeleteProvider = Provider.family<bool, String>((ref, resource) {
  return ref.watch(hasPermissionProvider((resource: resource, action: 'delete', constraint: null)));
});
