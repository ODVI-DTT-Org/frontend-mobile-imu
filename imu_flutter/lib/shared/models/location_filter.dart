class LocationFilter {
  final String? province;
  final List<String>? municipalities;
  final List<String>? barangays;
  final String? addressQuery;

  const LocationFilter({
    this.province,
    this.municipalities,
    this.barangays,
    this.addressQuery,
  });

  bool get hasFilter =>
      province != null ||
      (barangays != null && barangays!.isNotEmpty) ||
      (addressQuery != null && addressQuery!.trim().isNotEmpty);

  static LocationFilter none() => const LocationFilter();

  static const _absent = Object();

  LocationFilter copyWith({
    Object? province = _absent,
    Object? municipalities = _absent,
    Object? barangays = _absent,
    Object? addressQuery = _absent,
  }) {
    return LocationFilter(
      province: identical(province, _absent) ? this.province : province as String?,
      municipalities: identical(municipalities, _absent) ? this.municipalities : municipalities as List<String>?,
      barangays: identical(barangays, _absent) ? this.barangays : barangays as List<String>?,
      addressQuery: identical(addressQuery, _absent) ? this.addressQuery : addressQuery as String?,
    );
  }

  Map<String, String> toQueryParams() {
    if (!hasFilter) return {};

    final params = <String, String>{};

    if (province != null && province!.isNotEmpty) {
      params['province'] = province!;
    }

    if (municipalities != null && municipalities!.isNotEmpty) {
      params['municipality'] = municipalities!.join(',');
    }

    if (barangays != null && barangays!.isNotEmpty) {
      params['barangay'] = barangays!.join(',');
    }

    final query = addressQuery?.trim();
    if (query != null && query.isNotEmpty) {
      params['address_search'] = query;
    }

    return params;
  }

  bool matchesClientAddress({
    Object? fullAddress,
    Object? region,
    Object? province,
    Object? municipality,
    Object? barangay,
    Object? addressBarangay,
    Object? addressCity,
    Object? addressProvince,
  }) {
    final query = addressQuery?.trim().toLowerCase();
    if (query == null || query.isEmpty) return true;

    final haystack = [
      fullAddress,
      region,
      province,
      municipality,
      barangay,
      addressBarangay,
      addressCity,
      addressProvince,
    ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(' ')
        .toLowerCase();

    if (haystack.isEmpty) return false;
    return query
        .split(RegExp(r'\s+'))
        .where((word) => word.length >= 2)
        .every(haystack.contains);
  }

  String getDisplayLabel() {
    final parts = <String>[];
    if (province != null) parts.add(province!);

    if (municipalities == null || municipalities!.isEmpty) {
      if (barangays != null && barangays!.isNotEmpty) {
        parts.add(barangays!.length == 1
            ? barangays!.first
            : '${barangays!.length} barangays');
      }
      if (addressQuery != null && addressQuery!.trim().isNotEmpty) {
        parts.add('"${addressQuery!.trim()}"');
      }
      return parts.join(' • ');
    }

    if (municipalities!.length == 1) {
      parts.add(municipalities!.first);
      if (barangays != null && barangays!.isNotEmpty) {
        parts.add(barangays!.length == 1
            ? barangays!.first
            : '${barangays!.length} barangays');
      }
      if (addressQuery != null && addressQuery!.trim().isNotEmpty) {
        parts.add('"${addressQuery!.trim()}"');
      }
      return parts.join(' • ');
    }

    final firstTwo = municipalities!.take(2).join(', ');
    final remaining = municipalities!.length - 2;

    if (remaining > 0) {
      parts.add('$firstTwo (+$remaining)');
      if (addressQuery != null && addressQuery!.trim().isNotEmpty) {
        parts.add('"${addressQuery!.trim()}"');
      }
      return parts.join(' • ');
    }

    parts.add(firstTwo);
    if (addressQuery != null && addressQuery!.trim().isNotEmpty) {
      parts.add('"${addressQuery!.trim()}"');
    }
    return parts.join(' • ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationFilter &&
        other.province == province &&
        _listEquals(other.municipalities, municipalities) &&
        _listEquals(other.barangays, barangays) &&
        other.addressQuery == addressQuery;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        province,
        Object.hashAll(municipalities ?? []),
        Object.hashAll(barangays ?? []),
        addressQuery,
      );

  @override
  String toString() =>
      'LocationFilter(province: $province, municipalities: $municipalities, barangays: $barangays, addressQuery: $addressQuery)';
}
