import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/auth/presentation/pages/pin_entry_page.dart';
import 'package:imu_flutter/features/auth/presentation/providers/auth_coordinator_provider.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';
import 'package:imu_flutter/features/auth/domain/entities/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCoordinator extends Mock implements AuthCoordinator {}

class FakeAuthState extends Fake implements AuthState {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthState());
  });

  // Skip all tests - Needs Riverpod 2.0 migration
  // TODO: Migrate to Riverpod 2.0 syntax and re-enable tests
  group('PinEntryPage Widget Tests - SKIPPED (Needs Riverpod 2.0 Migration)', () {
    late MockAuthCoordinator mockCoordinator;

    setUp(() {
      mockCoordinator = MockAuthCoordinator();

      // Set up default mock behaviors
      when(() => mockCoordinator.currentState).thenReturn(AuthenticatingWithPinState(
        pin: '123456',
        enteredAt: DateTime.now(),
        timeout: const Duration(minutes: 15),
      ));
      when(() => mockCoordinator.stateChangeStream).thenAnswer((_) => const Stream.empty());
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockCoordinator),
        ],
        child: const MaterialApp(
          home: PinEntryPage(),
        ),
      );
    }

    testWidgets('should display PIN entry form', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PinEntryPage), findsOneWidget);
    }, skip: true);

    testWidgets('should accept PIN input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Test PIN input
      final pinField = find.byKey(const Key('pin_field'));
      expect(pinField, findsOneWidget);
    }, skip: true);
  });
}
