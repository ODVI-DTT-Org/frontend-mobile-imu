import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/services/permissions/permission_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('PermissionService', () {
    group('canCreateTouchpoint', () {
      test('admin can create any touchpoint', () {
        final result = PermissionService.canCreateTouchpoint(
          role: UserRole.admin,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(result, true);

        final result2 = PermissionService.canCreateTouchpoint(
          role: UserRole.admin,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(result2, true);
      });

      test('area manager can create any touchpoint', () {
        final result = PermissionService.canCreateTouchpoint(
          role: UserRole.areaManager,
          touchpointNumber: 5,
          type: TouchpointType.call,
        );
        expect(result, true);
      });

      test('assistant area manager can create any touchpoint', () {
        final result = PermissionService.canCreateTouchpoint(
          role: UserRole.assistantAreaManager,
          touchpointNumber: 6,
          type: TouchpointType.call,
        );
        expect(result, true);
      });

      test('caravan can create visit touchpoints (1, 4, 7)', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(tp1, true);

        final tp4 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 4,
          type: TouchpointType.visit,
        );
        expect(tp4, true);

        final tp7 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 7,
          type: TouchpointType.visit,
        );
        expect(tp7, true);
      });

      test('caravan cannot create call touchpoints', () {
        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(tp2, false);

        final tp3 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 3,
          type: TouchpointType.call,
        );
        expect(tp3, false);
      });

      test('caravan cannot create visit for call touchpoints (2, 3, 5, 6)', () {
        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 2,
          type: TouchpointType.visit,
        );
        expect(tp2, false);

        final tp5 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 5,
          type: TouchpointType.visit,
        );
        expect(tp5, false);
      });

      test('caravan cannot create call for visit touchpoints (1, 4, 7)', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 1,
          type: TouchpointType.call,
        );
        expect(tp1, false);

        final tp4 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 4,
          type: TouchpointType.call,
        );
        expect(tp4, false);
      });

      test('tele can create call touchpoints (2, 3, 5, 6)', () {
        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(tp2, true);

        final tp3 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 3,
          type: TouchpointType.call,
        );
        expect(tp3, true);

        final tp5 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 5,
          type: TouchpointType.call,
        );
        expect(tp5, true);

        final tp6 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 6,
          type: TouchpointType.call,
        );
        expect(tp6, true);
      });

      test('tele cannot create visit touchpoints', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(tp1, false);

        final tp4 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 4,
          type: TouchpointType.visit,
        );
        expect(tp4, false);

        final tp7 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 7,
          type: TouchpointType.visit,
        );
        expect(tp7, false);
      });

      test('tele cannot create call for visit touchpoints (1, 4, 7)', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 1,
          type: TouchpointType.call,
        );
        expect(tp1, false);

        final tp4 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 4,
          type: TouchpointType.call,
        );
        expect(tp4, false);
      });

      test('tele cannot create visit for call touchpoints (2, 3, 5, 6)', () {
        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 2,
          type: TouchpointType.visit,
        );
        expect(tp2, false);

        final tp5 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 5,
          type: TouchpointType.visit,
        );
        expect(tp5, false);
      });
    });

    group('canManageArea', () {
      test('returns true for managers', () {
        expect(PermissionService.canManageArea(UserRole.admin), true);
        expect(PermissionService.canManageArea(UserRole.areaManager), true);
        expect(PermissionService.canManageArea(UserRole.assistantAreaManager), true);
      });

      test('returns false for caravan and tele', () {
        expect(PermissionService.canManageArea(UserRole.caravan), false);
        expect(PermissionService.canManageArea(UserRole.tele), false);
      });
    });

    group('canAccessAdmin', () {
      test('returns true only for admin', () {
        expect(PermissionService.canAccessAdmin(UserRole.admin), true);
        expect(PermissionService.canAccessAdmin(UserRole.areaManager), false);
        expect(PermissionService.canAccessAdmin(UserRole.caravan), false);
        expect(PermissionService.canAccessAdmin(UserRole.tele), false);
      });
    });
  });
}
