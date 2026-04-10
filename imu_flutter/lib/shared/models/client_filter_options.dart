// lib/shared/models/client_filter_options.dart
import '../../features/clients/data/models/client_model.dart';

class ClientFilterOptions {
  final List<ClientType> clientTypes;
  final List<MarketType> marketTypes;
  final List<PensionType> pensionTypes;
  final List<ProductType> productTypes;

  const ClientFilterOptions({
    this.clientTypes = const [],
    this.marketTypes = const [],
    this.pensionTypes = const [],
    this.productTypes = const [],
  });

  bool get isNotEmpty =>
      clientTypes.isNotEmpty ||
      marketTypes.isNotEmpty ||
      pensionTypes.isNotEmpty ||
      productTypes.isNotEmpty;

  /// Parse from API response (/api/filters/batch)
  factory ClientFilterOptions.fromAPIResponse(Map<String, dynamic> data) {
    final results = data['results'] as List? ?? [];

    ClientType? parseClientType(String value) {
      try {
        return ClientType.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    MarketType? parseMarketType(String value) {
      try {
        return MarketType.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    PensionType? parsePensionType(String value) {
      try {
        return PensionType.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    ProductType? parseProductType(String value) {
      try {
        return ProductType.values.firstWhere(
          (e) => e.name.toLowerCase() == value.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    List<ClientType> clientTypes = [];
    List<MarketType> marketTypes = [];
    List<PensionType> pensionTypes = [];
    List<ProductType> productTypes = [];

    for (final result in results) {
      if (result is! Map) continue;

      final table = result['table'] as String?;
      final column = result['column'] as String?;
      final items = result['items'] as List?;

      if (table != 'clients' || items == null) continue;

      for (final item in items) {
        if (item is! Map) continue;

        final value = item['value'] as String?;
        if (value == null || value == 'all' || value == 'Unspecified') continue;

        switch (column) {
          case 'client_type':
            final parsed = parseClientType(value);
            if (parsed != null && !clientTypes.contains(parsed)) {
              clientTypes.add(parsed);
            }
            break;
          case 'market_type':
            final parsed = parseMarketType(value);
            if (parsed != null && !marketTypes.contains(parsed)) {
              marketTypes.add(parsed);
            }
            break;
          case 'pension_type':
            final parsed = parsePensionType(value);
            if (parsed != null && !pensionTypes.contains(parsed)) {
              pensionTypes.add(parsed);
            }
            break;
          case 'product_type':
            final parsed = parseProductType(value);
            if (parsed != null && !productTypes.contains(parsed)) {
              productTypes.add(parsed);
            }
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
