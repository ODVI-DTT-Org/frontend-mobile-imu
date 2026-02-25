import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/local_storage/hive_service.dart';
import '../../services/sync/sync_service.dart';
import '../../services/location/geolocation_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/test_data_generator.dart';
import '../../features/targets/data/models/target_model.dart';
import '../../features/visits/data/models/missed_visit_model.dart';
import '../../features/attendance/data/models/attendance_record.dart';
import '../../features/profile/data/models/user_profile.dart';

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
          scheduledDate = client.createdAt.add(const Duration(days: 3));
        }

        // Check if overdue
        if (DateTime.now().isAfter(scheduledDate)) {
          final primaryPhone = client.phoneNumbers.isNotEmpty
              ? client.phoneNumbers.first.number
              : null;
          final primaryAddress = client.addresses.isNotEmpty
              ? client.addresses.first.fullAddress
              : null;

          missedVisits.add(MissedVisit(
            id: '${client.id}_$nextTouchpointNum',
            clientId: client.id,
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
  return TodayAttendanceNotifier(ref.watch(hiveServiceProvider));
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

  TodayAttendanceNotifier(this._hiveService) : super(null) {
    _loadToday();
  }

  Future<void> _loadToday() async {
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
  }

  Future<void> checkIn(AttendanceLocation location) async {
    final now = DateTime.now();
    final userId = 'user-1'; // TODO: Get from auth provider

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

/// Current user profile
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  return UserProfileNotifier();
});

/// Is profile loading
final isProfileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider) == null;
});

/// Profile Notifier
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    _loadProfile();
  }

  void _loadProfile() {
    // TODO: Load from Hive or API
    // For now, use mock data
    state = UserProfile.mock();
  }

  Future<void> updateProfile(UserProfile profile) async {
    // TODO: Save to Hive and sync to API
    state = profile.copyWith(updatedAt: DateTime.now());
  }

  Future<void> logout() async {
    state = null;
  }
}
