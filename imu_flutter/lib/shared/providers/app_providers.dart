import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/local_storage/hive_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/location/geolocation_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/test_data_generator.dart';
import '../../features/targets/data/models/target_model.dart';

// ==================== Service Providers ====================

/// Hive service provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Sync service provider
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService();
});

/// Geolocation service provider
final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

// ==================== Auth Providers ====================

/// Authentication state
final isAuthenticatedProvider = StateProvider<bool>((ref) => false);

/// Current user ID
final currentUserIdProvider = StateProvider<String?>((ref) => null);

/// Current user name
final currentUserNameProvider = StateProvider<String?>((ref) => null);

/// Has PIN been set
final hasPinProvider = StateProvider<bool>((ref) => false);

// ==================== Client Providers ====================

/// All clients
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);

  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  final clientsData = hiveService.getAllClients();
  return clientsData.map((data) => Client.fromJson(data)).toList();
});

/// Filtered clients by search query
final clientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered clients by type
final clientTypeFilterProvider = StateProvider<ClientType?>((ref) => null);

/// Filtered clients list
final filteredClientsProvider = Provider<List<Client>>((ref) {
  final clientsAsync = ref.watch(clientsProvider);
  final searchQuery = ref.watch(clientSearchQueryProvider);
  final typeFilter = ref.watch(clientTypeFilterProvider);

  return clientsAsync.when(
    data: (clients) {
      var filtered = clients;

      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        filtered = filtered.where((c) {
          return c.fullName.toLowerCase().contains(query);
        }).toList();
      }

      // Filter by client type
      if (typeFilter != null) {
        filtered = filtered.where((c) => c.clientType == typeFilter).toList();
      }

      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Selected client ID
final selectedClientIdProvider = StateProvider<String?>((ref) => null);

/// Selected client
final selectedClientProvider = Provider<Client?>((ref) {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return null;

  final clientsAsync = ref.watch(clientsProvider);
  return clientsAsync.when(
    data: (clients) {
      try {
        return clients.firstWhere((c) => c.id == clientId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== Touchpoint Providers ====================

/// Touchpoints for selected client
final clientTouchpointsProvider = FutureProvider<List<Touchpoint>>((ref) async {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return [];

  final hiveService = ref.watch(hiveServiceProvider);

  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  final touchpointsData = hiveService.getTouchpointsForClient(clientId);
  return touchpointsData.map((data) => Touchpoint.fromJson(data)).toList();
});

// ==================== Sync Providers ====================

/// Sync status
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.status;
});

/// Pending sync count
final pendingSyncCountProvider = Provider<int>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.pendingCount;
});

/// Last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncService = ref.watch(syncServiceProvider);
  return syncService.lastSyncTime;
});

// ==================== Settings Providers ====================

/// Theme mode
final themeModeProvider = StateProvider<String>((ref) => 'Light');

/// Text size
final textSizeProvider = StateProvider<String>((ref) => 'Medium');

/// Biometric enabled
final biometricEnabledProvider = StateProvider<bool>((ref) => false);

/// Push notifications enabled
final pushNotificationsEnabledProvider = StateProvider<bool>((ref) => true);

// ==================== Location Providers ====================

/// Current location
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  final geoService = ref.watch(geolocationServiceProvider);
  final position = await geoService.getCurrentPosition();

  if (position == null) return null;

  final address = await geoService.getAddressFromCoordinates(
    position.latitude,
    position.longitude,
  );

  return LocationData.fromPosition(position, address: address);
});

// ==================== UI State Providers ====================

/// Bottom nav index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Is loading overlay visible
final isLoadingOverlayVisibleProvider = StateProvider<bool>((ref) => false);

/// Snackbar message
final snackbarMessageProvider = StateProvider<String?>((ref) => null);

// ==================== Itinerary Providers ====================

/// Selected date for itinerary
final itinerarySelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

/// Selected day filter (today, tomorrow, yesterday)
final itineraryDayFilterProvider = StateProvider<String>((ref) => 'today');

// ==================== Debug Providers ====================

/// GPS location tracking service
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Test data generator
final testDataGeneratorProvider = Provider<TestDataGenerator>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return TestDataGenerator(hiveService);
});

/// Data statistics for debug dashboard
final dataStatsProvider = Provider<Map<String, int>>((ref) {
  final generator = ref.watch(testDataGeneratorProvider);
  return generator.getDataStats();
});

// ==================== Target Providers ====================

/// Selected target period
final targetPeriodProvider = StateProvider<TargetPeriod>((ref) {
  return TargetPeriod.weekly;
});

/// Current targets (mock data for now)
final targetsProvider = FutureProvider<List<Target>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);

  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  // TODO: Replace with actual Hive storage
  // For now, return mock data
  return _getMockTargets();
});

/// Current period target
final currentTargetProvider = Provider<Target?>((ref) {
  final period = ref.watch(targetPeriodProvider);
  final targetsAsync = ref.watch(targetsProvider);

  return targetsAsync.when(
    data: (targets) {
      try {
        return targets.firstWhere((t) => t.period == period);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Helper to generate mock targets
List<Target> _getMockTargets() {
  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 0);

  return [
    Target(
      id: 'daily-1',
      userId: 'user-1',
      periodStart: DateTime(now.year, now.month, now.day),
      periodEnd: DateTime(now.year, now.month, now.day, 23, 59, 59),
      period: TargetPeriod.daily,
      clientVisitsTarget: 5,
      clientVisitsCompleted: 3,
      touchpointsTarget: 10,
      touchpointsCompleted: 6,
      newClientsTarget: 2,
      newClientsAdded: 1,
      createdAt: now,
    ),
    Target(
      id: 'weekly-1',
      userId: 'user-1',
      periodStart: weekStart,
      periodEnd: weekEnd,
      period: TargetPeriod.weekly,
      clientVisitsTarget: 25,
      clientVisitsCompleted: 18,
      touchpointsTarget: 50,
      touchpointsCompleted: 35,
      newClientsTarget: 10,
      newClientsAdded: 7,
      createdAt: weekStart,
    ),
    Target(
      id: 'monthly-1',
      userId: 'user-1',
      periodStart: monthStart,
      periodEnd: monthEnd,
      period: TargetPeriod.monthly,
      clientVisitsTarget: 100,
      clientVisitsCompleted: 45,
      touchpointsTarget: 200,
      touchpointsCompleted: 90,
      newClientsTarget: 40,
      newClientsAdded: 18,
      createdAt: monthStart,
    ),
  ];
}
