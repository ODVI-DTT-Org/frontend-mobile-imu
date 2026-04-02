import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:imu_flutter/features/auth/presentation/providers/auth_coordinator_provider.dart';
import 'package:imu_flutter/features/auth/domain/entities/auth_state.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCoordinator extends Mock implements AuthCoordinator {}

// Fake implementation for AuthState fallback
class FakeAuthState extends Fake implements AuthState {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(FakeAuthState());
  });

  // Skip all tests - Needs Riverpod 2.0 migration
  // TODO: Migrate to Riverpod 2.0 syntax and re-enable tests
  group('LoginPage Widget Tests - SKIPPED (Needs Riverpod 2.0 Migration)', () {
    late MockAuthCoordinator mockCoordinator;

    setUp(() {
      mockCoordinator = MockAuthCoordinator();

      // Set up default mock behaviors
      when(() => mockCoordinator.currentState).thenReturn(NotAuthenticatedState());
      when(() => mockCoordinator.stateChangeStream).thenAnswer((_) => const Stream.empty());
      when(() => mockCoordinator.transitionTo(any())).thenAnswer((_) async {});
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          authCoordinatorProvider.overrideWithValue(mockCoordinator),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      );
    }

    testWidgets('should display all required UI elements', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    }, skip: true);

    testWidgets('should call login when button is pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      verify(() => mockCoordinator.transitionTo(any())).called(1);
    }, skip: true);
  });
}
