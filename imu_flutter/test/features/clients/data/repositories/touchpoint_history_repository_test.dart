import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/clients/data/repositories/touchpoint_history_repository.dart';

void main() {
  group('mergeTouchpointHistory', () {
    test('adds succeeded local touchpoints without duplicating summary rows', () {
      final summaryTouchpoint = _touchpoint(
        id: 'tp-1',
        number: 1,
        createdAt: DateTime(2026, 5, 18, 10),
      );
      final refreshedSummaryTouchpoint = _touchpoint(
        id: 'tp-2',
        number: 2,
        createdAt: DateTime(2026, 5, 18, 11),
        status: TouchpointStatus.completed,
      );
      final succeededLocalTouchpoint = _touchpoint(
        id: 'tp-2',
        number: 2,
        createdAt: DateTime(2026, 5, 18, 11),
      );
      final anotherSucceededLocalTouchpoint = _touchpoint(
        id: 'tp-3',
        number: 3,
        createdAt: DateTime(2026, 5, 18, 12),
      );

      final merged = mergeTouchpointHistory(
        summary: [summaryTouchpoint, refreshedSummaryTouchpoint],
        succeededLocal: [succeededLocalTouchpoint, anotherSucceededLocalTouchpoint],
      );

      expect(merged.map((touchpoint) => touchpoint.id), ['tp-3', 'tp-2', 'tp-1']);
      expect(
        merged.firstWhere((touchpoint) => touchpoint.id == 'tp-2').status,
        TouchpointStatus.completed,
        reason: 'The backend-refreshed summary row should win when IDs overlap.',
      );
    });
  });
}

Touchpoint _touchpoint({
  required String id,
  required int number,
  required DateTime createdAt,
  TouchpointStatus status = TouchpointStatus.interested,
}) {
  return Touchpoint(
    id: id,
    clientId: 'client-1',
    touchpointNumber: number,
    type: TouchpointType.visit,
    reason: TouchpointReason.interested,
    status: status,
    date: createdAt,
    createdAt: createdAt,
  );
}
