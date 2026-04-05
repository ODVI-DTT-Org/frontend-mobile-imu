import 'package:flutter/foundation.dart';

/// Client data model for IMU app
/// Aligned with database schema - uses direct columns instead of nested lists
class Client {
  final String? id;
  final String firstName;
  final String? middleName;
  final String lastName;
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
  final String? pan;
  final String? email;
  final String? facebookLink;
  final String? agencyId;
  final String? userId; // The user (caravan/tele) who owns this client
  final int? psgcId; // Foreign key to PSGC table (INTEGER in database)
  final String? region; // Region from PSGC (e.g., NCR, Region I)
  final String? province; // Province from PSGC (e.g., Metro Manila, Pangasinan)
  final String? municipality; // Municipality from PSGC
  final String? barangay; // Barangay from PSGC
  final String? udi; // Unified ID
  final List<Touchpoint> touchpoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isStarred;
  final bool loanReleased;
  final DateTime? loanReleasedAt;

  Client({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
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
    this.pan,
    this.email,
    this.facebookLink,
    this.agencyId,
    this.userId,
    this.psgcId,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.udi,
    this.touchpoints = const [],
    required this.createdAt,
    this.updatedAt,
    this.isStarred = false,
    this.loanReleased = false,
    this.loanReleasedAt,
  });

  String get fullName => '$firstName ${middleName != null ? '$middleName ' : ''}$lastName';

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

  int get completedTouchpoints => touchpoints.length;

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

  /// Compatibility getter for addresses - returns list with single address from direct fields
  List<Address> get addresses {
    if (region == null && province == null && municipality == null && barangay == null) {
      return [];
    }
    return [
      Address(
        id: '${id}_primary',
        street: '', // No street field in new schema
        barangay: barangay,
        city: municipality ?? '',
        province: province,
        zipCode: null,
        isPrimary: true,
        latitude: null,
        longitude: null,
      ),
    ];
  }

  /// Compatibility getter for phoneNumbers - returns list with single phone from direct field
  List<PhoneNumber> get phoneNumbers {
    if (phone == null || phone!.isEmpty) {
      return [];
    }
    return [
      PhoneNumber(
        id: '${id}_primary',
        number: phone!,
        label: 'Primary',
        isPrimary: true,
      ),
    ];
  }

  Client copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
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
    String? pan,
    String? email,
    String? facebookLink,
    String? agencyId,
    String? userId,
    int? psgcId,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
    String? udi,
    List<Touchpoint>? touchpoints,
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
      pan: pan ?? this.pan,
      email: email ?? this.email,
      facebookLink: facebookLink ?? this.facebookLink,
      agencyId: agencyId ?? this.agencyId,
      userId: userId ?? this.userId,
      psgcId: psgcId ?? this.psgcId,
      region: region ?? this.region,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
      udi: udi ?? this.udi,
      touchpoints: touchpoints ?? this.touchpoints,
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
      'pan': pan,
      'email': email,
      'facebookLink': facebookLink,
      'agencyId': agencyId,
      'userId': userId,
      'psgcId': psgcId,
      'region': region,
      'province': province,
      'municipality': municipality,
      'barangay': barangay,
      'udi': udi,
      'touchpoints': touchpoints.map((t) => t.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStarred': isStarred,
      'loanReleased': loanReleased,
      'loanReleasedAt': loanReleasedAt?.toIso8601String(),
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? json['first_name'] ?? '',
      middleName: json['middleName'] ?? json['middle_name'],
      lastName: json['lastName'] ?? json['last_name'] ?? '',
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
      clientType: ClientType.values.firstWhere(
        (e) => e.name == json['clientType'] || e.name == json['client_type'],
        orElse: () => ClientType.potential,
      ),
      marketType: json['marketType'] != null || json['market_type'] != null
          ? MarketType.values.firstWhere(
              (e) => e.name == (json['marketType'] ?? json['market_type']),
              orElse: () => MarketType.residential,
            )
          : null,
      productType: ProductType.values.firstWhere(
        (e) => e.name == json['productType'] || e.name == json['product_type'],
        orElse: () => ProductType.sssPensioner,
      ),
      pensionType: PensionType.values.firstWhere(
        (e) => e.name == json['pensionType'] || e.name == json['pension_type'],
        orElse: () => PensionType.none,
      ),
      pan: json['pan'],
      email: json['email'],
      facebookLink: json['facebookLink'] ?? json['facebook_link'],
      agencyId: json['agencyId'] ?? json['agency_id'],
      userId: json['userId'] ?? json['user_id'] ?? json['caravanId'] ?? json['caravan_id'],
      psgcId: json['psgcId'] ?? json['psgc_id'] is int ? json['psgc_id'] : (json['psgc_id'] != null ? int.tryParse(json['psgc_id'].toString()) : null),
      region: json['region'] ?? json['psgc_region'],
      province: json['province'] ?? json['psgc_province'],
      municipality: json['municipality'] ?? json['municipality_id'],
      barangay: json['barangay'] ?? json['psgc_barangay'],
      udi: json['udi'],
      touchpoints: (json['touchpoints'] as List?)?.map((t) => Touchpoint.fromJson(t)).toList() ?? [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null),
      isStarred: json['isStarred'] ?? json['is_starred'] ?? false,
      loanReleased: json['loanReleased'] ?? json['loan_released'] ?? false,
      loanReleasedAt: json['loanReleasedAt'] != null
          ? DateTime.parse(json['loanReleasedAt'])
          : (json['loan_released_at'] != null ? DateTime.parse(json['loan_released_at']) : null),
    );
  }

  /// Create Client from PowerSync/PostgreSQL row (snake_case column names)
  factory Client.fromRow(Map<String, dynamic> row) {
    // Helper to parse ProductType from backend values
    ProductType parseProductType(String? value) {
      if (value == null) return ProductType.sssPensioner;
      final upper = value.toUpperCase();
      if (upper == 'PENSION_LOAN' || upper == 'SSS_PENSION_LOAN') {
        return ProductType.sssPensioner;
      } else if (upper == 'GSIS_PENSION_LOAN') {
        return ProductType.gsisPensioner;
      } else if (upper == 'CASH_LOAN' || upper == 'PRIVATE') {
        return ProductType.private;
      }
      return ProductType.sssPensioner;
    }

    return Client(
      id: row['id'] as String,
      firstName: row['first_name'] as String? ?? '',
      lastName: row['last_name'] as String? ?? '',
      middleName: row['middle_name'] as String?,
      birthDate: row['birth_date'] != null ? DateTime.parse(row['birth_date'] as String) : null,
      email: row['email'] as String?,
      phone: row['phone'] as String?,
      agencyName: row['agency_name'] as String?,
      department: row['department'] as String?,
      position: row['position'] as String?,
      employmentStatus: row['employment_status'] as String?,
      payrollDate: row['payroll_date'] as String?,
      tenure: row['tenure'] as int?,
      clientType: ClientType.values.firstWhere(
        (e) => e.name.toUpperCase() == (row['client_type'] as String?)?.toUpperCase(),
        orElse: () => ClientType.potential,
      ),
      productType: parseProductType(row['product_type'] as String?),
      marketType: row['market_type'] != null
          ? MarketType.values.firstWhere(
              (e) => e.name.toUpperCase() == (row['market_type'] as String).toUpperCase(),
              orElse: () => MarketType.residential,
            )
          : null,
      pensionType: row['pension_type'] != null
          ? PensionType.values.firstWhere(
              (e) => e.name.toUpperCase() == (row['pension_type'] as String).toUpperCase(),
              orElse: () => PensionType.none,
            )
          : PensionType.none,
      pan: row['pan'] as String?,
      facebookLink: row['facebook_link'] as String?,
      remarks: row['remarks'] as String?,
      agencyId: row['agency_id'] as String?,
      userId: row['user_id'] as String? ?? row['caravan_id'] as String?,
      psgcId: row['psgc_id'] as int?,
      region: row['region'] as String?,
      province: row['province'] as String?,
      municipality: row['municipality'] as String?,
      barangay: row['barangay'] as String?,
      udi: row['udi'] as String?,
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
  sssPensioner,
  gsisPensioner,
  private,
}

enum PensionType {
  sss,
  gsis,
  private,
  none,
}

class Address {
  final String id;
  final String street;
  final String? barangay;
  final String city;
  final String? province;
  final String? zipCode;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.street,
    this.barangay,
    required this.city,
    this.province,
    this.zipCode,
    this.isPrimary = false,
    this.latitude,
    this.longitude,
  });

  String get fullAddress {
    final parts = [street];
    if (barangay != null) parts.add(barangay!);
    parts.add(city);
    if (province != null) parts.add(province!);
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'barangay': barangay,
    'city': city,
    'province': province,
    'zipCode': zipCode,
    'isPrimary': isPrimary,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] ?? '',
    street: json['street'] ?? '',
    barangay: json['barangay'],
    city: json['city'] ?? '',
    province: json['province'],
    zipCode: json['zipCode'],
    isPrimary: json['isPrimary'] ?? false,
    latitude: json['latitude'],
    longitude: json['longitude'],
  );
}

class PhoneNumber {
  final String id;
  final String number;
  final String? label;
  final bool isPrimary;

  PhoneNumber({
    required this.id,
    required this.number,
    this.label,
    this.isPrimary = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'label': label,
    'isPrimary': isPrimary,
  };

  factory PhoneNumber.fromJson(Map<String, dynamic> json) => PhoneNumber(
    id: json['id'] ?? '',
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
  final DateTime date;
  final String? address;
  final TimeOfDay? timeArrival;
  final TimeOfDay? timeDeparture;
  final String? odometerArrival;
  final String? odometerDeparture;
  final TouchpointReason reason;
  final TouchpointStatus status; // New: status field (Interested, Undecided, Not Interested, Completed)
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
    required this.date,
    this.address,
    this.timeArrival,
    this.timeDeparture,
    this.odometerArrival,
    this.odometerDeparture,
    required this.reason,
    this.status = TouchpointStatus.interested, // Default status
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
    DateTime? date,
    String? address,
    TimeOfDay? timeArrival,
    TimeOfDay? timeDeparture,
    String? odometerArrival,
    String? odometerDeparture,
    TouchpointReason? reason,
    TouchpointStatus? status,
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
      date: date ?? this.date,
      address: address ?? this.address,
      timeArrival: timeArrival ?? this.timeArrival,
      timeDeparture: timeDeparture ?? this.timeDeparture,
      odometerArrival: odometerArrival ?? this.odometerArrival,
      odometerDeparture: odometerDeparture ?? this.odometerDeparture,
      reason: reason ?? this.reason,
      status: status ?? this.status,
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
    'created_at': createdAt.toIso8601String(),
  };

  /// Parse from API format (snake_case) or local format (camelCase)
  factory Touchpoint.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      return (json[snakeCase] ?? json[camelCase]) as T?;
    }

    return Touchpoint(
      id: json['id'] ?? '',
      clientId: getValue<String>('client_id', 'clientId') ?? '',
      userId: getValue<String>('user_id', 'userId') ?? getValue<String>('agent_id', 'agentId'),
      touchpointNumber: getValue<int>('touchpoint_number', 'touchpointNumber') ?? 1,
      type: TouchpointType.fromApi(getValue<String>('type', 'type') ?? 'VISIT'),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      address: getValue<String>('address', 'address'),
      timeArrival: parseTime(getValue<String>('time_arrival', 'timeArrival')),
      timeDeparture: parseTime(getValue<String>('time_departure', 'timeDeparture')),
      odometerArrival: getValue<String>('odometer_start', 'odometerArrival'),
      odometerDeparture: getValue<String>('odometer_end', 'odometerDeparture'),
      reason: TouchpointReason.fromApi(getValue<String>('reason', 'reason') ?? 'INTERESTED'),
      status: TouchpointStatus.fromApi(getValue<String>('status', 'status') ?? 'INTERESTED'),
      nextVisitDate: parseDateTime(getValue<String>('next_visit_date', 'nextVisitDate')),
      remarks: getValue<String>('notes', 'remarks'),
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
