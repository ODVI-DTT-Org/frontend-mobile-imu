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
export '../../services/auth/auth_service.dart' show jwtAuthProvider;
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
// Re-export creation service providers
export './app_providers.dart' show touchpointCreationServiceProvider;
export './app_providers.dart' show visitCreationServiceProvider;
export './app_providers.dart' show releaseCreationServiceProvider;
export './app_providers.dart' show clientMutationServiceProvider;
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
// Re-export touchpoint creation service provider
export '../../services/touchpoint/touchpoint_creation_service.dart' show
  TouchpointCreationService;
// Re-export PowerSync database provider
export '../../services/sync/powersync_service.dart' show
  powerSyncDatabaseProvider;
// Re-export address and phone number repository providers
export '../../features/clients/data/repositories/address_repository.dart' show
  addressRepositoryProvider;
export '../../features/clients/data/repositories/phone_number_repository.dart' show
  phoneNumberRepositoryProvider;
// Re-export PowerSync feature repository providers
export './app_providers.dart' show
  visitRepositoryProvider,
  attendanceRepositoryProvider,
  groupRepositoryProvider,
  targetRepositoryProvider,
  visitsByClientProvider,
  currentMonthTargetProvider,
  myDayClientsProvider,
  powersyncGroupsProvider,
  refreshAssignedClientsProvider;
// Re-export client attribute filter providers
export 'client_attribute_filter_provider.dart' show
  clientAttributeFilterProvider,
  activeFilterCountProvider;
export 'touchpoint_filter_provider.dart' show touchpointFilterProvider, TouchpointFilterNotifier;
export 'client_filter_options_provider.dart' show
  clientFilterOptionsProvider,
  clientFilterOptionsServiceProvider;
// Re-export client filter types
export '../models/client_attribute_filter.dart' show ClientAttributeFilter;
export '../models/client_filter_options.dart' show ClientFilterOptions;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/search/fuzzy_search_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';
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
import '../../services/api/attendance_api_service.dart' hide AttendanceRecord;
import '../../services/api/profile_api_service.dart' hide UserProfile;
import '../../services/api/my_day_api_service.dart';
import '../../services/api/approvals_api_service.dart';
import '../../services/sync/powersync_service.dart';
import '../../services/touchpoint/touchpoint_count_service.dart';
import '../../services/touchpoint/touchpoint_creation_service.dart';
import '../../services/visit/visit_creation_service.dart';
import '../../services/release/release_creation_service.dart';
import '../../services/client/client_mutation_service.dart';
import '../../services/api/visit_api_service.dart' show VisitApiService, visitApiServiceProvider;
import '../../services/api/release_api_service.dart' show releaseApiServiceProvider;
import '../../services/api/upload_api_service.dart' show UploadApiService, uploadApiServiceProvider;
import '../../services/area/area_filter_service.dart';
import '../models/location_filter.dart';
import '../models/client_attribute_filter.dart';
import 'location_filter_providers.dart' show locationFilterProvider;
import 'client_attribute_filter_provider.dart' show clientAttributeFilterProvider;
import 'touchpoint_filter_provider.dart' show touchpointFilterProvider;
import '../../features/visits/data/models/visit_model.dart';
import '../../features/visits/data/repositories/visit_repository.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../../features/clients/data/repositories/client_repository.dart';
import '../../features/groups/data/models/group_model.dart';
import '../../features/groups/data/repositories/group_repository.dart';
import '../../features/targets/data/repositories/target_repository.dart';
import '../../features/my_day/data/models/my_day_client.dart';
import '../../features/my_day/presentation/providers/my_day_provider.dart' show myDayStateProvider;
import '../../services/local_storage/hive_service.dart';

// ==================== Service Providers ====================


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

  // Fetch all assigned clients from REST API → cache in Hive on login.
  Future<void> onLoginSuccess() async {
    try {
      debugPrint('[INITIAL SYNC] Login successful - fetching assigned clients into Hive cache...');

      final clientApiService = ref.read(clientApiServiceProvider);
      final hiveService = HiveService();

      final clients = await clientApiService.fetchAllAssignedClients();
      final clientJsons = clients.map((c) => c.toJson()).toList();
      await hiveService.saveAllClients(clientJsons);
      await hiveService.saveSetting('clients_last_fetch_ms', DateTime.now().millisecondsSinceEpoch);
      await hiveService.saveSetting('clients_cache_version', 3);

      ref.invalidate(assignedClientsProvider);

      debugPrint('[INITIAL SYNC] Cached ${clients.length} clients into Hive');
    } catch (e) {
      debugPrint('[INITIAL SYNC] Failed to populate Hive cache: $e');
      // Still invalidate so assignedClientsProvider shows whatever is in cache
      ref.invalidate(assignedClientsProvider);
    }
  }

  void onLogout() {
    // Invalidate the cached PowerSync database so the next login gets a fresh instance.
    // Without this, login → logout → login reuses a closed database and hangs on sync page.
    ref.invalidate(powerSyncDatabaseProvider);
    debugPrint('[AUTH] powerSyncDatabaseProvider invalidated on logout');
    // Clear Hive client cache so the next login starts fresh
    HiveService().clearClients().catchError((e) {
      debugPrint('[AUTH] Failed to clear Hive client cache on logout: $e');
      return Future<void>.value();
    });
  }

  final notifier = AuthNotifier(authService, onLoginSuccess: onLoginSuccess, onLogout: onLogout);

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

/// Client by ID provider - fetches a single client from PowerSync SQLite
/// Used by router for deep linking to client detail pages and forms
final clientByIdProvider = FutureProvider.family<Client, String>((ref, clientId) async {
  // Try Hive cache first (has embedded addresses + phoneNumbers)
  final hiveService = HiveService();
  final cachedJson = hiveService.getClient(clientId);
  if (cachedJson != null) {
    return Client.fromJson(cachedJson);
  }
  // Fallback: PowerSync SQLite (no addresses/phones, but better than nothing offline)
  final clientRepo = ref.watch(clientRepositoryProvider);
  final client = await clientRepo.getClient(clientId);
  if (client == null) throw Exception('Client not found: $clientId');
  return client;
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
  final touchpointFilter = ref.watch(touchpointFilterProvider);

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
      loanType: queryParams['loan_type'],
      municipalityIds: municipalityIds,
    );

    // Apply touchpoint filter locally on loaded results
    if (touchpointFilter.hasFilter) {
      final filteredItems = response.items
          .where((client) => touchpointFilter.matches(client))
          .toList();
      return ClientsResponse(
        items: filteredItems,
        page: response.page,
        perPage: response.perPage,
        totalItems: filteredItems.length,
        totalPages: response.totalPages,
      );
    }

    debugPrint('onlineClientsProvider: Got ${response.items.length} clients from API (page ${response.page} of ${response.totalPages}, total: ${response.totalItems})');
    return response;
  } catch (e) {
    debugPrint('onlineClientsProvider: Failed to fetch clients - $e');
    rethrow;
  }
});

/// Assigned clients — reads from Hive cache, applies filters/search/pagination locally.
/// Cache is populated on login via REST API (fetchAllAssignedClients).
final assignedClientsProvider = FutureProvider<ClientsResponse>((ref) async {
  final searchQuery = ref.watch(assignedClientSearchQueryProvider);
  final page = ref.watch(assignedClientPageProvider);
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);
  final touchpointFilter = ref.watch(touchpointFilterProvider);

  debugPrint('=== ASSIGNED CLIENTS FETCH ===');
  debugPrint('Search query: "$searchQuery", Page: $page');

  // Load from Hive cache (populated on login from REST API)
  final hiveService = HiveService();
  var rawClients = hiveService.getAllClients();

  // Bump this when the API response shape changes so stale caches are cleared.
  const kCacheVersion = 3;

  // Startup hydration: fetch from API if:
  //  - cache is empty
  //  - previous fetch was killed mid-way (no timestamp written)
  //  - cache schema version is outdated (stale data from a prior API shape)
  final lastFetchMs = hiveService.getSetting<int>('clients_last_fetch_ms');
  final cacheVersion = hiveService.getSetting<int>('clients_cache_version');
  if (rawClients.isEmpty || lastFetchMs == null || cacheVersion != kCacheVersion) {
    final isOnline = ref.read(isOnlineProvider);
    final jwtAuth = ref.read(jwtAuthProvider);
    if (isOnline && jwtAuth.isAuthenticated) {
      try {
        debugPrint('assignedClientsProvider: Cache empty - hydrating from API...');
        final clientApi = ref.read(clientApiServiceProvider);
        final clients = await clientApi.fetchAllAssignedClients();
        final clientJsons = clients.map((c) => c.toJson()).toList();
        await hiveService.saveAllClients(clientJsons);
        await hiveService.saveSetting('clients_last_fetch_ms', DateTime.now().millisecondsSinceEpoch);
        await hiveService.saveSetting('clients_cache_version', kCacheVersion);
        rawClients = hiveService.getAllClients();
        debugPrint('assignedClientsProvider: Hydrated ${rawClients.length} clients from API');
      } catch (e) {
        debugPrint('assignedClientsProvider: Startup hydration failed: $e');
      }
    }
  }

  var cachedClients = rawClients.map((json) => Client.fromJson(json)).toList();

  debugPrint('assignedClientsProvider: Got ${cachedClients.length} clients from Hive cache');

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

  // Apply touchpoint filter locally
  if (touchpointFilter.hasFilter) {
    cachedClients = cachedClients
        .where((client) => touchpointFilter.matches(client))
        .toList();
    debugPrint('assignedClientsProvider: After touchpoint filter - ${cachedClients.length} clients');
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


/// Callable that re-fetches all assigned clients from the REST API, saves to Hive,
/// and invalidates [assignedClientsProvider] so the UI rebuilds with fresh data.
/// Wire to pull-to-refresh and app-resume events.
final refreshAssignedClientsProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final clientApi = ref.read(clientApiServiceProvider);
    final hive = HiveService();
    final clients = await clientApi.fetchAllAssignedClients();
    final clientJsons = clients.map((c) => c.toJson()).toList();
    await hive.saveAllClients(clientJsons);
    await hive.saveSetting('clients_last_fetch_ms', DateTime.now().millisecondsSinceEpoch);
    ref.invalidate(assignedClientsProvider);
    debugPrint('refreshAssignedClientsProvider: Refreshed ${clients.length} clients');
  };
});

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

/// Touchpoints for selected client from Hive cache (used by touchpoint form)
final clientTouchpointsProvider = FutureProvider<List<Touchpoint>>((ref) async {
  final clientId = ref.watch(selectedClientIdProvider);
  if (clientId == null) return [];
  // Hive cache has touchpoint_summary embedded in client JSON
  final cachedJson = HiveService().getClient(clientId);
  if (cachedJson != null) {
    return Client.fromJson(cachedJson).touchpointSummary;
  }
  // Fallback: PowerSync SQLite
  final client = await ref.watch(clientRepositoryProvider).getClient(clientId);
  return client?.touchpointSummary ?? [];
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

/// Touchpoint creation service provider
final touchpointCreationServiceProvider = Provider<TouchpointCreationService>((ref) {
  return TouchpointCreationService();
});

/// Visit creation service provider
final visitCreationServiceProvider = Provider<VisitCreationService>((ref) {
  return VisitCreationService();
});

/// Release creation service provider
final releaseCreationServiceProvider = Provider<ReleaseCreationService>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  final releaseApi = ref.watch(releaseApiServiceProvider);
  final visitApi = ref.watch(visitApiServiceProvider);
  final approvalsApi = ref.watch(approvalsApiServiceProvider);
  final uploadApi = ref.watch(uploadApiServiceProvider);
  final role = ref.watch(currentUserRoleProvider);
  return ReleaseCreationService(connectivity, releaseApi, visitApi, approvalsApi, uploadApi, role);
});

/// Client mutation service provider
final clientMutationServiceProvider = Provider<ClientMutationService>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  final approvalsApi = ref.watch(approvalsApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);
  return ClientMutationService(role: role, approvalsApi: approvalsApi, isOnline: isOnline);
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

// ==================== PowerSync Repository Providers ====================

/// Repository providers for reading from local PowerSync SQLite
final visitRepositoryProvider = Provider<VisitRepository>((_) => VisitRepository());
final attendanceRepositoryProvider = Provider<AttendanceRepository>((_) => AttendanceRepository());
final groupRepositoryProvider = Provider<GroupRepository>((_) => GroupRepository());
final targetRepositoryProvider = Provider<TargetRepository>((_) => TargetRepository());

/// Visits for a specific client — live stream from PowerSync SQLite.
final visitsByClientProvider = StreamProvider.family<List<Visit>, String>((ref, clientId) {
  final repo = ref.watch(visitRepositoryProvider);
  return repo.watchByClientId(clientId);
});

/// Current month's target — live stream from PowerSync SQLite.
final currentMonthTargetProvider = StreamProvider<Target?>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) { yield null; return; }
  final repo = ref.watch(targetRepositoryProvider);
  yield* repo.watchCurrentMonthTarget(userId);
});

/// Today's My Day clients — derived from myDayStateProvider.
final myDayClientsProvider = Provider<List<MyDayClient>>((ref) {
  return ref.watch(myDayStateProvider).clients;
});

/// Groups for the current user — live stream from PowerSync SQLite.
final powersyncGroupsProvider = StreamProvider<List<ClientGroup>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) { yield <ClientGroup>[]; return; }
  final repo = ref.watch(groupRepositoryProvider);
  yield* repo.watchGroups(userId);
});

// ==================== Target Providers ====================

/// Selected target period
final targetPeriodProvider = StateProvider<TargetPeriod>((ref) {
  return TargetPeriod.weekly;
});

/// Current targets - reads from PowerSync SQLite (works offline).
final targetsProvider = FutureProvider<List<Target>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  final repo = ref.watch(targetRepositoryProvider);
  return repo.getAllTargets(userId);
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

/// Today's attendance record
final todayAttendanceProvider = StateNotifierProvider<TodayAttendanceNotifier, AttendanceRecord?>((ref) {
  return TodayAttendanceNotifier(ref);
});

/// Is user currently checked in
final isCheckedInProvider = Provider<bool>((ref) {
  final today = ref.watch(todayAttendanceProvider);
  return today?.status == AttendanceStatus.checkedIn;
});

/// Attendance history (last 30 days)
final attendanceHistoryProvider = FutureProvider<List<AttendanceRecord>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);
  final userId = authState.user?.id;
  if (userId == null) return [];
  return repo.getHistory(userId, limit: 30);
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

/// Today's Attendance Notifier — writes to PowerSync SQLite
class TodayAttendanceNotifier extends StateNotifier<AttendanceRecord?> {
  final Ref _ref;
  bool _isLoading = false;

  TodayAttendanceNotifier(this._ref) : super(null) {
    _loadToday();
  }

  bool get isLoading => _isLoading;

  Future<void> _loadToday() async {
    _isLoading = true;
    try {
      final userId = _ref.read(currentUserIdProvider);
      if (userId == null) return;
      final repo = _ref.read(attendanceRepositoryProvider);
      state = await repo.getTodayAttendance(userId);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> checkIn(AttendanceLocation location) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) {
      debugPrint('TodayAttendanceNotifier: Cannot check in - no user ID');
      return;
    }

    final db = await PowerSyncService.database;
    final now = DateTime.now();
    final today = _formatDate(now);
    final id = '$userId-$today';

    await db.execute(
      '''INSERT OR REPLACE INTO attendance
         (id, user_id, date, time_in, location_in_lat, location_in_lng, notes, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        id,
        userId,
        today,
        now.toIso8601String(),
        location.latitude,
        location.longitude,
        location.address,
        now.toIso8601String(),
      ],
    );

    debugPrint('TodayAttendanceNotifier: Check-in written to SQLite');

    state = AttendanceRecord(
      id: id,
      userId: userId,
      date: DateTime(now.year, now.month, now.day),
      checkInTime: now,
      checkInLocation: location,
      status: AttendanceStatus.checkedIn,
    );
  }

  Future<void> checkOut(AttendanceLocation location) async {
    if (state == null) return;

    final db = await PowerSyncService.database;
    final now = DateTime.now();

    await db.execute(
      '''UPDATE attendance
         SET time_out=?, location_out_lat=?, location_out_lng=?
         WHERE id=?''',
      [
        now.toIso8601String(),
        location.latitude,
        location.longitude,
        state!.id,
      ],
    );

    debugPrint('TodayAttendanceNotifier: Check-out written to SQLite');

    state = state!.copyWith(
      checkOutTime: now,
      checkOutLocation: location,
      status: AttendanceStatus.checkedOut,
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
