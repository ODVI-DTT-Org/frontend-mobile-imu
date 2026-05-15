// lib/features/record_forms/data/models/touchpoint_form_data.dart

import 'package:imu_flutter/features/record_forms/data/models/form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Caravan visit reasons — matches backend touchpoint_reasons table (role='caravan', touchpoint_type='Visit').
/// newReleaseLoan is kept for the loan release form only and excluded from the standard visit dropdown.
enum TouchpointReason {
  abroad('ABROAD', 'Abroad'),
  applyMembership('APPLY_MEMBERSHIP', 'Apply for PUSU / LIKA Membership'),
  backedOut('BACKED_OUT', 'Backed Out'),
  ciBi('CI_BI', 'CI/BI'),
  deceased('DECEASED', 'Deceased'),
  disapproved('DISAPPROVED', 'Disapproved'),
  forAdaCompliance('FOR_ADA_COMPLIANCE', 'For ADA Compliance'),
  forProcessing('FOR_PROCESSING', 'For Processing / Approval / Request / Buy-Out'),
  forUpdate('FOR_UPDATE', 'For Update'),
  forVerification('FOR_VERIFICATION', 'For Verification'),
  inaccessibleArea('INACCESSIBLE_AREA', 'Inaccessible / Critical Area'),
  interested('INTERESTED', 'Interested'),
  loanInquiry('LOAN_INQUIRY', 'Loan Inquiry'),
  movedOut('MOVED_OUT', 'Moved Out'),
  notAmenable('NOT_AMENABLE', 'Not Amenable to Our Product Criteria'),
  notAround('NOT_AROUND', 'Not Around'),
  notInList('NOT_IN_LIST', 'Not In the List'),
  notInterested('NOT_INTERESTED', 'Not Interested'),
  overage('OVERAGE', 'Overage'),
  poorHealth('POOR_HEALTH', 'Poor Health Condition'),
  returnedAtm('RETURNED_ATM', 'Returned ATM / Pick-up ATM'),
  telemarketing('TELEMARKETING', 'Telemarketing'),
  undecided('UNDECIDED', 'Undecided'),
  unlocated('UNLOCATED', 'Unlocated'),
  withOtherLending('WITH_OTHER_LENDING', 'With Other Lending'),
  interestedFamilyDeclined('INTERESTED_FAMILY_DECLINED', 'Interested, But Declined Due to Family Decision'),
  newReleaseLoan('NEW_RELEASE_LOAN', 'New Release Loan');

  final String apiValue;
  final String displayName;
  const TouchpointReason(this.apiValue, this.displayName);

  static TouchpointReason fromApi(String value) {
    return TouchpointReason.values.firstWhere(
      (reason) => reason.apiValue == value.toUpperCase(),
      orElse: () => TouchpointReason.interested,
    );
  }

  static List<TouchpointReason> get visitReasons =>
      values.where((r) => r != TouchpointReason.newReleaseLoan).toList();
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
  bfpActive('BFP_ACTIVE', 'BFP Active'),
  bfpPension('BFP_PENSION', 'BFP Pension'),
  pnpPension('PNP_PENSION', 'PNP Pension'),
  napolcom('NAPOLCOM', 'NAPOLCOM'),
  bfpStp('BFP_STP', 'BFP STP');

  final String apiValue;
  final String displayName;
  const ProductType(this.apiValue, this.displayName);

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
  preterm('PRETERM'),
  renewal('RENEWAL');

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
      'remarks': remarks,
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
