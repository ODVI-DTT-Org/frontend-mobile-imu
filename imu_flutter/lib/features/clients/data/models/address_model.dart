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
      if (barangay != null && barangay!.isNotEmpty) 'Brgy. $barangay!',
      if (municipality != null && municipality!.isNotEmpty) municipality!,
      if (province != null && province!.isNotEmpty) province!,
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }

  // Factory from PowerSync database row
  factory Address.fromSyncMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      clientId: map['client_id'] as String,
      psgcId: map['psgc_id'] as int,
      label: AddressLabel.fromString(map['label'] as String? ?? 'other'),
      streetAddress: map['street_address'] as String? ?? '',
      postalCode: map['postal_code'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      isPrimary: (map['is_primary'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updated_at'] as String? ?? DateTime.now().toIso8601String()),
      region: map['region'] as String?,
      province: map['province'] as String?,
      municipality: map['municipality'] as String?,
      barangay: map['barangay'] as String?,
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

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'psgc_id': psgcId,
      'label': label.name,
      'street_address': streetAddress,
      if (postalCode != null) 'postal_code': postalCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_primary': isPrimary,
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
