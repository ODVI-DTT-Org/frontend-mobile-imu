import 'package:powersync/powersync.dart';
import '../../shared/models/client_filter_options.dart';
import 'package:flutter/foundation.dart';

class ClientFilterOptionsService {
  final PowerSyncDatabase? _powerSync;

  ClientFilterOptionsService(this._powerSync);

  Future<ClientFilterOptions> fetchOptions() async {
    if (_powerSync == null) {
      debugPrint('[ClientFilterOptionsService] PowerSync not available');
      return const ClientFilterOptions();
    }

    try {
      debugPrint('[ClientFilterOptionsService] Fetching from PowerSync...');
      return await _fetchFromPowerSync();
    } on PowerSyncUnavailableException catch (e) {
      debugPrint('[ClientFilterOptionsService] PowerSync unavailable: $e');
      return const ClientFilterOptions();
    } catch (e) {
      debugPrint('[ClientFilterOptionsService] PowerSync failed: $e');
      return const ClientFilterOptions();
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
      _powerSync!.getAll('''
        SELECT DISTINCT UPPER(TRIM(loan_type)) as val
        FROM clients
        WHERE loan_type IS NOT NULL AND TRIM(loan_type) != ''
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
      loanTypes: toStrings(queryResults[4]),
    );
  }
}
