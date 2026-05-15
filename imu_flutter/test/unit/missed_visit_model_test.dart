import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/visits/data/models/missed_visit_model.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

void main() {
  group('MissedVisitSource', () {
    test('has missedItinerary and overdueClient values', () {
      expect(MissedVisitSource.values.length, 2);
      expect(MissedVisitSource.missedItinerary, isNotNull);
      expect(MissedVisitSource.overdueClient, isNotNull);
    });
  });

  group('MissedVisit.source field', () {
    test('defaults to overdueClient when constructed without source', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 1,
        touchpointType: TouchpointType.visit,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
      );
      expect(v.source, MissedVisitSource.overdueClient);
      expect(v.itineraryId, isNull);
    });

    test('source and itineraryId are preserved when set', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 2,
        touchpointType: TouchpointType.call,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
        source: MissedVisitSource.missedItinerary,
        itineraryId: 'itin-abc',
      );
      expect(v.source, MissedVisitSource.missedItinerary);
      expect(v.itineraryId, 'itin-abc');
    });

    test('toJson serialises source and itineraryId', () {
      final v = MissedVisit(
        id: 'x',
        clientId: 'c1',
        clientName: 'Test',
        touchpointNumber: 1,
        touchpointType: TouchpointType.visit,
        scheduledDate: DateTime(2026, 5, 1),
        createdAt: DateTime(2026, 5, 1),
        source: MissedVisitSource.missedItinerary,
        itineraryId: 'itin-abc',
      );
      final json = v.toJson();
      expect(json['source'], 'missedItinerary');
      expect(json['itineraryId'], 'itin-abc');
    });

    test('fromJson round-trips source and itineraryId', () {
      final json = {
        'id': 'x',
        'clientId': 'c1',
        'clientName': 'Test',
        'touchpointNumber': 1,
        'touchpointType': 'visit',
        'scheduledDate': '2026-05-01T00:00:00.000',
        'createdAt': '2026-05-01T00:00:00.000',
        'source': 'missedItinerary',
        'itineraryId': 'itin-abc',
      };
      final v = MissedVisit.fromJson(json);
      expect(v.source, MissedVisitSource.missedItinerary);
      expect(v.itineraryId, 'itin-abc');
    });

    test('fromJson defaults source to overdueClient when field is absent', () {
      final json = {
        'id': 'x',
        'clientId': 'c1',
        'clientName': 'Test',
        'touchpointNumber': 1,
        'touchpointType': 'visit',
        'scheduledDate': '2026-05-01T00:00:00.000',
        'createdAt': '2026-05-01T00:00:00.000',
      };
      final v = MissedVisit.fromJson(json);
      expect(v.source, MissedVisitSource.overdueClient);
      expect(v.itineraryId, isNull);
    });
  });
}
