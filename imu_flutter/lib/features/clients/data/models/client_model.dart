/// Client data model for IMU app
class Client {
  final String id;
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
  final String? phone; // Changed from contactNumber to match PocketBase schema
  final String? remarks;
  final ClientType clientType;
  final MarketType? marketType;
  final ProductType productType;
  final PensionType pensionType;
  final String? pan;
  final String? email;
  final String? facebookLink;
  final List<Address> addresses;
  final List<PhoneNumber> phoneNumbers;
  final List<Touchpoint> touchpoints;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isStarred;

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
    this.addresses = const [],
    this.phoneNumbers = const [],
    this.touchpoints = const [],
    required this.createdAt,
    this.updatedAt,
    this.isStarred = false,
  });

  String get fullName => '$firstName ${middleName != null ? '$middleName ' : ''}$lastName';

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
    List<Address>? addresses,
    List<PhoneNumber>? phoneNumbers,
    List<Touchpoint>? touchpoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isStarred,
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
      addresses: addresses ?? this.addresses,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      touchpoints: touchpoints ?? this.touchpoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isStarred: isStarred ?? this.isStarred,
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
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'phoneNumbers': phoneNumbers.map((p) => p.toJson()).toList(),
      'touchpoints': touchpoints.map((t) => t.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isStarred': isStarred,
    };
  }

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      middleName: json['middleName'],
      lastName: json['lastName'] ?? '',
      agencyName: json['agencyName'],
      department: json['department'],
      position: json['position'],
      employmentStatus: json['employmentStatus'],
      payrollDate: json['payrollDate'],
      tenure: json['tenure'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      phone: json['phone'] ?? json['contactNumber'] ?? json['phone_number'],
      remarks: json['remarks'],
      clientType: ClientType.values.firstWhere(
        (e) => e.name == json['clientType'],
        orElse: () => ClientType.potential,
      ),
      marketType: json['marketType'] != null
          ? MarketType.values.firstWhere(
              (e) => e.name == json['marketType'],
              orElse: () => MarketType.residential,
            )
          : null,
      productType: ProductType.values.firstWhere(
        (e) => e.name == json['productType'],
        orElse: () => ProductType.sssPensioner,
      ),
      pensionType: PensionType.values.firstWhere(
        (e) => e.name == json['pensionType'],
        orElse: () => PensionType.none,
      ),
      pan: json['pan'],
      email: json['email'],
      facebookLink: json['facebookLink'],
      addresses: (json['addresses'] as List?)?.map((a) => Address.fromJson(a)).toList() ?? [],
      phoneNumbers: (json['phoneNumbers'] as List?)?.map((p) => PhoneNumber.fromJson(p)).toList() ?? [],
      touchpoints: (json['touchpoints'] as List?)?.map((t) => Touchpoint.fromJson(t)).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isStarred: json['isStarred'] ?? false,
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
  final String? agentId; // The agent/caravan who created this touchpoint
  final int touchpointNumber; // 1-7
  final TouchpointType type;
  final DateTime date;
  final String? address;
  final TimeOfDay? timeArrival;
  final TimeOfDay? timeDeparture;
  final String? odometerArrival;
  final String? odometerDeparture;
  final TouchpointReason reason;
  final DateTime? nextVisitDate;
  final String? remarks;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Touchpoint({
    required this.id,
    required this.clientId,
    this.agentId,
    required this.touchpointNumber,
    required this.type,
    required this.date,
    this.address,
    this.timeArrival,
    this.timeDeparture,
    this.odometerArrival,
    this.odometerDeparture,
    required this.reason,
    this.nextVisitDate,
    this.remarks,
    this.photoPath,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  String get ordinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[touchpointNumber - 1];
  }

  /// Convert to PocketBase format (snake_case)
  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'agent_id': agentId,
    'touchpoint_number': touchpointNumber,
    'type': type.pocketBaseValue,
    'date': date.toIso8601String(),
    'address': address,
    'time_arrival': timeArrival != null
        ? '${timeArrival!.hour.toString().padLeft(2, '0')}:${timeArrival!.minute.toString().padLeft(2, '0')}'
        : null,
    'time_departure': timeDeparture != null
        ? '${timeDeparture!.hour.toString().padLeft(2, '0')}:${timeDeparture!.minute.toString().padLeft(2, '0')}'
        : null,
    'odometer_start': odometerArrival,
    'odometer_end': odometerDeparture,
    'reason': reason.pocketBaseValue,
    'next_visit_date': nextVisitDate?.toIso8601String(),
    'notes': remarks,
    'photo_path': photoPath,
    'latitude': latitude,
    'longitude': longitude,
    'created': createdAt.toIso8601String(),
  };

  /// Parse from PocketBase format (snake_case) or local format (camelCase)
  factory Touchpoint.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    // Helper to get value from either snake_case or camelCase
    T? getValue<T>(String snakeCase, String camelCase) {
      return (json[snakeCase] ?? json[camelCase]) as T?;
    }

    return Touchpoint(
      id: json['id'] ?? '',
      clientId: getValue<String>('client_id', 'clientId') ?? '',
      agentId: getValue<String>('agent_id', 'agentId'),
      touchpointNumber: getValue<int>('touchpoint_number', 'touchpointNumber') ?? 1,
      type: TouchpointType.fromPocketBase(getValue<String>('type', 'type') ?? 'VISIT'),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      address: getValue<String>('address', 'address'),
      timeArrival: parseTime(getValue<String>('time_arrival', 'timeArrival')),
      timeDeparture: parseTime(getValue<String>('time_departure', 'timeDeparture')),
      odometerArrival: getValue<String>('odometer_start', 'odometerArrival'),
      odometerDeparture: getValue<String>('odometer_end', 'odometerDeparture'),
      reason: TouchpointReason.fromPocketBase(getValue<String>('reason', 'reason') ?? 'INTERESTED'),
      nextVisitDate: getValue<String>('next_visit_date', 'nextVisitDate') != null
          ? DateTime.parse(getValue<String>('next_visit_date', 'nextVisitDate')!)
          : null,
      remarks: getValue<String>('notes', 'remarks'),
      photoPath: getValue<String>('photo_path', 'photoPath'),
      latitude: getValue<double>('latitude', 'latitude'),
      longitude: getValue<double>('longitude', 'longitude'),
      createdAt: getValue<String>('created', 'createdAt') != null
          ? DateTime.parse(getValue<String>('created', 'createdAt')!)
          : DateTime.now(),
    );
  }
}

/// Touchpoint type enum with PocketBase-compatible values
enum TouchpointType {
  visit('VISIT'),
  call('CALL');

  final String _pocketBaseValue;
  const TouchpointType(this._pocketBaseValue);

  String get pocketBaseValue => _pocketBaseValue;

  static TouchpointType fromPocketBase(String value) {
    return TouchpointType.values.firstWhere(
      (e) => e._pocketBaseValue == value.toUpperCase(),
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

/// Reason types for touchpoints with PocketBase-compatible values
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

  final String _pocketBaseValue;
  const TouchpointReason(this._pocketBaseValue);

  String get pocketBaseValue => _pocketBaseValue;

  static TouchpointReason fromPocketBase(String value) {
    return TouchpointReason.values.firstWhere(
      (e) => e._pocketBaseValue == value.toUpperCase(),
      orElse: () => TouchpointReason.interested,
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
