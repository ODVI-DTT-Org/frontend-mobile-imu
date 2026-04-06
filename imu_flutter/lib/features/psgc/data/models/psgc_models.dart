/// PSGC (Philippine Standard Geographic Code) models
///
/// Note: These models now derive data from the single 'psgc' table synced by PowerSync
/// instead of separate view tables. The single table has: id, region, province, mun_city_kind, mun_city, barangay, zip_code

/// Region model
class PsgcRegion {
  final String name;
  final String code;

  PsgcRegion({
    required this.name,
    required this.code,
  });

  // For backward compatibility with fromJson
  factory PsgcRegion.fromJson(Map<String, dynamic> json) {
    return PsgcRegion(
      name: json['name'] ?? json['region'] ?? '',
      code: json['code'] ?? json['region'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
  };
}

/// Province model
class PsgcProvince {
  final String name;
  final String code;
  final String region;
  final String? kind;
  final bool? isCity;

  PsgcProvince({
    required this.name,
    required this.code,
    required this.region,
    this.kind,
    this.isCity,
  });

  // For backward compatibility with fromJson
  factory PsgcProvince.fromJson(Map<String, dynamic> json) {
    return PsgcProvince(
      name: json['name'] ?? json['province'] ?? '',
      code: json['code'] ?? json['province'] ?? '',
      region: json['region'] ?? '',
      kind: json['kind'],
      isCity: json['is_city'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'region': region,
    if (kind != null) 'kind': kind,
    if (isCity != null) 'is_city': isCity,
  };
}

/// Municipality/City model
class PsgcMunicipality {
  final String name;
  final String displayName;
  final String province;
  final String region;
  final String? kind;
  final bool? isCity;

  PsgcMunicipality({
    required this.name,
    required this.displayName,
    required this.province,
    required this.region,
    this.kind,
    this.isCity,
  });

  // For backward compatibility with fromJson
  factory PsgcMunicipality.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? json['mun_city'] ?? '';
    return PsgcMunicipality(
      name: name,
      displayName: json['display_name'] ?? json['displayName'] ?? name,
      province: json['province'] ?? '',
      region: json['region'] ?? '',
      kind: json['kind'],
      isCity: json['is_city'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'display_name': displayName,
    'province': province,
    'region': region,
    if (kind != null) 'kind': kind,
    if (isCity != null) 'is_city': isCity,
  };
}

/// Barangay model
class PsgcBarangay {
  final String id;
  final String? region;
  final String? province;
  final String? municipality;
  final String? barangay;
  final String? municipalityKind;
  final String? zipCode;
  final Map<String, dynamic>? pinLocation;

  PsgcBarangay({
    required this.id,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.municipalityKind,
    this.zipCode,
    this.pinLocation,
  });

  factory PsgcBarangay.fromJson(Map<String, dynamic> json) {
    return PsgcBarangay(
      id: json['id'].toString(),
      region: json['region'],
      province: json['province'],
      municipality: json['municipality'],
      barangay: json['barangay'],
      municipalityKind: json['municipality_kind'] ?? json['mun_city_kind'],
      zipCode: json['zip_code'],
      pinLocation: json['pin_location'],
    );
  }

  /// Get full address string
  String get fullAddress {
    final parts = [barangay, municipality, province, region].whereType<String>();
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    if (region != null) 'region': region,
    if (province != null) 'province': province,
    if (municipality != null) 'municipality': municipality,
    if (barangay != null) 'barangay': barangay,
    if (municipalityKind != null) 'municipality_kind': municipalityKind,
    if (zipCode != null) 'zip_code': zipCode,
    if (pinLocation != null) 'pin_location': pinLocation,
  };
}
