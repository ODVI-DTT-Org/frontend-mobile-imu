import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Centralized permission checking service.
///
/// Provides role-based authorization for touchpoint creation,
/// area management, and admin access.
class PermissionService {
  PermissionService._();

  /// Check if a role can create a specific touchpoint.
  ///
  /// Touchpoint sequence: 1(Visit), 2(Call), 3(Call), 4(Visit), 5(Call), 6(Call), 7(Visit)
  ///
  /// Managers can create any touchpoint type.
  /// Caravan can only create Visit touchpoints (1, 4, 7).
  ///
  /// Returns true if the role can create this touchpoint, false otherwise.
  static bool canCreateTouchpoint({
    required UserRole role,
    required int touchpointNumber,
    required TouchpointType type,
  }) {
    // Managers can create any type
    if (role.canCreateAnyTouchpoint) {
      return true;
    }

    // Caravan can only create visits for specific touchpoint numbers
    if (role == UserRole.caravan) {
      const visitNumbers = [1, 4, 7];
      return visitNumbers.contains(touchpointNumber) && type == TouchpointType.visit;
    }

    return false;
  }

  /// Check if a role can manage geographic areas.
  ///
  /// Only managers (admin, area manager, assistant area manager) can manage areas.
  static bool canManageArea(UserRole role) => role.isManager;

  /// Check if a role can access admin features.
  ///
  /// Only admin can access admin features.
  static bool canAccessAdmin(UserRole role) => role == UserRole.admin;
}
