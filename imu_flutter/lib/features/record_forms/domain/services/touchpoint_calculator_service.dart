// lib/features/record_forms/domain/services/touchpoint_calculator_service.dart

import 'package:imu_flutter/features/clients/data/models/client_model.dart';

class TouchpointLimitException implements Exception {
  final String message;

  const TouchpointLimitException(this.message);

  @override
  String toString() => 'TouchpointLimitException: $message';
}

class TouchpointCalculatorService {
  /// Calculate the next touchpoint number for a client
  /// Returns 1 if no touchpoints exist
  /// Returns max(touchpoint_number) + 1 if touchpoints exist
  /// Throws TouchpointLimitException if already 7 touchpoints
  Future<int> calculateNextNumber(String clientId, List<Touchpoint> touchpoints) async {
    if (touchpoints.isEmpty) {
      return 1;
    }

    // Find the maximum touchpoint number
    final maxNumber = touchpoints
        .map((t) => t.touchpointNumber)
        .reduce((a, b) => a > b ? a : b);

    if (maxNumber >= 7) {
      throw const TouchpointLimitException(
        'Maximum 7 touchpoints reached for this client',
      );
    }

    return maxNumber + 1;
  }

  /// Get the expected touchpoint type for a given number
  /// Based on the pattern: Visit, Call, Call, Visit, Call, Call, Visit
  TouchpointType getExpectedType(int touchpointNumber) {
    if (touchpointNumber < 1 || touchpointNumber > 7) {
      throw ArgumentError('Touchpoint number must be between 1 and 7');
    }
    return TouchpointPattern.types[touchpointNumber - 1];
  }
}
