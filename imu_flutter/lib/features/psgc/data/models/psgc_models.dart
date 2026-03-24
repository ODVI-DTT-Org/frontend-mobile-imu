/// PSGC (Philippine Standard Geographic Code) models
///
/// Matches views from migration 010:
/// - psgc_regions
/// - psgc_provinces
/// - psgc_municipalities
/// - psgc_barangays

/// Region model
class PsgcRegion {
  final String id;
  final String name;
  final String code;

  PsgcRegion({
    required this.id,
    required this.name,
    required this.code,
  });

  factory PsgcRegion.fromJson(Map<String, dynamic> json) {
    return PsgcRegion(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
  };
}

/// Province model
class PsgcProvince {
  final String id;
  final String region;
  final String name;
  final String kind;
  final bool isCity;

  PsgcProvince({
    required this.id,
    required this.region,
    required this.name,
    required this.kind,
    required this.isCity,
  });

  factory PsgcProvince.fromJson(Map<String, dynamic> json) {
    return PsgcProvince(
      id: json['id'].toString(),
      region: json['region'] ?? '',
      name: json['name'] ?? '',
      kind: json['kind'] ?? '',
      isCity: json['is_city'] == true || json['is_city'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'region': region,
    'name': name,
    'kind': kind,
    'is_city': isCity,
  };
}

/// Municipality/City model
class PsgcMunicipality {
  final String id;
  final String region;
  final String province;
  final String name;
  final String kind; // 'mun' or 'city'
  final bool isCity;

  PsgcMunicipality({
    required this.id,
    required this.region,
    required this.province,
    required this.name,
    required this.kind,
    required this.isCity,
  });

  factory PsgcMunicipality.fromJson(Map<String, dynamic> json) {
    return PsgcMunicipality(
      id: json['id'].toString(),
      region: json['region'] ?? '',
      province: json['province'] ?? '',
      name: json['name'] ?? '',
      kind: json['kind'] ?? '',
      isCity: json['is_city'] == true || json['is_city'] == 1,
    );
  }

  /// Get display name (with City/Municipality suffix)
  String get displayName {
    if (isCity) {
      return '$name City';
    }
    return name;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'region': region,
    'province': province,
    'name': name,
    'kind': kind,
    'is_city': isCity,
  };
}

/// Barangay model
class PsgcBarangay {
  final String id;
  final String region;
  final String province;
  final String municipality;
  final String barangay;
  final String? zipCode;
  final Map<String, dynamic>? pinLocation;

  PsgcBarangay({
    required this.id,
    required this.region,
    required this.province,
    required this.municipality,
    required this.barangay,
    this.zipCode,
    this.pinLocation,
  });

  factory PsgcBarangay.fromJson(Map<String, dynamic> json) {
    return PsgcBarangay(
      id: json['id'].toString(),
      region: json['region'] ?? '',
      province: json['province'] ?? '',
      municipality: json['municipality'] ?? '',
      barangay: json['barangay'] ?? '',
      zipCode: json['zip_code'],
      pinLocation: json['pin_location'],
    );
  }

  /// Get full address string
  String get fullAddress {
    final parts = [barangay, municipality, province, region];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'region': region,
    'province': province,
    'municipality': municipality,
    'barangay': barangay,
    'zip_code': zipCode,
    'pin_location': pinLocation,
  };
}
