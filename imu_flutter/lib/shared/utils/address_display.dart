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

String? resolveAddressDisplay({
  Object? fullAddress,
  Object? region,
  Object? province,
  Object? municipality,
  Object? barangay,
  Object? addressStreet,
  Object? addressBarangay,
  Object? addressCity,
  Object? addressProvince,
  Object? fallbackAddress,
}) {
  final direct = cleanAddressPart(fullAddress);
  if (direct != null) return direct;

  final addressLookup = joinAddressParts([
    addressStreet,
    addressBarangay,
    addressCity,
    addressProvince,
  ]);
  if (addressLookup != null) return addressLookup;

  final clientLocation = joinAddressParts([
    region,
    province,
    municipality,
    barangay,
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
    addressStreet: row['address_street'],
    addressBarangay: row['address_barangay'],
    addressCity: row['address_city'],
    addressProvince: row['address_province'],
    fallbackAddress: row['address'],
  );
}
