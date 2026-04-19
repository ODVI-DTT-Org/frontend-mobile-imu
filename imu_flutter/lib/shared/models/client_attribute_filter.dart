import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final List<String>? clientTypes;
  final List<String>? marketTypes;
  final List<String>? pensionTypes;
  final List<String>? productTypes;
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
      final raw = (client.clientTypeRaw ?? '').toUpperCase().trim();
      if (!clientTypes!.any((f) => f.toUpperCase() == raw)) return false;
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      final raw = (client.marketTypeRaw ?? '').toUpperCase().trim();
      if (!marketTypes!.any((f) => f.toUpperCase() == raw)) return false;
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      final raw = (client.pensionTypeRaw ?? '').toUpperCase().trim();
      if (!pensionTypes!.any((f) => f.toUpperCase() == raw)) return false;
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      final raw = (client.productTypeRaw ?? '').toUpperCase().trim();
      if (!productTypes!.any((f) => f.toUpperCase() == raw)) return false;
    }
    if (loanTypes != null && loanTypes!.isNotEmpty) {
      if (!loanTypes!.contains(client.loanType)) return false;
    }
    return true;
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (clientTypes != null && clientTypes!.isNotEmpty) {
      params['client_type'] = clientTypes!.join(',');
    }
    if (marketTypes != null && marketTypes!.isNotEmpty) {
      params['market_type'] = marketTypes!.join(',');
    }
    if (pensionTypes != null && pensionTypes!.isNotEmpty) {
      params['pension_type'] = pensionTypes!.join(',');
    }
    if (productTypes != null && productTypes!.isNotEmpty) {
      params['product_type'] = productTypes!.join(',');
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

  static const _absent = Object();

  ClientAttributeFilter copyWith({
    Object? clientTypes = _absent,
    Object? marketTypes = _absent,
    Object? pensionTypes = _absent,
    Object? productTypes = _absent,
    Object? loanTypes = _absent,
  }) {
    return ClientAttributeFilter(
      clientTypes: identical(clientTypes, _absent) ? this.clientTypes : clientTypes as List<String>?,
      marketTypes: identical(marketTypes, _absent) ? this.marketTypes : marketTypes as List<String>?,
      pensionTypes: identical(pensionTypes, _absent) ? this.pensionTypes : pensionTypes as List<String>?,
      productTypes: identical(productTypes, _absent) ? this.productTypes : productTypes as List<String>?,
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
