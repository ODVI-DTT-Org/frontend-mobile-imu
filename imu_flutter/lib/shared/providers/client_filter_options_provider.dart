// lib/shared/providers/client_filter_options_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/filter/client_filter_options_service.dart';
import '../../services/api/client_filter_api_service.dart';
import '../../services/api/client_api_service.dart';
import '../models/client_filter_options.dart';
import 'app_providers.dart' show powerSyncDatabaseProvider, clientApiServiceProvider;

/// Service provider for filter options
final clientFilterOptionsServiceProvider =
    Provider<ClientFilterOptionsService>((ref) {
  final clientApiService = ref.watch(clientApiServiceProvider);
  final powerSync = ref.watch(powerSyncDatabaseProvider).value;

  final apiService = ClientFilterApiService();
  // Service handles null PowerSync - will fall back to API
  return ClientFilterOptionsService(apiService, powerSync);
});

/// Filter options data (auto-disposes after use)
/// Fetches distinct values for all 4 filter types
final clientFilterOptionsProvider =
    FutureProvider.autoDispose<ClientFilterOptions>((ref) async {
  final service = ref.watch(clientFilterOptionsServiceProvider);
  return await service.fetchOptions();
});
