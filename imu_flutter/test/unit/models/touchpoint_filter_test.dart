import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/touchpoint_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

Client _client({int touchpointNumber = 0, int? nextTouchpointNumber, bool loanReleased = false}) => Client(
  id: '1',
  firstName: 'Test',
  lastName: 'Client',
  clientType: ClientType.potential,
  productType: ProductType.pnpPension,
  pensionType: PensionType.sss,
  createdAt: DateTime.now(),
  touchpointNumber: touchpointNumber,
  nextTouchpointNumber: nextTouchpointNumber,
  loanReleased: loanReleased,
);

void main() {
  group('TouchpointFilter', () {
    test('empty filter has no filter active', () {
      const filter = TouchpointFilter();
      expect(filter.hasFilter, false);
    });

    test('filter with selected numbers is active', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 3});
      expect(filter.hasFilter, true);
    });

    test('matches returns true when no filter selected', () {
      const filter = TouchpointFilter();
      expect(filter.matches(_client(nextTouchpointNumber: 1)), true);
      expect(filter.matches(_client(nextTouchpointNumber: 5)), true);
    });

    test('matches by next_touchpoint_number, not touchpoint_number', () {
      const filter = TouchpointFilter(selectedNumbers: {2, 4});
      // client with 1 done → next is 2 → should match
      expect(filter.matches(_client(touchpointNumber: 1, nextTouchpointNumber: 2)), true);
      // client with 3 done → next is 4 → should match
      expect(filter.matches(_client(touchpointNumber: 3, nextTouchpointNumber: 4)), true);
      // client with 0 done → next is 1 → should NOT match
      expect(filter.matches(_client(touchpointNumber: 0, nextTouchpointNumber: 1)), false);
      // client with 2 done → next is 3 → should NOT match
      expect(filter.matches(_client(touchpointNumber: 2, nextTouchpointNumber: 3)), false);
    });

    test('filter {1} matches clients with next_touchpoint_number == 1 (0 completed)', () {
      const filter = TouchpointFilter(selectedNumbers: {1});
      expect(filter.matches(_client(touchpointNumber: 0, nextTouchpointNumber: 1)), true);
      expect(filter.matches(_client(touchpointNumber: 1, nextTouchpointNumber: 2)), false);
    });

    test('archive (8) matches clients with all 7 completed', () {
      const filter = TouchpointFilter(selectedNumbers: {8});
      expect(filter.matches(_client(touchpointNumber: 7, nextTouchpointNumber: null)), true);
      expect(filter.matches(_client(touchpointNumber: 6, nextTouchpointNumber: 7)), false);
    });

    test('archive (8) matches loan-released clients regardless of touchpoint count', () {
      const filter = TouchpointFilter(selectedNumbers: {8});
      expect(filter.matches(_client(touchpointNumber: 3, loanReleased: true)), true);
      expect(filter.matches(_client(touchpointNumber: 3, loanReleased: false)), false);
    });

    test('toggle adds number when absent', () {
      const filter = TouchpointFilter(selectedNumbers: {1});
      final updated = filter.toggle(3);
      expect(updated.selectedNumbers, {1, 3});
    });

    test('toggle removes number when present', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 3});
      final updated = filter.toggle(1);
      expect(updated.selectedNumbers, {3});
    });

    test('clear returns filter with empty set', () {
      const filter = TouchpointFilter(selectedNumbers: {1, 2, 3});
      final cleared = filter.clear();
      expect(cleared.hasFilter, false);
      expect(cleared.selectedNumbers, isEmpty);
    });

    test('toList returns sorted list of selected numbers', () {
      const filter = TouchpointFilter(selectedNumbers: {5, 1, 3});
      expect(filter.toList(), [1, 3, 5]);
    });
  });
}
