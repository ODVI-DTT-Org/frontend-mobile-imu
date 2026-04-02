// lib/shared/utils/permission_helpers.dart
import '../../core/models/user_role.dart';

/// Returns the generic permission denied message
String getPermissionDeniedMessage() {
  return "You don't have permission to perform this action";
}

/// Returns valid touchpoint numbers for the given role
List<int> getValidTouchpointNumbers(UserRole role) {
  if (role.isManager) {
    return [1, 2, 3, 4, 5, 6, 7];
  }

  if (role == UserRole.caravan) {
    return [1, 4, 7]; // Visit touchpoints only
  }

  if (role == UserRole.tele) {
    return [2, 3, 5, 6]; // Call touchpoints only
  }

  return [1, 2, 3, 4, 5, 6, 7]; // Default to all
}

/// Checks if the touchpoint number is valid for the given role
bool isValidTouchpointNumberForRole(int number, UserRole role) {
  final validNumbers = getValidTouchpointNumbers(role);
  return validNumbers.contains(number);
}
