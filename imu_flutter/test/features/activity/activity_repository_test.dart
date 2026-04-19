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
