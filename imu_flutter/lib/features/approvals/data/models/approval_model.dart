/// Approval status enum
enum ApprovalStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  final String value;
  const ApprovalStatus(this.value);

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ApprovalStatus.pending,
    );
  }
}

/// Approval type enum
enum ApprovalType {
  client('client'),
  clientDelete('client_delete'),
  clientAddress('address_add'),
  clientPhone('phone_add'),
  udi('udi');

  final String value;
  const ApprovalType(this.value);

  static ApprovalType fromString(String value) {
    return ApprovalType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ApprovalType.client,
    );
  }
}

/// Approval model
class Approval {
  final String id;
  final ApprovalType type;
  final ApprovalStatus status;
  final String clientId;
  final String? userId;
  final int? touchpointNumber;
  final String? role;
  final String? reason;
  final String? notes;
  final Map<String, dynamic>? updatedClientInformation; // NEW: JSONB field for client changes
  final String? updatedUdi; // NEW: Updated UDI value
  final String? udiNumber;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClientExpand? expand;

  Approval({
    required this.id,
    required this.type,
    required this.status,
    required this.clientId,
    this.userId,
    this.touchpointNumber,
    this.role,
    this.reason,
    this.notes,
    this.updatedClientInformation, // NEW
    this.updatedUdi, // NEW
    this.udiNumber,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.expand,
  });

  factory Approval.fromJson(Map<String, dynamic> json) {
    return Approval(
      id: json['id'] as String,
      type: ApprovalType.fromString(json['type'] as String? ?? 'client'),
      status: ApprovalStatus.fromString(json['status'] as String? ?? 'pending'),
      clientId: json['client_id'] as String,
      userId: json['user_id'] as String?,
      touchpointNumber: json['touchpoint_number'] as int?,
      role: json['role'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      updatedClientInformation: json['updated_client_information'] as Map<String, dynamic>?, // NEW
      updatedUdi: json['updated_udi'] as String?, // NEW
      udiNumber: json['udi_number'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      rejectedBy: json['rejected_by'] as String?,
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: DateTime.parse(json['created'] as String? ?? json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated'] as String? ?? json['updated_at'] as String),
      expand: json['expand'] != null
          ? ClientExpand.fromJson(json['expand'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'status': status.value,
      'client_id': clientId,
      'user_id': userId,
      'touchpoint_number': touchpointNumber,
      'role': role,
      'reason': reason,
      'notes': notes,
      'updated_client_information': updatedClientInformation, // NEW
      'updated_udi': updatedUdi, // NEW
      'udi_number': udiNumber,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejected_by': rejectedBy,
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (expand != null) 'expand': expand?.toJson(),
    };
  }

  /// Get display title for the approval
  String get displayTitle {
    switch (type) {
      case ApprovalType.client:
        return 'Client Edit';
      case ApprovalType.clientDelete:
        return 'Client Deletion';
      case ApprovalType.clientAddress:
        return 'Add Address';
      case ApprovalType.clientPhone:
        return 'Add Phone Number';
      case ApprovalType.udi:
        return 'Loan Release';
    }
  }

  /// Get display reason for the approval
  String get displayReason {
    if (reason != null && reason!.isNotEmpty) {
      return reason!;
    }
    switch (type) {
      case ApprovalType.client:
        return 'Client information update';
      case ApprovalType.clientDelete:
        return 'Request to delete client';
      case ApprovalType.clientAddress:
        return 'Request to add address';
      case ApprovalType.clientPhone:
        return 'Request to add phone number';
      case ApprovalType.udi:
        return 'Loan release request';
    }
  }

  /// Check if approval is pending
  bool get isPending => status == ApprovalStatus.pending;

  /// Check if approval is approved
  bool get isApproved => status == ApprovalStatus.approved;

  /// Check if approval is rejected
  bool get isRejected => status == ApprovalStatus.rejected;
}

/// Client expand data for approval
class ClientExpand {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? email;
  final String? phone;
  final String? clientType;

  ClientExpand({
    required this.id,
    this.firstName,
    this.lastName,
    this.middleName,
    this.email,
    this.phone,
    this.clientType,
  });

  factory ClientExpand.fromJson(Map<String, dynamic> json) {
    return ClientExpand(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      middleName: json['middle_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      clientType: json['client_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'email': email,
      'phone': phone,
      'client_type': clientType,
    };
  }

  /// Get full name
  String? get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName;
  }
}
