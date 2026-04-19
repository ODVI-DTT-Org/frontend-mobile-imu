import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/filter/client_filter_options_service.dart';
import '../../services/api/client_filter_api_service.dart';
import '../../services/filter_preferences_service.dart';
import '../models/client_filter_options.dart';

final clientFilterOptionsServiceProvider =
    Provider<ClientFilterOptionsService>((ref) {
  return ClientFilterOptionsService(
    ClientFilterApiService(),
    FilterPreferencesService(),
  );
});

/// Filter options — served from local cache, fetched from API on first login
final clientFilterOptionsProvider =
    FutureProvider.autoDispose<ClientFilterOptions>((ref) async {
  final service = ref.watch(clientFilterOptionsServiceProvider);
  return await service.fetchOptions();
});
