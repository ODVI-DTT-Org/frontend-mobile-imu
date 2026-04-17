import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'address_model.dart' as addr;
import 'phone_number_model.dart' as ph;

/// Client data model for IMU app
/// Aligned with database schema - uses direct columns instead of nested lists
class Client {
  final String? id;
  final String firstName;
  final String? middleName;
  final String lastName;

  // Legacy PCNICMS fields
  final String? extName; // Extension name (Jr., Sr., etc.)
  final String? fullname; // Full name (legacy computed field)
  // fullAddress removed - using getter instead
  final String? dob; // Date of birth as text (legacy)

  final String? agencyName;
  final String? department;
  final String? position;
  final String? employmentStatus;
  final String? payrollDate;
  final int? tenure;
  final DateTime? birthDate;
  final String? phone; // Primary contact number (single field)
  final String? remarks;
  final ClientType clientType;
  final MarketType? marketType;
  final ProductType productType;
  final PensionType pensionType;
  final LoanType? loanType;
  // Raw string values from database (preserves original data when enum parsing fails)
  final String? clientTypeRaw;
  final String? marketTypeRaw;
  final String? productTypeRaw;
  final String? pensionTypeRaw;
  final String? loanTypeRaw;
  final String? pan;
  final String? email;
  final String? facebookLink;
  final String? agencyId;

  // Legacy PCNICMS fields continued
  final String? accountCode;
  final String? accountNumber;
  final String? rank;
  final double? monthlyPensionAmount;
  final double? monthlyPensionGross;
  final String? atmNumber;
  final String? applicableRepublicAct;
  final String? unitCode;
  final String? pcniAcctCode;
  final String? gCompany; // G company (legacy)
  final String? gStatus; // G status (legacy)
  final String? status; // Client status (default: 'active')

  final int? psgcId; // Foreign key to PSGC table (INTEGER in database)
  final String? region; // Region from PSGC (e.g., NCR, Region I)
  final String? province; // Province from PSGC (e.g., Metro Manila, Pangasinan)
  final String? municipality; // Municipality from PSGC
  final String? barangay; // Barangay from PSGC
  final String? udi; // Unified ID
  final List<addr.Address> addresses; // Multiple addresses
  final List<ph.PhoneNumber> phoneNumbers; // Multiple phone numbers
  final List<Touchpoint> touchpoints;

  // NEW: Pre-calculated touchpoint data (from API)
  final List<Touchpoint> touchpointSummary; // From touchpoint_summary JSON
  final int touchpointNumber; // From touchpoint_number field
  final String? nextTouchpoint; // From next_touchpoint field
  final int? nextTouchpointNumber; // From next_touchpoint_number field (backend-calculated)
  final ClientTouchpointStatus? touchpointStatus; // From backend touchpoint_status object

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // User ID of who created the client
  final String? deletedBy; // User ID of who soft-deleted the client
  final DateTime? deletedAt; // Soft delete timestamp
  final bool isStarred;
  final bool loanReleased;
  final DateTime? loanReleasedAt;

  Client({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    this.extName,
    this.fullname,
    // fullAddress removed - using getter instead
    this.dob,
    this.agencyName,
    this.department,
    this.position,
    this.employmentStatus,
    this.payrollDate,
    this.tenure,
    this.birthDate,
    this.phone,
    this.remarks,
    required this.clientType,
    this.marketType,
    required this.productType,
    required this.pensionType,
    this.loanType,
    this.clientTypeRaw,
    this.marketTypeRaw,
    this.productTypeRaw,
    this.pensionTypeRaw,
    this.loanTypeRaw,
    this.pan,
    this.email,
    this.facebookLink,
    this.agencyId,
    this.accountCode,
    this.accountNumber,
    this.rank,
    this.monthlyPensionAmount,
    this.monthlyPensionGross,
    this.atmNumber,
    this.applicableRepublicAct,
    this.unitCode,
    this.pcniAcctCode,
    this.gCompany,
    this.gStatus,
    this.status,
    this.psgcId,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.udi,
    this.addresses = const [],
    this.phoneNumbers = const [],
    this.touchpoints = const [],
    this.touchpointSummary = const [],
    this.touchpointNumber = 1,
    this.nextTouchpoint,
    this.nextTouchpointNumber,
    this.touchpointStatus,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.deletedBy,
    this.deletedAt,
    this.isStarred = false,
    this.loanReleased = false,
    this.loanReleasedAt,
  });

  String get fullName {
    final firstMiddle = <String>[firstName];
    if (middleName != null && middleName!.isNotEmpty) {
      firstMiddle.add(middleName!);
    }
    return '$lastName, ${firstMiddle.join(' ')}';
  }

  String get fullAddress {
    final parts = <String>[];
    if (barangay != null && barangay!.isNotEmpty) parts.add(barangay!);
    if (municipality != null && municipality!.isNotEmpty) parts.add(municipality!);
    if (province != null && province!.isNotEmpty) parts.add(province!);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    return parts.join(', ');
  }

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  int get completedTouchpoints {
    // Use backend-calculated nextTouchpointNumber if available
    if (nextTouchpointNumber != null && nextTouchpointNumber! > 0) {
      return nextTouchpointNumber! - 1;
    }
    // Fallback: calculate from touchpointNumber, but ensure non-negative
    return touchpointNumber > 0 ? touchpointNumber - 1 : 0;
  }

  // Next touchpoint display
  String get nextTouchpointDisplay {
    if (nextTouchpoint == null) return '$touchpointNumber/7';
    return '$touchpointNumber/7 • ${nextTouchpoint!.toLowerCase()}';
  }

  /// Display product type - shows raw value if available, otherwise enum value
  String get productTypeDisplay {
    if (productTypeRaw != null && productTypeRaw!.isNotEmpty) {
      // Check if raw value matches known enum
      final rawLower = productTypeRaw!.toLowerCase();
      final enumMatch = ProductType.values.any((e) => e.name.toLowerCase() == rawLower);
      if (!enumMatch) {
        // Raw value is unknown, return it as-is
        return productTypeRaw!;
      }
    }
    // Use enum value
    return switch (productType) {
      ProductType.bfpActive => 'BFP ACTIVE',
      ProductType.bfpPension => 'BFP PENSION',
      ProductType.pnpPension => 'PNP PENSION',
      ProductType.napolcom => 'NAPOLCOM',
      ProductType.bfpStp => 'BFP STP',
    };
  }

  /// Display pension type - shows raw value if available, otherwise enum value
  String get pensionTypeDisplay {
    if (pensionTypeRaw != null && pensionTypeRaw!.isNotEmpty) {
      // Check if raw value matches known enum
      final rawLower = pensionTypeRaw!.toLowerCase();
      final enumMatch = PensionType.values.any((e) => e.name.toLowerCase() == rawLower);
      if (!enumMatch) {
        // Raw value is unknown, return it as-is
        return pensionTypeRaw!;
      }
    }
    // Use enum value
    return pensionType.name.toUpperCase();
  }

  /// Display loan type - shows raw value if available, otherwise enum value
  String? get loanTypeDisplay {
    if (loanType == null) return null;
    if (loanTypeRaw != null && loanTypeRaw!.isNotEmpty) {
      // Check if raw value matches known enum
      final rawLower = loanTypeRaw!.toLowerCase();
      final enumMatch = LoanType.values.any((e) => e.name.toLowerCase() == rawLower);
      if (!enumMatch) {
        // Raw value is unknown, return it as-is
        return loanTypeRaw!;
      }
    }
    // Use enum value
    return switch (loanType!) {
      LoanType.firstLoan => 'NEW',
      LoanType.additional => 'ADDITIONAL',
      LoanType.renewal => 'RENEWAL',
      LoanType.preterm => 'PRETERM',
    };
  }

  /// Display market type - shows raw value if available, otherwise enum value
  String? get marketTypeDisplay {
    if (marketType == null) return null;
    if (marketTypeRaw != null && marketTypeRaw!.isNotEmpty) {
      // Check if raw value matches known enum
      final rawLower = marketTypeRaw!.toLowerCase();
      final enumMatch = MarketType.values.any((e) => e.name.toLowerCase() == rawLower);
      if (!enumMatch) {
        // Raw value is unknown, return it as-is
        return marketTypeRaw!;
      }
    }
    // Use enum value
    return switch (marketType!) {
      MarketType.residential => 'Residential',
      MarketType.commercial => 'Commercial',
      MarketType.industrial => 'Industrial',
    };
  }

  /// Display client type - shows raw value if available, otherwise enum value
  String get clientTypeDisplay {
    if (clientTypeRaw != null && clientTypeRaw!.isNotEmpty) {
      // Check if raw value matches known enum
      final rawLower = clientTypeRaw!.toLowerCase();
      final enumMatch = ClientType.values.any((e) => e.name.toLowerCase() == rawLower);
      if (!enumMatch) {
        // Raw value is unknown, return it as-is
        return clientTypeRaw!;
      }
    }
    // Use enum value
    return clientType.name.toUpperCase();
  }

  TouchpointType? get nextTouchpointType {
    final next = completedTouchpoints;
    if (next >= 7) return null;
    return TouchpointPattern.types[next];
  }

  /// Check if client's location matches the given municipality code
  /// This is used for territory-based filtering
  bool matchesMunicipality(String? municipalityCode) {
    if (municipalityCode == null || municipalityCode.isEmpty) return true;
    // Direct match on municipality field
    return municipality == municipalityCode;
  }

  /// Get primary address with fallback to legacy fields
  addr.Address? get primaryAddress {
    if (addresses.isNotEmpty) {
      final primary = addresses.where((a) => a.isPrimary).firstOrNull;
      if (primary != null) return primary;
    }
    // Fallback to legacy fields
    if (region != null || province != null || municipality != null || barangay != null) {
      return addr.Address(
        id: 'legacy_$id',
        clientId: id ?? '',
        psgcId: psgcId ?? 0,
        label: addr.AddressLabel.home,
        streetAddress: '',
        postalCode: null,
        latitude: null,
        longitude: null,
        isPrimary: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        region: region,
        province: province,
        municipality: municipality,
        barangay: barangay,
      );
    }
    return null;
  }

  /// Get primary phone with fallback to legacy field
  ph.PhoneNumber? get primaryPhone {
    if (phoneNumbers.isNotEmpty) {
      final primary = phoneNumbers.where((p) => p.isPrimary).firstOrNull;
      if (primary != null) return primary;
    }
    // Fallback to legacy field
    if (phone != null && phone!.isNotEmpty) {
      return ph.PhoneNumber(
        id: 'legacy_$id',
        clientId: id ?? '',
        label: ph.PhoneLabel.mobile,
        number: phone!,
        isPrimary: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
    return null;
  }

  Client copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    String? extName,
    String? fullname,
    // fullAddress removed - using getter instead
    String? dob,
    String? agencyName,
    String? department,
    String? position,
    String? employmentStatus,
    String? payrollDate,
    int? tenure,
    DateTime? birthDate,
    String? phone,
    String? remarks,
    ClientType? clientType,
    MarketType? marketType,
    ProductType? productType,
    PensionType? pensionType,
    String? clientTypeRaw,
    String? marketTypeRaw,
    String? productTypeRaw,
    String? pensionTypeRaw,
    String? pan,
    String? email,
    String? facebookLink,
    String? agencyId,
    String? accountCode,
    String? accountNumber,
    String? rank,
    double? monthlyPensionAmount,
    double? monthlyPensionGross,
    String? atmNumber,
    String? applicableRepublicAct,
    String? unitCode,
    String? pcniAcctCode,
    String? gCompany,
    String? gStatus,
    String? status,
    int? psgcId,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
    String? udi,
    List<addr.Address>? addresses,
    List<ph.PhoneNumber>? phoneNumbers,
    List<Touchpoint>? touchpoints,
    List<Touchpoint>? touchpointSummary,
    int? touchpointNumber,
    String? nextTouchpoint,
    int? nextTouchpointNumber,
    ClientTouchpointStatus? touchpointStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
    bool? loanReleased,
    DateTime? loanReleasedAt,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      extName: extName ?? this.extName,
      fullname: fullname ?? this.fullname,
      // fullAddress removed - using getter instead
      dob: dob ?? this.dob,
      agencyName: agencyName ?? this.agencyName,
      department: department ?? this.department,
      position: position ?? this.position,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      payrollDate: payrollDate ?? this.payrollDate,
      tenure: tenure ?? this.tenure,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      remarks: remarks ?? this.remarks,
      clientType: clientType ?? this.clientType,
      marketType: marketType ?? this.marketType,
      productType: productType ?? this.productType,
      pensionType: pensionType ?? this.pensionType,
      clientTypeRaw: clientTypeRaw ?? this.clientTypeRaw,
      marketTypeRaw: marketTypeRaw ?? this.marketTypeRaw,
      productTypeRaw: productTypeRaw ?? this.productTypeRaw,
      pensionTypeRaw: pensionTypeRaw ?? this.pensionTypeRaw,
      pan: pan ?? this.pan,
      email: email ?? this.email,
      facebookLink: facebookLink ?? this.facebookLink,
      agencyId: agencyId ?? this.agencyId,
      accountCode: accountCode ?? this.accountCode,
      accountNumber: accountNumber ?? this.accountNumber,
      rank: rank ?? this.rank,
      monthlyPensionAmount: monthlyPensionAmount ?? this.monthlyPensionAmount,
      monthlyPensionGross: monthlyPensionGross ?? this.monthlyPensionGross,
      atmNumber: atmNumber ?? this.atmNumber,
      applicableRepublicAct: applicableRepublicAct ?? this.applicableRepublicAct,
      unitCode: unitCode ?? this.unitCode,
      pcniAcctCode: pcniAcctCode ?? this.pcniAcctCode,
      gCompany: gCompany ?? this.gCompany,
      gStatus: gStatus ?? this.gStatus,
      status: status ?? this.status,
      psgcId: psgcId ?? this.psgcId,
      region: region ?? this.region,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      udi: udi ?? this.udi,
      addresses: addresses ?? this.addresses,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      touchpoints: touchpoints ?? this.touchpoints,
      touchpointSummary: touchpointSummary ?? this.touchpointSummary,
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      nextTouchpoint: nextTouchpoint ?? this.nextTouchpoint,
      nextTouchpointNumber: nextTouchpointNumber ?? this.nextTouchpointNumber,
      touchpointStatus: touchpointStatus ?? this.touchpointStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
      loanReleased: loanReleased ?? this.loanReleased,
      loanReleasedAt: loanReleasedAt ?? this.loanReleasedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'agencyName': agencyName,
      'department': department,
      'position': position,
      'employmentStatus': employmentStatus,
      'payrollDate': payrollDate,
      'tenure': tenure,
      'birthDate': birthDate?.toIso8601String(),
      'phone': phone,
      'remarks': remarks,
      'clientType': clientType.name,
      'marketType': marketType?.name,
      'productType': productType.name,
      'pensionType': pensionType.name,
      'loanType': loanType?.name,
      'pan': pan,
      'email': email,
      'facebookLink': facebookLink,
      'agencyId': agencyId,
      'psgcId': psgcId,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'udi': udi,
      'touchpoints': touchpoints.map((t) {
        try {
          return t.toJson();
        } catch (e) {
          debugPrint('Client.toJson: Error serializing touchpoint - $e');
          // Return minimal valid touchpoint data
          return {
            'id': t.id,
            'client_id': t.clientId,
            'touchpoint_number': t.touchpointNumber,
            'type': 'Visit',
            'date': t.date.toIso8601String(),
            'status': 'Interested',
            'reason': 'Follow-up',
            'created_at': DateTime.now().toIso8601String(),
          };
        }
      }).toList(),
      'touchpoint_summary': touchpointSummary.map((t) {
        try {
          return t.toJson();
        } catch (e) {
          debugPrint('Client.toJson: Error serializing touchpoint summary - $e');
          // Return minimal valid touchpoint data
          return {
            'id': t.id,
            'client_id': t.clientId,
            'touchpoint_number': t.touchpointNumber,
            'type': 'Visit',
            'date': t.date.toIso8601String(),
            'status': 'Interested',
            'reason': 'Follow-up',
            'created_at': DateTime.now().toIso8601String(),
          };
        }
      }).toList(),
      'touchpoint_number': touchpointNumber,
      'next_touchpoint': nextTouchpoint,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStarred': isStarred,
      'loanReleased': loanReleased,
      'loanReleasedAt': loanReleasedAt?.toIso8601String(),
    };
  }

  /// Helper to parse boolean values from various types (bool, int, String)
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  /// Parse ClientType from string, return null if unknown (no default)
  static ClientType _parseClientType(dynamic value) {
    if (value == null) return ClientType.potential;
    final str = value.toString().toLowerCase();
    return ClientType.values.firstWhere(
      (e) => e.name.toLowerCase() == str,
      orElse: () => ClientType.potential,
    );
  }

  /// Parse MarketType from string, return null if unknown (no default)
  static MarketType? _parseMarketType(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    try {
      return MarketType.values.firstWhere(
        (e) => e.name.toLowerCase() == str,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse ProductType from string, return null if unknown (no default)
  static ProductType _parseProductType(dynamic value) {
    if (value == null) return ProductType.bfpActive;
    final str = value.toString().toLowerCase();
    try {
      return ProductType.values.firstWhere(
        (e) => e.name.toLowerCase() == str,
      );
    } catch (_) {
      return ProductType.bfpActive; // Fallback for new clients
    }
  }

  /// Parse PensionType from string, return null if unknown (no default)
  static PensionType _parsePensionType(dynamic value) {
    if (value == null) return PensionType.none;
    final str = value.toString().toLowerCase();
    try {
      return PensionType.values.firstWhere(
        (e) => e.name.toLowerCase() == str,
      );
    } catch (_) {
      return PensionType.none;
    }
  }

  /// Parse LoanType from string, return null if unknown (no default)
  static LoanType? _parseLoanType(dynamic value) {
    if (value == null) return null;
    final str = value.toString().toLowerCase();
    try {
      return LoanType.values.firstWhere(
        (e) => e.name.toLowerCase() == str,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parse field as string, handling int to string conversion
  static String? _parseStringField(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  /// Parse touchpoint_summary JSON array into Touchpoint objects
  static List<Touchpoint> _parseTouchpointSummary(dynamic value) {
    if (value == null || value == '') {
      return const [];
    }

    try {
      final jsonString = value.toString();
      if (jsonString.isEmpty) {
        return const [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => Touchpoint.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error parsing touchpoint_summary: $e');
      return const [];
    }
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      middleName: json['middleName'] ?? json['middle_name'],
      lastName: json['lastName'] ?? json['last_name'] ?? '',
      // Legacy PCNICMS fields
      extName: json['extName'] ?? json['ext_name'],
      fullname: json['fullname'] ?? json['full_name'],
      // fullAddress removed - using getter instead
      dob: json['dob'],
      // Standard fields
      agencyName: json['agencyName'] ?? json['agency_name'],
      department: json['department'],
      position: json['position'],
      employmentStatus: json['employmentStatus'] ?? json['employment_status'],
      payrollDate: json['payrollDate'] ?? json['payroll_date'],
      tenure: json['tenure'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : (json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null),
      phone: json['phone'] ?? json['contactNumber'] ?? json['phone_number'],
      remarks: json['remarks'],
      clientType: _parseClientType(json['clientType'] ?? json['client_type']),
      marketType: _parseMarketType(json['marketType'] ?? json['market_type']),
      productType: _parseProductType(json['productType'] ?? json['product_type']),
      pensionType: _parsePensionType(json['pensionType'] ?? json['pension_type']),
      loanType: _parseLoanType(json['loanType'] ?? json['loan_type']),
      clientTypeRaw: json['clientType'] ?? json['client_type'],
      marketTypeRaw: json['marketType'] ?? json['market_type'],
      productTypeRaw: json['productType'] ?? json['product_type'],
      pensionTypeRaw: json['pensionType'] ?? json['pension_type'],
      loanTypeRaw: _parseStringField(json['loanType'] ?? json['loan_type']),
      pan: json['pan'],
      email: json['email'],
      facebookLink: json['facebookLink'] ?? json['facebook_link'],
      agencyId: json['agencyId'] ?? json['agency_id'],
      // Legacy PCNICMS fields continued
      accountCode: json['accountCode'] ?? json['account_code'],
      accountNumber: json['accountNumber'] ?? json['account_number'],
      rank: json['rank'],
      monthlyPensionAmount: json['monthlyPensionAmount'] ?? json['monthly_pension_amount'],
      monthlyPensionGross: json['monthlyPensionGross'] ?? json['monthly_pension_gross'],
      atmNumber: json['atmNumber'] ?? json['atm_number'],
      applicableRepublicAct: json['applicableRepublicAct'] ?? json['applicable_republic_act'],
      unitCode: json['unitCode'] ?? json['unit_code'],
      pcniAcctCode: json['pcniAcctCode'] ?? json['pcni_acct_code'],
      gCompany: json['gCompany'] ?? json['g_company'],
      gStatus: json['gStatus'] ?? json['g_status'],
      status: json['status'],
      // PSGC fields
      psgcId: json['psgcId'] ?? (json['psgc_id'] is int ? json['psgc_id'] : (json['psgc_id'] != null ? int.tryParse(json['psgc_id'].toString()) : null)),
      region: json['region'] ?? json['psgc_region'],
      province: json['province'] ?? json['psgc_province'],
      municipality: json['municipality'] ?? json['municipality_id'],
      barangay: json['barangay'] ?? json['psgc_barangay'],
      udi: json['udi'],
      touchpoints: (json['touchpoints'] as List?)?.map((t) => Touchpoint.fromJson(t)).toList() ?? [],
      touchpointSummary: (json['touchpoint_summary'] as List?)?.map((t) => Touchpoint.fromJson(t)).toList() ?? [],
      touchpointNumber: json['touchpoint_number'] as int? ?? 1,
      nextTouchpoint: json['next_touchpoint'] as String?,
      nextTouchpointNumber: json['nextTouchpointNumber'] ?? json['next_touchpoint_number'] as int?,
      touchpointStatus: json['touchpoint_status'] != null
          ? ClientTouchpointStatus.fromJson(json['touchpoint_status'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null),
      createdBy: json['createdBy'] ?? json['created_by'],
      deletedBy: json['deletedBy'] ?? json['deleted_by'],
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : (json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null),
      isStarred: _parseBool(json['isStarred'] ?? json['is_starred']),
      loanReleased: _parseBool(json['loanReleased'] ?? json['loan_released']),
      loanReleasedAt: json['loanReleasedAt'] != null
          ? DateTime.parse(json['loanReleasedAt'])
          : (json['loan_released_at'] != null ? DateTime.parse(json['loan_released_at']) : null),
    );
  }

  /// Create Client from PowerSync/PostgreSQL row (snake_case column names)
  factory Client.fromRow(Map<String, dynamic> row) {
    final clientTypeRaw = _parseStringField(row['client_type']);
    final marketTypeRaw = _parseStringField(row['market_type']);
    final productTypeRaw = _parseStringField(row['product_type']);
    final pensionTypeRaw = _parseStringField(row['pension_type']);
    final loanTypeRaw = _parseStringField(row['loan_type']);

    return Client(
      id: row['id'] as String,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      middleName: row['middle_name'] as String?,
      // Legacy PCNICMS fields
      extName: row['ext_name'] as String?,
      fullname: row['fullname'] as String?,
      // fullAddress removed - using getter instead
      dob: row['dob'] as String?,
      // Standard fields
      birthDate: row['birth_date'] != null ? DateTime.parse(row['birth_date'] as String) : null,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      agencyName: row['agency_name'] as String?,
      department: row['department'] as String?,
      position: row['position'] as String?,
      employmentStatus: row['employment_status'] as String?,
      payrollDate: row['payroll_date'] as String?,
      tenure: row['tenure'] as int?,
      clientType: _parseClientType(clientTypeRaw),
      marketType: _parseMarketType(marketTypeRaw),
      productType: _parseProductType(productTypeRaw),
      pensionType: _parsePensionType(pensionTypeRaw),
      loanType: _parseLoanType(loanTypeRaw),
      clientTypeRaw: clientTypeRaw,
      marketTypeRaw: marketTypeRaw,
      productTypeRaw: productTypeRaw,
      pensionTypeRaw: pensionTypeRaw,
      loanTypeRaw: loanTypeRaw,
      pan: row['pan'] as String?,
      facebookLink: row['facebook_link'] as String?,
      remarks: row['remarks'] as String?,
      agencyId: row['agency_id'] as String?,
      // Legacy PCNICMS fields continued
      accountCode: row['account_code'] as String?,
      accountNumber: row['account_number'] as String?,
      rank: row['rank'] as String?,
      monthlyPensionAmount: row['monthly_pension_amount'] as double?,
      monthlyPensionGross: row['monthly_pension_gross'] as double?,
      atmNumber: row['atm_number'] as String?,
      applicableRepublicAct: row['applicable_republic_act'] as String?,
      unitCode: row['unit_code'] as String?,
      pcniAcctCode: row['pcni_acct_code'] as String?,
      gCompany: row['g_company'] as String?,
      gStatus: row['g_status'] as String?,
      status: row['status'] as String?,
      // PSGC fields
      psgcId: row['psgc_id'] as int?,
      region: row['region'] as String?,
      province: row['province'] as String?,
      municipality: row['municipality'] as String?,
      barangay: row['barangay'] as String?,
      udi: row['udi'] as String?,
      touchpointSummary: _parseTouchpointSummary(row['touchpoint_summary']),
      touchpointNumber: row['touchpoint_number'] as int? ?? 1,
      nextTouchpoint: row['next_touchpoint'] as String?,
      nextTouchpointNumber: row['next_touchpoint_number'] as int?,
      touchpointStatus: row['touchpoint_status'] != null
          ? ClientTouchpointStatus.fromRow(row)
          : null,
      isStarred: (row['is_starred'] as bool?) ?? false,
      loanReleased: (row['loan_released'] as bool?) ?? false,
      loanReleasedAt: row['loan_released_at'] != null
          ? DateTime.parse(row['loan_released_at'] as String)
          : null,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      createdBy: row['created_by'] as String?,
      deletedBy: row['deleted_by'] as String?,
      deletedAt: row['deleted_at'] != null
          ? DateTime.parse(row['deleted_at'] as String)
          : null,
    );
  }
}

enum ClientType {
  potential,
  existing,
}

enum MarketType {
  residential,
  commercial,
  industrial,
}

enum ProductType {
  bfpActive,
  bfpPension,
  pnpPension,
  napolcom,
  bfpStp,
}

enum PensionType {
  sss,
  gsis,
  private,
  none,
}

enum LoanType {
  firstLoan,
  additional,
  renewal,
  preterm,
}

enum AddressType {
  home,
  work,
  mailing,
}

class Address {
  final String id;
  final AddressType type;
  final String street;
  final String? barangay;
  final String city;
  final String? province;
  final String? postalCode;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    this.type = AddressType.home,
    required this.street,
    this.barangay,
    required this.city,
    this.province,
    this.postalCode,
    this.isPrimary = false,
    this.latitude,
    this.longitude,
  });

  String get fullAddress {
    final parts = [street];
    if (barangay != null) parts.add(barangay!);
    parts.add(city);
    if (province != null) parts.add(province!);
    if (postalCode != null) parts.add(postalCode!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'street': street,
    'barangay': barangay,
    'city': city,
    'province': province,
    'postal_code': postalCode,
    'isPrimary': isPrimary,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] ?? '',
    type: json['type'] != null
        ? AddressType.values.firstWhere(
            (e) => e.name == json['type'],
            orElse: () => AddressType.home,
          )
        : AddressType.home,
    street: json['street'] ?? '',
    barangay: json['barangay'],
    city: json['city'] ?? '',
    province: json['province'],
    postalCode: json['postal_code'] ?? json['zipCode'], // Handle both old and new field names
    isPrimary: json['isPrimary'] ?? false,
    latitude: json['latitude'],
    longitude: json['longitude'],
  );
}

enum PhoneType {
  mobile,
  landline,
}

class PhoneNumber {
  final String id;
  final PhoneType type;
  final String number;
  final String? label;
  final bool isPrimary;

  PhoneNumber({
    required this.id,
    this.type = PhoneType.mobile,
    required this.number,
    this.label,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'number': number,
    'label': label,
    'isPrimary': isPrimary,
  };

  factory PhoneNumber.fromJson(Map<String, dynamic> json) => PhoneNumber(
    id: json['id'] ?? '',
    type: json['type'] != null
        ? PhoneType.values.firstWhere(
            (e) => e.name == json['type'],
            orElse: () => PhoneType.mobile,
          )
        : PhoneType.mobile,
    number: json['number'] ?? '',
    label: json['label'],
    isPrimary: json['isPrimary'] ?? false,
  );
}

/// Touchpoint/Visit model
class Touchpoint {
  final String id;
  final String clientId;
  final String? userId; // The user (caravan/tele) who created this touchpoint (was agentId)
  final int touchpointNumber; // 1-7
  final TouchpointType type;
  final TouchpointReason reason;
  final TouchpointStatus status; // New: status field (Interested, Undecided, Not Interested, Completed)
  // Raw string values from database (preserves original data when enum parsing fails)
  final String? typeRaw;
  final String? reasonRaw;
  final String? statusRaw;
  final DateTime date;
  final String? address;
  final TimeOfDay? timeArrival;
  final TimeOfDay? timeDeparture;
  final String? odometerArrival;
  final String? odometerDeparture;
  final DateTime? nextVisitDate;
  final String? remarks;
  final String? photoPath;
  final String? audioPath;
  final double? latitude;
  final double? longitude;

  // === Time In/Out fields (new) ===
  final DateTime? timeIn;
  final double? timeInGpsLat;
  final double? timeInGpsLng;
  final String? timeInGpsAddress;
  final DateTime? timeOut;
  final double? timeOutGpsLat;
  final double? timeOutGpsLng;
  final String? timeOutGpsAddress;

  final String? rejectionReason; // NEW: Reason for touchpoint rejection
  final DateTime? updatedAt; // NEW: Last update timestamp

  final DateTime createdAt;

  Touchpoint({
    required this.id,
    required this.clientId,
    this.userId,
    required this.touchpointNumber,
    required this.type,
    required this.reason,
    this.status = TouchpointStatus.interested, // Default status
    this.typeRaw,
    this.reasonRaw,
    this.statusRaw,
    required this.date,
    this.address,
    this.timeArrival,
    this.timeDeparture,
    this.odometerArrival,
    this.odometerDeparture,
    this.nextVisitDate,
    this.remarks,
    this.photoPath,
    this.audioPath,
    this.latitude,
    this.longitude,
    this.timeIn,
    this.timeInGpsLat,
    this.timeInGpsLng,
    this.timeInGpsAddress,
    this.timeOut,
    this.timeOutGpsLat,
    this.timeOutGpsLng,
    this.timeOutGpsAddress,
    this.rejectionReason, // NEW
    this.updatedAt, // NEW
    required this.createdAt,
  });

  // Legacy getter for backward compatibility
  String? get agentId => userId;

  String get ordinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[touchpointNumber - 1];
  }

  Touchpoint copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? agentId, // Legacy parameter name for backward compatibility
    int? touchpointNumber,
    TouchpointType? type,
    TouchpointReason? reason,
    TouchpointStatus? status,
    String? typeRaw,
    String? reasonRaw,
    String? statusRaw,
    DateTime? date,
    String? address,
    TimeOfDay? timeArrival,
    TimeOfDay? timeDeparture,
    String? odometerArrival,
    String? odometerDeparture,
    DateTime? nextVisitDate,
    String? remarks,
    String? photoPath,
    String? audioPath,
    double? latitude,
    double? longitude,
    DateTime? timeIn,
    double? timeInGpsLat,
    double? timeInGpsLng,
    String? timeInGpsAddress,
    DateTime? timeOut,
    double? timeOutGpsLat,
    double? timeOutGpsLng,
    String? timeOutGpsAddress,
    String? rejectionReason, // NEW
    DateTime? updatedAt, // NEW
    DateTime? createdAt,
  }) {
    return Touchpoint(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? agentId ?? this.userId, // Support both parameter names
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      typeRaw: typeRaw ?? this.typeRaw,
      reasonRaw: reasonRaw ?? this.reasonRaw,
      statusRaw: statusRaw ?? this.statusRaw,
      date: date ?? this.date,
      address: address ?? this.address,
      timeArrival: timeArrival ?? this.timeArrival,
      timeDeparture: timeDeparture ?? this.timeDeparture,
      odometerArrival: odometerArrival ?? this.odometerArrival,
      odometerDeparture: odometerDeparture ?? this.odometerDeparture,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      remarks: remarks ?? this.remarks,
      photoPath: photoPath ?? this.photoPath,
      audioPath: audioPath ?? this.audioPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timeIn: timeIn ?? this.timeIn,
      timeInGpsLat: timeInGpsLat ?? this.timeInGpsLat,
      timeInGpsLng: timeInGpsLng ?? this.timeInGpsLng,
      timeInGpsAddress: timeInGpsAddress ?? this.timeInGpsAddress,
      timeOut: timeOut ?? this.timeOut,
      timeOutGpsLat: timeOutGpsLat ?? this.timeOutGpsLat,
      timeOutGpsLng: timeOutGpsLng ?? this.timeOutGpsLng,
      timeOutGpsAddress: timeOutGpsAddress ?? this.timeOutGpsAddress,
      rejectionReason: rejectionReason ?? this.rejectionReason, // NEW
      updatedAt: updatedAt ?? this.updatedAt, // NEW
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to API format (snake_case for PostgreSQL/PowerSync)
  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'user_id': userId, // Changed from agent_id
    'touchpoint_number': touchpointNumber,
    'type': type.apiValue,
    'date': date.toIso8601String(),
    'address': address,
    'time_arrival': timeArrival != null
        ? '${timeArrival!.hour.toString().padLeft(2, '0')}:${timeArrival!.minute.toString().padLeft(2, '0')}'
        : null,
    'time_departure': timeDeparture != null
        ? '${timeDeparture!.hour.toString().padLeft(2, '0')}:${timeDeparture!.minute.toString().padLeft(2, '0')}'
        : null,
    'odometer_arrival': odometerArrival,
    'odometer_departure': odometerDeparture,
    'reason': reason.apiValue,
    'status': status.apiValue, // New: status field
    'next_visit_date': nextVisitDate?.toIso8601String(),
    'notes': remarks,
    'photo_url': photoPath, // Changed to photo_url for API compatibility
    'audio_url': audioPath, // Changed to audio_url for API compatibility
    'latitude': latitude,
    'longitude': longitude,
    'time_in': timeIn?.toIso8601String(),
    'time_in_gps_lat': timeInGpsLat,
    'time_in_gps_lng': timeInGpsLng,
    'time_in_gps_address': timeInGpsAddress,
    'time_out': timeOut?.toIso8601String(),
    'time_out_gps_lat': timeOutGpsLat,
    'time_out_gps_lng': timeOutGpsLng,
    'time_out_gps_address': timeOutGpsAddress,
    'rejection_reason': rejectionReason, // NEW
    'updated_at': updatedAt?.toIso8601String(), // NEW
    'created_at': createdAt?.toIso8601String(),
  };

  /// Parse from API format (snake_case) or local format (camelCase)
  factory Touchpoint.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;

      // If it looks like a timestamp (contains 'T' or starts with year), parse as DateTime first
      if (time.contains('T') || time.startsWith('20') || time.startsWith('19')) {
        try {
          final dt = DateTime.parse(time);
          return TimeOfDay(hour: dt.hour, minute: dt.minute);
        } catch (e) {
          debugPrint('[Touchpoint] Failed to parse time from timestamp: "$time", error: $e');
          // Fall through to simple parsing
        }
      }

      // Simple "HH:MM" format parsing
      final parts = time.split(':');
      if (parts.length >= 2) {
        try {
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (e) {
          debugPrint('[Touchpoint] Failed to parse time from simple format: "$time", error: $e');
        }
      }

      return null;
    }

    // Robust DateTime parser that handles various ISO 8601 formats including microseconds
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try parsing with microseconds - remove them: 2026-04-05T22:30:12.123456+00
          try {
            final clean = value.replaceAll(RegExp(r'\.\d+([+-])'), r'$1');
            return DateTime.parse(clean);
          } catch (e2) {
            debugPrint('[Touchpoint] Failed to parse date: "$value", error: $e');
            return null;
          }
        }
      }
      return null;
    }

    // Helper to get value from either snake_case or camelCase
    T? getValue<T>(String snakeCase, String camelCase) {
      final value = json[snakeCase] ?? json[camelCase];
      if (value == null) return null;
      // Handle int type conversion - value might already be int or might be String
      if (T == int && value is String) {
        return int.tryParse(value) as T?;
      }
      if (T == int && value is int) {
        return value as T;
      }
      if (T == double && value is String) {
        return double.tryParse(value) as T?;
      }
      if (T == double && value is double) {
        return value as T;
      }
      return value as T?;
    }

    // Capture raw values before parsing
    final typeRaw = getValue<String>('touchpoint_type', 'touchpointType') ?? getValue<String>('type', 'type');
    final reasonRaw = getValue<String>('reason', 'reason');
    final statusRaw = getValue<String>('status', 'status');

    return Touchpoint(
      id: json['id'] ?? '',
      clientId: getValue<String>('client_id', 'clientId') ?? '',
      userId: getValue<String>('user_id', 'userId') ?? getValue<String>('agent_id', 'agentId'),
      touchpointNumber: getValue<int>('touchpoint_number', 'touchpointNumber') ?? 1,
      type: TouchpointType.fromApi(typeRaw ?? 'VISIT'),
      reason: TouchpointReason.fromApi(reasonRaw ?? 'INTERESTED'),
      status: TouchpointStatus.fromApi(statusRaw ?? 'INTERESTED'),
      typeRaw: typeRaw,
      reasonRaw: reasonRaw,
      statusRaw: statusRaw,
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      address: getValue<String>('address', 'address'),
      timeArrival: parseTime(getValue<String>('time_arrival', 'timeArrival')),
      timeDeparture: parseTime(getValue<String>('time_departure', 'timeDeparture')),
      odometerArrival: getValue<String>('odometer_arrival', 'odometerArrival'),
      odometerDeparture: getValue<String>('odometer_departure', 'odometerDeparture'),
      nextVisitDate: parseDateTime(getValue<String>('next_visit_date', 'nextVisitDate')),
      remarks: getValue<String>('notes', 'remarks') ?? getValue<String>('remarks', 'remarks'),
      photoPath: getValue<String>('photo_url', 'photoUrl') ?? getValue<String>('photo_path', 'photoPath'),
      audioPath: getValue<String>('audio_url', 'audioUrl') ?? getValue<String>('audio_path', 'audioPath'),
      latitude: getValue<double>('latitude', 'latitude'),
      longitude: getValue<double>('longitude', 'longitude'),
      timeIn: parseDateTime(getValue<String>('time_in', 'timeIn')),
      timeInGpsLat: getValue<double>('time_in_gps_lat', 'timeInGpsLat'),
      timeInGpsLng: getValue<double>('time_in_gps_lng', 'timeInGpsLng'),
      timeInGpsAddress: getValue<String>('time_in_gps_address', 'timeInGpsAddress'),
      timeOut: parseDateTime(getValue<String>('time_out', 'timeOut')),
      timeOutGpsLat: getValue<double>('time_out_gps_lat', 'timeOutGpsLat'),
      timeOutGpsLng: getValue<double>('time_out_gps_lng', 'timeOutGpsLng'),
      timeOutGpsAddress: getValue<String>('time_out_gps_address', 'timeOutGpsAddress'),
      rejectionReason: getValue<String>('rejection_reason', 'rejectionReason'), // NEW
      updatedAt: parseDateTime(getValue<String>('updated_at', 'updatedAt')),
      createdAt: parseDateTime(getValue<String>('created_at', 'createdAt')) ?? DateTime.now(),
    );
  }

  /// Create Touchpoint from PowerSync/PostgreSQL row (snake_case columns)
  factory Touchpoint.fromRow(Map<String, dynamic> row) {
    // Helper to parse TimeOfDay from string format
    TimeOfDay? parseTime(dynamic value) {
      if (value == null) return null;
      final str = value.toString();
      final parts = str.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      return null;
    }

    // Helper to parse DateTime from various formats
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          // Try parsing with microseconds - remove them: 2026-04-05T22:30:12.123456+00
          try {
            final clean = value.replaceAll(RegExp(r'\.\d+([+-])'), r'$1');
            return DateTime.parse(clean);
          } catch (e2) {
            return null;
          }
        }
      }
      return null;
    }

    // Capture raw values before parsing
    final typeRaw = row['type'] as String?;
    final reasonRaw = row['reason'] as String?;
    final statusRaw = row['status'] as String?;

    return Touchpoint(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String?,
      touchpointNumber: row['touchpoint_number'] as int,
      type: TouchpointType.fromApi(typeRaw ?? 'VISIT'),
      reason: TouchpointReason.fromApi(reasonRaw ?? 'INTERESTED'),
      status: TouchpointStatus.fromApi(statusRaw ?? 'Interested'),
      typeRaw: typeRaw,
      reasonRaw: reasonRaw,
      statusRaw: statusRaw,
      date: row['date'] != null
          ? DateTime.parse(row['date'] as String)
          : DateTime.now(),
      timeArrival: parseTime(row['time_arrival']),
      timeDeparture: parseTime(row['time_departure']),
      remarks: row['notes'] as String?,
      photoPath: row['photo_path'] as String?,
      audioPath: row['audio_path'] as String?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      timeIn: parseDateTime(row['time_in']),
      timeInGpsLat: row['time_in_gps_lat'] as double?,
      timeInGpsLng: row['time_in_gps_lng'] as double?,
      timeInGpsAddress: row['time_in_gps_address'] as String?,
      timeOut: parseDateTime(row['time_out']),
      timeOutGpsLat: row['time_out_gps_lat'] as double?,
      timeOutGpsLng: row['time_out_gps_lng'] as double?,
      timeOutGpsAddress: row['time_out_gps_address'] as String?,
      createdAt: parseDateTime(row['created_at']) ?? DateTime.now(),
    );
  }
}

/// Touchpoint type enum with API-compatible values
/// Backend constraint: CHECK (touchpoint_type IN ('Visit', 'Call'))
enum TouchpointType {
  visit('Visit'),
  call('Call');

  final String _apiValue;
  const TouchpointType(this._apiValue);

  String get apiValue => _apiValue;

  static TouchpointType fromApi(String value) {
    // Handle both title case ('Visit', 'Call') and uppercase ('VISIT', 'CALL')
    // for backward compatibility with any existing uppercase data
    final normalizedValue = value.toLowerCase();
    return TouchpointType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalizedValue ||
              e._apiValue.toLowerCase() == normalizedValue,
      orElse: () => TouchpointType.visit,
    );
  }
}

/// Touchpoint pattern: Visit-Call-Call-Visit-Call-Call-Visit
class TouchpointPattern {
  static const List<TouchpointType> types = [
    TouchpointType.visit,  // 1st
    TouchpointType.call,   // 2nd
    TouchpointType.call,   // 3rd
    TouchpointType.visit,  // 4th
    TouchpointType.call,   // 5th
    TouchpointType.call,   // 6th
    TouchpointType.visit,  // 7th
  ];

  static TouchpointType getType(int touchpointNumber) {
    return types[touchpointNumber - 1];
  }
}

/// Reason types for touchpoints with API-compatible values
enum TouchpointReason {
  abroad('ABROAD'),
  applyMembership('APPLY_MEMBERSHIP'),
  backedOut('BACKED_OUT'),
  ciBi('CI_BI'),
  deceased('DECEASED'),
  disapproved('DISAPPROVED'),
  forAdaCompliance('FOR_ADA_COMPLIANCE'),
  forProcessing('FOR_PROCESSING'),
  forUpdate('FOR_UPDATE'),
  forVerification('FOR_VERIFICATION'),
  inaccessibleArea('INACCESSIBLE_AREA'),
  interested('INTERESTED'),
  loanInquiry('LOAN_INQUIRY'),
  movedOut('MOVED_OUT'),
  notAmenable('NOT_AMENABLE'),
  notAround('NOT_AROUND'),
  notInList('NOT_IN_LIST'),
  notInterested('NOT_INTERESTED'),
  overage('OVERAGE'),
  poorHealth('POOR_HEALTH'),
  returnedAtm('RETURNED_ATM'),
  undecided('UNDECIDED'),
  unlocated('UNLOCATED'),
  withOtherLending('WITH_OTHER_LENDING'),
  interestedButDeclined('INTERESTED_BUT_DECLINED'),
  telemarketing('TELEMARKETING');

  final String _apiValue;
  const TouchpointReason(this._apiValue);

  String get apiValue => _apiValue;

  static TouchpointReason fromApi(String value) {
    return TouchpointReason.values.firstWhere(
      (e) => e._apiValue == value.toUpperCase(),
      orElse: () => TouchpointReason.interested,
    );
  }
}

/// Client touchpoint status from backend API
/// Represents the touchpoint_status object returned by /api/clients endpoints
class ClientTouchpointStatus {
  final int completedTouchpoints;
  final int? nextTouchpointNumber;
  final String? nextTouchpointType; // 'Visit' or 'Call'
  final bool canCreateTouchpoint;
  final String? expectedRole; // 'caravan' or 'tele'
  final bool isComplete;
  final String? lastTouchpointType;
  final String? lastTouchpointAgentName;
  final bool loanReleased;
  final DateTime? loanReleasedAt;

  const ClientTouchpointStatus({
    required this.completedTouchpoints,
    this.nextTouchpointNumber,
    this.nextTouchpointType,
    required this.canCreateTouchpoint,
    this.expectedRole,
    required this.isComplete,
    this.lastTouchpointType,
    this.lastTouchpointAgentName,
    required this.loanReleased,
    this.loanReleasedAt,
  });

  /// Create from backend API response (touchpoint_status object)
  factory ClientTouchpointStatus.fromJson(Map<String, dynamic> json) {
    return ClientTouchpointStatus(
      completedTouchpoints: json['completed_touchpoints'] as int? ?? 0,
      nextTouchpointNumber: json['next_touchpoint_number'] as int?,
      nextTouchpointType: json['next_touchpoint_type'] as String?,
      canCreateTouchpoint: json['can_create_touchpoint'] as bool? ?? false,
      expectedRole: json['expected_role'] as String?,
      isComplete: json['is_complete'] as bool? ?? false,
      lastTouchpointType: json['last_touchpoint_type'] as String?,
      lastTouchpointAgentName: json['last_touchpoint_agent_name'] as String?,
      loanReleased: json['loan_released'] as bool? ?? false,
      loanReleasedAt: json['loan_released_at'] != null
          ? DateTime.parse(json['loan_released_at'] as String)
          : null,
    );
  }

  /// Create from database row (snake_case columns)
  factory ClientTouchpointStatus.fromRow(Map<String, dynamic> row) {
    // Handle both nested touchpoint_status object and flat fields
    final touchpointStatus = row['touchpoint_status'] as Map<String, dynamic>?;

    if (touchpointStatus != null) {
      return ClientTouchpointStatus.fromJson(touchpointStatus);
    }

    // Fallback to flat fields if touchpoint_status not available
    return ClientTouchpointStatus(
      completedTouchpoints: row['completed_touchpoints'] as int? ??
                          (row['touchpoint_number'] as int? ?? 0),
      nextTouchpointNumber: row['next_touchpoint_number'] as int?,
      nextTouchpointType: row['next_touchpoint_type'] as String?,
      canCreateTouchpoint: false, // Will be computed locally if not provided
      expectedRole: null,
      isComplete: (row['touchpoint_number'] as int? ?? 0) >= 7 ||
                  (row['loan_released'] as bool? ?? false),
      lastTouchpointType: row['last_touchpoint_type'] as String?,
      lastTouchpointAgentName: row['last_touchpoint_agent_name'] as String?,
      loanReleased: row['loan_released'] as bool? ?? false,
      loanReleasedAt: row['loan_released_at'] != null
          ? DateTime.parse(row['loan_released_at'] as String)
          : null,
    );
  }
}

/// Touchpoint status enum with API-compatible values
enum TouchpointStatus {
  interested('Interested'),
  undecided('Undecided'),
  notInterested('Not Interested'),
  completed('Completed');

  final String _apiValue;
  const TouchpointStatus(this._apiValue);

  String get apiValue => _apiValue;

  static TouchpointStatus fromApi(String value) {
    return TouchpointStatus.values.firstWhere(
      (e) => e._apiValue == value,
      orElse: () => TouchpointStatus.interested,
    );
  }
}

/// TimeOfDay helper class (since Flutter's TimeOfDay doesn't serialize easily)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  int get hourOfPeriod => hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

  String get period => hour < 12 ? 'AM' : 'PM';

  String format() {
    final h = hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}
