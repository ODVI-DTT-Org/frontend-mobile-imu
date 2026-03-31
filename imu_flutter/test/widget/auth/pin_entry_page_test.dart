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

  group('PinEntryPage Widget Tests', () {
    late MockAuthCoordinator mockCoordinator;

    setUp(() {
      mockCoordinator = MockAuthCoordinator();

      // Set up default mock behaviors
      when(() => mockCoordinator.currentState).thenReturn(
        PinEntryState(userId: 'user-123', remainingAttempts: 5),
      );
      when(() => mockCoordinator.stateChangeStream).thenAnswer((_) => const Stream.empty());
      when(() => mockCoordinator.transitionTo(any())).thenAnswer((_) async {});
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

    testWidgets('should display PIN entry page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(PinEntryPage), findsOneWidget);
      expect(find.text('Enter PIN'), findsOneWidget);
    });

    testWidgets('should have show/hide PIN toggle button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const Key('toggle_pin_visibility')), findsOneWidget);
    });

    testWidgets('should have backspace button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const Key('backspace_button')), findsOneWidget);
    });

    testWidgets('should have digit buttons 0-9', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      for (int i = 0; i <= 9; i++) {
        expect(find.byKey(Key('digit_$i')), findsOneWidget);
      }
    });

    testWidgets('should have forgot PIN button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byKey(const Key('forgot_pin_button')), findsOneWidget);
    });
  });
}
