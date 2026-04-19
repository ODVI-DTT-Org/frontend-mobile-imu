import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final List<ClientType>? clientTypes;
  final List<MarketType>? marketTypes;
  final List<PensionType>? pensionTypes;
  final List<ProductType>? productTypes;
  final List<LoanType>? loanTypes;

  const ClientAttributeFilter({
    this.clientTypes,
    this.marketTypes,
    this.pensionTypes,
    this.productTypes,
    this.loanTypes,
  });

  bool get hasFilter =>
      (clientTypes?.isNotEmpty ?? false) ||
      (marketTypes?.isNotEmpty ?? false) ||
      (pensionTypes?.isNotEmpty ?? false) ||
      (productTypes?.isNotEmpty ?? false) ||
      (loanTypes?.isNotEmpty ?? false);

  int get activeFilterCount {
    return (clientTypes?.length ?? 0) +
        (marketTypes?.length ?? 0) +
        (pensionTypes?.length ?? 0) +
        (productTypes?.length ?? 0) +
        (loanTypes?.length ?? 0);
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
    if (loanTypes != null && loanTypes!.isNotEmpty) {
      if (!loanTypes!.contains(client.loanType)) return false;
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
    if (loanTypes != null && loanTypes!.isNotEmpty) {
      params['loan_type'] = loanTypes!.map((t) => _loanTypeApiValue(t)).join(',');
    }
    return params;
  }

  String _loanTypeApiValue(LoanType type) {
    switch (type) {
      case LoanType.firstLoan:
        return 'NEW';
      case LoanType.additional:
        return 'ADDITIONAL';
      case LoanType.renewal:
        return 'RENEWAL';
      case LoanType.preterm:
        return 'PRETERM';
    }
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
    Object? loanTypes = _absent,
  }) {
    return ClientAttributeFilter(
      clientTypes: identical(clientTypes, _absent) ? this.clientTypes : clientTypes as List<ClientType>?,
      marketTypes: identical(marketTypes, _absent) ? this.marketTypes : marketTypes as List<MarketType>?,
      pensionTypes: identical(pensionTypes, _absent) ? this.pensionTypes : pensionTypes as List<PensionType>?,
      productTypes: identical(productTypes, _absent) ? this.productTypes : productTypes as List<ProductType>?,
      loanTypes: identical(loanTypes, _absent) ? this.loanTypes : loanTypes as List<LoanType>?,
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
        listEq.equals(other.productTypes, productTypes) &&
        listEq.equals(other.loanTypes, loanTypes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(clientTypes ?? []),
        Object.hashAll(marketTypes ?? []),
        Object.hashAll(pensionTypes ?? []),
        Object.hashAll(productTypes ?? []),
        Object.hashAll(loanTypes ?? []),
      );

  @override
  String toString() =>
      'ClientAttributeFilter(clientTypes: $clientTypes, marketTypes: $marketTypes, '
      'pensionTypes: $pensionTypes, productTypes: $productTypes, loanTypes: $loanTypes)';
}
