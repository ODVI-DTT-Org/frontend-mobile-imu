const noAddressAvailableText = 'No address available';

String? cleanAddressPart(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

String? joinAddressParts(Iterable<Object?> values) {
  final parts = values
      .map(cleanAddressPart)
      .whereType<String>()
      .toList();
  if (parts.isEmpty) return null;
  return parts.join(', ');
}

bool isPrimaryAddressValue(Object? value) {
  if (value is bool) return value;
  if (value is num) return value == 1;
  final text = cleanAddressPart(value)?.toLowerCase();
  return text == 'true' || text == '1';
}

Map<String, dynamic>? selectPrimaryAddressMap(Object? addresses) {
  if (addresses is! List || addresses.isEmpty) return null;
  final maps = addresses
      .whereType<Map>()
      .map((address) => Map<String, dynamic>.from(address))
      .toList();
  if (maps.isEmpty) return null;
  return maps.firstWhere(
    (address) => isPrimaryAddressValue(address['is_primary'] ?? address['isPrimary']),
    orElse: () => maps.first,
  );
}

String? resolveAddressDisplay({
  Object? fullAddress,
  Object? region,
  Object? province,
  Object? municipality,
  Object? barangay,
  Object? street,
  Object? addressStreet,
  Object? addressBarangay,
  Object? addressCity,
  Object? addressProvince,
  Object? fallbackAddress,
}) {
  // Selected primary address from the client's address list.
  final primaryAddress = joinAddressParts([
    addressStreet,
    addressBarangay,
    addressCity,
    addressProvince,
  ]);
  if (primaryAddress != null) return primaryAddress;

  final direct = cleanAddressPart(fullAddress);
  if (direct != null) return direct;

  // Client PSGC fields, broad to specific, skip empty parts.
  final clientLocation = joinAddressParts([
    region,
    province,
    municipality,
    barangay,
    street,
  ]);
  if (clientLocation != null) return clientLocation;

  return cleanAddressPart(fallbackAddress);
}

String resolveAddressDisplayOrFallback({
  Object? fullAddress,
  Object? region,
  Object? province,
  Object? municipality,
  Object? barangay,
  Object? street,
  Object? addressStreet,
  Object? addressBarangay,
  Object? addressCity,
  Object? addressProvince,
  Object? fallbackAddress,
}) {
  return resolveAddressDisplay(
        fullAddress: fullAddress,
        region: region,
        province: province,
        municipality: municipality,
        barangay: barangay,
        street: street,
        addressStreet: addressStreet,
        addressBarangay: addressBarangay,
        addressCity: addressCity,
        addressProvince: addressProvince,
        fallbackAddress: fallbackAddress,
      ) ??
      noAddressAvailableText;
}

String? resolveAddressDisplayFromRow(Map<String, dynamic> row) {
  return resolveAddressDisplay(
    fullAddress: row['full_address'],
    region: row['region'],
    province: row['province'],
    municipality: row['municipality'],
    barangay: row['barangay'],
    street: row['street'],
    addressStreet: row['address_street'],
    addressBarangay: row['address_barangay'],
    addressCity: row['address_city'],
    addressProvince: row['address_province'],
    fallbackAddress: row['address'],
  );
}
