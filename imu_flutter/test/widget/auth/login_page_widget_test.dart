import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:imu_flutter/features/auth/presentation/pages/pin_setup_page.dart';
import 'package:imu_flutter/features/auth/presentation/providers/auth_coordinator_provider.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Skip all tests - Needs Riverpod 2.0 migration
  // TODO: Migrate to Riverpod 2.0 syntax and re-enable tests
  group('LoginPage Widget Tests - SKIPPED (Needs Riverpod 2.0 Migration)', () {
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

    testWidgets('should render login form', (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: LoginPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    }, skip: true);
  });
}
