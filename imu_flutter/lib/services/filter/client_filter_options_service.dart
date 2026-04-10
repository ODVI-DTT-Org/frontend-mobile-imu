// lib/services/filter/client_filter_options_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import '../api/client_filter_api_service.dart';
import '../../shared/models/client_filter_options.dart';
import '../../shared/providers/app_providers.dart' show powerSyncDatabaseProvider;
import '../../features/clients/data/models/client_model.dart';

class ClientFilterOptionsService {
  final ClientFilterApiService _apiService;
  final PowerSyncDatabase _powerSync;

  ClientFilterOptionsService(this._apiService, this._powerSync);

  /// Fetch filter options using hybrid approach
  /// Tries PowerSync first, falls back to API
  Future<ClientFilterOptions> fetchOptions() async {
    try {
      // Try PowerSync first (fast, offline-capable)
      final options = await _fetchFromPowerSync();
      if (options.isNotEmpty) {
        return options;
      }
    } catch (e) {
      // Fallback to API
    }

    // Fallback to API
    return await _apiService.fetchFilterOptions();
  }

  /// Fetch distinct values from PowerSync
  Future<ClientFilterOptions> _fetchFromPowerSync() async {
    final results = await _powerSync.getAll('''
      SELECT DISTINCT
        client_type,
        market_type,
        pension_type,
        product_type
      FROM clients
      WHERE client_type IS NOT NULL
         OR market_type IS NOT NULL
         OR pension_type IS NOT NULL
         OR product_type IS NOT NULL
    ''');

    final clientTypes = <ClientType>{};
    final marketTypes = <MarketType>{};
    final pensionTypes = <PensionType>{};
    final productTypes = <ProductType>{};

    for (final row in results) {
      final clientType = row['client_type'] as String?;
      final marketType = row['market_type'] as String?;
      final pensionType = row['pension_type'] as String?;
      final productType = row['product_type'] as String?;

      if (clientType != null) {
        final parsed = _parseClientType(clientType);
        if (parsed != null) clientTypes.add(parsed);
      }

      if (marketType != null) {
        final parsed = _parseMarketType(marketType);
        if (parsed != null) marketTypes.add(parsed);
      }

      if (pensionType != null) {
        final parsed = _parsePensionType(pensionType);
        if (parsed != null) pensionTypes.add(parsed);
      }

      if (productType != null) {
        final parsed = _parseProductType(productType);
        if (parsed != null) productTypes.add(parsed);
      }
    }

    return ClientFilterOptions(
      clientTypes: clientTypes.toList(),
      marketTypes: marketTypes.toList(),
      pensionTypes: pensionTypes.toList(),
      productTypes: productTypes.toList(),
    );
  }

  ClientType? _parseClientType(String value) {
    try {
      return ClientType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  MarketType? _parseMarketType(String value) {
    try {
      return MarketType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  PensionType? _parsePensionType(String value) {
    try {
      return PensionType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  ProductType? _parseProductType(String value) {
    try {
      return ProductType.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
