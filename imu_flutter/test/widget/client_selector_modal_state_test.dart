import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/shared/widgets/client_selector_modal.dart';

void main() {
  group('shouldDisableClientAddAction', () {
    test('disables add action for clients already scheduled on the selected date', () {
      final disabled = shouldDisableClientAddAction(
        clientId: 'client-1',
        scheduledClientIds: {'client-1'},
        addingClientIds: const {},
        addedClientIds: const {},
      );

      expect(disabled, isTrue);
    });

    test('disables add action while a client is being added or was just added', () {
      expect(
        shouldDisableClientAddAction(
          clientId: 'client-1',
          scheduledClientIds: const {},
          addingClientIds: {'client-1'},
          addedClientIds: const {},
        ),
        isTrue,
      );

      expect(
        shouldDisableClientAddAction(
          clientId: 'client-1',
          scheduledClientIds: const {},
          addingClientIds: const {},
          addedClientIds: {'client-1'},
        ),
        isTrue,
      );
    });

    test('leaves add action enabled for unscheduled clients', () {
      final disabled = shouldDisableClientAddAction(
        clientId: 'client-1',
        scheduledClientIds: const {},
        addingClientIds: const {},
        addedClientIds: const {},
      );

      expect(disabled, isFalse);
    });
  });
}
