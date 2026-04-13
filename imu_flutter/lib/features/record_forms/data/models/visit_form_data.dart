// lib/features/record_forms/data/models/visit_form_data.dart

import 'package:imu_flutter/features/record_forms/data/models/form_data.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Form data for Visit Only records
/// Auto-sets reason to clientNotAvailable and status to incomplete
class VisitFormData extends FormData {
  final TouchpointReason? reason;
  final TouchpointStatus? status;

  const VisitFormData({
    required super.client,
    super.timeIn,
    super.timeOut,
    super.odometerIn,
    super.odometerOut,
    super.photoPath,
    super.remarks,
    super.gpsLatitude,
    super.gpsLongitude,
    super.gpsAddress,
    this.reason,
    this.status,
  });

  /// Factory constructor that auto-sets reason and status
  factory VisitFormData.withAutoSetValues({
    required Client client,
    DateTime? timeIn,
    DateTime? timeOut,
    String? odometerIn,
    String? odometerOut,
    String? photoPath,
    String? remarks,
    double? gpsLatitude,
    double? gpsLongitude,
    String? gpsAddress,
  }) {
    return VisitFormData(
      client: client,
      timeIn: timeIn,
      timeOut: timeOut,
      odometerIn: odometerIn,
      odometerOut: odometerOut,
      photoPath: photoPath,
      remarks: remarks,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAddress: gpsAddress,
      reason: TouchpointReason.clientNotAvailable,
      status: TouchpointStatus.incomplete,
    );
  }

  @override
  Map<String, String?> get validationErrors {
    final errors = <String, String?>{};

    // Time In validation
    if (timeIn == null) {
      errors['timeIn'] = 'Time In is required';
    }

    // Time Out validation
    if (calculatedTimeOut == null) {
      errors['timeOut'] = 'Time Out is required';
    } else if (timeIn != null && calculatedTimeOut!.isBefore(timeIn!)) {
      errors['timeOut'] = 'Must be after Time In';
    }

    // Odometer In validation
    if (odometerIn == null || odometerIn!.isEmpty) {
      errors['odometerIn'] = 'Odometer In is required';
    }

    // Odometer Out validation
    if (odometerOut == null || odometerOut!.isEmpty) {
      errors['odometerOut'] = 'Odometer Out is required';
    } else if (odometerIn != null && odometerOut != null) {
      final inValue = int.tryParse(odometerIn!);
      final outValue = int.tryParse(odometerOut!);
      if (inValue != null && outValue != null && outValue < inValue) {
        errors['odometerOut'] = 'Must be >= Odometer In';
      }
    }

    // Photo validation
    if (photoPath == null || photoPath!.isEmpty) {
      errors['photo'] = 'Photo is required';
    }

    // Remarks validation
    if (remarks != null && remarks!.length > 255) {
      errors['remarks'] = 'Max 255 characters';
    }

    // Visit-specific validations
    // Note: reason and status are auto-set, but we validate they're present
    if (reason == null) {
      errors['reason'] = 'Reason must be auto-set to Client Not Available';
    }

    if (status == null) {
      errors['status'] = 'Status must be auto-set to Incomplete';
    }

    // Verify auto-set values
    if (reason != TouchpointReason.clientNotAvailable) {
      errors['reason'] = 'Reason must be Client Not Available';
    }

    if (status != TouchpointStatus.incomplete) {
      errors['status'] = 'Status must be Incomplete';
    }

    return errors;
  }

  @override
  bool get isFilled => super.isFilled && reason != null && status != null;

  @override
  VisitFormData copyWith({
    Client? client,
    DateTime? timeIn,
    DateTime? timeOut,
    String? odometerIn,
    String? odometerOut,
    String? photoPath,
    String? remarks,
    double? gpsLatitude,
    double? gpsLongitude,
    String? gpsAddress,
    TouchpointReason? reason,
    TouchpointStatus? status,
    bool clearTimeIn = false,
    bool clearTimeOut = false,
    bool clearPhoto = false,
    bool clearRemarks = false,
  }) {
    return VisitFormData(
      client: client ?? this.client,
      timeIn: clearTimeIn ? null : (timeIn ?? this.timeIn),
      timeOut: clearTimeOut ? null : (timeOut ?? this.timeOut),
      odometerIn: odometerIn ?? this.odometerIn,
      odometerOut: odometerOut ?? this.odometerOut,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      gpsLatitude: gpsLatitude ?? this.gpsLatitude,
      gpsLongitude: gpsLongitude ?? this.gpsLongitude,
      gpsAddress: gpsAddress ?? this.gpsAddress,
      // Preserve auto-set values unless explicitly overridden
      reason: reason ?? this.reason,
      status: status ?? this.status,
    );
  }

  /// Convert to visit API payload
  Map<String, dynamic> toVisitPayload() {
    return {
      'client_id': client.id,
      'user_id': '', // Will be filled by provider
      'type': 'regular_visit',
      'time_in': timeIn?.toIso8601String(),
      'time_out': calculatedTimeOut?.toIso8601String(),
      'odometer_arrival': odometerIn,
      'odometer_departure': odometerOut,
      'photo_url': photoPath,
      'latitude': gpsLatitude,
      'longitude': gpsLongitude,
      'address': gpsAddress,
      'reason': reason?.apiValue,
      'status': status?.apiValue,
      'notes': remarks,
    };
  }
}
