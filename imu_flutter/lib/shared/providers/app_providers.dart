// Re-export connectivity providers
export '../../services/connectivity_service.dart' show isOnlineProvider, connectivityStatusProvider;
// Re-export API service providers
export '../../services/api/client_api_service.dart' show clientApiServiceProvider;
export '../../services/api/touchpoint_api_service.dart' show touchpointApiServiceProvider;
export '../../services/api/attendance_api_service.dart' show attendanceApiServiceProvider;
export '../../services/api/my_day_api_service.dart' show myDayApiServiceProvider;
export '../../services/api/approvals_api_service.dart' show approvalsApiServiceProvider;
// Re-export background sync providers
export '../../services/api/background_sync_service.dart' show backgroundSyncServiceProvider, backgroundSyncStatusProvider, BackgroundSyncStatus, BackgroundSyncService;
// Re-export auth providers
export '../../services/auth/jwt_auth_service.dart' show jwtAuthProvider;
export '../../services/auth/offline_auth_service.dart' show offlineAuthProvider;

import 'dart:convert';
import 'package:flutter/foundation.dart';
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
import '../../services/auth/auth_service.dart';
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
// Note: Primary auth state is managed by authNotifierProvider in auth_service.dart

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

/// Offline auth service provider
final offlineAuthProvider = Provider<OfflineAuthService>((ref) {
  return OfflineAuthService();
});

// ==================== Client Providers ====================

/// All clients - tries PowerSync first, then REST API, then Hive cache
final clientsProvider = FutureProvider<List<Client>>((ref) async {
  final hiveService = ref.watch(hiveServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (!hiveService.isInitialized) {
    await hiveService.init();
  }

  debugPrint('=== FETCHING CLIENTS ===');
  debugPrint('Is Online: $isOnline');
  debugPrint('PowerSync Connected: ${PowerSyncService.isConnected}');

  // Try to fetch from PowerSync first
  if (PowerSyncService.isConnected) {
    try {
      debugPrint('Fetching clients from PowerSync...');
      final result = await PowerSyncService.query('SELECT * FROM clients ORDER BY created_at DESC');
      debugPrint('PowerSync returned ${result.length} clients');

      if (result.isNotEmpty) {
        final clients = result.map((row) {
          debugPrint('PowerSync client row: $row');
          return Client.fromRow(row);
        }).toList();
        debugPrint('Converted ${clients.length} clients from PowerSync');
        return clients;
      } else {
        debugPrint('PowerSync query returned empty results');
      }
    } catch (e) {
      debugPrint('Failed to fetch clients from PowerSync: $e');
    }
  } else {
    debugPrint('PowerSync not connected, skipping');
  }

  // Try REST API if online
  if (isOnline) {
    try {
      debugPrint('Fetching clients from REST API...');
      final clientApi = ref.watch(clientApiServiceProvider);
      final clients = await clientApi.fetchClients();
      debugPrint('REST API returned ${clients.length} clients');

      if (clients.isNotEmpty) {
        // Cache clients to Hive for offline use
        for (final client in clients) {
          await hiveService.addClient(client.toJson());
        }
        debugPrint('Cached ${clients.length} clients to Hive');
        return clients;
      } else {
        debugPrint('REST API returned empty results');
      }
    } catch (e) {
      debugPrint('Failed to fetch clients from REST API: $e');
    }
  }

  // Fall back to local Hive cache
  debugPrint('Using local Hive cache for clients');
  final clientsData = hiveService.getAllClients();
  final clients = clientsData.map((data) => Client.fromJson(data)).toList();
  debugPrint('Hive cache returned ${clients.length} clients');
  debugPrint('=== END CLIENT FETCH ===');
  return clients;
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

// ==================== Online-Only Client Providers ====================

/// Online clients search query state
final onlineClientSearchQueryProvider = StateProvider<String>((ref) => '');

/// Online clients pagination state
final onlineClientPageProvider = StateProvider<int>((ref) => 1);

/// Online clients response metadata (totalItems, totalPages)
final onlineClientsMetaProvider = Provider<ClientsResponse?>((ref) {
  final asyncValue = ref.watch(onlineClientsProvider);
  return asyncValue.when(
    data: (response) => response,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Online clients - fetches ALL clients from REST API (not PowerSync)
/// This is used for "All Clients" mode to search beyond territory-filtered PowerSync data
final onlineClientsProvider = FutureProvider<ClientsResponse>((ref) async {
  final isOnline = ref.watch(isOnlineProvider);
  final searchQuery = ref.watch(onlineClientSearchQueryProvider);
  final page = ref.watch(onlineClientPageProvider);

  // Must be online to fetch all clients
  if (!isOnline) {
    debugPrint('onlineClientsProvider: Device is offline, cannot fetch online clients');
    throw Exception('Device is offline. Please connect to the internet to search all clients.');
  }

  try {
    debugPrint('onlineClientsProvider: Fetching clients from online API...');
    debugPrint('onlineClientsProvider: Search query: "$searchQuery", Page: $page');

    final clientApi = ref.watch(clientApiServiceProvider);

    final response = await clientApi.fetchClients(
      page: page,
      perPage: 50,
      search: searchQuery.isNotEmpty ? searchQuery : null,
    );

    debugPrint('onlineClientsProvider: Got ${response.items.length} clients from API (page ${response.page} of ${response.totalPages}, total: ${response.totalItems})');
    return response;
  } catch (e) {
    debugPrint('onlineClientsProvider: Failed to fetch clients - $e');
    rethrow;
  }
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
  final clientsAsync = ref.watch(clientsProvider);

  return clientsAsync.when(
    data: (clients) {
      final missedVisits = <MissedVisit>[];

      for (final client in clients) {
        // Get the next expected touchpoint
        final nextTouchpointNum = client.completedTouchpoints + 1;
        if (nextTouchpointNum > 7) continue; // All touchpoints completed

        final nextType = client.nextTouchpointType;
        if (nextType == null) continue;

        // Determine scheduled date based on last touchpoint or client creation
        DateTime scheduledDate;
        if (client.touchpoints.isNotEmpty) {
          final lastTouchpoint = client.touchpoints.last;
          // Schedule next touchpoint 3 days after last one
          scheduledDate = lastTouchpoint.date.add(const Duration(days: 3));
        } else {
          // If no touchpoints, check if client was created more than 3 days ago
          scheduledDate = (client.createdAt ?? DateTime.now()).add(const Duration(days: 3));
        }

        // Check if overdue
        if (DateTime.now().isAfter(scheduledDate)) {
          final primaryPhone = client.phoneNumbers.isNotEmpty
              ? client.phoneNumbers.first.number
              : null;
          final primaryAddress = client.addresses.isNotEmpty
              ? client.addresses.first.fullAddress
              : null;

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
