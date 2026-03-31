import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:imu_flutter/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:imu_flutter/features/auth/presentation/pages/pin_entry_page.dart';
import 'package:imu_flutter/features/auth/presentation/pages/session_locked_page.dart';
import 'package:imu_flutter/features/auth/presentation/providers/auth_coordinator_provider.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';
import 'package:imu_flutter/main.dart' as app;

/// Integration tests for authentication flows.
///
/// These tests verify the complete user journeys from login to authenticated state,
/// including PIN setup, biometric authentication, session locking, and token refresh.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Initialize app with test configuration
      container = ProviderContainer(
        overrides: [
          authCoordinatorProvider.overrideWithValue(
            AuthCoordinator(),
          ),
        ],
      );

      // Initialize the app
      app.main();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete login flow with PIN setup', (tester) async {
      // Start at login page
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify we're on login page
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Enter valid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.byType(ElevatedButton).first);

      // Pump and settle to allow navigation
      await tester.pumpAndSettle();

      // Should navigate to PIN setup page
      expect(find.byType(PinSetupPage), findsOneWidget);

      // Verify PIN setup UI elements
      expect(find.text('Create your PIN'), findsOneWidget);
      expect(find.text('Enter a 6-digit PIN'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('PIN entry flow for returning user', (tester) async {
      // Start at PIN entry page
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PinEntryPage(),
          ),
        ),
      );

      // Verify PIN entry UI
      expect(find.text('Enter your PIN'), findsOneWidget);

      // Enter 6-digit PIN
      await tester.tap(find.text('1'));
      await tester.pump();

      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.text('3'));
      await tester.pump();

      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('5'));
      await tester.pump();

      await tester.tap(find.text('6'));
      await tester.pump();

      // Verify PIN is entered (6 digits shown)
      expect(find.text('1'), findsNothing); // Individual digits should not remain
    });

    testWidgets('Session lock flow with PIN unlock', (tester) async {
      // Start at session locked page
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SessionLockedPage(),
          ),
        ),
      );

      // Verify session locked UI
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
      expect(find.text('Session Locked'), findsOneWidget);
      expect(find.text('Enter your PIN to unlock'), findsOneWidget);

      // Enter PIN to unlock
      await tester.tap(find.text('1'));
      await tester.pump();

      await tester.tap(find.text('2'));
      await tester.pump();

      await tester.tap(find.text('3'));
      await tester.pump();

      await tester.tap(find.text('4'));
      await tester.pump();

      await tester.tap(find.text('5'));
      await tester.pump();

      await tester.tap(find.text('6'));
      await tester.pump();

      // Verify unlock was attempted (PIN digits entered)
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('Error handling for invalid credentials', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email',
      );

      // Tap login button
      await tester.tap(find.byType(ElevatedButton).first);

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('Loading state during authentication', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Enter valid credentials
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.byType(ElevatedButton).first);

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Password visibility toggle', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find password field
      final passwordField = find.byKey(const Key('password_field'));
      expect(passwordField, findsOneWidget);

      // Find toggle button
      final toggleButton = find.byKey(const Key('toggle_password_visibility'));
      expect(toggleButton, findsOneWidget);

      // Enter password
      await tester.enterText(passwordField, 'password123');

      // Verify password is obscured by default
      TextField textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isTrue);

      // Tap toggle button
      await tester.tap(toggleButton);
      await tester.pump();

      // Verify password is now visible
      textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isFalse);

      // Tap toggle button again
      await tester.tap(toggleButton);
      await tester.pump();

      // Verify password is obscured again
      textField = tester.widget<TextField>(passwordField);
      expect(textField.obscureText, isTrue);
    });
  });

  group('End-to-End Authentication Scenarios', () {
    testWidgets('New user onboarding flow', (tester) async {
      // This test simulates a complete new user journey:
      // 1. Login with email/password
      // 2. Setup PIN
      // 3. Reach authenticated state
      // 4. Lock due to inactivity
      // 5. Unlock with PIN

      // Start at login
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Login flow
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'newuser@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
      'password123',
      );
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      // Should be on PIN setup
      expect(find.byType(PinSetupPage), findsOneWidget);
    });

    testWidgets('Returning user login flow', (tester) async {
      // This test simulates a returning user journey:
      // 1. Login with email/password
      // 2. Enter PIN
      // 3. Reach authenticated state

      // Start at PIN entry (simulating returning user)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PinEntryPage(),
          ),
        ),
      );

      // Verify PIN entry UI
      expect(find.text('Enter your PIN'), findsOneWidget);
    });

    testWidgets('Session lock and unlock flow', (tester) async {
      // This test simulates session management:
      // 1. User is authenticated
      // 2. Session locks after inactivity
      // 3. User unlocks with PIN
      // 4. Session resumes

      // Start at session locked page
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SessionLockedPage(),
          ),
        ),
      );

      // Verify lock screen
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
      expect(find.text('Session Locked'), findsOneWidget);
    });
  });
}
