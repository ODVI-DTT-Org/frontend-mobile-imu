import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientAttributeFilter {
  final List<String>? clientTypes;
  final List<String>? marketTypes;
  final List<String>? pensionTypes;
  final List<String>? productTypes;
  final List<String>? loanTypes;
  final List<String>? touchpointStatuses;
  final List<String>? touchpointReasons;
  final DateTime? touchpointDateFrom;
  final DateTime? touchpointDateTo;

  const ClientAttributeFilter({
    this.clientTypes,
    this.marketTypes,
    this.pensionTypes,
    this.productTypes,
    this.loanTypes,
    this.touchpointStatuses,
    this.touchpointReasons,
    this.touchpointDateFrom,
    this.touchpointDateTo,
  });

  bool get hasFilter =>
      (clientTypes?.isNotEmpty ?? false) ||
      (marketTypes?.isNotEmpty ?? false) ||
      (pensionTypes?.isNotEmpty ?? false) ||
      (productTypes?.isNotEmpty ?? false) ||
      (loanTypes?.isNotEmpty ?? false) ||
      (touchpointStatuses?.isNotEmpty ?? false) ||
      (touchpointReasons?.isNotEmpty ?? false) ||
      (touchpointDateFrom != null) ||
      (touchpointDateTo != null);

  int get activeFilterCount {
    return (clientTypes?.length ?? 0) +
        (marketTypes?.length ?? 0) +
        (pensionTypes?.length ?? 0) +
        (productTypes?.length ?? 0) +
        (loanTypes?.length ?? 0) +
        (touchpointStatuses?.length ?? 0) +
        (touchpointReasons?.length ?? 0) +
        ((touchpointDateFrom != null || touchpointDateTo != null) ? 1 : 0);
  }

  static ClientAttributeFilter none() => const ClientAttributeFilter(
    touchpointReasons: null,
    touchpointDateFrom: null,
    touchpointDateTo: null,
  );

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
      final raw = (client.loanTypeRaw ?? '').toUpperCase().trim();
      if (!loanTypes!.any((f) => f.toUpperCase() == raw)) return false;
    }
    if (touchpointStatuses != null && touchpointStatuses!.isNotEmpty) {
      // Per-touchpoint interest level (matches the TouchpointStatus enum the
      // backend stores in touchpoints.status, denormalised into
      // clients.touchpoint_summary). 'loan_released' is a special chip that
      // checks the Client.loanReleased boolean instead.
      final loanReleasedSelected = touchpointStatuses!.contains('loan_released');
      final interestSelected =
          touchpointStatuses!.where((s) => s != 'loan_released').toSet();

      bool hasMatch = false;
      if (loanReleasedSelected && client.loanReleased) {
        hasMatch = true;
      }
      if (!hasMatch && interestSelected.isNotEmpty) {
        // Prefer the denormalised summary (matches backend); fall back to the
        // full touchpoints list if the summary is empty (legacy rows).
        final source = client.touchpointSummary.isNotEmpty
            ? client.touchpointSummary
            : client.touchpoints;
        hasMatch = source.any((tp) =>
            interestSelected.contains(tp.status.apiValue.toUpperCase()));
      }
      if (!hasMatch) return false;
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
      params['loan_type'] = loanTypes!.join(',');
    }
    if (touchpointStatuses != null && touchpointStatuses!.isNotEmpty) {
      // visit_status filters per-touchpoint interest level via the backend's
      // jsonb_array_elements(touchpoint_summary) EXISTS check (added in
      // backend feat: visit_status filter). 'loan_released' is a separate
      // chip that maps to the dedicated loan_released boolean param.
      final interest =
          touchpointStatuses!.where((s) => s != 'loan_released').toList();
      if (interest.isNotEmpty) {
        params['visit_status'] = interest.join(',');
      }
      if (touchpointStatuses!.contains('loan_released')) {
        params['loan_released'] = 'true';
      }
    }
    if (touchpointReasons != null && touchpointReasons!.isNotEmpty) {
      params['touchpoint_reason_codes'] = touchpointReasons!.join(',');
    }
    if (touchpointDateFrom != null) {
      params['touchpoint_date_from'] = DateFormat('yyyy-MM-dd').format(touchpointDateFrom!);
    }
    if (touchpointDateTo != null) {
      params['touchpoint_date_to'] = DateFormat('yyyy-MM-dd').format(touchpointDateTo!);
    }
    return params;
  }

  static const _absent = Object();

  ClientAttributeFilter copyWith({
    Object? clientTypes = _absent,
    Object? marketTypes = _absent,
    Object? pensionTypes = _absent,
    Object? productTypes = _absent,
    Object? loanTypes = _absent,
    Object? touchpointStatuses = _absent,
    Object? touchpointReasons = _absent,
    Object? touchpointDateFrom = _absent,
    Object? touchpointDateTo = _absent,
  }) {
    return ClientAttributeFilter(
      clientTypes: identical(clientTypes, _absent) ? this.clientTypes : clientTypes as List<String>?,
      marketTypes: identical(marketTypes, _absent) ? this.marketTypes : marketTypes as List<String>?,
      pensionTypes: identical(pensionTypes, _absent) ? this.pensionTypes : pensionTypes as List<String>?,
      productTypes: identical(productTypes, _absent) ? this.productTypes : productTypes as List<String>?,
      loanTypes: identical(loanTypes, _absent) ? this.loanTypes : loanTypes as List<String>?,
      touchpointStatuses: identical(touchpointStatuses, _absent) ? this.touchpointStatuses : touchpointStatuses as List<String>?,
      touchpointReasons: identical(touchpointReasons, _absent) ? this.touchpointReasons : touchpointReasons as List<String>?,
      touchpointDateFrom: identical(touchpointDateFrom, _absent) ? this.touchpointDateFrom : touchpointDateFrom as DateTime?,
      touchpointDateTo: identical(touchpointDateTo, _absent) ? this.touchpointDateTo : touchpointDateTo as DateTime?,
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
        listEq.equals(other.loanTypes, loanTypes) &&
        listEq.equals(other.touchpointStatuses, touchpointStatuses) &&
        listEq.equals(other.touchpointReasons, touchpointReasons) &&
        other.touchpointDateFrom == touchpointDateFrom &&
        other.touchpointDateTo == touchpointDateTo;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(clientTypes ?? []),
        Object.hashAll(marketTypes ?? []),
        Object.hashAll(pensionTypes ?? []),
        Object.hashAll(productTypes ?? []),
        Object.hashAll(loanTypes ?? []),
        Object.hashAll(touchpointStatuses ?? []),
        Object.hashAll(touchpointReasons ?? []),
        touchpointDateFrom,
        touchpointDateTo,
      );

  @override
  String toString() =>
      'ClientAttributeFilter(clientTypes: $clientTypes, marketTypes: $marketTypes, '
      'pensionTypes: $pensionTypes, productTypes: $productTypes, loanTypes: $loanTypes, '
      'touchpointStatuses: $touchpointStatuses, touchpointReasons: $touchpointReasons, '
      'touchpointDateFrom: $touchpointDateFrom, touchpointDateTo: $touchpointDateTo)';
}
