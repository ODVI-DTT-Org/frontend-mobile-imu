import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/my_day/data/models/my_day_client.dart';

void main() {
  group('MyDayClient.fromPowerSync', () {
    Map<String, dynamic> baseRow({String? touchpointSummary}) => {
          'id': 'itin-1',
          'client_id': 'client-1',
          'first_name': 'Juan',
          'last_name': 'dela Cruz',
          'priority': 'normal',
          'notes': null,
          'status': 'pending',
          'scheduled_time': '09:00',
          'touchpoint_summary': touchpointSummary,
        };

    test('no touchpoints: touchpointNumber=0, next=1 Visit', () {
      final client = MyDayClient.fromPowerSync(baseRow());
      expect(client.id, 'itin-1');
      expect(client.clientId, 'client-1');
      expect(client.fullName, 'Juan dela Cruz');
      expect(client.touchpointNumber, 0);
      expect(client.touchpointType, 'visit');
      expect(client.nextTouchpointNumber, 1);
      expect(client.nextTouchpointType, 'Visit');
      expect(client.previousTouchpointNumber, isNull);
    });

    test('first touchpoint done: next=2 Call', () {
      final summary = jsonEncode([
        {'touchpoint_number': 1, 'type': 'Visit', 'reason': 'intro', 'status': 'Completed', 'date': '2026-01-01'}
      ]);
      final client = MyDayClient.fromPowerSync(baseRow(touchpointSummary: summary));
      expect(client.touchpointNumber, 2);
      expect(client.touchpointType, 'call');
      expect(client.nextTouchpointNumber, 2);
      expect(client.nextTouchpointType, 'Call');
      expect(client.previousTouchpointNumber, 1);
      expect(client.previousTouchpointType, 'Visit');
    });

    test('touchpoints 1-3 done: next=4 Visit', () {
      final summary = jsonEncode([
        {'touchpoint_number': 1, 'type': 'Visit', 'reason': 'intro', 'status': 'Completed', 'date': '2026-01-01'},
        {'touchpoint_number': 2, 'type': 'Call', 'reason': 'follow', 'status': 'Completed', 'date': '2026-01-05'},
        {'touchpoint_number': 3, 'type': 'Call', 'reason': 'follow', 'status': 'Completed', 'date': '2026-01-10'},
      ]);
      final client = MyDayClient.fromPowerSync(baseRow(touchpointSummary: summary));
      expect(client.nextTouchpointNumber, 4);
      expect(client.nextTouchpointType, 'Visit');
      expect(client.previousTouchpointNumber, 3);
    });

    test('all 7 touchpoints done: nextNum null', () {
      final summary = jsonEncode(List.generate(
          7, (i) => {'touchpoint_number': i + 1, 'type': 'x', 'reason': 'x', 'status': 'Completed', 'date': '2026-01-01'}));
      final client = MyDayClient.fromPowerSync(baseRow(touchpointSummary: summary));
      expect(client.nextTouchpointNumber, isNull);
      expect(client.nextTouchpointType, isNull);
    });

    test('null touchpoint_summary handled gracefully', () {
      final client = MyDayClient.fromPowerSync(baseRow(touchpointSummary: null));
      expect(client.touchpointNumber, 0);
      expect(client.nextTouchpointNumber, 1);
    });

    test('throws on missing client_id', () {
      final row = baseRow()..remove('client_id');
      row['client_id'] = null;
      expect(() => MyDayClient.fromPowerSync(row), throwsArgumentError);
    });
  });

  group('MyDayClient.fromJson', () {
    test('parses assignedByName', () {
      final json = {
        'id': 'item-1',
        'client_id': 'client-1',
        'full_name': 'Dela Cruz, Juan',
        'touchpoint_number': 1,
        'touchpoint_type': 'visit',
        'priority': 'high',
        'assigned_by_name': 'Maria Santos',
      };
      final client = MyDayClient.fromJson(json);
      expect(client.assignedByName, 'Maria Santos');
    });

    test('handles missing assignedByName gracefully', () {
      final json = {
        'id': 'item-2',
        'client_id': 'client-1',
        'full_name': 'Dela Cruz, Juan',
        'touchpoint_number': 1,
        'touchpoint_type': 'visit',
        'priority': 'normal',
      };
      final client = MyDayClient.fromJson(json);
      expect(client.assignedByName, isNull);
    });
  });
}
