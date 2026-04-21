import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/services/network_state_service.dart';

/// Provider for NetworkStateService instance.
/// Creates a new instance that is automatically disposed when no longer needed.
final networkStateServiceProvider = Provider<NetworkStateService>((ref) {
  final service = NetworkStateService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Stream provider for network status changes.
/// Automatically updates when network state changes.
final networkStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(networkStateServiceProvider);
  // Initialize monitoring
  service.initialize();
  return service.onNetworkStatusChange;
});

/// Provider that returns true if device is online.
/// Watches networkStatusProvider and converts to boolean.
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(networkStatusProvider).value;
  return status != NetworkStatus.offline;
});

/// Provider that returns true if device is offline.
/// Directly accesses the service's isOffline property for immediate updates.
final isOfflineProvider = Provider<bool>((ref) {
  final service = ref.watch(networkStateServiceProvider);
  return service.isOffline;
});
