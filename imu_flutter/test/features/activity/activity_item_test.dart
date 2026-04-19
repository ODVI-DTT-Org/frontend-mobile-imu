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

    test('statusLabel returns PENDING for pending', () {
      final item = ActivityItem(
        id: '3',
        type: ActivityType.approval,
        subtype: ActivitySubtype.clientEdit,
        status: ActivityStatus.pending,
        createdAt: DateTime.now(),
      );
      expect(item.statusLabel, 'PENDING');
    });

    test('statusLabel returns COMPLETED for completed', () {
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
