/// Display helper extension methods for converting database values to user-friendly labels
///
/// This file provides extension methods for enums and string values to convert
/// database values to display labels for the UI.

/// Visit type display helpers
extension VisitTypeDisplayHelper on String {
  /// Convert visit type database value to display label
  String get visitTypeDisplay {
    switch (this) {
      case 'regular_visit':
        return 'Regular Visit';
      case 'release_loan':
        return 'Release Loan';
      default:
        return 'Unknown Visit Type';
    }
  }

  /// Check if this is a valid visit type
  bool get isValidVisitType {
    return this == 'regular_visit' || this == 'release_loan';
  }
}

/// Touchpoint type display helpers
extension TouchpointTypeDisplayHelper on String {
  /// Convert touchpoint type database value to display label
  String get touchpointTypeDisplay {
    switch (this) {
      case 'Visit':
        return 'Visit';
      case 'Call':
        return 'Call';
      default:
        return 'Unknown Type';
    }
  }

  /// Check if this is a valid touchpoint type
  bool get isValidTouchpointType {
    return this == 'Visit' || this == 'Call';
  }
}

/// Release status display helpers
extension ReleaseStatusDisplayHelper on String {
  /// Convert release status database value to display label
  String get releaseStatusDisplay {
    switch (this) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'disbursed':
        return 'Disbursed';
      default:
        return 'Unknown Status';
    }
  }

  /// Check if this is a valid release status
  bool get isValidReleaseStatus {
    return this == 'pending' ||
           this == 'approved' ||
           this == 'rejected' ||
           this == 'disbursed';
  }

  /// Check if release status is pending (can be approved/rejected)
  bool get isReleasePending => this == 'pending';

  /// Check if release status is approved (can be disbursed)
  bool get isReleaseApproved => this == 'approved';

  /// Check if release status is rejected (cannot be changed)
  bool get isReleaseRejected => this == 'rejected';

  /// Check if release status is disbursed (final state)
  bool get isReleaseDisbursed => this == 'disbursed';
}

/// Product type display helpers
extension ProductTypeDisplayHelper on String {
  /// Convert product type database value to display label
  String get productTypeDisplay {
    switch (this) {
      case 'PUSU':
        return 'Pension Update Salary Loan';
      case 'LIKA':
        return 'Livelihood Loan for Karanasan sa Ago';
      case 'SUB2K':
        return 'Sub2K Loan';
      default:
        return 'Unknown Product';
    }
  }

  /// Get short product type label (abbreviated)
  String get productTypeShort {
    switch (this) {
      case 'PUSU':
        return 'PUSU';
      case 'LIKA':
        return 'LIKA';
      case 'SUB2K':
        return 'SUB2K';
      default:
        return 'Unknown';
    }
  }

  /// Check if this is a valid product type
  bool get isValidProductType {
    return this == 'PUSU' || this == 'LIKA' || this == 'SUB2K';
  }
}

/// Loan type display helpers
extension LoanTypeDisplayHelper on String {
  /// Convert loan type database value to display label
  String get loanTypeDisplay {
    switch (this) {
      case 'NEW':
        return 'New Loan';
      case 'ADDITIONAL':
        return 'Additional Loan';
      case 'RENEWAL':
        return 'Renewal';
      case 'PRETERM':
        return 'Pre-termination';
      default:
        return 'Unknown Loan Type';
    }
  }

  /// Check if this is a valid loan type
  bool get isValidLoanType {
    return this == 'NEW' ||
           this == 'ADDITIONAL' ||
           this == 'RENEWAL' ||
           this == 'PRETERM';
  }
}

/// Touchpoint status display helpers (for backwards compatibility)
extension TouchpointStatusDisplayHelper on String {
  /// Convert touchpoint status database value to display label
  String get touchpointStatusDisplay {
    switch (this) {
      case 'Interested':
        return 'Interested';
      case 'Undecided':
        return 'Undecided';
      case 'Not Interested':
        return 'Not Interested';
      case 'Completed':
        return 'Completed';
      default:
        return 'Unknown Status';
    }
  }

  /// Check if this is a valid touchpoint status
  bool get isValidTouchpointStatus {
    return this == 'Interested' ||
           this == 'Undecided' ||
           this == 'Not Interested' ||
           this == 'Completed';
  }

  /// Check if touchpoint status indicates interest (Interested or Undecided)
  bool get isInterested =>
      this == 'Interested' || this == 'Undecided';

  /// Check if touchpoint status is completed
  bool get isCompleted => this == 'Completed';

  /// Check if touchpoint status is not interested
  bool get isNotInterested => this == 'Not Interested';
}
