import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Result of touchpoint sequence validation
class TouchpointValidationResult {
  final bool isValid;
  final String? error;
  final TouchpointType? expectedType;
  final TouchpointType? providedType;
  final int? touchpointNumber;

  TouchpointValidationResult({
    required this.isValid,
    this.error,
    this.expectedType,
    this.providedType,
    this.touchpointNumber,
  });

  @override
  String toString() {
    if (isValid) {
      return 'Touchpoint #$touchpointNumber is valid (${expectedType == TouchpointType.visit ? "Visit" : "Call"})';
    }
    return error ?? 'Unknown validation error';
  }
}

/// Result of checking if a client can create a new touchpoint
class TouchpointCanCreateResult {
  final bool canCreate;
  final String? reason;
  final int completedTouchpoints;
  final int? nextTouchpointNumber;
  final TouchpointType? nextTouchpointType;

  TouchpointCanCreateResult({
    required this.canCreate,
    this.reason,
    required this.completedTouchpoints,
    this.nextTouchpointNumber,
    this.nextTouchpointType,
  });

  String get nextTouchpointDisplay {
    if (nextTouchpointNumber == null || nextTouchpointType == null) return 'All touchpoints completed';
    final typeStr = nextTouchpointType == TouchpointType.visit ? 'Visit' : 'Call';
    final ordinal = _getOrdinal(nextTouchpointNumber!);
    return '$ordinal $typeStr';
  }

  String _getOrdinal(int number) {
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
}
