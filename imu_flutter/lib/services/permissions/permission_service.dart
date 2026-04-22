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
  /// UPDATED for Unli Touchpoint - no number restrictions
  ///
  /// Managers can create any touchpoint type.
  /// Caravan can only create Visit touchpoints (any number).
  /// Tele can only create Call touchpoints (any number).
  ///
  /// Returns true if the role can create this touchpoint, false otherwise.
  ///
  /// OLD: COMMENTED OUT for Unli Touchpoint - had number restrictions
  /// Touchpoint pattern no longer enforced - backend determines type.
  /// Caravan can only create Visit touchpoints.
  /// Tele can only create Call touchpoints.
  // static bool canCreateTouchpoint({
  //   required UserRole role,
  //   required int touchpointNumber,
  //   required TouchpointType type,
  // }) {
  //   // Managers can create any type
  //   if (role.isManager) {
  //     return true;
  //   }
  //
  //   // Caravan can only create visits for specific touchpoint numbers
  //   if (role == UserRole.caravan) {
  //     const visitNumbers = [1, 4, 7];
  //     return visitNumbers.contains(touchpointNumber) && type == TouchpointType.visit;
  //   }
  //
  //   // Tele can only create calls for specific touchpoint numbers
  //   if (role == UserRole.tele) {
  //     const callNumbers = [2, 3, 5, 6];
  //     return callNumbers.contains(touchpointNumber) && type == TouchpointType.call;
  //   }
  //
  //   return false;
  // }

  /// NEW: Simplified implementation - type check only, no number restrictions
  static bool canCreateTouchpoint({
    required UserRole role,
    required int touchpointNumber, // Kept for backward compatibility
    required TouchpointType type,
  }) {
    // Managers can create any type
    if (role.isManager) {
      return true;
    }

    // Caravan can only create Visit touchpoints (any number)
    if (role == UserRole.caravan) {
      return type == TouchpointType.visit;
    }

    // Tele can only create Call touchpoints (any number)
    if (role == UserRole.tele) {
      return type == TouchpointType.call;
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
