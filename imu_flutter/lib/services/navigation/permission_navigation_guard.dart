import 'package:flutter/material.dart';
import '../../core/models/user_role.dart';
import '../../services/permissions/permission_service.dart';
import '../../services/permissions/remote_permission_service.dart';

/// Navigation guard that checks permissions before allowing navigation
///
/// Usage:
/// ```dart
/// final canNavigate = await PermissionNavigationGuard.canNavigateToRoute(
///   route: '/clients/create',
///   userRole: userRole,
/// );
/// if (!canNavigate) {
///   showErrorSnackBar('You don't have permission');
/// }
/// ```
class PermissionNavigationGuard {
  PermissionNavigationGuard._();

  /// Route definitions with required permissions
  static const Map<String, _RoutePermission> _routePermissions = {
    // Admin routes
    '/admin': _RoutePermission(
      resource: 'system',
      action: 'read',
      requiredRoles: [UserRole.admin],
    ),

    // User management routes
    '/users': _RoutePermission(
      resource: 'users',
      action: 'read',
      requiredRoles: [UserRole.admin, UserRole.areaManager, UserRole.assistantAreaManager],
    ),
    '/users/create': _RoutePermission(
      resource: 'users',
      action: 'create',
      requiredRoles: [UserRole.admin, UserRole.areaManager, UserRole.assistantAreaManager],
    ),

    // Client management routes
    '/clients/create': _RoutePermission(
      resource: 'clients',
      action: 'create',
      requiredRoles: [UserRole.admin, UserRole.areaManager, UserRole.assistantAreaManager, UserRole.caravan],
    ),

    // Touchpoint routes
    '/touchpoints/create': _RoutePermission(
      resource: 'touchpoints',
      action: 'create',
      checkTouchpointType: true,
    ),

    // Reports routes
    '/reports': _RoutePermission(
      resource: 'reports',
      action: 'read',
      requiredRoles: [UserRole.admin, UserRole.areaManager, UserRole.assistantAreaManager],
    ),

    // Settings routes
    '/settings/users': _RoutePermission(
      resource: 'users',
      action: 'update',
      requiredRoles: [UserRole.admin, UserRole.areaManager],
    ),
  };

  /// Check if user can navigate to a specific route
  static Future<bool> canNavigateToRoute({
    required String route,
    required UserRole userRole,
    int? touchpointNumber,
  }) async {
    final routePermission = _routePermissions[route];

    if (routePermission == null) {
      // No permissions defined for this route, allow access
      return true;
    }

    // Check role-based permissions first
    if (routePermission.requiredRoles != null) {
      if (!routePermission.requiredRoles!.contains(userRole)) {
        debugPrint('Navigation denied: $route - insufficient role');
        return false;
      }
    }

    // Check permission-based access
    if (routePermission.resource != null && routePermission.action != null) {
      final permissionService = RemotePermissionService();

      // For touchpoint creation, use PermissionService (local check)
      if (routePermission.checkTouchpointType == true && touchpointNumber != null) {
        // This would need touchpoint type from context
        // For now, just check if they can create touchpoints at all
        return PermissionService.canManageArea(userRole);
      }

      final hasPermission = await permissionService.hasPermission(
        resource: routePermission.resource!,
        action: routePermission.action!,
      );

      if (!hasPermission) {
        debugPrint('Navigation denied: $route - insufficient permission');
        return false;
      }
    }

    return true;
  }

  /// Get navigation options for bottom navigation bar
  /// Returns list of enabled/disabled navigation items based on permissions
  static Future<List<NavigationItem>> getNavigationItems({
    required UserRole userRole,
  }) async {
    final permissionService = RemotePermissionService();

    final allItems = [
      NavigationItem(
        route: '/home',
        icon: Icons.home,
        label: 'Home',
        enabled: true, // Everyone can access home
      ),
      NavigationItem(
        route: '/clients',
        icon: Icons.people,
        label: 'Clients',
        enabled: true, // Everyone can view clients
      ),
      NavigationItem(
        route: '/itinerary',
        icon: Icons.calendar_today,
        label: 'Itinerary',
        enabled: true, // Everyone can view itinerary
      ),
      NavigationItem(
        route: '/reports',
        icon: Icons.assessment,
        label: 'Reports',
        enabled: userRole.isManager, // Only managers can see reports
      ),
      NavigationItem(
        route: '/settings',
        icon: Icons.settings,
        label: 'Settings',
        enabled: true, // Everyone can access settings
      ),
    ];

    return allItems;
  }

  /// Check if menu item should be shown
  static Future<bool> shouldShowMenuItem({
    required String route,
    required UserRole userRole,
  }) async {
    final items = await getNavigationItems(userRole: userRole);
    final item = items.firstWhere(
      (i) => i.route == route,
      orElse: () => NavigationItem(route: route, icon: Icons.error, label: 'Unknown', enabled: false),
    );

    return item.enabled;
  }
}

/// Internal class for route permission definitions
class _RoutePermission {
  final String? resource;
  final String? action;
  final List<UserRole>? requiredRoles;
  final bool checkTouchpointType;

  const _RoutePermission({
    this.resource,
    this.action,
    this.requiredRoles,
    this.checkTouchpointType = false,
  });
}

/// Navigation item model
class NavigationItem {
  final String route;
  final IconData icon;
  final String label;
  final bool enabled;

  const NavigationItem({
    required this.route,
    required this.icon,
    required this.label,
    required this.enabled,
  });
}
