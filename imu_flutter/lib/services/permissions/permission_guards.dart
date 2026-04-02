import 'package:flutter/widgets.dart';
import 'package:imu_flutter/core/models/user_role.dart';

/// Widget that shows/hides child based on user role.
///
/// Example:
/// ```dart
/// RoleBasedWidget(
///   role: userRole,
///   allowedRoles: [UserRole.admin, UserRole.areaManager],
///   child: AdminButton(),
/// )
/// ```
class RoleBasedWidget extends StatelessWidget {
  const RoleBasedWidget({
    super.key,
    required this.role,
    required this.allowedRoles,
    required this.child,
  });

  final UserRole role;
  final List<UserRole> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(role)) {
      return child;
    }
    return const SizedBox.shrink();
  }
}

/// Widget that enables/disables child based on user role.
///
/// Example:
/// ```dart
/// DisableBasedOnRole(
///   role: userRole,
///   enabledRoles: [UserRole.admin],
///   child: ElevatedButton(
///     onPressed: () => doAdminThing(),
///     child: Text('Admin Action'),
///   ),
/// )
/// ```
class DisableBasedOnRole extends StatelessWidget {
  const DisableBasedOnRole({
    super.key,
    required this.role,
    required this.enabledRoles,
    required this.child,
    this.disabledChild,
  });

  final UserRole role;
  final List<UserRole> enabledRoles;
  final Widget child;
  final Widget? disabledChild;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabledRoles.contains(role);

    if (isEnabled) {
      return child;
    }

    return disabledChild ?? IgnorePointer(child: Opacity(opacity: 0.5, child: child));
  }
}

/// Widget that shows child only if condition is true.
///
/// Example:
/// ```dart
/// ConditionalVisibility(
///   visible: user.canCreateTouchpoints,
///   child: TouchpointButton(),
/// )
/// ```
class ConditionalVisibility extends StatelessWidget {
  const ConditionalVisibility({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (visible) {
      return child;
    }
    return const SizedBox.shrink();
  }
}
