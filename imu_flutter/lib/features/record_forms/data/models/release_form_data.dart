// lib/features/record_forms/data/models/release_form_data.dart

import 'package:imu_flutter/features/record_forms/data/models/form_data.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' show Client;

/// Form data for Release Loan records
/// Auto-sets reason to newReleaseLoan and status to completed
/// Adds UDI number, product type, and loan type fields
class ReleaseFormData extends FormData {
  final TouchpointReason? reason;
  final TouchpointStatus? status;
  final String? udiNumber;      // UDI number = release amount
  final ProductType? productType;
  final LoanType? loanType;

  const ReleaseFormData({
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
    this.udiNumber,
    this.productType,
    this.loanType,
  });

  /// Factory constructor that auto-sets reason and status
  factory ReleaseFormData.withAutoSetValues({
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
    String? udiNumber,
    ProductType? productType,
    LoanType? loanType,
  }) {
    return ReleaseFormData(
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
      reason: TouchpointReason.newReleaseLoan,
      status: TouchpointStatus.completed,
      udiNumber: udiNumber,
      productType: productType,
      loanType: loanType,
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

    // Release-specific validations
    if (udiNumber == null || udiNumber!.isEmpty) {
      errors['udiNumber'] = 'UDI number is required';
    } else {
      // Must be a valid number
      final numberValue = double.tryParse(udiNumber!);
      if (numberValue == null) {
        errors['udiNumber'] = 'Must be a valid number';
      } else if (numberValue <= 0) {
        errors['udiNumber'] = 'Must be greater than 0';
      }
    }

    if (productType == null) {
      errors['productType'] = 'Please select a product type';
    }

    if (loanType == null) {
      errors['loanType'] = 'Please select a loan type';
    }

    // Verify auto-set values
    if (reason != TouchpointReason.newReleaseLoan) {
      errors['reason'] = 'Reason must be New Release Loan';
    }

    if (status != TouchpointStatus.completed) {
      errors['status'] = 'Status must be Completed';
    }

    return errors;
  }

  @override
  bool get isFilled => super.isFilled &&
                        reason != null &&
                        status != null &&
                        udiNumber != null &&
                        udiNumber!.isNotEmpty &&
                        productType != null &&
                        loanType != null;

  @override
  ReleaseFormData copyWith({
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
    String? udiNumber,
    ProductType? productType,
    LoanType? loanType,
    bool clearTimeIn = false,
    bool clearTimeOut = false,
    bool clearPhoto = false,
    bool clearRemarks = false,
    bool clearUdiNumber = false,
  }) {
    return ReleaseFormData(
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
      udiNumber: clearUdiNumber ? null : (udiNumber ?? this.udiNumber),
      productType: productType ?? this.productType,
      loanType: loanType ?? this.loanType,
    );
  }

  /// Convert to visit API payload
  Map<String, dynamic> toVisitPayload() {
    return {
      'client_id': client.id,
      'user_id': '', // Will be filled by provider
      'type': 'loan_release',
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

  /// Convert to release API payload
  Map<String, dynamic> toReleasePayload(String visitId) {
    return {
      'client_id': client.id,
      'user_id': '', // Will be filled by provider
      'visit_id': visitId,
      'udi_number': udiNumber,
      'release_amount': double.tryParse(udiNumber ?? '0') ?? 0.0,
      'product_type': productType?.apiValue,
      'loan_type': loanType?.apiValue,
      'notes': remarks,
    };
  }
}
