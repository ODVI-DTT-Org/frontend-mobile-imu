import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final List<ClientType>? clientTypes;
  final List<MarketType>? marketTypes;
  final List<PensionType>? pensionTypes;
  final List<ProductType>? productTypes;

  const ClientAttributeFilter({
    this.clientTypes,
    this.marketTypes,
    this.pensionTypes,
    this.productTypes,
  });

  bool get hasFilter =>
      (clientTypes?.isNotEmpty ?? false) ||
      (marketTypes?.isNotEmpty ?? false) ||
      (pensionTypes?.isNotEmpty ?? false) ||
      (productTypes?.isNotEmpty ?? false);

  int get activeFilterCount {
    return (clientTypes?.length ?? 0) +
        (marketTypes?.length ?? 0) +
        (pensionTypes?.length ?? 0) +
        (productTypes?.length ?? 0);
  }

  static ClientAttributeFilter none() => const ClientAttributeFilter();

  /// OR within category, AND across categories
  bool matches(Client client) {
    if (clientTypes != null && clientTypes!.isNotEmpty) {
      if (!clientTypes!.contains(client.clientType)) return false;
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      if (!marketTypes!.contains(client.marketType)) return false;
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      if (!pensionTypes!.contains(client.pensionType)) return false;
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      if (!productTypes!.contains(client.productType)) return false;
    }
    return true;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (clientTypes != null && clientTypes!.isNotEmpty) {
      params['client_type'] = clientTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      params['market_type'] = marketTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      params['pension_type'] = pensionTypes!.map((t) => t.name.toUpperCase()).join(',');
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      params['product_type'] = productTypes!.map((t) => _productTypeApiValue(t)).join(',');
    }
    return params;
  }

  String _productTypeApiValue(ProductType type) {
    switch (type) {
      case ProductType.bfpActive:
        return 'BFP ACTIVE';
      case ProductType.bfpPension:
        return 'BFP PENSION';
      case ProductType.pnpPension:
        return 'PNP PENSION';
      case ProductType.napolcom:
        return 'NAPOLCOM';
      case ProductType.bfpStp:
        return 'BFP STP';
    }
  }

  static const _absent = Object();

  ClientAttributeFilter copyWith({
    Object? clientTypes = _absent,
    Object? marketTypes = _absent,
    Object? pensionTypes = _absent,
    Object? productTypes = _absent,
  }) {
    return ClientAttributeFilter(
      clientTypes: identical(clientTypes, _absent) ? this.clientTypes : clientTypes as List<ClientType>?,
      marketTypes: identical(marketTypes, _absent) ? this.marketTypes : marketTypes as List<MarketType>?,
      pensionTypes: identical(pensionTypes, _absent) ? this.pensionTypes : pensionTypes as List<PensionType>?,
      productTypes: identical(productTypes, _absent) ? this.productTypes : productTypes as List<ProductType>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    const listEq = ListEquality();
    return other is ClientAttributeFilter &&
        listEq.equals(other.clientTypes, clientTypes) &&
        listEq.equals(other.marketTypes, marketTypes) &&
        listEq.equals(other.pensionTypes, pensionTypes) &&
        listEq.equals(other.productTypes, productTypes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(clientTypes ?? []),
        Object.hashAll(marketTypes ?? []),
        Object.hashAll(pensionTypes ?? []),
        Object.hashAll(productTypes ?? []),
      );

  @override
  String toString() =>
      'ClientAttributeFilter(clientTypes: $clientTypes, marketTypes: $marketTypes, '
      'pensionTypes: $pensionTypes, productTypes: $productTypes)';
}
