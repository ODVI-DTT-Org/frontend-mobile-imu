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

  group('LoginPage Widget Tests', () {
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
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('should validate empty email', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('should validate invalid email format', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'invalid-email');
      
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should validate empty password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'user@example.com');
      
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should validate short password', (tester) async {
      await tester.pumpWidget(createTestWidget());
      
      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'user@example.com');
      
      final passwordField = find.byKey(const Key('password_field'));
      await tester.enterText(passwordField, '12345');
      
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should transition to LoggingInState on valid submit', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'user@example.com');

      final passwordField = find.byKey(const Key('password_field'));
      await tester.enterText(passwordField, 'password123');

      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pump(); // Trigger the build

      verify(() => mockCoordinator.transitionTo(any())).called(1);
    });

    testWidgets('should show loading overlay when in LOGGING_IN state', (tester) async {
      when(() => mockCoordinator.currentState).thenReturn(LoggingInState(email: 'test@example.com'));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Trigger the build without settling

      expect(find.text('Signing in...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error on transition failure', (tester) async {
      when(() => mockCoordinator.transitionTo(any())).thenThrow(Exception('Network error'));

      await tester.pumpWidget(createTestWidget());
      
      final emailField = find.byKey(const Key('email_field'));
      await tester.enterText(emailField, 'user@example.com');
      
      final passwordField = find.byKey(const Key('password_field'));
      await tester.enterText(passwordField, 'password123');
      
      final loginButton = find.byKey(const Key('login_button'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('An error occurred'), findsOneWidget);
    });

    testWidgets('should show snackbar when forgot password tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final forgotButton = find.byKey(const Key('forgot_password_button'));
      await tester.tap(forgotButton);

      await tester.pumpAndSettle();

      expect(find.text('Forgot password feature coming soon'), findsOneWidget);
    });
  });
}
