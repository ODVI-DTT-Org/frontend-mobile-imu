import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:imu_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';

import '../mocks/mocks.dart';

class MockAuthNotifier extends StateNotifier<AuthState>
    with Mock
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  Future<bool> login(String email, String password) async {
    return Future.value(true);
  }

  void clearError() {}
}

void main() {
  group('LoginPage Widget Tests', () {
    testWidgets('renders login form with email and password fields',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Assert - Check for key UI elements
      expect(find.text('Itinerary Manager - Uniformed'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act - Tap login without entering email
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act - Enter invalid email
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'invalidemail');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows validation error for empty password',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act - Enter valid email but no password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows validation error for short password',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act - Enter valid email but short password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'short');
      await tester.tap(find.text('LOGIN'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('shows offline banner when offline', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Assert
      expect(
          find.text('You are offline. Login requires internet connection.'),
          findsOneWidget);
    });

    testWidgets('login button is disabled when offline',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Act
      final loginButton = find.widgetWithText(ElevatedButton, 'LOGIN');

      // Assert
      final ElevatedButton button = tester.widget(loginButton);
      expect(button.enabled, isFalse);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: false),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Find password field
      final passwordField = find.widgetWithText(TextField, 'Password');
      TextField textField = tester.widget(passwordField);
      expect(textField.obscureText, isTrue);

      // Tap visibility toggle
      // FIXED: LoginPage uses LucideIcons.eyeOff, not Icons.visibility_off_outlined
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Assert - Password should now be visible
      textField = tester.widget(passwordField);
      expect(textField.obscureText, isFalse);
    });

    testWidgets('shows loading indicator when loading',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith((ref) => MockAuthNotifier(
                  const AuthState(isAuthenticated: false, isLoading: true),
                )),
            isOnlineProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
