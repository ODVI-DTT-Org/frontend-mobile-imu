// lib/shared/utils/permission_helpers.dart
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart' show TouchpointType;

/// Returns the generic permission denied message
String getPermissionDeniedMessage() {
  return "You don't have permission to perform this action";
}

/// COMMENTED OUT for Unli Touchpoint - no number restrictions
/// OLD: Returns valid touchpoint numbers for the given role
// List<int> getValidTouchpointNumbers(UserRole role) {
//   if (role.isManager) {
//     return [1, 2, 3, 4, 5, 6, 7];
//   }
//
//   if (role == UserRole.caravan) {
//     return [1, 4, 7]; // Visit touchpoints only
//   }
//
//   if (role == UserRole.tele) {
//     return [2, 3, 5, 6]; // Call touchpoints only
//   }
//
//   return [1, 2, 3, 4, 5, 6, 7]; // Default to all
// }

/// NEW: Returns empty list (no number restrictions for Unli Touchpoint)
/// All roles can create touchpoints with any number
/// Type restrictions still apply (Caravan=Visit, Tele=Call)
List<int> getValidTouchpointNumbers(UserRole role) {
  return []; // No number restrictions - unlimited touchpoints
}

/// Returns valid touchpoint types for the given role
List<TouchpointType> getValidTouchpointTypes(UserRole role) {
  if (role.isManager) {
    return [TouchpointType.visit, TouchpointType.call];
  }

  if (role == UserRole.caravan) {
    return [TouchpointType.visit]; // Visit touchpoints only
  }

  if (role == UserRole.tele) {
    return [TouchpointType.call]; // Call touchpoints only
  }

  return [TouchpointType.visit, TouchpointType.call]; // Default to all
}

/// COMMENTED OUT for Unli Touchpoint - no number restrictions
/// OLD: Checks if the touchpoint number is valid for the given role
// bool isValidTouchpointNumberForRole(int number, UserRole role) {
//   final validNumbers = getValidTouchpointNumbers(role);
//   return validNumbers.contains(number);
// }

/// NEW: All touchpoint numbers are valid for Unli Touchpoint
/// Type restrictions still apply (Caravan=Visit, Tele=Call)
bool isValidTouchpointNumberForRole(int number, UserRole role) {
  return true; // All numbers valid - unlimited touchpoints
}

/// Checks if the touchpoint type is valid for the given role
bool isValidTouchpointTypeForRole(TouchpointType type, UserRole role) {
  final validTypes = getValidTouchpointTypes(role);
  return validTypes.contains(type);
}
