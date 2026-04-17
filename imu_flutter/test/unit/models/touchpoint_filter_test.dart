import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/models/touchpoint_filter.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';

Client _client({required int touchpointNumber}) => Client(
  id: '1',
  firstName: 'Test',
  lastName: 'Client',
  clientType: ClientType.potential,
  productType: ProductType.pnpPension,
  pensionType: PensionType.sss,
  createdAt: DateTime.now(),
  touchpointNumber: touchpointNumber,
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
      expect(filter.matches(_client(touchpointNumber: 1)), true);
      expect(filter.matches(_client(touchpointNumber: 5)), true);
    });

    test('matches returns true when client touchpoint is in selected set', () {
      const filter = TouchpointFilter(selectedNumbers: {2, 4});
      expect(filter.matches(_client(touchpointNumber: 2)), true);
      expect(filter.matches(_client(touchpointNumber: 4)), true);
    });

    test('matches returns false when client touchpoint is not in selected set', () {
      const filter = TouchpointFilter(selectedNumbers: {2, 4});
      expect(filter.matches(_client(touchpointNumber: 1)), false);
      expect(filter.matches(_client(touchpointNumber: 3)), false);
    });

    test('archive (8) matches clients with touchpointNumber > 7', () {
      const filter = TouchpointFilter(selectedNumbers: {8});
      expect(filter.matches(_client(touchpointNumber: 8)), true);
      expect(filter.matches(_client(touchpointNumber: 10)), true);
      expect(filter.matches(_client(touchpointNumber: 7)), false);
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
