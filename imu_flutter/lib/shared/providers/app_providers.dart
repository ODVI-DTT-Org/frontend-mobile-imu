// Re-export connectivity providers
export '../../services/connectivity_service.dart' show isOnlineProvider, connectivityStatusProvider;
// Re-export API service providers
export '../../services/api/client_api_service.dart' show clientApiServiceProvider;
export '../../services/api/touchpoint_api_service.dart' show touchpointApiServiceProvider;
export '../../services/api/attendance_api_service.dart' show attendanceApiServiceProvider;
export '../../services/api/my_day_api_service.dart' show myDayApiServiceProvider;
export '../../services/api/approvals_api_service.dart' show approvalsApiServiceProvider;
export '../../services/api/bulk_delete_api_service.dart' show bulkDeleteApiServiceProvider;
export '../../services/api/upload_api_service.dart' show uploadApiServiceProvider;
export '../../services/api/visit_api_service.dart' show visitApiServiceProvider;
export '../../services/api/release_api_service.dart' show releaseApiServiceProvider;
// Re-export background sync providers
export '../../services/api/background_sync_service.dart' show backgroundSyncServiceProvider, backgroundSyncStatusProvider, BackgroundSyncStatus, BackgroundSyncService;
// Re-export auth providers
export '../../services/auth/jwt_auth_service.dart' show jwtAuthProvider;
export '../../services/auth/offline_auth_service.dart' show offlineAuthProvider;
export './app_providers.dart' show authNotifierProvider;
// Re-export permission providers
export 'permission_providers.dart' show
  permissionServiceProvider,
  cachedPermissionsProvider,
  hasPermissionProvider,
  canCreateProvider,
  canReadProvider,
  canUpdateProvider,
  canDeleteProvider;
// Re-export user providers
export './app_providers.dart' show currentUserRoleProvider;
// Re-export area filter providers
export '../../services/area/area_filter_service.dart' show
  areaFilterServiceProvider;
// Re-export location filter providers
export 'location_filter_providers.dart' show
  locationFilterProvider,
  assignedAreasProvider,
  AssignedAreas;
// Re-export touchpoint count provider
export '../../services/touchpoint/touchpoint_count_service.dart' show
  touchpointCountServiceProvider;
// Re-export PowerSync database provider
export '../../services/sync/powersync_service.dart' show
  powerSyncDatabaseProvider;
// Re-export address and phone number repository providers
export '../../features/clients/data/repositories/address_repository.dart' show
  addressRepositoryProvider;
export '../../features/clients/data/repositories/phone_number_repository.dart' show
  phoneNumberRepositoryProvider;
// Re-export client attribute filter providers
export 'client_attribute_filter_provider.dart' show
  clientAttributeFilterProvider,
  activeFilterCountProvider;
export 'client_filter_options_provider.dart' show
  clientFilterOptionsProvider,
  clientFilterOptionsServiceProvider;
// Re-export client filter types
export '../models/client_attribute_filter.dart' show ClientAttributeFilter;
export '../../services/filter/client_filter_options_service.dart' show ClientFilterOptions;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/search/fuzzy_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/local_storage/hive_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/location/geolocation_service.dart';
import '../../core/services/location_service.dart';
import '../../features/targets/data/models/target_model.dart';
import '../../features/visits/data/models/missed_visit_model.dart';
import '../../features/attendance/data/models/attendance_record.dart';
import '../../features/profile/data/models/user_profile.dart';
import '../../core/models/user_role.dart';
import '../../services/auth/auth_service.dart' show AuthService, AuthNotifier, AuthState, jwtAuthProvider;
import '../../services/auth/offline_auth_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/api/client_api_service.dart';
import '../../services/api/touchpoint_api_service.dart';
import '../../services/api/itinerary_api_service.dart';
import '../../services/api/targets_api_service.dart';
import '../../services/api/attendance_api_service.dart' hide AttendanceRecord;
import '../../services/api/profile_api_service.dart' hide UserProfile;
import '../../services/api/my_day_api_service.dart';
import '../../services/api/approvals_api_service.dart';
import '../../services/api/groups_api_service.dart';
import '../../services/sync/powersync_service.dart';
import '../../services/touchpoint/touchpoint_count_service.dart';
import '../../services/area/area_filter_service.dart';
import '../models/location_filter.dart';
import '../models/client_attribute_filter.dart';
import 'location_filter_providers.dart' show locationFilterProvider;
import 'client_attribute_filter_provider.dart' show clientAttributeFilterProvider;

// ==================== Service Providers ====================

/// Hive service provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Sync service provider - re-exported from sync_service.dart
// This is now defined in lib/services/sync/sync_service.dart

/// Geolocation service provider
final geolocationServiceProvider = Provider<GeolocationService>((ref) {
  return GeolocationService();
});

// Note: connectivityServiceProvider, isOnlineProvider, and connectivityStatusProvider
// are defined in connectivity_service.dart - use that import

// ==================== Auth Providers ====================

/// Provider for authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return AuthService(jwtAuth: jwtAuth);
});

/// Provider for authentication state with initial sync callback
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);

  debugPrint('[AUTH-PROVIDER] Creating authNotifierProvider...');

  // Create initial sync callback that triggers assigned clients sync
  Future<void> onLoginSuccess() async {
    try {
      debugPrint('[INITIAL SYNC] Login successful - triggering initial client sync...');

      // Invalidate assigned clients provider to trigger sync
      // This will fetch all assigned clients from API and cache to Hive
      ref.invalidate(assignedClientsProvider);

      debugPrint('[INITIAL SYNC] Initial client sync triggered');
    } catch (e) {
      debugPrint('[INITIAL SYNC] Failed to trigger initial sync: $e');
    }
  }

  final notifier = AuthNotifier(authService, onLoginSuccess: onLoginSuccess);

  debugPrint('[AUTH-PROVIDER] Calling checkAuthStatus() (without await)...');
  // Check auth status on initialization
  // NOTE: This is called WITHOUT await, so it runs in the background
  // The provider returns immediately, potentially before tokens are loaded
  notifier.checkAuthStatus();

  debugPrint('[AUTH-PROVIDER] Provider created and returned (checkAuthStatus may still be running)');
  return notifier;
});

/// Authentication state - derived from authNotifierProvider
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

/// Current user record
/// TODO: Phase 1 - Update to use new user model from Supabase
final currentUserRecordProvider = Provider<Map<String, dynamic>?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.user == null) return null;
  final user = authState.user!;
  return {
    'id': user.id,
    'email': user.email,
    'first_name': user.firstName,
    'last_name': user.lastName,
  };
});

/// Current user ID - derived from auth state
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.id;
});

/// Current user name - derived from auth state
final currentUserNameProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;
  if (user == null) return null;

  final firstName = user.firstName;
  final lastName = user.lastName;
  final fullName = '$firstName $lastName'.trim();
  return fullName.isNotEmpty ? fullName : user.email;
});

/// Current user email - derived from auth state
final currentUserEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.email;
});

/// Current user role - derived from auth state
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user?.role ?? UserRole.caravan;
});

/// Offline auth service provider
final offlineAuthProvider = Provider<OfflineAuthService>((ref) {
  return OfflineAuthService();
});

// ==================== Client Providers ====================

/// Client by ID provider - fetches a single client from Hive cache
/// Used by router for deep linking to client detail pages and forms
final clientByIdProvider = FutureProvider.family<Client, String>((ref, clientId) async {
  final hiveService = ref.watch(hiveServiceProvider);

  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  final clientData = hiveService.getClient(clientId);
  if (clientData == null) {
    throw Exception('Client not found: $clientId');
  }

  return Client.fromJson(clientData);
});

// ==================== Online-Only Client Providers ====================

/// Online clients search query state
final onlineClientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Online clients pagination state
final onlineClientPageProvider = StateProvider<int>((ref) => 1);

/// Assigned clients search query state
final assignedClientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Assigned clients pagination state
final assignedClientPageProvider = StateProvider<int>((ref) => 1);

/// Assigned clients response metadata (totalItems, totalPages)
final assignedClientsMetaProvider = Provider<ClientsResponse?>((ref) {
  final asyncValue = ref.watch(assignedClientsProvider);
  return asyncValue.when(
    data: (response) => response,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Online clients response metadata (totalItems, totalPages)
final onlineClientsMetaProvider = Provider<ClientsResponse?>((ref) {
  final asyncValue = ref.watch(onlineClientsProvider);
  return asyncValue.when(
    data: (response) => response,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Online clients - fetches clients from REST API with optional location filtering
/// This is used for "All Clients" mode to search the entire client database
/// Supports location filtering via municipality params
/// Supports client attribute filtering (client_type, market_type, pension_type, product_type)
final onlineClientsProvider = FutureProvider<ClientsResponse>((ref) async {
  final isOnline = ref.watch(isOnlineProvider);
  final searchQuery = ref.watch(onlineClientSearchQueryProvider);
  final page = ref.watch(onlineClientPageProvider);
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);

  // Must be online to fetch all clients
  if (!isOnline) {
    debugPrint('onlineClientsProvider: Device is offline, cannot fetch online clients');
    throw Exception('Device is offline. Please connect to the internet to search all clients.');
  }

  try {
    debugPrint('onlineClientsProvider: Fetching clients from online API...');
    debugPrint('onlineClientsProvider: Search query: "$searchQuery", Page: $page');
    debugPrint('onlineClientsProvider: Location filter: ${locationFilter.toQueryParams()}');
    debugPrint('onlineClientsProvider: Attribute filter: ${attributeFilter.toQueryParams()}');

    final clientApi = ref.watch(clientApiServiceProvider);

    // Convert location filter to municipality IDs list
    // Format: "PROVINCE-MUNICIPALITY" (e.g., "PANGASINAN-DAGUPAN CITY")
    List<String>? municipalityIds;
    if (locationFilter.hasFilter && locationFilter.municipalities != null && locationFilter.municipalities!.isNotEmpty) {
      municipalityIds = locationFilter.municipalities!.map((municipality) {
        // Create ID in format: PROVINCE-MUNICIPALITY
        final province = locationFilter.province ?? '';
        return '$province-$municipality';
      }).toList();
      debugPrint('onlineClientsProvider: Converted to municipality IDs: $municipalityIds');
    }

    // Convert attribute filter to API parameters
    final queryParams = attributeFilter.toQueryParams();

    final response = await clientApi.fetchClients(
      page: page,
      perPage: 10, // Paginate 10 items per page
      search: searchQuery.isNotEmpty ? searchQuery : null,
      clientType: queryParams['client_type'],
      marketType: queryParams['market_type'],
      pensionType: queryParams['pension_type'],
      productType: queryParams['product_type'],
      municipalityIds: municipalityIds,
    );

    debugPrint('onlineClientsProvider: Got ${response.items.length} clients from API (page ${response.page} of ${response.totalPages}, total: ${response.totalItems})');
    return response;
  } catch (e) {
    debugPrint('onlineClientsProvider: Failed to fetch clients - $e');
    rethrow;
  }
});

/// Assigned clients - Uses Hive cache with API refresh in background
/// This is used for "Assigned Clients" mode to show clients in user's territory
///
/// Strategy:
/// 1. Load from Hive cache immediately (fast, works offline)
/// 2. Apply pagination locally
/// 3. If cache is empty AND online, fetch immediately from API (not background)
/// 4. If cache has data AND online, trigger background refresh from API
/// 5. Update Hive cache when API returns
final assignedClientsProvider = FutureProvider<ClientsResponse>((ref) async {
  final isOnline = ref.watch(isOnlineProvider);
  final searchQuery = ref.watch(assignedClientSearchQueryProvider);
  final page = ref.watch(assignedClientPageProvider);
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);
  final hiveService = ref.watch(hiveServiceProvider);

  debugPrint('=== ASSIGNED CLIENTS FETCH ===');
  debugPrint('Is Online: $isOnline');
  debugPrint('Search query: "$searchQuery", Page: $page');
  debugPrint('Location filter: ${locationFilter.toQueryParams()}');
  debugPrint('Attribute filter: ${attributeFilter.toQueryParams()}');

  // Initialize Hive if needed
  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  // Step 1: Load from Hive cache immediately
  debugPrint('assignedClientsProvider: Loading from Hive cache...');
  final clientsData = hiveService.getAllClients();

  // Parse clients with error handling to skip invalid records
  var cachedClients = <Client>[];
  for (final data in clientsData) {
    try {
      final client = Client.fromJson(data);
      cachedClients.add(client);
    } catch (e) {
      debugPrint('assignedClientsProvider: Error parsing client data - $e');
      debugPrint('assignedClientsProvider: Skipping invalid client record');
      // Continue with next client instead of failing entire provider
    }
  }

  debugPrint('assignedClientsProvider: Got ${cachedClients.length} clients from Hive cache');

  // Step 2: If cache is empty AND online, fetch immediately from API (not background)
  // This ensures data is loaded even if background refresh fails or is skipped
  if (cachedClients.isEmpty && isOnline) {
    debugPrint('assignedClientsProvider: Cache empty and online - fetching IMMEDIATELY from API...');
    try {
      final clientApi = ref.read(clientApiServiceProvider);
      final queryParams = attributeFilter.toQueryParams();
      final response = await clientApi.fetchAssignedClients(
        page: 1,
        perPage: 100,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        clientType: queryParams['client_type'],
        marketType: queryParams['market_type'],
        pensionType: queryParams['pension_type'],
        productType: queryParams['product_type'],
        province: locationFilter.province,
        municipality: locationFilter.municipalities?.join(','),
      );

      final fetchedClients = response.items;
      debugPrint('assignedClientsProvider: Immediate fetch - Got ${fetchedClients.length} clients from API');

      // Update Hive cache with fetched data
      if (fetchedClients.isNotEmpty) {
        for (final client in fetchedClients) {
          final clientJson = client.toJson();
          final clientId = client.id;
          if (clientJson != null && clientId != null) {
            await hiveService.saveClient(clientId, clientJson);
          }
        }
        debugPrint('assignedClientsProvider: Immediate fetch - Cached ${fetchedClients.length} clients to Hive');

        // Update cached clients with fetched data
        cachedClients = fetchedClients;
      }
    } catch (e) {
      debugPrint('assignedClientsProvider: Immediate fetch failed - $e');
      // Fall back to empty cache - UI will show empty state
    }
  } else if (isOnline) {
    // Step 3: If cache has data AND online, trigger background refresh from API
    // Don't wait - trigger in background
    _refreshAssignedClientsFromApi(ref, hiveService, searchQuery, locationFilter, attributeFilter);
  }

  // Apply location filter locally if needed
  if (locationFilter.hasFilter) {
    debugPrint('assignedClientsProvider: Applying location filter locally - province: ${locationFilter.province}, municipalities: ${locationFilter.municipalities}');
    cachedClients = cachedClients.where((c) {
      // Check if client's province matches filter
      if (locationFilter.province != null && c.province != locationFilter.province) {
        return false;
      }
      // Check if client's municipality matches filter (if specified)
      if (locationFilter.municipalities != null && locationFilter.municipalities!.isNotEmpty) {
        if (!locationFilter.municipalities!.contains(c.municipality)) {
          return false;
        }
      }
      return true;
    }).toList();
    debugPrint('assignedClientsProvider: After location filter - ${cachedClients.length} clients');
  }

  // Apply attribute filter locally if needed
  if (attributeFilter.hasFilter) {
    debugPrint('assignedClientsProvider: Applying attribute filter locally - ${attributeFilter.toQueryParams()}');
    cachedClients = cachedClients.where((client) => attributeFilter.matches(client)).toList();
    debugPrint('assignedClientsProvider: After attribute filter - ${cachedClients.length} clients');
  }

  // Apply fuzzy search filter locally if needed
  if (searchQuery.isNotEmpty) {
    debugPrint('assignedClientsProvider: Applying fuzzy search for query: "$searchQuery"');
    final fuzzyService = FuzzySearchService(cachedClients);
    cachedClients = fuzzyService.searchByName(searchQuery);
    debugPrint('assignedClientsProvider: After fuzzy search filter - ${cachedClients.length} clients');
  }

  // Calculate pagination locally
  const itemsPerPage = 10;
  final totalItems = cachedClients.length;
  final totalPages = (totalItems / itemsPerPage).ceil();
  final startIndex = (page - 1) * itemsPerPage;
  final endIndex = (startIndex + itemsPerPage).clamp(0, totalItems);
  final paginatedClients = cachedClients.sublist(startIndex, endIndex);

  debugPrint('assignedClientsProvider: Showing ${paginatedClients.length} of $totalItems clients (page $page of $totalPages) from cache');

  // Return cached data immediately
  debugPrint('=== ASSIGNED CLIENTS FETCH COMPLETE ===');
  return ClientsResponse(
    items: paginatedClients,
    page: page,
    perPage: itemsPerPage,
    totalItems: totalItems,
    totalPages: totalPages,
  );
});

/// Background refresh function - fetches from API and updates Hive cache
/// Includes location filter support for province/municipality filtering
/// Includes client attribute filter support (client_type, market_type, pension_type, product_type)
void _refreshAssignedClientsFromApi(
  FutureProviderRef<ClientsResponse> ref,
  HiveService hiveService,
  String searchQuery,
  LocationFilter locationFilter,
  ClientAttributeFilter attributeFilter,
) async {
  try {
    debugPrint('assignedClientsProvider: Background refresh from API...');
    debugPrint('assignedClientsProvider: Background refresh - Location filter: ${locationFilter.toQueryParams()}');
    debugPrint('assignedClientsProvider: Background refresh - Attribute filter: ${attributeFilter.toQueryParams()}');

    final clientApi = ref.read(clientApiServiceProvider);
    final queryParams = attributeFilter.toQueryParams();

    // Fetch all pages from /clients/assigned
    final allClients = <Client>[];
    int currentPage = 1;
    int totalFetched = 0;
    int totalCount = 0;
    const int perPage = 100; // Fetch more per page to reduce API calls

    do {
      final response = await clientApi.fetchAssignedClients(
        page: currentPage,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        clientType: queryParams['client_type'],
        marketType: queryParams['market_type'],
        pensionType: queryParams['pension_type'],
        productType: queryParams['product_type'],
        province: locationFilter.province,
        municipality: locationFilter.municipalities?.join(','),
      );

      totalCount = response.totalItems.toInt();
      final clients = response.items;
      totalFetched += clients.length;
      allClients.addAll(clients);

      debugPrint('assignedClientsProvider: Background refresh - Fetched page $currentPage - ${clients.length} clients (total: $totalFetched/$totalCount)');

      currentPage++;
    } while (totalFetched < totalCount);

    // Update Hive cache
    if (allClients.isNotEmpty) {
      for (final client in allClients) {
        final clientJson = client.toJson();
        final clientId = client.id;
        if (clientJson != null && clientId != null) {
          await hiveService.saveClient(clientId, clientJson);
        }
      }
      debugPrint('assignedClientsProvider: Background refresh - Cached ${allClients.length} clients to Hive');
    }
  } catch (e) {
    debugPrint('assignedClientsProvider: Background refresh failed - $e');
    // Silently fail - UI will continue using cached data
  }
}

/// Provider for user's assigned municipality IDs
/// Fetches and caches the user's assigned municipalities from the backend
final assignedMunicipalitiesProvider = FutureProvider<List<String>>((ref) async {
  // Import and use jwtAuthProvider from auth_service.dart
  final jwtAuth = ref.watch(jwtAuthProvider);
  final token = jwtAuth.accessToken;

  if (token == null) {
    return [];
  }

  final userId = jwtAuth.currentUser?.id ?? '';
  if (userId.isEmpty) {
    return [];
  }

  final areaFilterService = ref.watch(areaFilterServiceProvider);
  final locations = await areaFilterService.fetchUserLocations(token, userId);

  return locations.map((l) => l.municipalityId).toSet().toList();
});

/// Selected client ID
final selectedClientIdProvider = StateProvider<String?>((ref) => null);

/// Selected client
final selectedClientProvider = Provider<Client?>((ref) {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return null;

  final clientsAsync = ref.watch(assignedClientsProvider);
  return clientsAsync.when(
    data: (response) {
      try {
        return response.items.firstWhere((c) => c.id == clientId);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== Touchpoint Providers ====================

/// Touchpoints for selected client from Hive (used by touchpoint form)
/// Kept for offline touchpoint creation
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

/// Touchpoints for selected client from PowerSync (used by client selector)
/// Provides real-time synced touchpoint data for status display
final clientTouchpointsSyncProvider = FutureProvider.autoDispose<List<Touchpoint>>((ref) async {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return [];

  // Query PowerSync for touchpoints
  final touchpoints = await PowerSyncService.query('''
    SELECT t.id, t.client_id, t.user_id, t.touchpoint_number, t.type,
           t.date, t.time_arrival, t.time_departure, t.reason, t.status,
           t.notes, t.photo_path, t.audio_path,
           t.latitude, t.longitude,
           t.time_in, t.time_in_gps_lat, t.time_in_gps_lng, t.time_in_gps_address,
           t.time_out, t.time_out_gps_lat, t.time_out_gps_lng, t.time_out_gps_address
    FROM touchpoints t
    WHERE t.client_id = ?
    ORDER BY t.touchpoint_number ASC
  ''', [clientId]);

  // Fallback to Hive if PowerSync empty (migration safety)
  if (touchpoints.isEmpty) {
    final hiveService = ref.watch(hiveServiceProvider);
    if (!hiveService.isInitialized) {
      await hiveService.init();
    }
    final touchpointsData = hiveService.getTouchpointsForClient(clientId);
    return touchpointsData.map((data) => Touchpoint.fromJson(data)).toList();
  }

  return touchpoints.map((row) => Touchpoint.fromRow(row)).toList();
});

/// Touchpoint counts for multiple clients from PowerSync (with API fallback)
/// Returns Map<String, int> where key is client_id and value is touchpoint count
/// Used by ClientListTile and ClientSelectorModal to display accurate progress badges
///
/// Cache: 5-minute TTL auto-refresh
/// Invalidation: Automatically refreshes when client list changes
/// Fallback: API call when PowerSync query fails (only when online)
final clientTouchpointCountsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  // Determine which client provider is currently active
  final clientsAsync = ref.watch(assignedClientsProvider);

  // Extract client IDs from the clients list
  final clientIds = clientsAsync.when(
    data: (response) => response.items
        .map((client) => client.id!)
        .where((id) => id.isNotEmpty)
        .toList(),
    loading: () => <String>[],
    error: (_, __) => <String>[],
  );

  if (clientIds.isEmpty) return {};

  // Use service to fetch counts
  final service = ref.watch(touchpointCountServiceProvider);
  return await service.fetchCounts(clientIds);
});

// ==================== Sync Providers ====================

/// Sync status - re-exported from sync_service.dart
// This is now defined in lib/services/sync/sync_service.dart

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

/// Loading overlay message
final loadingMessageProvider = StateProvider<String?>((ref) => null);

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

// ==================== Target Providers ====================

/// Selected target period
final targetPeriodProvider = StateProvider<TargetPeriod>((ref) {
  return TargetPeriod.weekly;
});

/// Current targets - uses API when online
final targetsProvider = FutureProvider<List<Target>>((ref) async {
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      final targetsApi = ref.watch(targetsApiServiceProvider);
      final targets = await targetsApi.fetchTargets();
      if (targets.isNotEmpty) return targets;
    } catch (e) {
      debugPrint('Failed to fetch targets from API: $e');
    }
  }

  // Return empty list if no targets available
  return [];
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


// ==================== Missed Visits Providers ====================

/// Missed visits filter
final missedVisitsFilterProvider = StateProvider<MissedVisitPriority?>((ref) {
  return null; // null means show all
});

/// Compute missed visits from clients and touchpoints
final missedVisitsProvider = Provider<List<MissedVisit>>((ref) {
  final clientsAsync = ref.watch(assignedClientsProvider);

  return clientsAsync.when(
    data: (response) {
      final missedVisits = <MissedVisit>[];

      for (final client in response.items) {
        // Get the next expected touchpoint
        final nextTouchpointNum = client.completedTouchpoints + 1;
        if (nextTouchpointNum > 7) continue; // All touchpoints completed

        final nextType = client.nextTouchpointType;
        if (nextType == null) continue;

        // Determine scheduled date based on last touchpoint or client creation
        DateTime scheduledDate;
        if (client.touchpointSummary.isNotEmpty) {
          final lastTouchpoint = client.touchpointSummary.last;
          // Schedule next touchpoint 3 days after last one
          scheduledDate = lastTouchpoint.date.add(const Duration(days: 3));
        } else {
          // If no touchpoints, check if client was created more than 3 days ago
          scheduledDate = (client.createdAt ?? DateTime.now()).add(const Duration(days: 3));
        }

        // Check if overdue
        if (DateTime.now().isAfter(scheduledDate)) {
          final primaryPhone = client.phone;
          final primaryAddress = client.fullAddress;

          if (client.id == null) continue; // Skip clients without ID
          missedVisits.add(MissedVisit(
            id: '${client.id}_$nextTouchpointNum',
            clientId: client.id!,
            clientName: client.fullName,
            touchpointNumber: nextTouchpointNum,
            touchpointType: nextType,
            scheduledDate: scheduledDate,
            createdAt: DateTime.now(),
            primaryPhone: primaryPhone,
            primaryAddress: primaryAddress,
          ));
        }
      }

      // Sort by priority (high first) then by days overdue
      missedVisits.sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return b.daysOverdue.compareTo(a.daysOverdue);
      });

      return missedVisits;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Filtered missed visits by priority
final filteredMissedVisitsProvider = Provider<List<MissedVisit>>((ref) {
  final missedVisits = ref.watch(missedVisitsProvider);
  final filter = ref.watch(missedVisitsFilterProvider);

  if (filter == null) return missedVisits;

  return missedVisits.where((v) => v.priority == filter).toList();
});

/// Missed visits count by priority
final missedVisitsCountProvider = Provider<Map<MissedVisitPriority, int>>((ref) {
  final missedVisits = ref.watch(missedVisitsProvider);

  return {
    MissedVisitPriority.high: missedVisits.where((v) => v.priority == MissedVisitPriority.high).length,
    MissedVisitPriority.medium: missedVisits.where((v) => v.priority == MissedVisitPriority.medium).length,
    MissedVisitPriority.low: missedVisits.where((v) => v.priority == MissedVisitPriority.low).length,
  };
});

// ==================== Attendance Providers ====================

/// Attendance records box name
const _attendanceBox = 'attendance';

/// Today's attendance record
final todayAttendanceProvider = StateNotifierProvider<TodayAttendanceNotifier, AttendanceRecord?>((ref) {
  return TodayAttendanceNotifier(ref.watch(hiveServiceProvider), ref);
});

/// Is user currently checked in
final isCheckedInProvider = Provider<bool>((ref) {
  final today = ref.watch(todayAttendanceProvider);
  return today?.status == AttendanceStatus.checkedIn;
});

/// Attendance history (last 14 days)
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);
  if (!hiveService.isInitialized) await hiveService.init();

  final records = <AttendanceRecord>[];
  final box = Hive.box<String>(_attendanceBox);

  final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

  for (final key in box.keys) {
    final data = box.get(key);
    if (data != null) {
      final record = AttendanceRecord.fromJson(
        Map<String, dynamic>.from(const JsonDecoder().convert(data)),
      );
      if (record.date.isAfter(twoWeeksAgo)) {
        records.add(record);
      }
    }
  }

  records.sort((a, b) => b.date.compareTo(a.date));
  return records;
});

/// Attendance stats for current month
final attendanceStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final historyAsync = ref.watch(attendanceHistoryProvider);
  final now = DateTime.now();

  return historyAsync.when(
    data: (records) {
      final monthRecords = records.where((r) =>
        r.date.month == now.month && r.date.year == now.year
      ).toList();

      final completeDays = monthRecords.where((r) => r.status == AttendanceStatus.checkedOut).length;
      final totalHours = monthRecords.fold<double>(0, (sum, r) => sum + (r.totalHours ?? 0));

      return {
        'daysWorked': completeDays,
        'totalHours': totalHours.toStringAsFixed(1),
        'averageHours': completeDays > 0 ? (totalHours / completeDays).toStringAsFixed(1) : '0',
      };
    },
    loading: () => {'daysWorked': 0, 'totalHours': '0', 'averageHours': '0'},
    error: (_, __) => {'daysWorked': 0, 'totalHours': '0', 'averageHours': '0'},
  );
});

/// Today's Attendance Notifier
class TodayAttendanceNotifier extends StateNotifier<AttendanceRecord?> {
  final HiveService _hiveService;
  final Ref _ref;
  bool _isLoading = false;

  TodayAttendanceNotifier(this._hiveService, this._ref) : super(null) {
    _loadToday();
  }

  bool get isLoading => _isLoading;

  Future<void> _loadToday() async {
    _isLoading = true;
    try {
      if (!_hiveService.isInitialized) await _hiveService.init();
      final today = _formatDate(DateTime.now());
      final box = Hive.box<String>(_attendanceBox);
      final data = box.get(today);

      if (data != null) {
        state = AttendanceRecord.fromJson(
          Map<String, dynamic>.from(const JsonDecoder().convert(data)),
        );
      } else {
        state = null;
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> checkIn(AttendanceLocation location) async {
    final now = DateTime.now();
    final userId = _ref.read(currentUserIdProvider);

    if (userId == null) {
      debugPrint('TodayAttendanceNotifier: Cannot check in - no user ID available');
      return;
    }

    final record = AttendanceRecord(
      id: _formatDate(now),
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInLocation: location,
      status: AttendanceStatus.checkedIn,
    );

    // ✅ FIXED: Call API to sync to database when online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      try {
        final attendanceApi = _ref.read(attendanceApiServiceProvider);
        final apiRecord = await attendanceApi.checkIn(
          latitude: location.latitude,
          longitude: location.longitude,
          notes: location.address,
        );
        debugPrint('TodayAttendanceNotifier: Check-in synced to database');
      } catch (e) {
        debugPrint('TodayAttendanceNotifier: Failed to sync check-in to database: $e');
        // Continue with local save even if API fails
      }
    }

    await _saveRecord(record);
    state = record;
  }

  Future<void> checkOut(AttendanceLocation location) async {
    if (state == null) return;

    final now = DateTime.now();
    final record = state!.copyWith(
      checkOutTime: now,
      checkOutLocation: location,
      status: AttendanceStatus.checkedOut,
    );

    // ✅ FIXED: Call API to sync to database when online
    final isOnline = _ref.read(isOnlineProvider);
    if (isOnline) {
      try {
        final attendanceApi = _ref.read(attendanceApiServiceProvider);
        final apiRecord = await attendanceApi.checkOut(
          latitude: location.latitude,
          longitude: location.longitude,
          notes: location.address,
        );
        debugPrint('TodayAttendanceNotifier: Check-out synced to database');
      } catch (e) {
        debugPrint('TodayAttendanceNotifier: Failed to sync check-out to database: $e');
        // Continue with local save even if API fails
      }
    }

    await _saveRecord(record);
    state = record;
  }

  Future<void> _saveRecord(AttendanceRecord record) async {
    final box = Hive.box<String>(_attendanceBox);
    await box.put(record.id, const JsonEncoder().convert(record.toJson()));
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

// ==================== Profile Providers ====================

/// Current user profile - uses API when online
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier(ref);
});

/// Is profile loading
final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider) == null;
});

/// Profile Notifier
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  final Ref _ref;
  bool _isLoading = false;

  UserProfileNotifier(this._ref) : super(null) {
    _loadProfile();
  }

  bool get isLoading => _isLoading;

  Future<void> _loadProfile() async {
    _isLoading = true;
    try {
      final isOnline = _ref.read(isOnlineProvider);
      final userId = _ref.read(currentUserIdProvider);

      if (isOnline && userId != null) {
        try {
          final profileApi = _ref.read(profileApiServiceProvider);
          final profile = await profileApi.fetchProfile(userId);
          if (profile != null) {
            state = _convertToUserProfile(profile);
            return;
          }
        } catch (e) {
          debugPrint('Failed to fetch profile from API: $e');
        }
      }

      // No profile available - return null
      state = null;
    } finally {
      _isLoading = false;
    }
  }

  UserProfile _convertToUserProfile(dynamic apiProfile) {
    // Handle both UserProfile from API and mock data
    if (apiProfile is UserProfile) {
      return apiProfile;
    }
    // Fallback for raw data
    return UserProfile(
      id: apiProfile.id ?? '',
      firstName: apiProfile.firstName ?? '',
      lastName: apiProfile.lastName ?? '',
      email: apiProfile.email ?? '',
      phone: apiProfile.phone ?? '',
      employeeId: apiProfile.employeeId ?? apiProfile.id?.toString().substring(0, 8).toUpperCase() ?? '',
      role: apiProfile.role ?? 'Field Agent',
      profilePhotoUrl: apiProfile.profilePhotoUrl,
      createdAt: apiProfile.createdAt ?? DateTime.now(),
      updatedAt: apiProfile.updatedAt,
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    final isOnline = _ref.read(isOnlineProvider);
    final userId = _ref.read(currentUserIdProvider);

    if (isOnline && userId != null) {
      try {
        final profileApi = _ref.read(profileApiServiceProvider);
        await profileApi.updateProfile(userId, {
          'first_name': profile.firstName,
          'last_name': profile.lastName,
          'phone': profile.phone,
        });
      } catch (e) {
        debugPrint('Failed to update profile via API: $e');
      }
    }

    state = profile.copyWith(updatedAt: DateTime.now());
  }

  Future<void> logout() async {
    state = null;
  }
}
