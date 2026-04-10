// lib/shared/models/client_attribute_filter.dart
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final ClientType? clientType;
  final MarketType? marketType;
  final PensionType? pensionType;
  final ProductType? productType;

  const ClientAttributeFilter({
    this.clientType,
    this.marketType,
    this.pensionType,
    this.productType,
  });

  bool get hasFilter =>
      clientType != null ||
      marketType != null ||
      pensionType != null ||
      productType != null;

  int get activeFilterCount {
    return [clientType, marketType, pensionType, productType]
        .where((f) => f != null)
        .length;
  }

  static ClientAttributeFilter none() => const ClientAttributeFilter();

  /// AND logic - client must match ALL non-null filters
  bool matches(Client client) {
    if (clientType != null && client.clientType != clientType) {
      return false;
    }
    if (marketType != null && client.marketType != marketType) {
      return false;
    }
    if (pensionType != null && client.pensionType != pensionType) {
      return false;
    }
    if (productType != null && client.productType != productType) {
      return false;
    }
    return true;
  }

  /// Convert to API query parameters for All Clients mode
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (clientType != null) {
      params['client_type'] = clientType!.name.toUpperCase();
    }
    if (marketType != null) {
      params['market_type'] = marketType!.name;
    }
    if (pensionType != null) {
      params['pension_type'] = pensionType!.name;
    }
    if (productType != null) {
      params['product_type'] = productType!.name;
    }
    return params;
  }

  ClientAttributeFilter copyWith({
    ClientType? clientType,
    MarketType? marketType,
    PensionType? pensionType,
    ProductType? productType,
  }) {
    return ClientAttributeFilter(
      clientType: clientType ?? this.clientType,
      marketType: marketType ?? this.marketType,
      pensionType: pensionType ?? this.pensionType,
      productType: productType ?? this.productType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClientAttributeFilter &&
        other.clientType == clientType &&
        other.marketType == marketType &&
        other.pensionType == pensionType &&
        other.productType == productType;
  }

  @override
  int get hashCode =>
      Object.hash(clientType, marketType, pensionType, productType);

  @override
  String toString() =>
      'ClientAttributeFilter(clientType: $clientType, marketType: $marketType, pensionType: $pensionType, productType: $productType)';
}
