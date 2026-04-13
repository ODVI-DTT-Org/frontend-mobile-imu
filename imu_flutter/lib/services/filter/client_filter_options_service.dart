// lib/services/filter/client_filter_options_service.dart
import 'package:powersync/powersync.dart';
import '../api/client_filter_api_service.dart';
import '../../shared/models/client_filter_options.dart';
import '../../features/clients/data/models/client_model.dart';
import 'package:flutter/foundation.dart';
import 'client_filter_exceptions.dart';

class ClientFilterOptionsService {
  final ClientFilterApiService _apiService;
  final PowerSyncDatabase? _powerSync;

  ClientFilterOptionsService(this._apiService, this._powerSync);

  /// Fetch filter options using PowerSync (offline-first)
  /// Falls back to API only if PowerSync fails or returns empty results
  Future<ClientFilterOptions> fetchOptions() async {
    // If PowerSync is not available, fall back to API immediately
    if (_powerSync == null) {
      debugPrint('[ClientFilterOptionsService] PowerSync not available, using API');
      return await _apiService.fetchFilterOptions();
    }

    try {
      debugPrint('[ClientFilterOptionsService] Fetching from PowerSync...');
      final options = await _fetchFromPowerSync();

      final hasData = options.clientTypes.isNotEmpty ||
                     options.marketTypes.isNotEmpty ||
                     options.pensionTypes.isNotEmpty ||
                     options.productTypes.isNotEmpty;

      if (hasData) {
        debugPrint('[ClientFilterOptionsService] PowerSync success: '
            '${options.clientTypes.length} client types, '
            '${options.marketTypes.length} market types, '
            '${options.pensionTypes.length} pension types, '
            '${options.productTypes.length} product types');
        return options;
      } else {
        debugPrint('[ClientFilterOptionsService] PowerSync returned empty, falling back to API');
      }
    } on PowerSyncUnavailableException catch (e) {
      // Re-throw PowerSync-specific exceptions
      debugPrint('[ClientFilterOptionsService] PowerSync unavailable: $e');
      rethrow;
    } catch (e) {
      debugPrint('[ClientFilterOptionsService] PowerSync failed: $e, falling back to API');
    }

    // Fallback to API
    try {
      return await _apiService.fetchFilterOptions();
    } catch (e) {
      throw FilterOptionsLoadException(
        'Failed to load filter options from both PowerSync and API',
        e,
      );
    }
  }

  /// Fetch distinct values from PowerSync using separate optimized queries
  Future<ClientFilterOptions> _fetchFromPowerSync() async {
    if (_powerSync == null) {
      throw PowerSyncUnavailableException('PowerSync database is not available');
    }

    // Fetch each filter type separately for better performance and NULL handling
    final clientTypesResult = await _powerSync!.getAll('''
      SELECT DISTINCT client_type
      FROM clients
      WHERE client_type IS NOT NULL
      ORDER BY client_type
    ''');

    final marketTypesResult = await _powerSync!.getAll('''
      SELECT DISTINCT market_type
      FROM clients
      WHERE market_type IS NOT NULL
      ORDER BY market_type
    ''');

    final pensionTypesResult = await _powerSync!.getAll('''
      SELECT DISTINCT pension_type
      FROM clients
      WHERE pension_type IS NOT NULL
      ORDER BY pension_type
    ''');

    final productTypesResult = await _powerSync!.getAll('''
      SELECT DISTINCT product_type
      FROM clients
      WHERE product_type IS NOT NULL
      ORDER BY product_type
    ''');

    final clientTypes = <ClientType>{};
    final marketTypes = <MarketType>{};
    final pensionTypes = <PensionType>{};
    final productTypes = <ProductType>{};

    // Parse client types
    for (final row in clientTypesResult) {
      final value = row['client_type'] as String?;
      if (value != null) {
        final parsed = _parseClientType(value);
        if (parsed != null) clientTypes.add(parsed);
      }
    }

    // Parse market types
    for (final row in marketTypesResult) {
      final value = row['market_type'] as String?;
      if (value != null) {
        final parsed = _parseMarketType(value);
        if (parsed != null) marketTypes.add(parsed);
      }
    }

    // Parse pension types
    for (final row in pensionTypesResult) {
      final value = row['pension_type'] as String?;
      if (value != null) {
        final parsed = _parsePensionType(value);
        if (parsed != null) pensionTypes.add(parsed);
      }
    }

    // Parse product types
    for (final row in productTypesResult) {
      final value = row['product_type'] as String?;
      if (value != null) {
        final parsed = _parseProductType(value);
        if (parsed != null) productTypes.add(parsed);
      }
    }

    return ClientFilterOptions(
      clientTypes: clientTypes.toList()..sort(),
      marketTypes: marketTypes.toList()..sort(),
      pensionTypes: pensionTypes.toList()..sort(),
      productTypes: productTypes.toList()..sort(),
    );
  }

  /// Parse client type from database value (e.g., "POTENTIAL" -> ClientType.potential)
  ClientType? _parseClientType(String value) {
    try {
      return ClientType.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
      );
    } catch (_) {
      debugPrint('[ClientFilterOptionsService] Failed to parse ClientType: $value');
      return null;
    }
  }

  /// Parse market type from database value (e.g., "RESIDENTIAL" -> MarketType.residential)
  MarketType? _parseMarketType(String value) {
    try {
      return MarketType.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
      );
    } catch (_) {
      debugPrint('[ClientFilterOptionsService] Failed to parse MarketType: $value');
      return null;
    }
  }

  /// Parse pension type from database value (e.g., "SSS" -> PensionType.sss)
  PensionType? _parsePensionType(String value) {
    try {
      return PensionType.values.firstWhere(
        (e) => e.name.toUpperCase() == value.toUpperCase(),
      );
    } catch (_) {
      debugPrint('[ClientFilterOptionsService] Failed to parse PensionType: $value');
      return null;
    }
  }

  /// Parse product type from database value (e.g., "SSS_PENSIONER" -> ProductType.sssPensioner)
  ProductType? _parseProductType(String value) {
    try {
      // Handle special case for underscore conversion
      switch (value.toUpperCase()) {
        case 'SSS_PENSIONER':
          return ProductType.sssPensioner;
        case 'GSIS_PENSIONER':
          return ProductType.gsisPensioner;
        case 'PRIVATE':
          return ProductType.private;
        default:
          // Try normal parsing as fallback
          return ProductType.values.firstWhere(
            (e) => e.name.toUpperCase() == value.toUpperCase(),
          );
      }
    } catch (_) {
      debugPrint('[ClientFilterOptionsService] Failed to parse ProductType: $value');
      return null;
    }
  }
}
