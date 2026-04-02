import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permissions/remote_permission_service.dart';
import '../providers/app_providers.dart';

/// Widget that shows/hides its child based on user permissions
///
/// Example:
/// ```dart
/// PermissionWidget(
///   resource: 'clients',
///   action: 'create',
///   child: ElevatedButton('Add Client'),
///   fallback: Text('You don't have permission'),
/// )
/// ```
class PermissionWidget extends ConsumerWidget {
  final String resource;
  final String action;
  final String? constraint;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.resource,
    required this.action,
    this.constraint,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = RemotePermissionService();

    return FutureBuilder<bool>(
      future: permissionService.hasPermission(
        resource: resource,
        action: action,
        constraint: constraint,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show nothing while checking permissions
          return const SizedBox.shrink();
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Simplified permission widget for common CRUD operations
class PermissionCreator extends ConsumerWidget {
  final String resource;
  final Widget child;
  final Widget? fallback;

  const PermissionCreator({
    super.key,
    required this.resource,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionWidget(
      resource: resource,
      action: 'create',
      child: child,
      fallback: fallback,
    );
  }
}

class PermissionReader extends ConsumerWidget {
  final String resource;
  final Widget child;
  final Widget? fallback;

  const PermissionReader({
    super.key,
    required this.resource,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionWidget(
      resource: resource,
      action: 'read',
      child: child,
      fallback: fallback,
    );
  }
}

class PermissionUpdater extends ConsumerWidget {
  final String resource;
  final Widget child;
  final Widget? fallback;

  const PermissionUpdater({
    super.key,
    required this.resource,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionWidget(
      resource: resource,
      action: 'update',
      child: child,
      fallback: fallback,
    );
  }
}

class PermissionDeleter extends ConsumerWidget {
  final String resource;
  final Widget child;
  final Widget? fallback;

  const PermissionDeleter({
    super.key,
    required this.resource,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionWidget(
      resource: resource,
      action: 'delete',
      child: child,
      fallback: fallback,
    );
  }
}

/// Widget that disables its child based on permissions
///
/// Unlike PermissionWidget which hides the child, this widget
/// shows the child but disables it when user lacks permissions.
///
/// Example:
/// ```dart
/// PermissionGuard(
///   resource: 'clients',
///   action: 'update',
///   child: ElevatedButton('Edit Client'),
///   disabledChild: Opacity(
///     opacity: 0.5,
///     child: ElevatedButton('Edit Client'),
///   ),
/// )
/// ```
class PermissionGuard extends ConsumerWidget {
  final String resource;
  final String action;
  final String? constraint;
  final Widget child;
  final Widget? disabledChild;

  const PermissionGuard({
    super.key,
    required this.resource,
    required this.action,
    this.constraint,
    required this.child,
    this.disabledChild,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionService = RemotePermissionService();

    return FutureBuilder<bool>(
      future: permissionService.hasPermission(
        resource: resource,
        action: action,
        constraint: constraint,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show disabled state while checking
          return disabledChild ?? _buildDisabled(child);
        }

        final hasPermission = snapshot.data ?? false;

        if (hasPermission) {
          return child;
        }

        return disabledChild ?? _buildDisabled(child);
      },
    );
  }

  Widget _buildDisabled(Widget child) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.5,
        child: child,
      ),
    );
  }
}

/// Widget that shows different content based on ownership
///
/// Example:
/// ```dart
/// OwnershipWidget(
///   ownerId: touchpoint.userId,
///   currentUserId: currentUser.id,
///   child: ElevatedButton('Edit'),
///   fallback: Text('Not your touchpoint'),
/// )
/// ```
class OwnershipWidget extends StatelessWidget {
  final String ownerId;
  final String? currentUserId;
  final Widget child;
  final Widget? fallback;
  final List<String>? adminRoles;

  const OwnershipWidget({
    super.key,
    required this.ownerId,
    this.currentUserId,
    required this.child,
    this.fallback,
    this.adminRoles,
  });

  @override
  Widget build(BuildContext context) {
    // Admin roles can bypass ownership check
    if (adminRoles != null && currentUserId != null) {
      // Check if current user has admin role (this would need to be passed in or checked via provider)
      // For now, we'll just check ownership
    }

    final isOwner = ownerId == currentUserId;

    if (isOwner) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
