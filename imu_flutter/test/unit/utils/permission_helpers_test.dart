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

  // UPDATED for Unli Touchpoint - no number restrictions
  group('getValidTouchpointNumbers', () {
    test('returns empty list for caravan role (no number restrictions)', () {
      expect(getValidTouchpointNumbers(UserRole.caravan), []);
    });

    test('returns empty list for tele role (no number restrictions)', () {
      expect(getValidTouchpointNumbers(UserRole.tele), []);
    });

    test('returns empty list for admin role (no number restrictions)', () {
      expect(getValidTouchpointNumbers(UserRole.admin), []);
    });

    test('returns empty list for area manager role (no number restrictions)', () {
      expect(getValidTouchpointNumbers(UserRole.areaManager), []);
    });

    test('returns empty list for assistant area manager role (no number restrictions)', () {
      expect(getValidTouchpointNumbers(UserRole.assistantAreaManager), []);
    });
  });

  // UPDATED for Unli Touchpoint - all numbers valid
  group('isValidTouchpointNumberForRole', () {
    test('returns true for all numbers with caravan role', () {
      expect(isValidTouchpointNumberForRole(1, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(2, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(4, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(7, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(8, UserRole.caravan), true);
      expect(isValidTouchpointNumberForRole(50, UserRole.caravan), true);
    });

    test('returns true for all numbers with tele role', () {
      expect(isValidTouchpointNumberForRole(1, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(2, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(3, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(5, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(6, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(8, UserRole.tele), true);
      expect(isValidTouchpointNumberForRole(50, UserRole.tele), true);
    });

    test('returns true for all numbers with admin role', () {
      for (int i = 1; i <= 50; i++) {
        expect(isValidTouchpointNumberForRole(i, UserRole.admin), true);
      }
    });
  });

  // Type restrictions still apply
  group('getValidTouchpointTypes', () {
    test('returns only Visit type for caravan role', () {
      final types = getValidTouchpointTypes(UserRole.caravan);
      expect(types, [TouchpointType.visit]);
    });

    test('returns only Call type for tele role', () {
      final types = getValidTouchpointTypes(UserRole.tele);
      expect(types, [TouchpointType.call]);
    });

    test('returns both types for admin role', () {
      final types = getValidTouchpointTypes(UserRole.admin);
      expect(types, contains(TouchpointType.visit));
      expect(types, contains(TouchpointType.call));
    });

    test('returns both types for area manager role', () {
      final types = getValidTouchpointTypes(UserRole.areaManager);
      expect(types, contains(TouchpointType.visit));
      expect(types, contains(TouchpointType.call));
    });

    test('returns both types for assistant area manager role', () {
      final types = getValidTouchpointTypes(UserRole.assistantAreaManager);
      expect(types, contains(TouchpointType.visit));
      expect(types, contains(TouchpointType.call));
    });
  });

  group('isValidTouchpointTypeForRole', () {
    test('returns true for Visit type with caravan role', () {
      expect(isValidTouchpointTypeForRole(TouchpointType.visit, UserRole.caravan), true);
    });

    test('returns false for Call type with caravan role', () {
      expect(isValidTouchpointTypeForRole(TouchpointType.call, UserRole.caravan), false);
    });

    test('returns true for Call type with tele role', () {
      expect(isValidTouchpointTypeForRole(TouchpointType.call, UserRole.tele), true);
    });

    test('returns false for Visit type with tele role', () {
      expect(isValidTouchpointTypeForRole(TouchpointType.visit, UserRole.tele), false);
    });

    test('returns true for both types with admin role', () {
      expect(isValidTouchpointTypeForRole(TouchpointType.visit, UserRole.admin), true);
      expect(isValidTouchpointTypeForRole(TouchpointType.call, UserRole.admin), true);
    });
  });
}
