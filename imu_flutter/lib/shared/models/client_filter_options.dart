const _kDefaultClientTypes  = ['POTENTIAL', 'EXISTING'];
const _kDefaultMarketTypes  = ['RESIDENTIAL', 'COMMERCIAL', 'INDUSTRIAL'];
const _kDefaultPensionTypes = ['SSS', 'GSIS', 'PRIVATE', 'NONE'];
const _kDefaultProductTypes = ['BFP ACTIVE', 'BFP PENSION', 'PNP PENSION', 'NAPOLCOM', 'BFP STP'];

class ClientFilterOptions {
  final List<String> clientTypes;
  final List<String> marketTypes;
  final List<String> pensionTypes;
  final List<String> productTypes;

  const ClientFilterOptions({
    this.clientTypes = const [],
    this.marketTypes = const [],
    this.pensionTypes = const [],
    this.productTypes = const [],
  });

  /// Returns options merged with hardcoded defaults — any empty list is filled
  /// with known-valid values so the filter UI always shows something.
  ClientFilterOptions withFallbackDefaults() => ClientFilterOptions(
    clientTypes:  clientTypes.isNotEmpty  ? clientTypes  : _kDefaultClientTypes,
    marketTypes:  marketTypes.isNotEmpty  ? marketTypes  : _kDefaultMarketTypes,
    pensionTypes: pensionTypes.isNotEmpty ? pensionTypes : _kDefaultPensionTypes,
    productTypes: productTypes.isNotEmpty ? productTypes : _kDefaultProductTypes,
  );

  bool get isNotEmpty =>
      clientTypes.isNotEmpty ||
      marketTypes.isNotEmpty ||
      pensionTypes.isNotEmpty ||
      productTypes.isNotEmpty;

  /// Parse from API response (/api/filters/batch)
  factory ClientFilterOptions.fromAPIResponse(Map<String, dynamic> data) {
    final results = data['results'] as List? ?? [];

    final clientTypes = <String>[];
    final marketTypes = <String>[];
    final pensionTypes = <String>[];
    final productTypes = <String>[];

    for (final result in results) {
      if (result is! Map) continue;

      final table = result['table'] as String?;
      final column = result['column'] as String?;
      final items = result['items'] as List?;

      if (table != 'clients' || items == null) continue;

      for (final item in items) {
        if (item is! Map) continue;

        final value = item['value'] as String?;
        if (value == null || value.isEmpty || value == 'all' || value == 'Unspecified') continue;

        final normalized = value.toUpperCase().trim();
        switch (column) {
          case 'client_type':
            if (!clientTypes.contains(normalized)) clientTypes.add(normalized);
            break;
          case 'market_type':
            if (!marketTypes.contains(normalized)) marketTypes.add(normalized);
            break;
          case 'pension_type':
            if (!pensionTypes.contains(normalized)) pensionTypes.add(normalized);
            break;
          case 'product_type':
            if (!productTypes.contains(normalized)) productTypes.add(normalized);
            break;
        }
      }
    }

    return ClientFilterOptions(
      clientTypes: clientTypes,
      marketTypes: marketTypes,
      pensionTypes: pensionTypes,
      productTypes: productTypes,
    );
  }
}
