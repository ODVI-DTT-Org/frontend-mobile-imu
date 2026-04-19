import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_attribute_filter.dart';
import '../models/location_filter.dart';
import '../../services/filter_preferences_service.dart';
import 'location_filter_providers.dart' show locationFilterProvider;

final clientAttributeFilterProvider =
    StateNotifierProvider<ClientAttributeFilterNotifier, ClientAttributeFilter>((ref) {
  return ClientAttributeFilterNotifier();
});

class ClientAttributeFilterNotifier extends StateNotifier<ClientAttributeFilter> {
  final FilterPreferencesService _prefs = FilterPreferencesService();

  ClientAttributeFilterNotifier() : super(ClientAttributeFilter.none()) {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    final clientTypes = await _prefs.getClientTypes();
    final marketTypes = await _prefs.getMarketTypes();
    final pensionTypes = await _prefs.getPensionTypes();
    final productTypes = await _prefs.getProductTypes();
    final loanTypes = await _prefs.getLoanTypes();

    if (clientTypes.isNotEmpty || marketTypes.isNotEmpty ||
        pensionTypes.isNotEmpty || productTypes.isNotEmpty || loanTypes.isNotEmpty) {
      state = ClientAttributeFilter(
        clientTypes: clientTypes.isEmpty ? null : clientTypes,
        marketTypes: marketTypes.isEmpty ? null : marketTypes,
        pensionTypes: pensionTypes.isEmpty ? null : pensionTypes,
        productTypes: productTypes.isEmpty ? null : productTypes,
        loanTypes: loanTypes.isEmpty ? null : loanTypes,
      );
    }
  }

  void updateFilter(ClientAttributeFilter newFilter) {
    state = newFilter;
    _persistFilter(newFilter);
  }

  void toggleClientType(String value) {
    final current = List<String>.from(state.clientTypes ?? []);
    current.contains(value) ? current.remove(value) : current.add(value);
    updateFilter(state.copyWith(clientTypes: current.isEmpty ? null : current));
  }

  void toggleMarketType(String value) {
    final current = List<String>.from(state.marketTypes ?? []);
    current.contains(value) ? current.remove(value) : current.add(value);
    updateFilter(state.copyWith(marketTypes: current.isEmpty ? null : current));
  }

  void togglePensionType(String value) {
    final current = List<String>.from(state.pensionTypes ?? []);
    current.contains(value) ? current.remove(value) : current.add(value);
    updateFilter(state.copyWith(pensionTypes: current.isEmpty ? null : current));
  }

  void toggleProductType(String value) {
    final current = List<String>.from(state.productTypes ?? []);
    current.contains(value) ? current.remove(value) : current.add(value);
    updateFilter(state.copyWith(productTypes: current.isEmpty ? null : current));
  }

  void toggleLoanType(String value) {
    final current = List<String>.from(state.loanTypes ?? []);
    current.contains(value) ? current.remove(value) : current.add(value);
    updateFilter(state.copyWith(loanTypes: current.isEmpty ? null : current));
  }

  void clear() {
    state = ClientAttributeFilter.none();
    _prefs.clearAttributeFilters();
  }

  void _persistFilter(ClientAttributeFilter filter) {
    _prefs.setClientTypes(filter.clientTypes ?? []);
    _prefs.setMarketTypes(filter.marketTypes ?? []);
    _prefs.setPensionTypes(filter.pensionTypes ?? []);
    _prefs.setProductTypes(filter.productTypes ?? []);
    _prefs.setLoanTypes(filter.loanTypes ?? []);
  }
}

/// Total count of active filters (location + attributes)
final activeFilterCountProvider = Provider<int>((ref) {
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);

  int count = 0;
  if (locationFilter.province != null) {
    count += 1;
    if (locationFilter.municipalities != null && locationFilter.municipalities!.isNotEmpty) {
      count += locationFilter.municipalities!.length;
    }
  }
  count += attributeFilter.activeFilterCount;
  return count;
});
