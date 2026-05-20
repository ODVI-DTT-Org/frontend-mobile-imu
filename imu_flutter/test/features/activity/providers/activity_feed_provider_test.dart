import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/data/repositories/activity_repository.dart';
import 'package:imu_flutter/features/activity/providers/activity_feed_provider.dart';

class _ActivityRepositoryStub extends ActivityRepository {
  _ActivityRepositoryStub() : super(userId: 'user-1');

  @override
  Future<List<ActivityItem>> fetchAll({
    required DateTime from,
    required DateTime to,
    ActivityType? typeFilter,
  }) async {
    return const [];
  }
}

void main() {
  test('load after dispose is ignored', () async {
    final notifier = ActivityFeedNotifier(_ActivityRepositoryStub());

    notifier.dispose();

    await expectLater(notifier.load(), completes);
  });

  test('in-flight load completion after dispose is ignored', () async {
    final completer = Completer<List<ActivityItem>>();
    final notifier = ActivityFeedNotifier(_DelayedActivityRepository(completer));

    notifier.dispose();
    completer.complete(const []);

    await expectLater(completer.future, completes);
  });
}

class _DelayedActivityRepository extends ActivityRepository {
  final Future<List<ActivityItem>> _items;

  _DelayedActivityRepository(Completer<List<ActivityItem>> completer)
      : _items = completer.future,
        super(userId: 'user-1');

  @override
  Future<List<ActivityItem>> fetchAll({
    required DateTime from,
    required DateTime to,
    ActivityType? typeFilter,
  }) {
    return _items;
  }
}
