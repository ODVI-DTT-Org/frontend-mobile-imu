import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/services/touchpoint/touchpoint_validation_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('TouchpointValidationService', () {
    group('Touchpoint Sequence Validation', () {
      test('should validate correct touchpoint sequence: 1=Visit, 2=Call, 3=Call, 4=Visit, 5=Call, 6=Call, 7=Visit', () {
        final sequence = {
          1: TouchpointType.visit,
          2: TouchpointType.call,
          3: TouchpointType.call,
          4: TouchpointType.visit,
          5: TouchpointType.call,
          6: TouchpointType.call,
          7: TouchpointType.visit,
        };

        for (final entry in sequence.entries) {
          final result = TouchpointValidationService.validateTouchpointSequence(
            touchpointNumber: entry.key,
            touchpointType: entry.value,
          );

          expect(result.isValid, true,
            reason: 'Touchpoint #${entry.key} should be ${entry.value}');
          expect(result.expectedType, entry.value);
          expect(result.touchpointNumber, entry.key);
        }
      });

      test('should reject incorrect touchpoint type for touchpoint #1 (must be Visit)', () {
        final result = TouchpointValidationService.validateTouchpointSequence(
          touchpointNumber: 1,
          touchpointType: TouchpointType.call,
        );

        expect(result.isValid, false);
        expect(result.error, contains('Invalid touchpoint type for touchpoint #1'));
        expect(result.expectedType, TouchpointType.visit);
        expect(result.providedType, TouchpointType.call);
      });

      test('should reject incorrect touchpoint type for touchpoint #2 (must be Call)', () {
        final result = TouchpointValidationService.validateTouchpointSequence(
          touchpointNumber: 2,
          touchpointType: TouchpointType.visit,
        );

        expect(result.isValid, false);
        expect(result.error, contains('Invalid touchpoint type for touchpoint #2'));
        expect(result.expectedType, TouchpointType.call);
        expect(result.providedType, TouchpointType.visit);
      });

      test('should reject touchpoint number outside 1-7 range', () {
        expect(
          () => TouchpointValidationService.getExpectedTouchpointType(0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => TouchpointValidationService.getExpectedTouchpointType(8),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should return correct sequence display', () {
        final display = TouchpointValidationService.getSequenceDisplay();

        expect(display, [
          '1st Visit',
          '2nd Call',
          '3rd Call',
          '4th Visit',
          '5th Call',
          '6th Call',
          '7th Visit',
        ]);
      });

      test('should return correct Visit touchpoint numbers', () {
        final visitNumbers = TouchpointValidationService.getVisitTouchpoints();

        expect(visitNumbers, [1, 4, 7]);
      });

      test('should return correct Call touchpoint numbers', () {
        final callNumbers = TouchpointValidationService.getCallTouchpoints();

        expect(callNumbers, [2, 3, 5, 6]);
      });
    });

    group('Role-Based Validation', () {
      test('should allow Caravan user to create Visit touchpoint (1, 4, 7)', () {
        const visitTouchpoints = [1, 4, 7];

        for (final touchpointNumber in visitTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.visit,
            userRole: UserRole.caravan,
          );

          expect(result.isValid, true,
            reason: 'Caravan user should be able to create Visit touchpoint #$touchpointNumber');
          expect(result.expectedType, TouchpointType.visit);
        }
      });

      test('should reject Caravan user from creating Call touchpoint (2, 3, 5, 6)', () {
        const callTouchpoints = [2, 3, 5, 6];

        for (final touchpointNumber in callTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.call,
            userRole: UserRole.caravan,
          );

          expect(result.isValid, false,
            reason: 'Caravan user should NOT be able to create Call touchpoint #$touchpointNumber');
          expect(result.error, contains('Caravan users can only create Visit touchpoints'));
        }
      });

      test('should reject Caravan user from creating Visit at wrong position (2, 3, 5, 6)', () {
        const wrongPositions = [2, 3, 5, 6];

        for (final touchpointNumber in wrongPositions) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.visit,
            userRole: UserRole.caravan,
          );

          expect(result.isValid, false,
            reason: 'Caravan user should NOT be able to create Visit at wrong position #$touchpointNumber');
        }
      });

      test('should allow Tele user to create Call touchpoint (2, 3, 5, 6)', () {
        const callTouchpoints = [2, 3, 5, 6];

        for (final touchpointNumber in callTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.call,
            userRole: UserRole.tele,
          );

          expect(result.isValid, true,
            reason: 'Tele user should be able to create Call touchpoint #$touchpointNumber');
          expect(result.expectedType, TouchpointType.call);
        }
      });

      test('should reject Tele user from creating Visit touchpoint (1, 4, 7)', () {
        const visitTouchpoints = [1, 4, 7];

        for (final touchpointNumber in visitTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.visit,
            userRole: UserRole.tele,
          );

          expect(result.isValid, false,
            reason: 'Tele user should NOT be able to create Visit touchpoint #$touchpointNumber');
          expect(result.error, contains('Tele users can only create Call touchpoints'));
        }
      });

      test('should reject Tele user from creating Call at wrong position (1, 4, 7)', () {
        const wrongPositions = [1, 4, 7];

        for (final touchpointNumber in wrongPositions) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpointNumber,
            touchpointType: TouchpointType.call,
            userRole: UserRole.tele,
          );

          expect(result.isValid, false,
            reason: 'Tele user should NOT be able to create Call at wrong position #$touchpointNumber');
        }
      });

      test('should allow Admin users to create any touchpoint type', () {
        final allTouchpoints = [
          {'number': 1, 'type': TouchpointType.visit},
          {'number': 2, 'type': TouchpointType.call},
          {'number': 3, 'type': TouchpointType.call},
          {'number': 4, 'type': TouchpointType.visit},
          {'number': 5, 'type': TouchpointType.call},
          {'number': 6, 'type': TouchpointType.call},
          {'number': 7, 'type': TouchpointType.visit},
        ];

        for (final touchpoint in allTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpoint['number'] as int,
            touchpointType: touchpoint['type'] as TouchpointType,
            userRole: UserRole.admin,
          );

          expect(result.isValid, true,
            reason: 'Admin user should be able to create any touchpoint');
        }
      });

      test('should allow Area Manager users to create any touchpoint type', () {
        final testTouchpoints = [
          {'number': 1, 'type': TouchpointType.visit},
          {'number': 2, 'type': TouchpointType.call},
        ];

        for (final touchpoint in testTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpoint['number'] as int,
            touchpointType: touchpoint['type'] as TouchpointType,
            userRole: UserRole.areaManager,
          );

          expect(result.isValid, true,
            reason: 'Area Manager should be able to create any touchpoint');
        }
      });

      test('should allow Assistant Area Manager users to create any touchpoint type', () {
        final testTouchpoints = [
          {'number': 1, 'type': TouchpointType.visit},
          {'number': 2, 'type': TouchpointType.call},
        ];

        for (final touchpoint in testTouchpoints) {
          final result = TouchpointValidationService.validateTouchpointForRole(
            touchpointNumber: touchpoint['number'] as int,
            touchpointType: touchpoint['type'] as TouchpointType,
            userRole: UserRole.assistantAreaManager,
          );

          expect(result.isValid, true,
            reason: 'Assistant Area Manager should be able to create any touchpoint');
        }
      });

      test('canRoleCreateTouchpoint should return correct for Caravan', () {
        expect(TouchpointValidationService.canRoleCreateTouchpoint(
          touchpointNumber: 1,
          userRole: UserRole.caravan,
        ), true);

        expect(TouchpointValidationService.canRoleCreateTouchpoint(
          touchpointNumber: 2,
          userRole: UserRole.caravan,
        ), false);
      });

      test('canRoleCreateTouchpoint should return correct for Tele', () {
        expect(TouchpointValidationService.canRoleCreateTouchpoint(
          touchpointNumber: 2,
          userRole: UserRole.tele,
        ), true);

        expect(TouchpointValidationService.canRoleCreateTouchpoint(
          touchpointNumber: 1,
          userRole: UserRole.tele,
        ), false);
      });

      test('canRoleCreateTouchpoint should return true for all managers', () {
        final managerRoles = [
          UserRole.admin,
          UserRole.areaManager,
          UserRole.assistantAreaManager,
        ];

        for (final role in managerRoles) {
          expect(TouchpointValidationService.canRoleCreateTouchpoint(
            touchpointNumber: 1,
            userRole: role,
          ), true, reason: '$role should be able to create any touchpoint');

          expect(TouchpointValidationService.canRoleCreateTouchpoint(
            touchpointNumber: 2,
            userRole: role,
          ), true, reason: '$role should be able to create any touchpoint');
        }
      });
    });

    group('Next Touchpoint Number Calculation', () {
      test('should return 1 for client with no touchpoints', () {
        final client = Client(
          id: 'test-client-1',
          firstName: 'John',
          lastName: 'Doe',
          clientType: ClientType.potential,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: [],
        );

        final nextNumber = TouchpointValidationService.getNextTouchpointNumber(client);

        expect(nextNumber, 1);
      });

      test('should return 2 for client with 1 touchpoint', () {
        final client = Client(
          id: 'test-client-2',
          firstName: 'Jane',
          lastName: 'Smith',
          clientType: ClientType.existing,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: [
            Touchpoint(
              id: 'tp-1',
              clientId: 'test-client-2',
              touchpointNumber: 1,
              type: TouchpointType.visit,
              date: DateTime.now(),
              reason: TouchpointReason.interested,
              status: TouchpointStatus.interested,
            ),
          ],
        );

        final nextNumber = TouchpointValidationService.getNextTouchpointNumber(client);

        expect(nextNumber, 2);
      });

      test('should return null for client with all 7 touchpoints', () {
        final touchpoints = List.generate(7, (index) {
          final number = index + 1;
          return Touchpoint(
            id: 'tp-$number',
            clientId: 'test-client-complete',
            touchpointNumber: number,
            type: number == 1 || number == 4 || number == 7
                ? TouchpointType.visit
                : TouchpointType.call,
            date: DateTime.now(),
            reason: TouchpointReason.interested,
            status: TouchpointStatus.completed,
          );
        });

        final client = Client(
          id: 'test-client-complete',
          firstName: 'Complete',
          lastName: 'Client',
          clientType: ClientType.existing,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: touchpoints,
        );

        final nextNumber = TouchpointValidationService.getNextTouchpointNumber(client);

        expect(nextNumber, null);
      });

      test('canCreateTouchpoint should return correct result for client with no touchpoints', () {
        final client = Client(
          id: 'test-client-new',
          firstName: 'New',
          lastName: 'Client',
          clientType: ClientType.potential,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: [],
        );

        final result = TouchpointValidationService.canCreateTouchpoint(client);

        expect(result.canCreate, true);
        expect(result.completedTouchpoints, 0);
        expect(result.nextTouchpointNumber, 1);
        expect(result.nextTouchpointType, TouchpointType.visit);
        expect(result.reason, null);
      });

      test('canCreateTouchpoint should return correct result for client with 3 touchpoints', () {
        final client = Client(
          id: 'test-client-partial',
          firstName: 'Partial',
          lastName: 'Client',
          clientType: ClientType.existing,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: [
            Touchpoint(
              id: 'tp-1',
              clientId: 'test-client-partial',
              touchpointNumber: 1,
              type: TouchpointType.visit,
              date: DateTime.now(),
              reason: TouchpointReason.interested,
              status: TouchpointStatus.interested,
            ),
            Touchpoint(
              id: 'tp-2',
              clientId: 'test-client-partial',
              touchpointNumber: 2,
              type: TouchpointType.call,
              date: DateTime.now(),
              reason: TouchpointReason.interested,
              status: TouchpointStatus.interested,
            ),
            Touchpoint(
              id: 'tp-3',
              clientId: 'test-client-partial',
              touchpointNumber: 3,
              type: TouchpointType.call,
              date: DateTime.now(),
              reason: TouchpointReason.interested,
              status: TouchpointStatus.undecided,
            ),
          ],
        );

        final result = TouchpointValidationService.canCreateTouchpoint(client);

        expect(result.canCreate, true);
        expect(result.completedTouchpoints, 3);
        expect(result.nextTouchpointNumber, 4);
        expect(result.nextTouchpointType, TouchpointType.visit);
        expect(result.reason, null);
      });

      test('canCreateTouchpoint should return correct result for complete client', () {
        final touchpoints = List.generate(7, (index) {
          final number = index + 1;
          return Touchpoint(
            id: 'tp-$number',
            clientId: 'test-client-done',
            touchpointNumber: number,
            type: number == 1 || number == 4 || number == 7
                ? TouchpointType.visit
                : TouchpointType.call,
            date: DateTime.now(),
            reason: TouchpointReason.interested,
            status: TouchpointStatus.completed,
          );
        });

        final client = Client(
          id: 'test-client-done',
          firstName: 'Done',
          lastName: 'Client',
          clientType: ClientType.existing,
          productType: 'LOAN',
          marketType: 'RETAIL',
          pensionType: 'SSS',
          touchpoints: touchpoints,
        );

        final result = TouchpointValidationService.canCreateTouchpoint(client);

        expect(result.canCreate, false);
        expect(result.completedTouchpoints, 7);
        expect(result.nextTouchpointNumber, null);
        expect(result.nextTouchpointType, null);
        expect(result.reason, contains('All 7 touchpoints have been completed'));
      });
    });

    group('UserRole Enum', () {
      test('should have correct api values', () {
        expect(UserRole.caravan.apiValue, 'caravan');
        expect(UserRole.tele.apiValue, 'tele');
        expect(UserRole.admin.apiValue, 'admin');
        expect(UserRole.areaManager.apiValue, 'area_manager');
        expect(UserRole.assistantAreaManager.apiValue, 'assistant_area_manager');
      });

      test('fromApi should parse correctly', () {
        expect(UserRole.fromApi('caravan'), UserRole.caravan);
        expect(UserRole.fromApi('tele'), UserRole.tele);
        expect(UserRole.fromApi('admin'), UserRole.admin);
        expect(UserRole.fromApi('area_manager'), UserRole.areaManager);
        expect(UserRole.fromApi('assistant_area_manager'), UserRole.assistantAreaManager);

        // Case insensitive
        expect(UserRole.fromApi('CARAVAN'), UserRole.caravan);
        expect(UserRole.fromApi('Tele'), UserRole.tele);

        // Default to caravan for invalid values
        expect(UserRole.fromApi('invalid'), UserRole.caravan);
        expect(UserRole.fromApi(''), UserRole.caravan);
      });
    });
  });
}
