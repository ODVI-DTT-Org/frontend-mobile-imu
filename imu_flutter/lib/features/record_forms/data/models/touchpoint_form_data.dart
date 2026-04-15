// lib/features/record_forms/data/models/touchpoint_form_data.dart

import 'package:imu_flutter/features/record_forms/data/models/form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

enum TouchpointReason {
  abroad('ABROAD'),
  interested('INTERESTED'),
  loanInquiry('LOAN_INQUIRY'),
  followUp('FOLLOW_UP'),
  documentsSubmitted('DOCUMENTS_SUBMITTED'),
  documentsIncomplete('DOCUMENTS_INCOMPLETE'),
  notAround('NOT_AROUND'),
  rescheduled('RESCHEDULED'),
  declined('DECLINED'),
  referred('REFERRED'),
  wrongNumber('WRONG_NUMBER'),
  disconnected('DISCONNECTED'),
  busy('BUSY'),
  callBack('CALL_BACK'),
  meetingSet('MEETING_SET'),
  paymentCollection('PAYMENT_COLLECTION'),
  paymentPromised('PAYMENT_PROMISED'),
  complaint('COMPLAINT'),
  query('QUERY'),
  renewal('RENEWAL'),
  additional('ADDITIONAL'),
  preterm('PRETERM'),
  newApplication('NEW_APPLICATION'),
  verification('VERIFICATION'),
  approval('APPROVAL'),
  disbursement('DISBURSEMENT'),
  clientNotAvailable('CLIENT_NOT_AVAILABLE'),  // For Visit Only
  newReleaseLoan('NEW_RELEASE_LOAN');         // For Release Loan

  final String apiValue;
  const TouchpointReason(this.apiValue);

  String get displayName {
    return apiValue
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static TouchpointReason fromApi(String value) {
    return TouchpointReason.values.firstWhere(
      (reason) => reason.apiValue == value,
      orElse: () => TouchpointReason.interested,
    );
  }
}

enum TouchpointStatus {
  interested('INTERESTED'),
  undecided('UNDECIDED'),
  notInterested('NOT_INTERESTED'),
  completed('COMPLETED'),
  followUpNeeded('FOLLOW_UP_NEEDED'),
  incomplete('INCOMPLETE');  // For Visit Only

  final String apiValue;
  const TouchpointStatus(this.apiValue);

  String get displayName {
    return apiValue
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static TouchpointStatus fromApi(String value) {
    return TouchpointStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => TouchpointStatus.interested,
    );
  }
}

enum ProductType {
  bfpActive('BFP_ACTIVE'),
  bfpPension('BFP_PENSION'),
  pnpPension('PNP_PENSION'),
  napolcom('NAPOLCOM'),
  bfpStp('BFP_STP');

  final String apiValue;
  const ProductType(this.apiValue);

  String get displayName {
    return apiValue
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  static ProductType fromApi(String value) {
    return ProductType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => ProductType.bfpActive,
    );
  }
}

enum LoanType {
  newLoan('NEW'),
  additional('ADDITIONAL'),
  renewal('RENEWAL'),
  preterm('PRETERM');

  final String apiValue;
  const LoanType(this.apiValue);

  String get displayName => apiValue;

  static LoanType fromApi(String value) {
    return LoanType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => LoanType.newLoan,
    );
  }
}

class TouchpointFormData extends FormData {
  final TouchpointReason? reason;
  final TouchpointStatus? status;

  const TouchpointFormData({
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

    // Touchpoint-specific validations
    if (reason == null) {
      errors['reason'] = 'Please select a reason';
    }

    if (status == null) {
      errors['status'] = 'Please select status';
    }

    return errors;
  }

  @override
  bool get isFilled => super.isFilled && reason != null && status != null;

  @override
  TouchpointFormData copyWith({
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
    return TouchpointFormData(
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

  /// Convert to touchpoint API payload
  Map<String, dynamic> toTouchpointPayload(String visitId, int touchpointNumber) {
    return {
      'client_id': client.id,
      'user_id': '', // Will be filled by provider
      'visit_id': visitId,
      'touchpoint_number': touchpointNumber,
      'type': 'Visit',
    };
  }
}
