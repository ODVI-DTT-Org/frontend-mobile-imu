import '../api/client_filter_api_service.dart';
import '../../shared/models/client_filter_options.dart';
import '../filter_preferences_service.dart';
import 'package:flutter/foundation.dart';

class ClientFilterOptionsService {
  final ClientFilterApiService _apiService;
  final FilterPreferencesService _prefs;

  ClientFilterOptionsService(this._apiService, this._prefs);

  Future<ClientFilterOptions> fetchOptions() async {
    // Serve from local cache if available (works offline)
    if (await _prefs.hasFilterOptionsCache()) {
      debugPrint('[ClientFilterOptionsService] Serving from local cache');
      return ClientFilterOptions(
        clientTypes: await _prefs.getCachedClientTypeOptions(),
        marketTypes: await _prefs.getCachedMarketTypeOptions(),
        pensionTypes: await _prefs.getCachedPensionTypeOptions(),
        productTypes: await _prefs.getCachedProductTypeOptions(),
        loanTypes: await _prefs.getCachedLoanTypeOptions(),
        touchpointReasons: await _prefs.getCachedTouchpointReasonsOptions(),
      );
    }

    // Cache miss — fetch from API and save locally
    debugPrint('[ClientFilterOptionsService] Cache empty, fetching from API');
    try {
      final options = await _apiService.fetchFilterOptions();
      await _prefs.cacheFilterOptions(
        clientTypes: options.clientTypes,
        marketTypes: options.marketTypes,
        pensionTypes: options.pensionTypes,
        productTypes: options.productTypes,
        loanTypes: options.loanTypes,
        touchpointReasons: options.touchpointReasons,
      );
      debugPrint('[ClientFilterOptionsService] Cached filter options from API');
      return options;
    } catch (e) {
      debugPrint('[ClientFilterOptionsService] API fetch failed: $e');
      return const ClientFilterOptions();
    }
  }

  /// Call this on logout to force a fresh fetch on next login
  Future<void> clearCache() => _prefs.clearFilterOptionsCache();
}
