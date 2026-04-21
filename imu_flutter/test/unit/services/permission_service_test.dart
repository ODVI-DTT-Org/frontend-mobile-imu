import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/services/permissions/permission_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('PermissionService', () {
    group('canCreateTouchpoint', () {
      test('admin can create any touchpoint type', () {
        final resultVisit = PermissionService.canCreateTouchpoint(
          role: UserRole.admin,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(resultVisit, true);

        final resultCall = PermissionService.canCreateTouchpoint(
          role: UserRole.admin,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(resultCall, true);
      });

      test('area manager can create any touchpoint type', () {
        final result = PermissionService.canCreateTouchpoint(
          role: UserRole.areaManager,
          touchpointNumber: 5,
          type: TouchpointType.call,
        );
        expect(result, true);
      });

      test('assistant area manager can create any touchpoint type', () {
        final result = PermissionService.canCreateTouchpoint(
          role: UserRole.assistantAreaManager,
          touchpointNumber: 6,
          type: TouchpointType.call,
        );
        expect(result, true);
      });

      // UPDATED for Unli Touchpoint - no number restrictions
      test('caravan can create visit touchpoints at any number', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(tp1, true);

        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 2,
          type: TouchpointType.visit,
        );
        expect(tp2, true);

        final tp8 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 8,
          type: TouchpointType.visit,
        );
        expect(tp8, true);

        final tp50 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 50,
          type: TouchpointType.visit,
        );
        expect(tp50, true);
      });

      test('caravan cannot create call touchpoints at any number', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 1,
          type: TouchpointType.call,
        );
        expect(tp1, false);

        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(tp2, false);

        final tp8 = PermissionService.canCreateTouchpoint(
          role: UserRole.caravan,
          touchpointNumber: 8,
          type: TouchpointType.call,
        );
        expect(tp8, false);
      });

      // UPDATED for Unli Touchpoint - no number restrictions
      test('tele can create call touchpoints at any number', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 1,
          type: TouchpointType.call,
        );
        expect(tp1, true);

        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 2,
          type: TouchpointType.call,
        );
        expect(tp2, true);

        final tp8 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 8,
          type: TouchpointType.call,
        );
        expect(tp8, true);

        final tp50 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 50,
          type: TouchpointType.call,
        );
        expect(tp50, true);
      });

      test('tele cannot create visit touchpoints at any number', () {
        final tp1 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 1,
          type: TouchpointType.visit,
        );
        expect(tp1, false);

        final tp2 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 2,
          type: TouchpointType.visit,
        );
        expect(tp2, false);

        final tp8 = PermissionService.canCreateTouchpoint(
          role: UserRole.tele,
          touchpointNumber: 8,
          type: TouchpointType.visit,
        );
        expect(tp8, false);
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
