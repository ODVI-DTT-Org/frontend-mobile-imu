import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/data/repositories/activity_repository.dart';

class ActivityFeedState {
  static const int pageSize = 200;

  final List<ActivityItem> items;
  final bool isLoading;
  final String? error;
  final DateTimeRange dateRange;
  final ActivityType? typeFilter;
  final int dayWindowSize;

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

  /// True when no non-default filters are active (chips hidden for defaults).
  bool get isDefaultFilter => typeFilter == null && dayWindowSize == 7;

  ActivityFeedState copyWith({
    List<ActivityItem>? items,
    bool? isLoading,
    String? error,
    DateTimeRange? dateRange,
    ActivityType? typeFilter,
    int? dayWindowSize,
    bool clearError = false,
    bool clearTypeFilter = false,
  }) {
    return ActivityFeedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      dateRange: dateRange ?? this.dateRange,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
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
    final newWindowSize =
        newRange.end.difference(newRange.start).inDays;

    state = state.copyWith(
      typeFilter: typeFilter,
      clearTypeFilter: typeFilter == null,
      dateRange: newRange,
      dayWindowSize: newWindowSize < 1 ? 1 : newWindowSize,
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

  Future<void> refresh() => load();
}

final activityFeedProvider =
    StateNotifierProvider<ActivityFeedNotifier, ActivityFeedState>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return ActivityFeedNotifier(repo);
});
