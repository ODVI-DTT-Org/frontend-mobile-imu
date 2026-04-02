// test/unit/utils/permission_helpers_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/utils/permission_helpers.dart';
import 'package:imu_flutter/core/models/user_role.dart';

void main() {
  group('showPermissionDenied', () {
    test('returns correct permission denied message', () {
      expect(getPermissionDeniedMessage(), "You don't have permission to perform this action");
    });
  });

  group('getValidTouchpointNumbers', () {
    test('returns visit numbers for caravan role', () {
      expect(getValidTouchpointNumbers(UserRole.caravan), [1, 4, 7]);
    });

    test('returns call numbers for tele role', () {
      expect(getValidTouchpointNumbers(UserRole.tele), [2, 3, 5, 6]);
    });

    test('returns all numbers for admin role', () {
      expect(getValidTouchpointNumbers(UserRole.admin), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('returns all numbers for area manager role', () {
      expect(getValidTouchpointNumbers(UserRole.areaManager), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('returns all numbers for assistant area manager role', () {
      expect(getValidTouchpointNumbers(UserRole.assistantAreaManager), [1, 2, 3, 4, 5, 6, 7]);
    });
  });

  group('isValidTouchpointNumberForRole', () {
    test('returns true for valid visit number with caravan role', () {
      expect(isValidTouchpointNumberForRole(1, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(4, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(7, UserRole.caravan), true);
    });

    test('returns false for invalid visit number with caravan role', () {
      expect(isValidTouchpointNumberForRole(2, UserRole.caravan), false);
      expect(isValidTouchpointNumberForRole(3, UserRole.caravan), false);
    });

    test('returns true for valid call number with tele role', () {
      expect(isValidTouchpointNumberForRole(2, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(3, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(5, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(6, UserRole.tele), true);
    });

    test('returns false for invalid call number with tele role', () {
      expect(isValidTouchpointNumberForRole(1, UserRole.tele), false);
      expect(isValidTouchpointNumberForRole(4, UserRole.tele), false);
      expect(isValidTouchpointNumberForRole(7, UserRole.tele), false);
    });

    test('returns true for all numbers with admin role', () {
      for (int i = 1; i <= 7; i++) {
        expect(isValidTouchpointNumberForRole(i, UserRole.admin), true);
      }
    });
  });
}
