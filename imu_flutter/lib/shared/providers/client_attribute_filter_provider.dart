import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_attribute_filter.dart';
import '../models/location_filter.dart';
import '../../features/clients/data/models/client_model.dart';
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
    final clientTypeStrs = await _prefs.getClientTypes();
    final marketTypeStrs = await _prefs.getMarketTypes();
    final pensionTypeStrs = await _prefs.getPensionTypes();
    final productTypeStrs = await _prefs.getProductTypes();
    final loanTypeStrs = await _prefs.getLoanTypes();

    List<T> parseEnums<T extends Enum>(List<String> strs, List<T> values) =>
        strs
            .map((s) {
              try {
                return values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase());
              } catch (_) {
                return null;
              }
            })
            .whereType<T>()
            .toList();

    final clientTypes = parseEnums(clientTypeStrs, ClientType.values);
    final marketTypes = parseEnums(marketTypeStrs, MarketType.values);
    final pensionTypes = parseEnums(pensionTypeStrs, PensionType.values);
    final productTypes = parseEnums(productTypeStrs, ProductType.values);
    final loanTypes = parseEnums(loanTypeStrs, LoanType.values);

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

  void toggleClientType(ClientType type) {
    final current = List<ClientType>.from(state.clientTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(clientTypes: current.isEmpty ? null : current));
  }

  void toggleMarketType(MarketType type) {
    final current = List<MarketType>.from(state.marketTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(marketTypes: current.isEmpty ? null : current));
  }

  void togglePensionType(PensionType type) {
    final current = List<PensionType>.from(state.pensionTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(pensionTypes: current.isEmpty ? null : current));
  }

  void toggleProductType(ProductType type) {
    final current = List<ProductType>.from(state.productTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(productTypes: current.isEmpty ? null : current));
  }

  void toggleLoanType(LoanType type) {
    final current = List<LoanType>.from(state.loanTypes ?? []);
    current.contains(type) ? current.remove(type) : current.add(type);
    updateFilter(state.copyWith(loanTypes: current.isEmpty ? null : current));
  }

  void clear() {
    state = ClientAttributeFilter.none();
    _prefs.clearAttributeFilters();
  }

  void _persistFilter(ClientAttributeFilter filter) {
    _prefs.setClientTypes(filter.clientTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setMarketTypes(filter.marketTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setPensionTypes(filter.pensionTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setProductTypes(filter.productTypes?.map((t) => t.name).toList() ?? []);
    _prefs.setLoanTypes(filter.loanTypes?.map((t) => t.name).toList() ?? []);
  }
}

/// Total count of active filters (location + attributes)
/// Used for badge display on filter icons
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
