import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:imu_flutter/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:imu_flutter/features/auth/presentation/providers/auth_coordinator_provider.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage Widget Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          authCoordinatorProvider.overrideWithValue(
            AuthCoordinator(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('should render login form with email and password fields', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify email field exists
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('Email'), findsOneWidget);

      // Verify password field exists
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);

      // Verify login button
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('should validate email format', (tester) async {
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

      // Should show error message
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('should show loading state during login', (tester) async {
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

    testWidgets('should navigate to PIN entry on successful login', (tester) async {
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

      // Pump and settle to allow navigation
      await tester.pumpAndSettle();

      // Should navigate to PIN setup or entry
      expect(find.byType(PinSetupPage), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Enter password
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Find the toggle button
      final toggleButton = find.byKey(const Key('toggle_password_visibility'));

      // Initially password should be obscured
      TextField passwordField = tester.widget<TextField>(
        find.byKey(const Key('password_field')),
      );
      expect(passwordField.obscureText, isTrue);

      // Tap toggle button to show password
      await tester.tap(toggleButton);
      await tester.pump();

      passwordField = tester.widget<TextField>(
        find.byKey(const Key('password_field')),
      );
      expect(passwordField.obscureText, isFalse);

      // Tap toggle button to hide password
      await tester.tap(toggleButton);
      await tester.pump();

      passwordField = tester.widget<TextField>(
        find.byKey(const Key('password_field')),
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('should show forgot password button', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Verify forgot password button exists
      expect(find.text('Forgot Password?'), findsOneWidget);
    });
  });
}
