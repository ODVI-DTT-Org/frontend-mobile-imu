// test/unit/services/touchpoint_calculator_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/record_forms/domain/services/touchpoint_calculator_service.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('TouchpointCalculatorService', () {
    test('calculates next touchpoint number as 1 for new client', () async {
      final service = TouchpointCalculatorService();

      // Empty touchpoints list means new client
      final nextNumber = await service.calculateNextNumber('client-123', []);

      expect(nextNumber, 1);
    });

    test('calculates next touchpoint number as 4 for client with 3 touchpoints', () async {
      final service = TouchpointCalculatorService();

      // Mock 3 touchpoints with numbers 1, 2, 3
      final touchpoints = [
        Touchpoint(
          id: '1',
          clientId: 'client-123',
          touchpointNumber: 1,
          type: TouchpointType.visit,
          reason: TouchpointReason.interested,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        Touchpoint(
          id: '2',
          clientId: 'client-123',
          touchpointNumber: 2,
          type: TouchpointType.call,
          reason: TouchpointReason.undecided,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        Touchpoint(
          id: '3',
          clientId: 'client-123',
          touchpointNumber: 3,
          type: TouchpointType.call,
          reason: TouchpointReason.interested,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final nextNumber = await service.calculateNextNumber('client-123', touchpoints);

      expect(nextNumber, 4);
    });

    test('throws exception when max 7 touchpoints reached', () async {
      final service = TouchpointCalculatorService();

      // Mock 7 touchpoints (max limit)
      final touchpoints = List.generate(7, (i) => Touchpoint(
        id: i.toString(),
        clientId: 'client-123',
        touchpointNumber: i + 1,
        type: TouchpointType.visit,
        reason: TouchpointReason.interested,
        status: TouchpointStatus.interested,
        date: DateTime.now(),
        createdAt: DateTime.now(),
      ));

      expect(
        () => service.calculateNextNumber('client-123', touchpoints),
        throwsA(isA<TouchpointLimitException>()),
      );
    });

    test('handles gaps in touchpoint numbers correctly', () async {
      final service = TouchpointCalculatorService();

      // Touchpoints with gaps: 1, 3, 5 (should return 6)
      final touchpoints = [
        Touchpoint(
          id: '1',
          clientId: 'client-123',
          touchpointNumber: 1,
          type: TouchpointType.visit,
          reason: TouchpointReason.interested,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        Touchpoint(
          id: '3',
          clientId: 'client-123',
          touchpointNumber: 3,
          type: TouchpointType.call,
          reason: TouchpointReason.undecided,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
        Touchpoint(
          id: '5',
          clientId: 'client-123',
          touchpointNumber: 5,
          type: TouchpointType.call,
          reason: TouchpointReason.interested,
          status: TouchpointStatus.interested,
          date: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      ];

      final nextNumber = await service.calculateNextNumber('client-123', touchpoints);

      expect(nextNumber, 6); // Should return max + 1, not fill gaps
    });
  });
}
