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
