import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/data/models/touchpoint_validation_model.dart';

/// DEPRECATED: Use [PermissionService] instead.
///
/// This service is replaced by the centralized permission system.
/// Import 'package:imu_flutter/services/permissions/permission_service.dart'
///
/// @deprecated Use PermissionService.canCreateTouchpoint() instead.
/// This will be removed in v2.0.0.
///
/// Note: Sequence validation methods (getExpectedTouchpointType, validateTouchpointSequence,
/// getSequenceDisplay) are still valid. Only role-based validation methods are deprecated.

/// User roles for touchpoint creation
enum UserRole {
  caravan('caravan'),
  tele('tele'),
  admin('admin'),
  areaManager('area_manager'),
  assistantAreaManager('assistant_area_manager');

  final String _apiValue;
  const UserRole(this._apiValue);

  String get apiValue => _apiValue;

  static UserRole fromApi(String value) {
    return UserRole.values.firstWhere(
      (e) => e._apiValue == value.toLowerCase(),
      orElse: () => UserRole.caravan,
    );
  }
}

/// Service for validating touchpoint sequences
class TouchpointValidationService {
  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// NOTE: Touchpoint pattern no longer enforced - backend determines type
  // static const List<TouchpointType> _sequence = [
  //   TouchpointType.visit,  // 1st
  //   TouchpointType.call,   // 2nd
  //   TouchpointType.call,   // 3rd
  //   TouchpointType.visit,  // 4th
  //   TouchpointType.call,   // 5th
  //   TouchpointType.call,   // 6th
  //   TouchpointType.visit,  // 7th
  // ];

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// NOTE: Touchpoint pattern no longer enforced - backend determines type
  // static const List<int> _visitTouchpoints = [1, 4, 7];

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Touchpoint numbers for Call type (2, 3, 5, 6)
  // static const List<int> _callTouchpoints = [2, 3, 5, 6];

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Get the expected touchpoint type for a given touchpoint number
  // static TouchpointType getExpectedTouchpointType(int touchpointNumber) {
  //   if (touchpointNumber < 1 || touchpointNumber > 7) {
  //     throw ArgumentError('Touchpoint number must be between 1 and 7');
  //   }
  //   return _sequence[touchpointNumber - 1];
  // }

  /// COMMENTED OUT for Unli Touchpoint - no touchpoint limit
  /// Get the next expected touchpoint number for a client
  /// Returns null if all touchpoints are completed (no next type)
  // static int? getNextTouchpointNumber(Client client) {
  //   final completedCount = client.touchpointSummary.length;
  //   if (completedCount >= 7) return null;
  //   return completedCount + 1;
  // }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Validate touchpoint sequence
  // static TouchpointValidationResult validateTouchpointSequence({
  //   required int touchpointNumber,
  //   required TouchpointType touchpointType,
  // }) {
  //   final expectedType = getExpectedTouchpointType(touchpointNumber);
  //
  //   if (touchpointType != expectedType) {
  //     return TouchpointValidationResult(
  //       isValid: false,
  //       error: 'Invalid touchpoint type for touchpoint #$touchpointNumber. '
  //           'Expected \'${_typeToString(expectedType)}\' but got \'${_typeToString(touchpointType)}\'',
  //       expectedType: expectedType,
  //       providedType: touchpointType,
  //       touchpointNumber: touchpointNumber,
  //     );
  //   }
  //
  //   return TouchpointValidationResult(
  //     isValid: true,
  //     expectedType: expectedType,
  //     touchpointNumber: touchpointNumber,
  //   );
  // }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Validate touchpoint based on user role
  /// Caravan users can only create Visit touchpoints (1, 4, 7)
  /// Tele users can only create Call touchpoints (2, 3, 5, 6)
  @Deprecated('Use PermissionService.canCreateTouchpoint() instead')
  // static TouchpointValidationResult validateTouchpointForRole({
  //   required int touchpointNumber,
  //   required TouchpointType touchpointType,
  //   required UserRole userRole,
  // }) {
  //   // First validate the sequence
  //   final sequenceValidation = validateTouchpointSequence(
  //     touchpointNumber: touchpointNumber,
  //     touchpointType: touchpointType,
  //   );
  //
  //   if (!sequenceValidation.isValid) {
  //     return sequenceValidation;
  //   }
  //
  //   // Then validate role-based permissions
  //   String? roleError;
  //
  //   switch (userRole) {
  //     case UserRole.caravan:
  //       if (!_visitTouchpoints.contains(touchpointNumber)) {
  //         roleError = 'Caravan users can only create Visit touchpoints (1, 4, 7)';
  //       } else if (touchpointType != TouchpointType.visit) {
  //         roleError = 'Caravan users can only create Visit touchpoints';
  //       }
  //       break;
  //
  //     case UserRole.tele:
  //       if (!_callTouchpoints.contains(touchpointNumber)) {
  //         roleError = 'Tele users can only create Call touchpoints (2, 3, 5, 6)';
  //       } else if (touchpointType != TouchpointType.call) {
  //         roleError = 'Tele users can only create Call touchpoints';
  //       }
  //       break;
  //
  //     case UserRole.admin:
  //     case UserRole.areaManager:
  //     case UserRole.assistantAreaManager:
  //       // Managers can create any touchpoint type
  //       break;
  //   }
  //
  //   if (roleError != null) {
  //     return TouchpointValidationResult(
  //       isValid: false,
  //       error: roleError,
  //       expectedType: sequenceValidation.expectedType,
  //       providedType: touchpointType,
  //       touchpointNumber: touchpointNumber,
  //     );
  //   }
  //
  //   return sequenceValidation; // Already validated as valid
  // }

  /// COMMENTED OUT for Unli Touchpoint - no 7-touchpoint limit
  /// Check if a client can create a new touchpoint
  // static TouchpointCanCreateResult canCreateTouchpoint(Client client) {
  //   final nextNumber = getNextTouchpointNumber(client);
  //
  //   if (nextNumber == null) {
  //     return TouchpointCanCreateResult(
  //       canCreate: false,
  //       reason: 'All 7 touchpoints have been completed for this client',
  //       completedTouchpoints: 7,
  //       nextTouchpointNumber: null,
  //       nextTouchpointType: null,
  //     );
  //   }
  //
  //   final nextType = getExpectedTouchpointType(nextNumber);
  //
  //   return TouchpointCanCreateResult(
  //     canCreate: true,
  //     completedTouchpoints: nextNumber - 1,
  //     nextTouchpointNumber: nextNumber,
  //     nextTouchpointType: nextType,
  //   );
  // }

  /// COMMENTED OUT for Unli Touchpoint - no number restrictions
  /// Check if a user role can create a specific touchpoint
  @Deprecated('Use PermissionService.canCreateTouchpoint() instead')
  // static bool canRoleCreateTouchpoint({
  //   required int touchpointNumber,
  //   required UserRole userRole,
  // }) {
  //   switch (userRole) {
  //     case UserRole.caravan:
  //       return _visitTouchpoints.contains(touchpointNumber);
  //
  //     case UserRole.tele:
  //       return _callTouchpoints.contains(touchpointNumber);
  //
  //     case UserRole.admin:
  //     case UserRole.areaManager:
  //     case UserRole.assistantAreaManager:
  //       return true; // Managers can create any touchpoint
  //   }
  // }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Get the sequence as a list of strings for display
  // static List<String> getSequenceDisplay() {
  //   return List.generate(7, (index) {
  //     final number = index + 1;
  //     final type = _sequence[index];
  //     return '${_getOrdinal(number)} ${_typeToString(type)}';
  //   });
  // }

  /// Get ordinal suffix for a number (1st, 2nd, 3rd, etc.)
  static String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  /// Convert TouchpointType to display string
  static String _typeToString(TouchpointType type) {
    return type == TouchpointType.visit ? 'Visit' : 'Call';
  }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Get the full sequence as TouchpointType list
  // static List<TouchpointType> getSequence() {
  //   return List.from(_sequence);
  // }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Get Visit touchpoint numbers (1, 4, 7)
  // static List<int> getVisitTouchpoints() {
  //   return List.from(_visitTouchpoints);
  // }

  /// COMMENTED OUT for Unli Touchpoint - no pattern restrictions
  /// Get Call touchpoint numbers (2, 3, 5, 6)
  // static List<int> getCallTouchpoints() {
  //   return List.from(_callTouchpoints);
  // }
}
