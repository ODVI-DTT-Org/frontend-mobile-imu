// lib/features/record_forms/data/models/form_data.dart

import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Base class for all form data
abstract class FormData {
  final Client client;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? odometerIn;
  final String? odometerOut;
  final String? photoPath;
  final String? remarks;
  final double? gpsLatitude;
  final double? gpsLongitude;
  final String? gpsAddress;

  const FormData({
    required this.client,
    this.timeIn,
    this.timeOut,
    this.odometerIn,
    this.odometerOut,
    this.photoPath,
    this.remarks,
    this.gpsLatitude,
    this.gpsLongitude,
    this.gpsAddress,
  });

  /// Calculate Time Out as Time In + 5 minutes if not set
  DateTime? get calculatedTimeOut {
    if (timeOut != null) return timeOut;
    if (timeIn == null) return null;
    return timeIn!.add(const Duration(minutes: 5));
  }

  /// Check if all required fields are filled
  bool get isFilled => timeIn != null &&
                        calculatedTimeOut != null &&
                        odometerIn != null &&
                        odometerOut != null &&
                        photoPath != null;

  /// Validation errors map
  Map<String, String?> get validationErrors;

  /// Check if form is valid
  bool get isValid => validationErrors.values.every((error) => error == null);
}
