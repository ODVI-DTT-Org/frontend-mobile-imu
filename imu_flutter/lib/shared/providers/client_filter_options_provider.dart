// lib/shared/providers/client_filter_options_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/filter/client_filter_options_service.dart';
import '../models/client_filter_options.dart';
import 'app_providers.dart' show powerSyncDatabaseProvider;

final clientFilterOptionsServiceProvider =
    Provider<ClientFilterOptionsService>((ref) {
  final powerSync = ref.watch(powerSyncDatabaseProvider).value;
  return ClientFilterOptionsService(powerSync);
});

/// Filter options fetched from local PowerSync only (offline-first)
final clientFilterOptionsProvider =
    FutureProvider.autoDispose<ClientFilterOptions>((ref) async {
  final service = ref.watch(clientFilterOptionsServiceProvider);
  return await service.fetchOptions();
});
