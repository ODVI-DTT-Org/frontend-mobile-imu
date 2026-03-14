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
  final String? contactNumber;
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
    this.contactNumber,
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
    String? contactNumber,
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
      contactNumber: contactNumber ?? this.contactNumber,
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
      'contactNumber': contactNumber,
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
      contactNumber: json['contactNumber'],
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'touchpointNumber': touchpointNumber,
    'type': type.name,
    'date': date.toIso8601String(),
    'address': address,
    'timeArrival': timeArrival != null ? '${timeArrival!.hour}:${timeArrival!.minute}' : null,
    'timeDeparture': timeDeparture != null ? '${timeDeparture!.hour}:${timeDeparture!.minute}' : null,
    'odometerArrival': odometerArrival,
    'odometerDeparture': odometerDeparture,
    'reason': reason.name,
    'nextVisitDate': nextVisitDate?.toIso8601String(),
    'remarks': remarks,
    'photoPath': photoPath,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Touchpoint.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? time) {
      if (time == null) return null;
      final parts = time.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Touchpoint(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      touchpointNumber: json['touchpointNumber'] ?? 1,
      type: TouchpointType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TouchpointType.visit,
      ),
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      address: json['address'],
      timeArrival: parseTime(json['timeArrival']),
      timeDeparture: parseTime(json['timeDeparture']),
      odometerArrival: json['odometerArrival'],
      odometerDeparture: json['odometerDeparture'],
      reason: TouchpointReason.values.firstWhere(
        (e) => e.name == json['reason'],
        orElse: () => TouchpointReason.interested,
      ),
      nextVisitDate: json['nextVisitDate'] != null ? DateTime.parse(json['nextVisitDate']) : null,
      remarks: json['remarks'],
      photoPath: json['photoPath'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

enum TouchpointType {
  visit,
  call,
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

/// Reason types for touchpoints
enum TouchpointReason {
  abroad,
  applyMembership,
  backedOut,
  ciBi,
  deceased,
  disapproved,
  forAdaCompliance,
  forProcessing,
  forUpdate,
  forVerification,
  inaccessibleArea,
  interested,
  loanInquiry,
  movedOut,
  notAmenable,
  notAround,
  notInList,
  notInterested,
  overage,
  poorHealth,
  returnedAtm,
  undecided,
  unlocated,
  withOtherLending,
  interestedButDeclined,
  telemarketing,
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
