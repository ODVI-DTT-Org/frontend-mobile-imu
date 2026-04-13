// lib/shared/providers/client_attribute_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_attribute_filter.dart';
import '../models/location_filter.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/filter_preferences_service.dart';
import 'location_filter_providers.dart' show locationFilterProvider;

/// Active client attribute filter state with persistence
/// Loads from SharedPreferences on initialization, saves on change
final clientAttributeFilterProvider =
    StateNotifierProvider<ClientAttributeFilterNotifier, ClientAttributeFilter>((ref) {
  return ClientAttributeFilterNotifier();
});

/// Notifier for client attribute filter with persistence support
class ClientAttributeFilterNotifier extends StateNotifier<ClientAttributeFilter> {
  final FilterPreferencesService _prefs = FilterPreferencesService();

  ClientAttributeFilterNotifier() : super(ClientAttributeFilter.none()) {
    _loadFromPreferences();
  }

  /// Load saved filter from SharedPreferences
  Future<void> _loadFromPreferences() async {
    final clientTypeStr = _prefs.getClientType();
    final marketTypeStr = _prefs.getMarketType();
    final pensionTypeStr = _prefs.getPensionType();
    final productTypeStr = _prefs.getProductType();

    // Parse strings to enums
    ClientType? clientType;
    if (clientTypeStr != null) {
      try {
        clientType = ClientType.values.firstWhere(
          (e) => e.name.toLowerCase() == clientTypeStr.toLowerCase(),
        );
      } catch (_) {
        clientType = null;
      }
    }

    MarketType? marketType;
    if (marketTypeStr != null) {
      try {
        marketType = MarketType.values.firstWhere(
          (e) => e.name.toLowerCase() == marketTypeStr.toLowerCase(),
        );
      } catch (_) {
        marketType = null;
      }
    }

    PensionType? pensionType;
    if (pensionTypeStr != null) {
      try {
        pensionType = PensionType.values.firstWhere(
          (e) => e.name.toLowerCase() == pensionTypeStr.toLowerCase(),
        );
      } catch (_) {
        pensionType = null;
      }
    }

    ProductType? productType;
    if (productTypeStr != null) {
      try {
        productType = ProductType.values.firstWhere(
          (e) => e.name.toLowerCase() == productTypeStr.toLowerCase(),
        );
      } catch (_) {
        productType = null;
      }
    }

    if (clientType != null || marketType != null ||
        pensionType != null || productType != null) {
      state = ClientAttributeFilter(
        clientType: clientType,
        marketType: marketType,
        pensionType: pensionType,
        productType: productType,
      );
    }
  }

  /// Update filter and persist to SharedPreferences
  void updateFilter(ClientAttributeFilter newFilter) {
    state = newFilter;
    _persistFilter(newFilter);
  }

  /// Set client type and persist
  void setClientType(ClientType? type) {
    state = state.copyWith(clientType: type);
    _prefs.setClientType(type?.name);
  }

  /// Set market type and persist
  void setMarketType(MarketType? type) {
    state = state.copyWith(marketType: type);
    _prefs.setMarketType(type?.name);
  }

  /// Set pension type and persist
  void setPensionType(PensionType? type) {
    state = state.copyWith(pensionType: type);
    _prefs.setPensionType(type?.name);
  }

  /// Set product type and persist
  void setProductType(ProductType? type) {
    state = state.copyWith(productType: type);
    _prefs.setProductType(type?.name);
  }

  /// Clear filter and persist
  void clear() {
    state = ClientAttributeFilter.none();
    _prefs.clearAttributeFilters();
  }

  /// Persist filter to SharedPreferences
  void _persistFilter(ClientAttributeFilter filter) {
    _prefs.setClientType(filter.clientType?.name);
    _prefs.setMarketType(filter.marketType?.name);
    _prefs.setPensionType(filter.pensionType?.name);
    _prefs.setProductType(filter.productType?.name);
  }
}

/// Total count of active filters (location + attributes)
/// Used for badge display on filter icons
final activeFilterCountProvider = Provider<int>((ref) {
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);

  int count = 0;

  // Count location filters
  if (locationFilter.province != null) {
    count += 1;
    if (locationFilter.municipalities != null &&
        locationFilter.municipalities!.isNotEmpty) {
      count += locationFilter.municipalities!.length.toInt();
    }
  }

  // Count attribute filters
  count += attributeFilter.activeFilterCount;

  return count;
});
