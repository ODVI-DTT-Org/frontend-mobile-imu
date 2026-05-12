import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart';

void main() {
  group('filterAssignedClientCache', () {
    test('keeps only clients marked as assigned cache entries', () {
      final filtered = filterAssignedClientCache([
        {
          'id': 'assigned-1',
          'first_name': 'Juan',
          'last_name': 'Dela Cruz',
          '_cache_source': 'assigned',
        },
        {
          'id': 'favorite-1',
          'first_name': 'Maria',
          'last_name': 'Santos',
          '_cache_source': 'favorite',
        },
      ]);

      expect(filtered, hasLength(1));
      expect(filtered.first['id'], 'assigned-1');
    });

    test('excludes untagged clients to avoid favorites leaking into assigned list', () {
      final filtered = filterAssignedClientCache([
        {
          'id': 'favorite-1',
          'first_name': 'Maria',
          'last_name': 'Santos',
        },
      ]);

      expect(filtered, isEmpty);
    });
  });
}
