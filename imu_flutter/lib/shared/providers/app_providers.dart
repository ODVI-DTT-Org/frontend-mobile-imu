// Re-export connectivity providers
export '../../services/connectivity_service.dart' show isOnlineProvider, connectivityStatusProvider;
// Re-export API service providers
export '../../services/api/client_api_service.dart' show clientApiServiceProvider;
export '../../services/api/touchpoint_api_service.dart' show touchpointApiServiceProvider;
export '../../services/api/attendance_api_service.dart' show attendanceApiServiceProvider;
export '../../services/api/my_day_api_service.dart' show myDayApiServiceProvider;
export '../../features/my_day/presentation/providers/my_day_provider.dart' show myDayStateProvider;
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
export './app_providers.dart' show
  authNotifierProvider,
  assignedClientsFetchProvider,
  assignedClientsProvider;
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
// Re-export enhanced location service with PSGC fallback
export '../../services/location/enhanced_location_provider.dart' show
  enhancedLocationServiceProvider;
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/sync/sync_service.dart';
import '../../services/location/geolocation_service.dart';
import '../../services/location/enhanced_location_provider.dart';
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
import '../../services/release/pending_release_service.dart';
import '../../features/itineraries/data/repositories/itinerary_repository.dart'
    show itineraryRepositoryProvider;

export '../../services/release/pending_release_service.dart' show pendingReleaseServiceProvider, PendingReleaseService, PendingFlushResult;
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
import '../models/touchpoint_filter.dart' show TouchpointFilter;
import '../../features/visits/data/models/visit_model.dart';
import '../../features/visits/data/repositories/visit_repository.dart';
import '../../features/attendance/data/repositories/attendance_repository.dart';
import '../../features/clients/data/repositories/client_repository.dart';
import '../../features/clients/data/repositories/touchpoint_history_repository.dart';
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

  // Show cached clients immediately, then sync in background.
  Future<void> onLoginSuccess() async {
    // Invalidate immediately so UI shows stale cache (or empty) right away.
    ref.invalidate(assignedClientsProvider);
    // Fire background sync — does NOT block login.
    _syncClientsInBackground(ref);
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

/// Fetches all assigned clients in parallel batches and saves to Hive.
/// Runs fire-and-forget — does not block the caller.
void _syncClientsInBackground(Ref ref) {
  Future(() async {
    try {
      debugPrint('[BG-SYNC] Starting background client sync...');

      // Notify that fetch is starting
      ref.read(assignedClientsFetchProvider.notifier).startFetch();

      final clientApi = ref.read(clientApiServiceProvider);
      final hive = HiveService();
      final clients = await clientApi.fetchAllAssignedClients();
      final clientJsons = clients.map((c) => c.toJson()).toList();
      await hive.saveAllClients(clientJsons);
      await hive.saveSetting('clients_last_fetch_ms', DateTime.now().millisecondsSinceEpoch);
      await hive.saveSetting('clients_cache_version', 3);
      ref.invalidate(assignedClientsProvider);

      // Notify that fetch is complete
      ref.read(assignedClientsFetchProvider.notifier).completeFetch(clients.length);

      debugPrint('[BG-SYNC] Done — ${clients.length} clients cached');
    } catch (e) {
      debugPrint('[BG-SYNC] Failed: $e');
      // Reset fetch state on error
      ref.read(assignedClientsFetchProvider.notifier).reset();
    }
  });
}

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

/// Client by ID provider - fetches a single client with smart fallback
/// Priority: Hive cache → PowerSync SQLite → Online API
/// Used by router for deep linking to client detail pages and forms
final clientByIdProvider = FutureProvider.family<Client, String>((ref, clientId) async {
  // Try Hive cache first (has embedded addresses + phoneNumbers)
  final hiveService = HiveService();
  final cachedJson = hiveService.getClient(clientId);
  if (cachedJson != null) {
    debugPrint('[clientByIdProvider] Found in Hive cache: $clientId');
    return Client.fromJson(cachedJson);
  }

  // Fallback: PowerSync SQLite (no addresses/phones, but better than nothing offline)
  final clientRepo = ref.watch(clientRepositoryProvider);
  final localClient = await clientRepo.getClient(clientId);
  if (localClient != null) {
    debugPrint('[clientByIdProvider] Found in PowerSync: $clientId');
    return localClient;
  }

  // Final fallback: Online API (when online and client not found locally)
  final isOnline = ref.watch(isOnlineProvider);
  if (isOnline) {
    debugPrint('[clientByIdProvider] Not found locally, fetching from API: $clientId');
    try {
      final clientApi = ref.watch(clientApiServiceProvider);
      final onlineClient = await clientApi.fetchClient(clientId);
      if (onlineClient != null) {
        // Cache the fetched client locally for future use
        await hiveService.saveClient(onlineClient.toJson());
        debugPrint('[clientByIdProvider] Fetched from API and cached: $clientId');
        return onlineClient;
      }
    } catch (e) {
      debugPrint('[clientByIdProvider] API fetch failed: $e');
    }
  }

  throw Exception('Client not found: $clientId');
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

    String? province;
    List<String>? municipalityIds;
    List<String>? barangays;
    String? addressSearch;
    if (locationFilter.hasFilter) {
      province = locationFilter.province;
      if (locationFilter.municipalities != null && locationFilter.municipalities!.isNotEmpty) {
        municipalityIds = locationFilter.municipalities!.toList();
      }
      if (locationFilter.barangays != null && locationFilter.barangays!.isNotEmpty) {
        barangays = locationFilter.barangays!.toList();
      }
      addressSearch = locationFilter.addressQuery;
      debugPrint('onlineClientsProvider: Location filter — province: $province, municipalities: $municipalityIds, barangays: $barangays, addressSearch: $addressSearch');
    }

    // Convert attribute filter to API parameters
    final queryParams = attributeFilter.toQueryParams();

    // Convert touchpoint filter to API parameters
    List<String>? nextTouchpointNumbers;
    if (touchpointFilter.hasFilter) {
      nextTouchpointNumbers = touchpointFilter.selectedNumbers.map((n) {
        return n == 8 ? 'archive' : n.toString();
      }).toList();
      debugPrint('onlineClientsProvider: Touchpoint filter: $nextTouchpointNumbers');
    }

    final response = await clientApi.fetchClients(
      page: page,
      perPage: 10,
      search: searchQuery.isNotEmpty ? searchQuery : null,
      clientType: queryParams['client_type'],
      marketType: queryParams['market_type'],
      pensionType: queryParams['pension_type'],
      productType: queryParams['product_type'],
      loanType: queryParams['loan_type'],
      touchpointStatus: queryParams['touchpoint_status'],
      visitStatus: queryParams['visit_status'],
      loanReleased: queryParams['loan_released'] == 'true' ? true : null,
      province: province,
      municipalityIds: municipalityIds,
      barangays: barangays,
      addressSearch: addressSearch,
      nextTouchpointNumbers: nextTouchpointNumbers,
      touchpointDateFrom: queryParams['touchpoint_date_from'],
      touchpointDateTo: queryParams['touchpoint_date_to'],
      recentlyVisitedDays: attributeFilter.recentlyVisitedDays,
    );

    debugPrint('onlineClientsProvider: Got ${response.items.length} clients from API (page ${response.page} of ${response.totalPages}, total: ${response.totalItems})');
    return response;
  } catch (e) {
    debugPrint('onlineClientsProvider: Failed to fetch clients - $e');
    rethrow;
  }
});

/// Hive fallback for [assignedClientsProvider].
///
/// Used when PowerSync SQLite has no clients yet (e.g. the sync loading page
/// skipped PowerSync because Hive already had cached data) OR when the
/// municipality assignments API was unreachable so [effectiveMunicipalities]
/// came back empty. The Hive cache already contains only the user's assigned
/// clients, so no territory filter is re-applied here; only the user-applied
/// location sub-filter, search, and attribute/touchpoint predicates are run.
ClientsResponse _buildHiveFallback({
  required HiveService hive,
  required LocationFilter locationFilter,
  required String searchQuery,
  required ClientAttributeFilter attributeFilter,
  required TouchpointFilter touchpointFilter,
  required int page,
  required int itemsPerPage,
}) {
  var clients = hive.getAllClients()
      .map((json) => Client.fromJson(json))
      .where((c) => c.deletedAt == null)
      .toList();

  // Apply user-selected location sub-filter (Hive is already territory-scoped).
  if (locationFilter.municipalities?.isNotEmpty == true) {
    final upper = locationFilter.municipalities!.map((m) => m.toUpperCase()).toSet();
    clients = clients
        .where((c) => c.municipality != null && upper.contains(c.municipality!.toUpperCase()))
        .toList();
  }
  if (locationFilter.province != null) {
    final p = locationFilter.province!.toUpperCase();
    clients = clients.where((c) => c.province?.toUpperCase() == p).toList();
  }
  if (locationFilter.barangays?.isNotEmpty == true) {
    final barangays = locationFilter.barangays!.map((b) => b.toUpperCase()).toSet();
    clients = clients
        .where((c) => c.barangay != null && barangays.contains(c.barangay!.toUpperCase()))
        .toList();
  }
  if ((locationFilter.addressQuery?.trim().isNotEmpty ?? false)) {
    clients = clients.where((c) {
      final primary = c.addresses.isNotEmpty ? c.addresses.first : null;
      return locationFilter.matchesClientAddress(
        fullAddress: c.tableFullAddress,
        region: c.region,
        province: c.province,
        municipality: c.municipality,
        barangay: c.barangay,
        addressBarangay: primary?.barangay,
        addressCity: primary?.municipality,
        addressProvince: primary?.province,
      );
    }).toList();
  }

  // Text search — AND across words, LIKE on name/agency fields (mirrors SQL path).
  if (searchQuery.isNotEmpty) {
    final words = searchQuery.trim().split(RegExp(r'\s+')).where((w) => w.length >= 2).toList();
    for (final word in words) {
      final q = word.toLowerCase();
      clients = clients.where((c) =>
        c.firstName.toLowerCase().contains(q) ||
        c.lastName.toLowerCase().contains(q) ||
        (c.middleName?.toLowerCase().contains(q) ?? false) ||
        (c.agencyName?.toLowerCase().contains(q) ?? false)
      ).toList();
    }
  }

  // attributeFilter.matches() covers type chips, touchpoint statuses, date
  // ranges, and recentlyVisitedDays — all in one pass.
  clients = clients.where((c) => attributeFilter.matches(c)).toList();
  if (touchpointFilter.hasFilter) {
    clients = clients.where((c) => touchpointFilter.matches(c)).toList();
  }

  final totalItems = clients.length;
  final totalPages = (totalItems / itemsPerPage).ceil().clamp(1, 9999);
  final offset = ((page - 1) * itemsPerPage).clamp(0, totalItems);
  final end = (offset + itemsPerPage).clamp(0, totalItems);
  return ClientsResponse(
    items: clients.sublist(offset, end),
    page: page,
    perPage: itemsPerPage,
    totalItems: totalItems,
    totalPages: totalPages,
  );
}

/// Assigned clients — queries PowerSync SQLite directly with SQL filters and
/// LIMIT/OFFSET pagination. No full Hive load; only the requested page is
/// transferred from the DB to Dart memory.
///
/// Simple filters (location, type, search) run entirely in SQL.
/// Complex filters that touch the touchpoint_summary JSON column or need
/// next_touchpoint_number (not in the PowerSync schema) are applied in Dart
/// on the SQL-reduced result set rather than on all 5k+ clients.
final assignedClientsProvider = FutureProvider<ClientsResponse>((ref) async {
  final searchQuery = ref.watch(assignedClientSearchQueryProvider);
  final page = ref.watch(assignedClientPageProvider);
  final locationFilter = ref.watch(locationFilterProvider);
  final attributeFilter = ref.watch(clientAttributeFilterProvider);
  final touchpointFilter = ref.watch(touchpointFilterProvider);

  // Resolve user's territory municipalities before touching the DB.
  final assignedMunicipalities =
      await ref.watch(assignedMunicipalitiesProvider.future);

  // Compute effective municipality filter: intersection of user territory and
  // any user-applied location filter; if the user filtered by municipality we
  // narrow to that subset, otherwise all assigned municipalities are the base.
  final List<String> effectiveMunicipalities;
  if (locationFilter.municipalities?.isNotEmpty == true) {
    effectiveMunicipalities = assignedMunicipalities
        .where((m) => locationFilter.municipalities!.contains(m))
        .toList();
  } else {
    effectiveMunicipalities = assignedMunicipalities;
  }

  const itemsPerPage = 20;

  // If user has no territory assignment (or filter produces empty set), bail.
  // Before returning empty, try Hive — the assignments API may have been
  // unreachable and the AreaFilterService cache not yet seeded.
  if (effectiveMunicipalities.isEmpty) {
    final hive = HiveService();
    if (hive.cachedClientCount > 0) {
      return _buildHiveFallback(
        hive: hive, locationFilter: locationFilter,
        searchQuery: searchQuery, attributeFilter: attributeFilter,
        touchpointFilter: touchpointFilter, page: page, itemsPerPage: itemsPerPage,
      );
    }
    return ClientsResponse(
      items: [], page: page, perPage: itemsPerPage, totalItems: 0, totalPages: 1,
    );
  }

  final db = await PowerSyncService.database;

  // ── Hive fallback when PowerSync SQLite is not yet populated ─────────────
  // The sync loading page fast-tracks to home when Hive has data, skipping
  // the PowerSync wait. The clients table may be empty on that first visit.
  // Read from Hive so the user sees their assigned clients immediately while
  // PowerSync populates SQLite in the background.
  {
    final psRows = await db.getAll('SELECT COUNT(*) as cnt FROM clients LIMIT 1');
    final psCount = (psRows.first['cnt'] as int?) ?? 0;
    if (psCount == 0) {
      final hive = HiveService();
      if (hive.cachedClientCount > 0) {
        return _buildHiveFallback(
          hive: hive, locationFilter: locationFilter,
          searchQuery: searchQuery, attributeFilter: attributeFilter,
          touchpointFilter: touchpointFilter, page: page, itemsPerPage: itemsPerPage,
        );
      }
    }
  }

  // ── Build SQL WHERE conditions ────────────────────────────────────────────
  final conditions = <String>['deleted_at IS NULL'];
  final params = <Object?>[];

  // Base territory filter — always applied on the Assigned tab.
  final mPh = effectiveMunicipalities.map((_) => '?').join(', ');
  conditions.add('municipality IN ($mPh)');
  params.addAll(effectiveMunicipalities);

  // Location (province only — municipality already handled above)
  if (locationFilter.province != null) {
    conditions.add('province = ?');
    params.add(locationFilter.province);
  }

  if (locationFilter.barangays?.isNotEmpty == true) {
    final bPh = locationFilter.barangays!.map((_) => '?').join(', ');
    conditions.add('UPPER(barangay) IN ($bPh)');
    params.addAll(locationFilter.barangays!.map((b) => b.toUpperCase()));
  }

  final addressQuery = locationFilter.addressQuery?.trim();
  if (addressQuery != null && addressQuery.isNotEmpty) {
    for (final word in addressQuery
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)) {
      conditions.add(
        "(LOWER(COALESCE(full_address, '')) LIKE ? OR LOWER(COALESCE(region, '')) LIKE ? OR LOWER(COALESCE(province, '')) LIKE ? OR LOWER(COALESCE(municipality, '')) LIKE ? OR LOWER(COALESCE(barangay, '')) LIKE ?)",
      );
      final pct = '%${word.toLowerCase()}%';
      params.addAll([pct, pct, pct, pct, pct]);
    }
  }

  // Attribute type filters — OR within a category, AND across categories.
  // Mirrors ClientAttributeFilter.matches() case-insensitive logic.
  void addUpperIn(String col, List<String>? values) {
    if (values == null || values.isEmpty) return;
    final ph = values.map((_) => '?').join(', ');
    conditions.add('UPPER($col) IN ($ph)');
    params.addAll(values.map((v) => v.toUpperCase()));
  }
  addUpperIn('client_type', attributeFilter.clientTypes);
  addUpperIn('market_type', attributeFilter.marketTypes);
  addUpperIn('pension_type', attributeFilter.pensionTypes);
  addUpperIn('product_type', attributeFilter.productTypes);
  addUpperIn('loan_type', attributeFilter.loanTypes);

  // Text search — AND across words, LIKE match on name / agency fields.
  if (searchQuery.isNotEmpty) {
    final words = searchQuery.trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 2)
        .toList();
    for (final word in words) {
      conditions.add(
        '(first_name LIKE ? OR last_name LIKE ? OR middle_name LIKE ? OR agency_name LIKE ?)',
      );
      final pct = '%$word%';
      params.addAll([pct, pct, pct, pct]);
    }
  }

  final where = conditions.join(' AND ');

  // ── Detect complex filters needing Dart post-processing ──────────────────
  // touchpointStatuses / date range / recentlyVisited use the touchpoint_summary
  // JSON column which SQLite can't easily query.
  // touchpointFilter uses next_touchpoint_number which is absent from the schema.
  final hasComplexFilter = touchpointFilter.hasFilter ||
      attributeFilter.touchpointStatuses?.isNotEmpty == true ||
      attributeFilter.touchpointDateFrom != null ||
      attributeFilter.touchpointDateTo != null ||
      attributeFilter.recentlyVisitedDays != null;

  if (hasComplexFilter) {
    // Fetch all SQL-filtered rows (type/location/search already applied),
    // then apply the complex Dart predicates on the smaller result set.
    final rows = await db.getAll(
      'SELECT * FROM clients WHERE $where ORDER BY first_name, last_name',
      params,
    );
    var clients = rows.map((r) => Client.fromRow(r)).toList();

    if (attributeFilter.touchpointStatuses?.isNotEmpty == true ||
        attributeFilter.touchpointDateFrom != null ||
        attributeFilter.touchpointDateTo != null ||
        attributeFilter.recentlyVisitedDays != null) {
      clients = clients.where((c) => attributeFilter.matches(c)).toList();
    }
    if (touchpointFilter.hasFilter) {
      clients = clients.where((c) => touchpointFilter.matches(c)).toList();
    }

    final totalItems = clients.length;
    final totalPages = (totalItems / itemsPerPage).ceil().clamp(1, 9999);
    final offset = ((page - 1) * itemsPerPage).clamp(0, totalItems);
    final end = (offset + itemsPerPage).clamp(0, totalItems);

    return ClientsResponse(
      items: clients.sublist(offset, end),
      page: page,
      perPage: itemsPerPage,
      totalItems: totalItems,
      totalPages: totalPages,
    );
  }

  // ── Fast path: SQL pagination only ───────────────────────────────────────
  final offset = (page - 1) * itemsPerPage;

  final countRows = await db.getAll(
    'SELECT COUNT(*) as cnt FROM clients WHERE $where',
    params,
  );
  final totalItems = (countRows.first['cnt'] as int?) ?? 0;
  final totalPages = (totalItems / itemsPerPage).ceil().clamp(1, 9999);

  final rows = await db.getAll(
    'SELECT * FROM clients WHERE $where ORDER BY first_name, last_name LIMIT ? OFFSET ?',
    [...params, itemsPerPage, offset],
  );

  return ClientsResponse(
    items: rows.map((r) => Client.fromRow(r)).toList(),
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

  return locations.map((l) => l.municipality).toSet().toList();
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

final touchpointHistoryRepositoryProvider = Provider<TouchpointHistoryRepository>((ref) {
  return TouchpointHistoryRepository();
});

/// Local touchpoints for a client, including rows still queued for PowerSync upload.
///
/// This bridges the delay before the denormalized client summary is downloaded.
/// History merge logic dedupes by ID once the same touchpoint appears in the
/// summary.
final succeededLocalClientTouchpointsProvider =
    StreamProvider.family<List<Touchpoint>, String>((ref, clientId) {
  final repository = ref.watch(touchpointHistoryRepositoryProvider);
  return repository.watchSucceededLocalTouchpoints(clientId);
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
  final pendingQueue = ref.watch(pendingReleaseServiceProvider);
  return ReleaseCreationService(
    connectivity,
    releaseApi,
    visitApi,
    approvalsApi,
    uploadApi,
    role,
    pendingQueue: pendingQueue,
  );
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

  // Use Mapbox + PSGC fallback (not native-only) so address survives
  // when the OS geocoder returns nothing.
  final locationService = ref.read(enhancedLocationServiceProvider);
  final addressResult = await locationService.getAddressFromCoordinates(
    position.latitude,
    position.longitude,
  );

  return LocationData.fromPosition(position, address: addressResult.fullAddress);
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

/// Stream of past-due itineraries from PowerSync.
/// Reactive — updates automatically when itineraries or clients change.
final missedItinerariesStreamProvider =
    StreamProvider<List<MissedVisit>>((ref) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield [];
    return;
  }
  final repo = ref.read(itineraryRepositoryProvider);
  yield* repo.watchMissedItineraries(userId).map((rows) {
    return rows.map((row) {
      final firstName = (row['first_name'] as String?) ?? '';
      final lastName = (row['last_name'] as String?) ?? '';
      final middleName = (row['middle_name'] as String?) ?? '';
      final clientName = [firstName, middleName, lastName]
          .where((s) => s.isNotEmpty)
          .join(' ');
      final touchpointNum = (row['touchpoint_number'] as int?) ?? 0;
      final nextTouchpointStr =
          (row['next_touchpoint'] as String?)?.toLowerCase();
      final touchpointType = nextTouchpointStr == 'call'
          ? TouchpointType.call
          : TouchpointType.visit;
      final scheduledDate = row['scheduled_date'] != null
          ? DateTime.tryParse(row['scheduled_date'] as String) ??
              DateTime.now()
          : DateTime.now();
      final createdAt = row['created_at'] != null
          ? DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()
          : DateTime.now();
      return MissedVisit(
        id: row['id'] as String,
        clientId: row['client_id'] as String,
        clientName: clientName,
        touchpointNumber: touchpointNum + 1,
        touchpointType: touchpointType,
        scheduledDate: scheduledDate,
        createdAt: createdAt,
        primaryPhone: row['phone'] as String?,
        source: MissedVisitSource.missedItinerary,
        itineraryId: row['id'] as String,
      );
    }).toList();
  });
});

/// Overdue clients from Hive cache that have no future or missed itinerary.
/// Watches syncServiceProvider so it recomputes after a sync completes.
final overdueClientsProvider =
    FutureProvider<List<MissedVisit>>((ref) async {
  // Re-evaluate whenever sync state changes (catches post-sync cache refresh)
  ref.watch(syncServiceProvider);

  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final db = await PowerSyncService.database;

  // Load all non-released clients with a next touchpoint — SQL pre-filter
  // reduces the set before the Dart overdue check below.
  final clientRows = await db.getAll(
    '''SELECT * FROM clients
       WHERE deleted_at IS NULL
         AND (loan_released IS NULL OR loan_released = 0)
         AND next_touchpoint IS NOT NULL''',
  );
  final clients = clientRows.map((r) => Client.fromRow(r)).toList();

  // Fetch future-scheduled itinerary client IDs to exclude (Set B)
  final futureRows = await db.getAll(
    '''SELECT DISTINCT client_id FROM itineraries
       WHERE user_id = ?
         AND DATE(scheduled_date) >= DATE('now', 'localtime')
         AND status IN ('pending', 'in_progress')''',
    [userId],
  );
  final futureClientIds =
      futureRows.map((r) => r['client_id'] as String).toSet();

  // Client IDs already covered by missed itineraries (Set A)
  final missedClientIds =
      (ref.read(missedItinerariesStreamProvider).valueOrNull ?? [])
          .map((v) => v.clientId)
          .toSet();

  final now = DateTime.now();
  final result = <MissedVisit>[];

  for (final client in clients) {
    if (client.id == null) continue;
    if (client.loanReleased) continue;
    if (client.nextTouchpoint == null) continue;
    if (missedClientIds.contains(client.id)) continue;
    if (futureClientIds.contains(client.id)) continue;

    DateTime lastActivity;
    if (client.touchpointSummary.isNotEmpty) {
      lastActivity = client.touchpointSummary
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b)
          .date;
    } else {
      lastActivity = client.createdAt ?? now;
    }

    if (now.difference(lastActivity).inDays <= 7) continue;

    final nextTouchpointNum = client.touchpointNumber + 1;
    final touchpointTypeEnum =
        client.nextTouchpoint?.toLowerCase() == 'call'
            ? TouchpointType.call
            : TouchpointType.visit;

    result.add(MissedVisit(
      id: '${client.id}_$nextTouchpointNum',
      clientId: client.id!,
      clientName: client.fullName,
      touchpointNumber: nextTouchpointNum,
      touchpointType: touchpointTypeEnum,
      scheduledDate: lastActivity.add(const Duration(days: 7)),
      createdAt: now,
      primaryPhone: client.phone,
      primaryAddress: client.fullAddress,
      source: MissedVisitSource.overdueClient,
    ));
  }

  return result;
});

/// Merged missed visits: PowerSync missed itineraries + Hive overdue clients.
/// Missed itinerary entries take precedence when clientId overlaps.
final missedVisitsProvider = Provider<List<MissedVisit>>((ref) {
  final itineraryVisits =
      ref.watch(missedItinerariesStreamProvider).valueOrNull ?? [];
  final overdueVisits =
      ref.watch(overdueClientsProvider).valueOrNull ?? [];

  final seenClientIds = itineraryVisits.map((v) => v.clientId).toSet();
  final merged = [
    ...itineraryVisits,
    ...overdueVisits.where((v) => !seenClientIds.contains(v.clientId)),
  ];

  merged.sort((a, b) {
    final priorityCompare = b.priority.index.compareTo(a.priority.index);
    if (priorityCompare != 0) return priorityCompare;
    return b.daysOverdue.compareTo(a.daysOverdue);
  });

  return merged;
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

/// State for tracking assigned clients initial fetch status
class AssignedClientsFetchNotifier extends StateNotifier<AssignedClientsFetchState> {
  AssignedClientsFetchNotifier() : super(AssignedClientsFetchState.initial());

  void startFetch() {
    state = AssignedClientsFetchState(
      isFetching: true,
      fetchCount: 0,
      lastFetchTime: null,
    );
  }

  void completeFetch(int count) {
    state = AssignedClientsFetchState(
      isFetching: false,
      fetchCount: count,
      lastFetchTime: DateTime.now(),
    );
  }

  void reset() {
    state = AssignedClientsFetchState.initial();
  }
}

/// State class for assigned clients fetch
class AssignedClientsFetchState {
  final bool isFetching;
  final int fetchCount;
  final DateTime? lastFetchTime;

  AssignedClientsFetchState({
    required this.isFetching,
    required this.fetchCount,
    this.lastFetchTime,
  });

  factory AssignedClientsFetchState.initial() {
    return AssignedClientsFetchState(
      isFetching: false,
      fetchCount: 0,
      lastFetchTime: null,
    );
  }
}

/// Provider for tracking assigned clients initial fetch status
final assignedClientsFetchProvider = StateNotifierProvider<AssignedClientsFetchNotifier, AssignedClientsFetchState>((ref) {
  return AssignedClientsFetchNotifier();
});
