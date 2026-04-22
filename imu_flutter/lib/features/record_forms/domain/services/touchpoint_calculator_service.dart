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
  /// No limit on touchpoints anymore (unlimited)
  Future<int> calculateNextNumber(String clientId, List<Touchpoint> touchpoints) async {
    if (touchpoints.isEmpty) {
      return 1;
    }

    // Find the maximum touchpoint number
    final maxNumber = touchpoints
        .map((t) => t.touchpointNumber)
        .reduce((a, b) => a > b ? a : b);

    // No more limit - always allow next touchpoint
    return maxNumber + 1;
  }

  /// Get the expected touchpoint type for a given number
  /// Note: Pattern enforcement removed - type is determined by backend/API
  /// This method is now deprecated and should not be used
  @Deprecated('Touchpoint type is now determined by backend, not by pattern')
  TouchpointType getExpectedType(int touchpointNumber) {
    // Return a default type - actual type comes from backend
    return TouchpointType.visit;
  }
}
