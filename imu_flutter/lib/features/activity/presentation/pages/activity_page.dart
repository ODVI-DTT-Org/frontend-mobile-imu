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
          // Active filter chips — only shown for non-default selections
          if (!state.isDefaultFilter) _buildFilterChips(state, notifier),

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
    final totalCount = _totalItemCount(grouped, state.hasMore);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        itemCount: totalCount,
        itemBuilder: (context, index) =>
            _buildListItem(index, grouped, sections, state, notifier),
      ),
    );
  }

  Widget _buildListItem(
    int index,
    Map<String, List<ActivityItem>> grouped,
    List<String> sections,
    ActivityFeedState state,
    ActivityFeedNotifier notifier,
  ) {
    int cursor = 0;
    for (final section in sections) {
      if (index == cursor) return _buildDateHeader(section);
      cursor++;
      final items = grouped[section]!;
      if (index < cursor + items.length) {
        return ActivityCard(item: items[index - cursor]);
      }
      cursor += items.length;
    }
    return _buildLoadMore(state, notifier);
  }

  int _totalItemCount(
    Map<String, List<ActivityItem>> grouped,
    bool hasMore,
  ) {
    int count = 0;
    for (final items in grouped.values) {
      count += 1 + items.length; // date header + cards
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
          Text(
            'Failed to load activity',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
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
      final String label;
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
