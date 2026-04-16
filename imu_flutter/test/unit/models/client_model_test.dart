import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('Client.fromRow', () {
    test('should parse touchpoint_summary JSON array', () {
      final row = {
        'id': 'client-123',
        'first_name': 'John',
        'last_name': 'Doe',
        'touchpoint_summary': '[{"id":"tp-1","touchpointNumber":1,"type":"Visit","date":"2026-04-17T10:00:00.000Z","reason":"LOAN_INQUIRY","status":"Interested","createdAt":"2026-04-17T10:00:00.000Z"}]',
        'touchpoint_number': 2,
        'next_touchpoint': 'Call',
      };

      final client = Client.fromRow(row);

      expect(client.touchpointSummary.length, 1);
      expect(client.touchpointSummary.first.id, 'tp-1');
      expect(client.touchpointNumber, 2);
      expect(client.nextTouchpoint, 'Call');
    });

    test('should handle empty touchpoint_summary', () {
      final row = {
        'id': 'client-123',
        'first_name': 'John',
        'last_name': 'Doe',
        'touchpoint_summary': '',
        'touchpoint_number': 1,
        'next_touchpoint': 'Visit',
      };

      final client = Client.fromRow(row);

      expect(client.touchpointSummary.isEmpty, true);
      expect(client.touchpointNumber, 1);
    });

    test('should handle malformed JSON gracefully', () {
      final row = {
        'id': 'client-123',
        'first_name': 'John',
        'last_name': 'Doe',
        'touchpoint_summary': 'invalid json',
        'touchpoint_number': 1,
        'next_touchpoint': null,
      };

      final client = Client.fromRow(row);

      expect(client.touchpointSummary.isEmpty, true);
      expect(client.touchpointNumber, 1);
    });

    test('should handle null touchpoint_summary', () {
      final row = {
        'id': 'client-123',
        'first_name': 'John',
        'last_name': 'Doe',
        'touchpoint_summary': null,
        'touchpoint_number': 1,
        'next_touchpoint': 'Visit',
      };

      final client = Client.fromRow(row);

      expect(client.touchpointSummary.isEmpty, true);
      expect(client.touchpointNumber, 1);
    });

    test('should parse multiple touchpoints from JSON array', () {
      final row = {
        'id': 'client-123',
        'first_name': 'John',
        'last_name': 'Doe',
        'touchpoint_summary': '[{"id":"tp-1","touchpointNumber":1,"type":"Visit","date":"2026-04-17T10:00:00.000Z","reason":"LOAN_INQUIRY","status":"Interested","createdAt":"2026-04-17T10:00:00.000Z"},{"id":"tp-2","touchpointNumber":2,"type":"Call","date":"2026-04-18T10:00:00.000Z","reason":"FOLLOW_UP","status":"Undecided","createdAt":"2026-04-18T10:00:00.000Z"}]',
        'touchpoint_number': 3,
        'next_touchpoint': 'Call',
      };

      final client = Client.fromRow(row);

      expect(client.touchpointSummary.length, 2);
      expect(client.touchpointSummary[0].id, 'tp-1');
      expect(client.touchpointSummary[0].touchpointNumber, 1);
      expect(client.touchpointSummary[1].id, 'tp-2');
      expect(client.touchpointSummary[1].touchpointNumber, 2);
      expect(client.touchpointNumber, 3);
    });
  });

  group('Client.completedTouchpoints', () {
    test('should return touchpointNumber minus 1', () {
      final client = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.existing,
        productType: ProductType.bfpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpointNumber: 3,
        touchpointSummary: [],
      );

      expect(client.completedTouchpoints, 2);
    });

    test('should return 0 when touchpointNumber is 1', () {
      final client = Client(
        id: 'client-1',
        firstName: 'John',
        lastName: 'Doe',
        clientType: ClientType.existing,
        productType: ProductType.bfpPension,
        pensionType: PensionType.sss,
        createdAt: DateTime.now(),
        touchpointNumber: 1,
        touchpointSummary: [],
      );

      expect(client.completedTouchpoints, 0);
    });
  });
}
