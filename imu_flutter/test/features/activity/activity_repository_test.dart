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

  group('ActivityRepository.activityFromPendingRelease', () {
    test('maps a queued release to pending loan release activity', () {
      final queuedAt = DateTime(2026, 5, 19, 10);
      final item = ActivityRepository.activityFromPendingRelease(
        {
          'id': 'queue-1',
          'clientId': 'client-1',
          'udiNumber': 'UDI-123',
          'remarks': 'Release notes',
          'queuedAt': queuedAt.toIso8601String(),
        },
        clientName: 'Dela Cruz, Juan',
      );

      expect(item.id, 'queue-1');
      expect(item.type, ActivityType.approval);
      expect(item.subtype, ActivitySubtype.loanRelease);
      expect(item.status, ActivityStatus.pending);
      expect(item.source, ActivitySource.pendingReleaseQueue);
      expect(item.clientName, 'Dela Cruz, Juan');
      expect(item.detail, 'UDI-123');
      expect(item.createdAt, queuedAt);
      expect(item.metadata['remarks'], 'Release notes');
    });
  });
}
