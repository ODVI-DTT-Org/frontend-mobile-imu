import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/services/touchpoint/pending_touchpoint_service.dart';
import 'package:imu_flutter/models/pending_touchpoint.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MockBox extends Mock implements Box<Map> {}

void main() {
  group('PendingTouchpointService', () {
    late PendingTouchpointService service;
    late MockBox mockBox;

    setUp(() {
      mockBox = MockBox();

      // Set up default mock behaviors
      when(() => mockBox.length).thenReturn(0);
      when(() => mockBox.values).thenReturn([]);
      when(() => mockBox.watch()).thenAnswer((_) => Stream.empty());

      service = PendingTouchpointService.test(mockBox);
    });

    test('should add pending touchpoint', () async {
      final touchpoint = Touchpoint(
        id: 'tp-1',
        clientId: 'client-1',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await service.addPendingTouchpoint('client-1', touchpoint);

      verify(() => mockBox.put(any(), any())).called(1);
    });

    test('should get pending touchpoints for client', () async {
      final touchpoint1 = Touchpoint(
        id: 'tp-1',
        clientId: 'client-1',
        touchpointNumber: 1,
        type: TouchpointType.visit,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        reason: TouchpointReason.loanInquiry,
        status: TouchpointStatus.interested,
      );

      final pending1 = PendingTouchpoint(
        id: 'pending-1',
        clientId: 'client-1',
        touchpoint: touchpoint1,
        createdAt: DateTime.now(),
      );

      final jsonData = pending1.toJson();

      when(() => mockBox.values).thenReturn([jsonData]);

      final client1Pending = await service.getPendingTouchpointsForClient('client-1');
      expect(client1Pending.length, 1);
      expect(client1Pending.first.clientId, 'client-1');
    });

    test('should count pending touchpoints', () async {
      when(() => mockBox.length).thenReturn(3);

      final count = await service.getPendingCount();
      expect(count, 3);
    });
  });
}
