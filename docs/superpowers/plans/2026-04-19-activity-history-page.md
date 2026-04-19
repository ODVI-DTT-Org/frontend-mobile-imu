# Activity History Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "My Activity" page accessible from the home grid showing a chronological feed of all actions the user has taken (touchpoints, visits, calls, approval submissions) with status badges and type/date filters.

**Architecture:** Local-first — all data read from PowerSync/SQLite already on device; no new backend endpoints. Approvals use their `status` column directly; touchpoints/visits/calls check the `ps_crud` internal table for pending upload detection. Filter state lives in a Riverpod `StateNotifier`.

**Tech Stack:** Flutter + Riverpod StateNotifier + PowerSync SQLite queries + GoRouter + `intl` for date formatting + Lucide Icons

---

## File Map

| File | Action | Responsibility |
|---|---|---|
| `lib/features/activity/data/models/activity_item.dart` | Create | Enums + ActivityItem model |
| `lib/features/activity/data/repositories/activity_repository.dart` | Create | Raw SQLite queries across 4 tables |
| `lib/features/activity/providers/activity_feed_provider.dart` | Create | State + notifier |
| `lib/features/activity/presentation/widgets/activity_card.dart` | Create | Single activity row card |
| `lib/features/activity/presentation/widgets/activity_filter_sheet.dart` | Create | Right-side filter drawer |
| `lib/features/activity/presentation/pages/activity_page.dart` | Create | Full page with AppBar, feed, load more |
| `lib/core/router/app_router.dart` | Modify | Add `/activity` route |
| `lib/features/home/presentation/pages/home_page.dart` | Modify | Add 8th grid tile |
| `lib/features/approvals/presentation/pages/pending_approvals_page.dart` | Delete | Superseded |

---

## Task 1: Data Models

**Files:**
- Create: `lib/features/activity/data/models/activity_item.dart`
- Create: `test/features/activity/activity_item_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/activity/activity_item_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

void main() {
  group('ActivityItem', () {
    test('displayTitle returns correct label for each subtype', () {
      final item = ActivityItem(
        id: '1',
        type: ActivityType.approval,
        subtype: ActivitySubtype.clientCreate,
        clientName: 'Juan dela Cruz',
        detail: 'Client Creation Request',
        status: ActivityStatus.pending,
        createdAt: DateTime(2026, 4, 19, 10, 0),
      );
      expect(item.displayTitle, 'Add Client');
    });

    test('displayTitle for touchpointVisit', () {
      final item = ActivityItem(
        id: '2',
        type: ActivityType.touchpoint,
        subtype: ActivitySubtype.touchpointVisit,
        clientName: 'Maria Santos',
        detail: 'Touchpoint #1 • Visit',
        status: ActivityStatus.completed,
        createdAt: DateTime(2026, 4, 19, 9, 0),
      );
      expect(item.displayTitle, 'Visit');
    });

    test('statusColor returns amber for pending', () {
      final item = ActivityItem(
        id: '3',
        type: ActivityType.approval,
        subtype: ActivitySubtype.clientEdit,
        status: ActivityStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(item.statusLabel, 'PENDING');
    });

    test('statusColor returns green for completed', () {
      final item = ActivityItem(
        id: '4',
        type: ActivityType.touchpoint,
        subtype: ActivitySubtype.touchpointCall,
        status: ActivityStatus.completed,
        createdAt: DateTime.now(),
      );
      expect(item.statusLabel, 'COMPLETED');
    });
  });

  group('ActivitySubtype.fromApproval', () {
    test('maps client + Client Creation Request to clientCreate', () {
      expect(
        ActivitySubtype.fromApproval(type: 'client', reason: 'Client Creation Request'),
        ActivitySubtype.clientCreate,
      );
    });

    test('maps client_delete to clientDelete', () {
      expect(
        ActivitySubtype.fromApproval(type: 'client_delete', reason: null),
        ActivitySubtype.clientDelete,
      );
    });

    test('maps loan_release_v2 to loanRelease', () {
      expect(
        ActivitySubtype.fromApproval(type: 'loan_release_v2', reason: null),
        ActivitySubtype.loanRelease,
      );
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd imu_flutter && flutter test test/features/activity/activity_item_test.dart
```
Expected: compilation error — `ActivityItem` not found.

- [ ] **Step 3: Create the model file**

```dart
// lib/features/activity/data/models/activity_item.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ActivityType { approval, touchpoint, visit, call }

enum ActivityStatus { pending, syncing, completed, approved, rejected, failed }

enum ActivitySubtype {
  // Approvals
  clientCreate,
  clientEdit,
  clientDelete,
  addressAdd,
  addressEdit,
  addressDelete,
  phoneAdd,
  phoneEdit,
  phoneDelete,
  loanRelease,
  // Touchpoints
  touchpointVisit,
  touchpointCall,
  // Standalone visit/call records
  visit,
  call;

  static ActivitySubtype fromApproval({
    required String type,
    required String? reason,
  }) {
    switch (type) {
      case 'client':
        return reason == 'Client Edit Request'
            ? ActivitySubtype.clientEdit
            : ActivitySubtype.clientCreate;
      case 'client_delete':
        return ActivitySubtype.clientDelete;
      case 'address_add':
        return ActivitySubtype.addressAdd;
      case 'address_edit':
        return ActivitySubtype.addressEdit;
      case 'address_delete':
        return ActivitySubtype.addressDelete;
      case 'phone_add':
        return ActivitySubtype.phoneAdd;
      case 'phone_edit':
        return ActivitySubtype.phoneEdit;
      case 'phone_delete':
        return ActivitySubtype.phoneDelete;
      case 'loan_release':
      case 'loan_release_v2':
        return ActivitySubtype.loanRelease;
      default:
        return ActivitySubtype.clientCreate;
    }
  }
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final ActivitySubtype subtype;
  final String? clientName;
  final String? detail;
  final ActivityStatus status;
  final DateTime createdAt;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.subtype,
    this.clientName,
    this.detail,
    required this.status,
    required this.createdAt,
  });

  String get displayTitle {
    switch (subtype) {
      case ActivitySubtype.clientCreate:   return 'Add Client';
      case ActivitySubtype.clientEdit:     return 'Edit Client';
      case ActivitySubtype.clientDelete:   return 'Delete Client';
      case ActivitySubtype.addressAdd:     return 'Add Address';
      case ActivitySubtype.addressEdit:    return 'Edit Address';
      case ActivitySubtype.addressDelete:  return 'Delete Address';
      case ActivitySubtype.phoneAdd:       return 'Add Phone';
      case ActivitySubtype.phoneEdit:      return 'Edit Phone';
      case ActivitySubtype.phoneDelete:    return 'Delete Phone';
      case ActivitySubtype.loanRelease:    return 'Loan Release';
      case ActivitySubtype.touchpointVisit: return 'Visit';
      case ActivitySubtype.touchpointCall:  return 'Call';
      case ActivitySubtype.visit:           return 'Visit Logged';
      case ActivitySubtype.call:            return 'Call Logged';
    }
  }

  IconData get icon {
    switch (subtype) {
      case ActivitySubtype.clientCreate:   return LucideIcons.userPlus;
      case ActivitySubtype.clientEdit:     return LucideIcons.userCog;
      case ActivitySubtype.clientDelete:   return LucideIcons.userX;
      case ActivitySubtype.addressAdd:
      case ActivitySubtype.addressEdit:
      case ActivitySubtype.addressDelete:  return LucideIcons.mapPin;
      case ActivitySubtype.phoneAdd:
      case ActivitySubtype.phoneEdit:
      case ActivitySubtype.phoneDelete:    return LucideIcons.phone;
      case ActivitySubtype.loanRelease:    return LucideIcons.fileText;
      case ActivitySubtype.touchpointVisit:
      case ActivitySubtype.visit:          return LucideIcons.mapPin;
      case ActivitySubtype.touchpointCall:
      case ActivitySubtype.call:           return LucideIcons.phone;
    }
  }

  Color get statusColor {
    switch (status) {
      case ActivityStatus.pending:            return Colors.amber;
      case ActivityStatus.syncing:            return Colors.blue;
      case ActivityStatus.completed:
      case ActivityStatus.approved:           return Colors.green;
      case ActivityStatus.rejected:
      case ActivityStatus.failed:             return Colors.red;
    }
  }

  String get statusLabel {
    switch (status) {
      case ActivityStatus.pending:   return 'PENDING';
      case ActivityStatus.syncing:   return 'SYNCING';
      case ActivityStatus.completed: return 'COMPLETED';
      case ActivityStatus.approved:  return 'APPROVED';
      case ActivityStatus.rejected:  return 'REJECTED';
      case ActivityStatus.failed:    return 'FAILED';
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/activity/activity_item_test.dart
```
Expected: All 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity/data/models/activity_item.dart \
        test/features/activity/activity_item_test.dart
git commit -m "feat: add ActivityItem model and enums"
```

---

## Task 2: ActivityRepository

**Files:**
- Create: `lib/features/activity/data/repositories/activity_repository.dart`
- Create: `test/features/activity/activity_repository_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/activity/activity_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/data/repositories/activity_repository.dart';

void main() {
  group('ActivityRepository.subtypeFromTouchpoint', () {
    test('Visit type maps to touchpointVisit', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('Visit'),
        ActivitySubtype.touchpointVisit,
      );
    });

    test('Call type maps to touchpointCall', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('Call'),
        ActivitySubtype.touchpointCall,
      );
    });

    test('unknown type defaults to touchpointVisit', () {
      expect(
        ActivityRepository.subtypeFromTouchpoint('unknown'),
        ActivitySubtype.touchpointVisit,
      );
    });
  });

  group('ActivityRepository.statusFromApproval', () {
    test('pending maps to pending', () {
      expect(ActivityRepository.statusFromApproval('pending'), ActivityStatus.pending);
    });
    test('approved maps to approved', () {
      expect(ActivityRepository.statusFromApproval('approved'), ActivityStatus.approved);
    });
    test('rejected maps to rejected', () {
      expect(ActivityRepository.statusFromApproval('rejected'), ActivityStatus.rejected);
    });
    test('unknown defaults to pending', () {
      expect(ActivityRepository.statusFromApproval('unknown'), ActivityStatus.pending);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
flutter test test/features/activity/activity_repository_test.dart
```
Expected: compilation error — `ActivityRepository` not found.

- [ ] **Step 3: Create the repository**

```dart
// lib/features/activity/data/repositories/activity_repository.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

class ActivityRepository {
  final String userId;

  const ActivityRepository({required this.userId});

  // ── Static helpers (used in tests) ──────────────────────────

  static ActivitySubtype subtypeFromTouchpoint(String type) {
    return type == 'Call'
        ? ActivitySubtype.touchpointCall
        : ActivitySubtype.touchpointVisit;
  }

  static ActivityStatus statusFromApproval(String status) {
    switch (status) {
      case 'approved': return ActivityStatus.approved;
      case 'rejected': return ActivityStatus.rejected;
      default:         return ActivityStatus.pending;
    }
  }

  // ── Pending upload IDs from PowerSync internal table ────────

  Future<Set<String>> _pendingIds(String table) async {
    try {
      final rows = await PowerSyncService.query(
        "SELECT json_extract(data, '\$.id') as row_id FROM ps_crud WHERE type = ?",
        [table],
      );
      return rows
          .map((r) => r['row_id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  // ── Table queries ────────────────────────────────────────────

  Future<List<ActivityItem>> fetchTouchpoints(DateTime from, DateTime to) async {
    final pending = await _pendingIds('touchpoints');
    final rows = await PowerSyncService.query(
      """
      SELECT t.id, t.type, t.reason, t.touchpoint_number, t.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM touchpoints t
      LEFT JOIN clients c ON c.id = t.client_id
      WHERE t.user_id = ?
        AND datetime(t.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY t.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      final tpNum = r['touchpoint_number'] as int? ?? 0;
      final tpType = r['type'] as String? ?? 'Visit';
      final reason = r['reason'] as String? ?? '';
      return ActivityItem(
        id: id,
        type: ActivityType.touchpoint,
        subtype: subtypeFromTouchpoint(tpType),
        clientName: r['client_name'] as String?,
        detail: 'Touchpoint #$tpNum • $tpType${reason.isNotEmpty ? ' — $reason' : ''}',
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchVisits(DateTime from, DateTime to) async {
    final pending = await _pendingIds('visits');
    final rows = await PowerSyncService.query(
      """
      SELECT v.id, v.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM visits v
      LEFT JOIN clients c ON c.id = v.client_id
      WHERE v.user_id = ?
        AND datetime(v.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY v.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      return ActivityItem(
        id: id,
        type: ActivityType.visit,
        subtype: ActivitySubtype.visit,
        clientName: r['client_name'] as String?,
        detail: null,
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchCalls(DateTime from, DateTime to) async {
    final pending = await _pendingIds('calls');
    final rows = await PowerSyncService.query(
      """
      SELECT ca.id, ca.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM calls ca
      LEFT JOIN clients c ON c.id = ca.client_id
      WHERE ca.user_id = ?
        AND datetime(ca.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY ca.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final id = r['id'] as String;
      return ActivityItem(
        id: id,
        type: ActivityType.call,
        subtype: ActivitySubtype.call,
        clientName: r['client_name'] as String?,
        detail: null,
        status: pending.contains(id) ? ActivityStatus.syncing : ActivityStatus.completed,
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  Future<List<ActivityItem>> fetchApprovals(DateTime from, DateTime to) async {
    final rows = await PowerSyncService.query(
      """
      SELECT a.id, a.type, a.status, a.reason, a.created_at,
             c.first_name || ' ' || c.last_name AS client_name
      FROM approvals a
      LEFT JOIN clients c ON c.id = a.client_id
      WHERE a.user_id = ?
        AND datetime(a.created_at) BETWEEN datetime(?) AND datetime(?)
      ORDER BY a.created_at DESC
      """,
      [userId, from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((r) {
      final type = r['type'] as String? ?? 'client';
      final reason = r['reason'] as String?;
      final statusStr = r['status'] as String? ?? 'pending';
      return ActivityItem(
        id: r['id'] as String,
        type: ActivityType.approval,
        subtype: ActivitySubtype.fromApproval(type: type, reason: reason),
        clientName: r['client_name'] as String?,
        detail: reason,
        status: statusFromApproval(statusStr),
        createdAt: DateTime.parse(r['created_at'] as String),
      );
    }).toList();
  }

  /// Fetch all activity types merged and sorted by createdAt DESC.
  /// Pass [typeFilter] to restrict to one type.
  Future<List<ActivityItem>> fetchAll({
    required DateTime from,
    required DateTime to,
    ActivityType? typeFilter,
  }) async {
    final futures = <Future<List<ActivityItem>>>[];

    if (typeFilter == null || typeFilter == ActivityType.touchpoint) {
      futures.add(fetchTouchpoints(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.visit) {
      futures.add(fetchVisits(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.call) {
      futures.add(fetchCalls(from, to));
    }
    if (typeFilter == null || typeFilter == ActivityType.approval) {
      futures.add(fetchApprovals(from, to));
    }

    final results = await Future.wait(futures);
    final merged = results.expand((list) => list).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return ActivityRepository(userId: userId);
});
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/activity/activity_repository_test.dart
```
Expected: All 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity/data/repositories/activity_repository.dart \
        test/features/activity/activity_repository_test.dart
git commit -m "feat: add ActivityRepository with SQLite queries"
```

---

## Task 3: ActivityFeedProvider

**Files:**
- Create: `lib/features/activity/providers/activity_feed_provider.dart`
- Create: `test/features/activity/activity_feed_provider_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/activity/activity_feed_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/providers/activity_feed_provider.dart';

void main() {
  group('ActivityFeedState', () {
    test('defaultDateRange spans last 7 days', () {
      final state = ActivityFeedState.initial();
      final diff = state.dateRange.end.difference(state.dateRange.start);
      expect(diff.inDays, 7);
    });

    test('typeFilter is null by default (All)', () {
      final state = ActivityFeedState.initial();
      expect(state.typeFilter, isNull);
    });

    test('hasMore is true when items equal page size', () {
      final state = ActivityFeedState.initial().copyWith(
        items: List.generate(
          ActivityFeedState.pageSize,
          (i) => ActivityItem(
            id: '$i',
            type: ActivityType.touchpoint,
            subtype: ActivitySubtype.touchpointVisit,
            status: ActivityStatus.completed,
            createdAt: DateTime.now(),
          ),
        ),
      );
      expect(state.hasMore, isTrue);
    });

    test('isDefaultFilter true when no filters applied', () {
      final state = ActivityFeedState.initial();
      expect(state.isDefaultFilter, isTrue);
    });

    test('isDefaultFilter false when type filter applied', () {
      final state = ActivityFeedState.initial().copyWith(
        typeFilter: ActivityType.approval,
      );
      expect(state.isDefaultFilter, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
flutter test test/features/activity/activity_feed_provider_test.dart
```
Expected: compilation error — `ActivityFeedState` not found.

- [ ] **Step 3: Create the provider**

```dart
// lib/features/activity/providers/activity_feed_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/data/repositories/activity_repository.dart';

class ActivityFeedState {
  static const int pageSize = 200; // items per 7-day window

  final List<ActivityItem> items;
  final bool isLoading;
  final String? error;
  final DateTimeRange dateRange;
  final ActivityType? typeFilter;
  final int dayWindowSize; // grows with each loadMore

  const ActivityFeedState({
    required this.items,
    required this.isLoading,
    required this.dateRange,
    required this.dayWindowSize,
    this.error,
    this.typeFilter,
  });

  factory ActivityFeedState.initial() {
    final now = DateTime.now();
    return ActivityFeedState(
      items: const [],
      isLoading: false,
      dateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      dayWindowSize: 7,
    );
  }

  bool get hasMore => items.length >= pageSize;

  /// True when no non-default filters are active (used for chip display).
  bool get isDefaultFilter =>
      typeFilter == null && dayWindowSize == 7;

  ActivityFeedState copyWith({
    List<ActivityItem>? items,
    bool? isLoading,
    String? error,
    DateTimeRange? dateRange,
    ActivityType? typeFilter,
    int? dayWindowSize,
    bool clearError = false,
  }) {
    return ActivityFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      typeFilter: typeFilter,
      dayWindowSize: dayWindowSize ?? this.dayWindowSize,
    );
  }
}

class ActivityFeedNotifier extends StateNotifier<ActivityFeedState> {
  final ActivityRepository _repo;

  ActivityFeedNotifier(this._repo) : super(ActivityFeedState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.fetchAll(
        from: state.dateRange.start,
        to: state.dateRange.end,
        typeFilter: state.typeFilter,
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> applyFilters({
    ActivityType? typeFilter,
    DateTimeRange? dateRange,
  }) async {
    final now = DateTime.now();
    final newRange = dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
    final newWindowSize = dateRange != null
        ? newRange.end.difference(newRange.start).inDays
        : 7;

    state = state.copyWith(
      typeFilter: typeFilter,
      dateRange: newRange,
      dayWindowSize: newWindowSize,
    );
    await load();
  }

  Future<void> clearFilters() async {
    state = ActivityFeedState.initial();
    await load();
  }

  Future<void> loadMore() async {
    final newWindowSize = state.dayWindowSize + 7;
    final now = DateTime.now();
    state = state.copyWith(
      dateRange: DateTimeRange(
        start: now.subtract(Duration(days: newWindowSize)),
        end: now,
      ),
      dayWindowSize: newWindowSize,
    );
    await load();
  }

  Future<void> refresh() async => load();
}

final activityFeedProvider =
    StateNotifierProvider<ActivityFeedNotifier, ActivityFeedState>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return ActivityFeedNotifier(repo);
});
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test test/features/activity/activity_feed_provider_test.dart
```
Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/activity/providers/activity_feed_provider.dart \
        test/features/activity/activity_feed_provider_test.dart
git commit -m "feat: add ActivityFeedProvider state notifier"
```

---

## Task 4: ActivityCard Widget

**Files:**
- Create: `lib/features/activity/presentation/widgets/activity_card.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/features/activity/presentation/widgets/activity_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

class ActivityCard extends StatelessWidget {
  final ActivityItem item;

  const ActivityCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: item.statusColor),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.displayTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Text(
                      _relativeTime(item.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                // Client name
                if (item.clientName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.clientName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],

                // Detail line
                if (item.detail != null && item.detail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.detail!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Status badge
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: item.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday ${DateFormat('h:mm a').format(dt)}';
    return DateFormat('MMM d, h:mm a').format(dt);
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/activity/presentation/widgets/activity_card.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity/presentation/widgets/activity_card.dart
git commit -m "feat: add ActivityCard widget"
```

---

## Task 5: ActivityFilterSheet Widget

**Files:**
- Create: `lib/features/activity/presentation/widgets/activity_filter_sheet.dart`

- [ ] **Step 1: Create the widget**

```dart
// lib/features/activity/presentation/widgets/activity_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

class ActivityFilterSheet extends StatefulWidget {
  final ActivityType? selectedType;
  final DateTimeRange selectedDateRange;
  final void Function(ActivityType? type, DateTimeRange dateRange) onApply;
  final VoidCallback onClear;

  const ActivityFilterSheet({
    super.key,
    required this.selectedType,
    required this.selectedDateRange,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<ActivityFilterSheet> createState() => _ActivityFilterSheetState();
}

class _ActivityFilterSheetState extends State<ActivityFilterSheet> {
  ActivityType? _type;
  _DatePreset _datePreset = _DatePreset.last7Days;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _type = widget.selectedType;
    final diff = widget.selectedDateRange.end
        .difference(widget.selectedDateRange.start)
        .inDays;
    if (diff <= 1) {
      _datePreset = _DatePreset.today;
    } else if (diff <= 7) {
      _datePreset = _DatePreset.last7Days;
    } else if (diff <= 30) {
      _datePreset = _DatePreset.last30Days;
    } else {
      _datePreset = _DatePreset.custom;
      _customRange = widget.selectedDateRange;
    }
  }

  DateTimeRange get _resolvedRange {
    final now = DateTime.now();
    switch (_datePreset) {
      case _DatePreset.today:
        return DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
      case _DatePreset.last7Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case _DatePreset.last30Days:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case _DatePreset.custom:
        return _customRange ??
            DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Type
                    const Text(
                      'Activity Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _typeOption(null, 'All'),
                    _typeOption(ActivityType.approval, 'Approvals'),
                    _typeOption(ActivityType.touchpoint, 'Touchpoints'),
                    _typeOption(ActivityType.visit, 'Visits'),
                    _typeOption(ActivityType.call, 'Calls'),

                    const SizedBox(height: 24),

                    // Date Range
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _dateOption(_DatePreset.last7Days, 'Last 7 days'),
                    _dateOption(_DatePreset.today, 'Today only'),
                    _dateOption(_DatePreset.last30Days, 'Last 30 days'),
                    _dateOption(_DatePreset.custom, 'Custom range'),

                    if (_datePreset == _DatePreset.custom) ...[
                      const SizedBox(height: 12),
                      _buildCustomRangePicker(),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_type, _resolvedRange);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeOption(ActivityType? value, String label) {
    return RadioListTile<ActivityType?>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      groupValue: _type,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _type = v),
    );
  }

  Widget _dateOption(_DatePreset preset, String label) {
    return RadioListTile<_DatePreset>(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: preset,
      groupValue: _datePreset,
      dense: true,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _datePreset = v!),
    );
  }

  Widget _buildCustomRangePicker() {
    return Row(
      children: [
        Expanded(
          child: _datePicker(
            label: 'From',
            date: _customRange?.start,
            onPick: (d) => setState(() {
              _customRange = DateTimeRange(
                start: d,
                end: _customRange?.end ?? DateTime.now(),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _datePicker(
            label: 'To',
            date: _customRange?.end,
            onPick: (d) => setState(() {
              _customRange = DateTimeRange(
                start: _customRange?.start ??
                    DateTime.now().subtract(const Duration(days: 7)),
                end: d,
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _datePicker({
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPick,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
      child: Text(
        date != null
            ? '${date.month}/${date.day}/${date.year}'
            : label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

enum _DatePreset { today, last7Days, last30Days, custom }
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/activity/presentation/widgets/activity_filter_sheet.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity/presentation/widgets/activity_filter_sheet.dart
git commit -m "feat: add ActivityFilterSheet drawer widget"
```

---

## Task 6: ActivityPage

**Files:**
- Create: `lib/features/activity/presentation/pages/activity_page.dart`

- [ ] **Step 1: Create the page**

```dart
// lib/features/activity/presentation/pages/activity_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/providers/activity_feed_provider.dart';
import 'package:imu_flutter/features/activity/presentation/widgets/activity_card.dart';
import 'package:imu_flutter/features/activity/presentation/widgets/activity_filter_sheet.dart';

class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityFeedProvider);
    final notifier = ref.read(activityFeedProvider.notifier);

    return Scaffold(
      endDrawer: ActivityFilterSheet(
        selectedType: state.typeFilter,
        selectedDateRange: state.dateRange,
        onApply: (type, range) => notifier.applyFilters(
          typeFilter: type,
          dateRange: range,
        ),
        onClear: notifier.clearFilters,
      ),
      appBar: AppBar(
        title: const Text('My Activity'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(LucideIcons.slidersHorizontal),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              tooltip: 'Filters',
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Active filter chips
          if (!state.isDefaultFilter)
            _buildFilterChips(context, state, notifier),

          // Feed
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.items.isEmpty
                    ? _buildError(state.error!, notifier)
                    : state.items.isEmpty
                        ? _buildEmpty()
                        : _buildFeed(state, notifier),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    ActivityFeedState state,
    ActivityFeedNotifier notifier,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (state.typeFilter != null)
            _chip(
              label: _typeLabel(state.typeFilter!),
              onDelete: () => notifier.applyFilters(
                typeFilter: null,
                dateRange: state.dateRange,
              ),
            ),
          if (state.dayWindowSize != 7)
            _chip(
              label: state.dayWindowSize == 1
                  ? 'Today'
                  : 'Last ${state.dayWindowSize} days',
              onDelete: () => notifier.applyFilters(
                typeFilter: state.typeFilter,
                dateRange: DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip({required String label, required VoidCallback onDelete}) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFeed(ActivityFeedState state, ActivityFeedNotifier notifier) {
    final grouped = _groupByDate(state.items);
    final sections = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: _totalItemCount(grouped, state.hasMore),
        itemBuilder: (context, index) {
          return _buildListItem(context, index, grouped, sections, state, notifier);
        },
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    int index,
    Map<String, List<ActivityItem>> grouped,
    List<String> sections,
    ActivityFeedState state,
    ActivityFeedNotifier notifier,
  ) {
    int cursor = 0;
    for (final section in sections) {
      // Date header
      if (index == cursor) {
        return _buildDateHeader(section);
      }
      cursor++;
      // Cards
      final items = grouped[section]!;
      if (index < cursor + items.length) {
        return ActivityCard(item: items[index - cursor]);
      }
      cursor += items.length;
    }
    // Load more button
    return _buildLoadMore(state, notifier);
  }

  int _totalItemCount(
    Map<String, List<ActivityItem>> grouped,
    bool hasMore,
  ) {
    int count = 0;
    for (final items in grouped.values) {
      count += 1 + items.length; // header + cards
    }
    if (hasMore) count++; // load more button
    return count;
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLoadMore(ActivityFeedState state, ActivityFeedNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : OutlinedButton(
              onPressed: notifier.loadMore,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Load 7 more days'),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No activity in this period',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error, ActivityFeedNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Failed to load activity', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          TextButton(onPressed: notifier.refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Map<String, List<ActivityItem>> _groupByDate(List<ActivityItem> items) {
    final result = <String, List<ActivityItem>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final item in items) {
      final itemDay = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      String label;
      if (itemDay == today) {
        label = 'Today';
      } else if (itemDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEE, MMM d').format(item.createdAt);
      }
      result.putIfAbsent(label, () => []).add(item);
    }
    return result;
  }

  String _typeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.approval:   return 'Approvals';
      case ActivityType.touchpoint: return 'Touchpoints';
      case ActivityType.visit:      return 'Visits';
      case ActivityType.call:       return 'Calls';
    }
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/features/activity/presentation/pages/activity_page.dart
```
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/activity/presentation/pages/activity_page.dart
git commit -m "feat: add ActivityPage with feed, date grouping, and filter chips"
```

---

## Task 7: Router + Home Grid Integration

**Files:**
- Modify: `lib/core/router/app_router.dart`
- Modify: `lib/features/home/presentation/pages/home_page.dart`

- [ ] **Step 1: Add route to router**

In `lib/core/router/app_router.dart`, add the import at the top with other page imports:

```dart
import '../../../features/activity/presentation/pages/activity_page.dart';
```

Then add the route after the `/settings` route (look for the `GoRoute(path: '/settings'` block):

```dart
GoRoute(
  path: '/activity',
  builder: (context, state) => const ActivityPage(),
),
```

- [ ] **Step 2: Add the 8th grid tile in home_page.dart**

In `lib/features/home/presentation/pages/home_page.dart`, update `_getMenuItems()`:

```dart
List<_MenuItem> _getMenuItems() {
  return [
    _MenuItem(icon: LucideIcons.sun, label: 'My Day', id: 'my-day'),
    _MenuItem(icon: LucideIcons.users, label: 'My Clients', id: 'clients'),
    _MenuItem(icon: LucideIcons.target, label: 'My Targets', id: 'targets'),
    _MenuItem(icon: LucideIcons.mapPin, label: 'Missed Visits', id: 'visits'),
    _MenuItem(icon: LucideIcons.calculator, label: 'Loan Calculator', id: 'calculator'),
    _MenuItem(icon: LucideIcons.clipboardList, label: 'Attendance', id: 'attendance'),
    _MenuItem(icon: LucideIcons.userCog, label: 'My Profile', id: 'profile'),
    _MenuItem(icon: LucideIcons.history, label: 'My Activity', id: 'activity'),
  ];
}
```

- [ ] **Step 3: Add navigation case in `_handleNavigation`**

In the same file, add a case to the switch in `_handleNavigation`:

```dart
case 'activity':
  context.push('/activity');
  break;
```

Add it before the `default:` case.

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze lib/core/router/app_router.dart \
               lib/features/home/presentation/pages/home_page.dart
```
Expected: No errors.

- [ ] **Step 5: Commit**

```bash
git add lib/core/router/app_router.dart \
        lib/features/home/presentation/pages/home_page.dart
git commit -m "feat: wire ActivityPage into router and home grid"
```

---

## Task 8: Delete Pending Approvals Page

**Files:**
- Delete: `lib/features/approvals/presentation/pages/pending_approvals_page.dart`

- [ ] **Step 1: Check for any remaining references**

```bash
grep -rn "PendingApprovalsPage\|pending_approvals_page" \
  /home/claude-team/loi/imu3/frontend-mobile-imu/imu_flutter/lib/
```
Expected: Zero results (it's currently unnavigable).

- [ ] **Step 2: Delete the file**

```bash
rm imu_flutter/lib/features/approvals/presentation/pages/pending_approvals_page.dart
```

- [ ] **Step 3: Verify full project still compiles**

```bash
flutter analyze
```
Expected: No errors.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: complete activity history page — remove superseded pending approvals page"
```

- [ ] **Step 6: Push**

```bash
git push
```
