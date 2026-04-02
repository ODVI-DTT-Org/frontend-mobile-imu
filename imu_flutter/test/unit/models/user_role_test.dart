import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/core/models/user_role.dart';

void main() {
  group('UserRole', () {
    group('apiValue', () {
      test('returns correct API value for each role', () {
        expect(UserRole.admin.apiValue, 'admin');
        expect(UserRole.areaManager.apiValue, 'area_manager');
        expect(UserRole.assistantAreaManager.apiValue, 'assistant_area_manager');
        expect(UserRole.caravan.apiValue, 'caravan');
      });
    });

    group('displayName', () {
      test('returns human-readable display name', () {
        expect(UserRole.admin.displayName, 'Admin');
        expect(UserRole.areaManager.displayName, 'Area Manager');
        expect(UserRole.assistantAreaManager.displayName, 'Assistant Area Manager');
        expect(UserRole.caravan.displayName, 'Caravan');
      });
    });

    group('canCreateAnyTouchpoint', () {
      test('returns true for managers', () {
        expect(UserRole.admin.canCreateAnyTouchpoint, true);
        expect(UserRole.areaManager.canCreateAnyTouchpoint, true);
        expect(UserRole.assistantAreaManager.canCreateAnyTouchpoint, true);
      });

      test('returns false for caravan', () {
        expect(UserRole.caravan.canCreateAnyTouchpoint, false);
      });
    });

    group('canCreateVisitTouchpoints', () {
      test('returns true for all mobile roles', () {
        expect(UserRole.admin.canCreateVisitTouchpoints, true);
        expect(UserRole.areaManager.canCreateVisitTouchpoints, true);
        expect(UserRole.assistantAreaManager.canCreateVisitTouchpoints, true);
        expect(UserRole.caravan.canCreateVisitTouchpoints, true);
      });
    });

    group('canCreateCallTouchpoints', () {
      test('returns true only for managers', () {
        expect(UserRole.admin.canCreateCallTouchpoints, true);
        expect(UserRole.areaManager.canCreateCallTouchpoints, true);
        expect(UserRole.assistantAreaManager.canCreateCallTouchpoints, true);
        expect(UserRole.caravan.canCreateCallTouchpoints, false);
      });
    });

    group('isManager', () {
      test('returns true for admin and managers', () {
        expect(UserRole.admin.isManager, true);
        expect(UserRole.areaManager.isManager, true);
        expect(UserRole.assistantAreaManager.isManager, true);
      });

      test('returns false for caravan', () {
        expect(UserRole.caravan.isManager, false);
      });
    });

    group('fromApi', () {
      test('parses valid role strings', () {
        expect(UserRole.fromApi('admin'), UserRole.admin);
        expect(UserRole.fromApi('area_manager'), UserRole.areaManager);
        expect(UserRole.fromApi('assistant_area_manager'), UserRole.assistantAreaManager);
        expect(UserRole.fromApi('caravan'), UserRole.caravan);
      });

      test('maps legacy roles to caravan', () {
        expect(UserRole.fromApi('field_agent'), UserRole.caravan);
        expect(UserRole.fromApi('staff'), UserRole.caravan);
        expect(UserRole.fromApi('fieldAgent'), UserRole.caravan);
      });

      test('handles null and empty strings', () {
        expect(UserRole.fromApi(null), UserRole.caravan);
        expect(UserRole.fromApi(''), UserRole.caravan);
        expect(UserRole.fromApi('  '), UserRole.caravan);
      });

      test('handles unknown roles with safe default', () {
        expect(UserRole.fromApi('unknown_role'), UserRole.caravan);
        expect(UserRole.fromApi('tele'), UserRole.caravan);
      });
    });

    group('fromJwt', () {
      test('parses role from JWT token', () {
        final jwt1 = {'role': 'admin'};
        expect(UserRole.fromJwt(jwt1), UserRole.admin);

        final jwt2 = {'role': 'caravan'};
        expect(UserRole.fromJwt(jwt2), UserRole.caravan);
      });

      test('maps legacy roles in JWT', () {
        final jwt1 = {'role': 'field_agent'};
        expect(UserRole.fromJwt(jwt1), UserRole.caravan);

        final jwt2 = {'role': 'staff'};
        expect(UserRole.fromJwt(jwt2), UserRole.caravan);
      });

      test('handles missing role with safe default', () {
        final jwt = <String, dynamic>{};
        expect(UserRole.fromJwt(jwt), UserRole.caravan);
      });

      test('handles null role with safe default', () {
        final jwt = {'role': null};
        expect(UserRole.fromJwt(jwt), UserRole.caravan);
      });
    });
  });
}
