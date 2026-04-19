import 'package:powersync/powersync.dart';
import '../api/client_filter_api_service.dart';
import '../../shared/models/client_filter_options.dart';
import 'package:flutter/foundation.dart';
import 'client_filter_exceptions.dart';

class ClientFilterOptionsService {
  final ClientFilterApiService _apiService;
  final PowerSyncDatabase? _powerSync;

  ClientFilterOptionsService(this._apiService, this._powerSync);

  Future<ClientFilterOptions> fetchOptions() async {
    if (_powerSync == null) {
      debugPrint('[ClientFilterOptionsService] PowerSync not available, using API');
      return await _apiService.fetchFilterOptions();
    }

    try {
      debugPrint('[ClientFilterOptionsService] Fetching from PowerSync...');
      final options = await _fetchFromPowerSync();

      if (options.isNotEmpty) {
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
      debugPrint('[ClientFilterOptionsService] PowerSync unavailable: $e');
      rethrow;
    } catch (e) {
      debugPrint('[ClientFilterOptionsService] PowerSync failed: $e, falling back to API');
    }

    try {
      return await _apiService.fetchFilterOptions();
    } catch (e) {
      throw FilterOptionsLoadException(
        'Failed to load filter options from both PowerSync and API',
        e,
      );
    }
  }

  Future<ClientFilterOptions> _fetchFromPowerSync() async {
    if (_powerSync == null) {
      throw PowerSyncUnavailableException('PowerSync database is not available');
    }

    final queryResults = await Future.wait([
      _powerSync!.getAll('''
        SELECT DISTINCT UPPER(TRIM(client_type)) as val
        FROM clients
        WHERE client_type IS NOT NULL AND TRIM(client_type) != ''
        ORDER BY val
      '''),
      _powerSync!.getAll('''
        SELECT DISTINCT UPPER(TRIM(market_type)) as val
        FROM clients
        WHERE market_type IS NOT NULL AND TRIM(market_type) != ''
        ORDER BY val
      '''),
      _powerSync!.getAll('''
        SELECT DISTINCT UPPER(TRIM(pension_type)) as val
        FROM clients
        WHERE pension_type IS NOT NULL AND TRIM(pension_type) != ''
        ORDER BY val
      '''),
      _powerSync!.getAll('''
        SELECT DISTINCT UPPER(TRIM(product_type)) as val
        FROM clients
        WHERE product_type IS NOT NULL AND TRIM(product_type) != ''
        ORDER BY val
      '''),
    ]);

    List<String> toStrings(List<Map<String, dynamic>> rows) {
      final seen = <String>{};
      final result = <String>[];
      for (final row in rows) {
        final val = row['val'] as String?;
        if (val != null && val.isNotEmpty && seen.add(val)) {
          result.add(val);
        }
      }
      return result;
    }

    return ClientFilterOptions(
      clientTypes: toStrings(queryResults[0]),
      marketTypes: toStrings(queryResults[1]),
      pensionTypes: toStrings(queryResults[2]),
      productTypes: toStrings(queryResults[3]),
    );
  }
}
