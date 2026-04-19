import 'client_model.dart';

enum AddressLabel {
  home('Home'),
  work('Work'),
  relative('Relative'),
  other('Other');

  final String displayName;
  const AddressLabel(this.displayName);

  static AddressLabel fromString(String value) {
    return AddressLabel.values.firstWhere(
      (label) => label.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AddressLabel.other,
    );
  }
}

class Address {
  final String id;
  final String clientId;
  final int psgcId;
  final AddressLabel label;
  final String streetAddress;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  // PSGC data (joined from PSGC table)
  final String? region;
  final String? province;
  final String? municipality;
  final String? barangay;

  Address({
    required this.id,
    required this.clientId,
    required this.psgcId,
    required this.label,
    required this.streetAddress,
    this.postalCode,
    this.latitude,
    this.longitude,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
  });

  // Computed full address
  String get fullAddress {
    final parts = <String>[
      streetAddress,
      if (barangay != null && barangay!.isNotEmpty) 'Brgy. ${barangay!}',
      if (municipality != null && municipality!.isNotEmpty) municipality!,
      if (province != null && province!.isNotEmpty) province!,
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  // Factory from PowerSync database row (PostgreSQL column names)
  factory Address.fromSyncMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      psgcId: 0, // not stored in addresses table
      label: AddressLabel.fromString(map['type'] as String? ?? 'other'),
      streetAddress: map['street'] as String? ?? '',
      postalCode: map['postal_code'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isPrimary: (map['is_primary'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.now(),
      province: map['province'] as String?,
      municipality: map['city'] as String?,
      barangay: map['barangay'] as String?,
    );
  }

  // Factory from API response JSON (same field names as fromSyncMap)
  factory Address.fromJson(Map<String, dynamic> json) {
    final isPrimaryRaw = json['is_primary'];
    final isPrimary = isPrimaryRaw is bool
        ? isPrimaryRaw
        : (isPrimaryRaw is int ? isPrimaryRaw == 1 : false);
    return Address(
      id: json['id'] as String? ?? '',
      clientId: json['client_id'] as String? ?? '',
      psgcId: 0,
      label: AddressLabel.fromString(json['type'] as String? ?? 'other'),
      streetAddress: json['street'] as String? ?? '',
      postalCode: json['postal_code'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      isPrimary: isPrimary,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      province: json['province'] as String?,
      municipality: json['city'] as String?,
      barangay: json['barangay'] as String?,
    );
  }

  // Factory from legacy client fields
  factory Address.fromLegacyFields(Client client) {
    return Address(
      id: 'legacy_${client.id}',
      clientId: client.id ?? '',
      psgcId: client.psgcId ?? 0,
      label: AddressLabel.home,
      streetAddress: '', // No address field in Client model
      postalCode: null,
      latitude: null,
      longitude: null,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      region: client.region,
      province: client.province,
      municipality: client.municipality,
      barangay: client.barangay,
    );
  }

  // Convert to JSON (includes id/client_id for local cache; safe to use for API too)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'type': label.name,
      'street': streetAddress,
      if (barangay != null) 'barangay': barangay,
      if (municipality != null) 'city': municipality,
      if (province != null) 'province': province,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with method
  Address copyWith({
    String? id,
    String? clientId,
    int? psgcId,
    AddressLabel? label,
    String? streetAddress,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? region,
    String? province,
    String? municipality,
    String? barangay,
  }) {
    return Address(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      psgcId: psgcId ?? this.psgcId,
      label: label ?? this.label,
      streetAddress: streetAddress ?? this.streetAddress,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      region: region ?? this.region,
      province: province ?? this.province,
      municipality: municipality ?? this.municipality,
      barangay: barangay ?? this.barangay,
    );
  }

  @override
  String toString() {
    return 'Address(id: $id, label: $label, fullAddress: $fullAddress, isPrimary: $isPrimary)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
