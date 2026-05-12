import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/itineraries/data/repositories/itinerary_repository.dart';

void main() {
  group('normalizeItineraryRowsForDisplay', () {
    test('keeps joined client name fields when no Hive cache is involved', () {
      final rows = [
        {
          'id': 'itin-1',
          'client_id': 'client-1',
          'first_name': 'Juan',
          'last_name': 'Dela Cruz',
          'middle_name': 'Santos',
          'scheduled_time': '09:00',
        },
      ];

      final normalized = normalizeItineraryRowsForDisplay(rows);

      expect(normalized, hasLength(1));
      expect(normalized.first['first_name'], 'Juan');
      expect(normalized.first['last_name'], 'Dela Cruz');
      expect(normalized.first['middle_name'], 'Santos');
    });

    test('collapses duplicate itinerary rows for the same client and keeps the richer row', () {
      final rows = [
        {
          'id': 'itin-1',
          'client_id': 'client-1',
          'first_name': '',
          'last_name': '',
          'scheduled_time': '09:00',
        },
        {
          'id': 'itin-2',
          'client_id': 'client-1',
          'first_name': 'Juan',
          'last_name': 'Dela Cruz',
          'scheduled_time': '10:00',
        },
        {
          'id': 'itin-3',
          'client_id': 'client-2',
          'first_name': 'Maria',
          'last_name': 'Santos',
          'scheduled_time': '11:00',
        },
      ];

      final normalized = normalizeItineraryRowsForDisplay(rows);

      expect(normalized, hasLength(2));
      expect(normalized.map((row) => row['client_id']), ['client-1', 'client-2']);
      expect(normalized.first['id'], 'itin-2');
      expect(normalized.first['first_name'], 'Juan');
      expect(normalized.first['last_name'], 'Dela Cruz');
    });
  });
}
