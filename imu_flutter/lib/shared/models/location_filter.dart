class LocationFilter {
  final String? province;
  final List<String>? municipalities;

  const LocationFilter({
    this.province,
    this.municipalities,
  });

  bool get hasFilter => province != null;

  static LocationFilter none() => const LocationFilter();

  LocationFilter copyWith({
    String? province,
    List<String>? municipalities,
  }) {
    return LocationFilter(
      province: province ?? this.province,
      municipalities: municipalities ?? this.municipalities,
    );
  }

  Map<String, String> toQueryParams() {
    if (!hasFilter) return {};

    final params = <String, String>{'province': province!};

    if (municipalities != null && municipalities!.isNotEmpty) {
      params['municipality'] = municipalities!.join(',');
    }

    return params;
  }

  String getDisplayLabel() {
    if (province == null) return '';

    if (municipalities == null || municipalities!.isEmpty) {
      return province!;
    }

    if (municipalities!.length == 1) {
      return '$province • ${municipalities!.first}';
    }

    final firstTwo = municipalities!.take(2).join(', ');
    final remaining = municipalities!.length - 2;

    if (remaining > 0) {
      return '$province • $firstTwo (+$remaining)';
    }

    return '$province • $firstTwo';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationFilter &&
        other.province == province &&
        _listEquals(other.municipalities, municipalities);
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
  int get hashCode => Object.hash(province, Object.hashAll(municipalities ?? []));

  @override
  String toString() => 'LocationFilter(province: $province, municipalities: $municipalities)';
}
