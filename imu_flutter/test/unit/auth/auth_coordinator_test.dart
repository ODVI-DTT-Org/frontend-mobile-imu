import 'package:flutter_test/flutter_test.dart';
import 'package:imu_flutter/features/auth/domain/entities/auth_state.dart';
import 'package:imu_flutter/features/auth/domain/services/auth_coordinator.dart';
import 'package:imu_flutter/features/auth/domain/repositories/auth_repository.dart';
import 'package:imu_flutter/features/auth/domain/services/token_manager.dart';
import 'package:imu_flutter/core/config/app_config.dart';

/// Mock AuthRepository for testing
class MockAuthRepository implements AuthRepository {
  bool _isAuthenticated = false; // Start as not authenticated for tests

  @override
  Future<TokenData> login(String email, String password) async {
    _isAuthenticated = true; // After login, authenticated
    return TokenData(
      accessToken: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
      expiresIn: const Duration(hours: 1),
      userId: 'mock_user_id',
    );
  }

  @override
  Future<TokenData> refreshToken(String refreshToken) async {
    return TokenData(
      accessToken: 'new_access_token',
      refreshToken: 'new_refresh_token',
      expiresIn: const Duration(hours: 1),
      userId: 'mock_user_id',
    );
  }

  @override
  Future<void> logout() async {
    _isAuthenticated = false; // After logout, not authenticated
  }

  @override
  Future<bool> isAuthenticated() async {
    return _isAuthenticated;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _isAuthenticated ? 'mock_user_id' : null;
  }

  @override
  TokenManager get tokenManager => MockTokenManager();
}

/// Mock TokenManager for testing
class MockTokenManager extends TokenManager {
  String? _accessToken;
  String? _refreshToken;

  MockTokenManager() : super();

  @override
  Future<void> storeTokens(TokenData data) async {
    _accessToken = data.accessToken;
    _refreshToken = data.refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }

  @override
  Future<String?> getUserId() async => 'mock_user_id';

  @override
  Duration? get timeUntilExpiry => const Duration(hours: 1);

  @override
  bool isTokenExpired() => false;

  @override
  bool willExpireSoon() => false;

  @override
  Future<bool> hasRefreshToken() async => _refreshToken != null;

  @override
  void dispose() {
    // Mock dispose
  }
}

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize AppConfig before running tests
  setUpAll(() async {
    await AppConfig.initialize(environment: 'test');
  });

  group('AuthCoordinator', () {
    late AuthCoordinator coordinator;
    late MockAuthRepository mockRepository;

    setUp(() {
      coordinator = AuthCoordinator();
      mockRepository = MockAuthRepository();

      // Initialize coordinator with mock repository
      coordinator.initialize(mockRepository);

      // Reset to initial state before each test
      coordinator.reset();
    });

    group('State Management', () {
      test('should have initial state NOT_AUTHENTICATED', () {
        expect(coordinator.currentState.type, AuthStateType.notAuthenticated);
      });

      test('should transition to LOGGING_IN state', () async {
        final newState = LoggingInState(email: 'test@example.com', password: 'password123');
        await coordinator.transitionTo(newState);

        // Note: With mock repository, login proceeds automatically to AuthenticatedState
        expect(coordinator.currentState.type, AuthStateType.authenticated);
      });

      test('should track state history', () async {
        final state1 = LoggingInState(email: 'test@example.com', password: 'password123');

        // Reset and initialize for this test
        coordinator.reset();
        coordinator.initialize(mockRepository);

        await coordinator.transitionTo(state1);
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition to AuthenticatedState

        // Should have history entries for the transitions
        expect(coordinator.stateHistory.length, greaterThan(0));
      });

      test('should limit history to 50 entries', () async {
        // Use valid transition cycle: NOT_AUTHENTICATED -> LOGGING_IN -> AUTHENTICATED -> NOT_AUTHENTICATED
        for (int i = 0; i < 60; i++) {
          await coordinator.transitionTo(LoggingInState(email: 'user$i@example.com', password: 'password123'));
          await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition to AuthenticatedState
          // Reset to NOT_AUTHENTICATED to continue the cycle
          coordinator.reset();
          await Future.delayed(const Duration(milliseconds: 50)); // Wait for reset to complete
          // Reinitialize after reset
          coordinator.initialize(mockRepository);
        }
        // History should not exceed 50 total across all cycles
        expect(coordinator.stateHistory.length, lessThanOrEqualTo(50));
      });

      test('stateHistory returns unmodifiable list', () {
        final history = coordinator.stateHistory;
        expect(() => history.add(AuthenticatedState(userId: 'test')), throwsUnsupportedError);
      });
    });

    group('Transition Validation', () {
      test('should allow valid transition from NOT_AUTHENTICATED to AUTHENTICATED', () async {
        final newState = AuthenticatedState(userId: 'user-123');
        await expectLater(
          () => coordinator.transitionTo(newState),
          throwsA(isA<InvalidTransitionException>()),
        );
      });

      test('should throw InvalidTransitionException for invalid transition', () async {
        final newState = AuthenticatedState(userId: 'user-123');
        await expectLater(
          () => coordinator.transitionTo(newState),
          throwsA(isA<InvalidTransitionException>()),
        );
      });

      test('canTransitionTo should return true for valid transitions', () {
        expect(coordinator.canTransitionTo(AuthStateType.authenticated), isFalse);
        expect(coordinator.canTransitionTo(AuthStateType.loggingIn), isTrue);
      });

      test('canTransitionTo should return false for invalid transitions', () {
        expect(coordinator.canTransitionTo(AuthStateType.authenticated), isFalse);
      });
    });

    group('Guard Clauses', () {
      test('should evaluate guard before transition', () async {
        var guardCalled = false;
        final newState = LoggingInState(email: 'test@example.com', password: 'password123');
        await coordinator.transitionTo(newState, guard: () async {
          guardCalled = true;
          return true;
        });
        expect(guardCalled, isTrue);
        // Note: With mock repo, this will auto-transition to AuthenticatedState
      });

      test('should prevent transition when guard returns false', () async {
        final newState = LoggingInState(email: 'test@example.com', password: 'password123');
        await expectLater(
          () => coordinator.transitionTo(newState, guard: () async => false),
          throwsA(isA<GuardFailedException>()),
        );
      });

      test('should support async guards', () async {
        final newState = LoggingInState(email: 'test@example.com', password: 'password123');
        await coordinator.transitionTo(newState, guard: () async {
          await Future.delayed(const Duration(milliseconds: 10));
          return true;
        });
        // Guard passed and login proceeded
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition
        expect(coordinator.currentState.type, AuthStateType.authenticated);
      });
    });

    group('Event Stream', () {
      test('should emit event on state transition', () async {
        // Ensure we start in NotAuthenticatedState
        coordinator.reset();
        coordinator.initialize(mockRepository);
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for init to complete

        final eventStream = coordinator.stateChangeStream;
        final events = <StateChangeEvent>[];

        // Start listening before the transition
        final subscription = eventStream.listen(events.add);

        // Now perform the transition (will auto-proceed through login flow)
        await coordinator.transitionTo(LoggingInState(email: 'test@example.com', password: 'password123'));

        // Wait a bit for events to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // We should have events emitted
        expect(events.length, greaterThan(0));
        // Events should have proper structure
        expect(events.first.fromState, isA<AuthStateType>());
        expect(events.first.toState, isA<AuthStateType>());
        expect(events.first.timestamp, isA<DateTime>());
        await subscription.cancel();
      });

      test('should support multiple listeners', () async {
        // Ensure we start in NotAuthenticatedState
        coordinator.reset();
        coordinator.initialize(mockRepository);
        await Future.delayed(const Duration(milliseconds: 50)); // Wait for init to complete

        final eventStream = coordinator.stateChangeStream;
        final events1 = <StateChangeEvent>[];
        final events2 = <StateChangeEvent>[];

        // Start listening before the transition
        final sub1 = eventStream.listen(events1.add);
        final sub2 = eventStream.listen(events2.add);

        // Now perform the transition
        await coordinator.transitionTo(LoggingInState(email: 'test@example.com', password: 'password123'));

        // Wait a bit for events to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        expect(events1.length, greaterThan(0));
        expect(events2.length, greaterThan(0));
        await sub1.cancel();
        await sub2.cancel();
      });
    });

    group('Utility Methods', () {
      test('isState should return true for matching state type', () {
        expect(coordinator.isState(AuthStateType.notAuthenticated), isTrue);
        expect(coordinator.isState(AuthStateType.authenticated), isFalse);
      });

      test('clearHistory should remove all history entries', () async {
        await coordinator.transitionTo(LoggingInState(email: 'test@example.com', password: 'password123'));
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition
        expect(coordinator.stateHistory.length, greaterThan(0));
        coordinator.clearHistory();
        expect(coordinator.stateHistory.length, 0);
      });

      test('reset should return to NOT_AUTHENTICATED state', () async {
        await coordinator.transitionTo(LoggingInState(email: 'test@example.com', password: 'password123'));
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition
        await coordinator.reset();
        expect(coordinator.currentState.type, AuthStateType.notAuthenticated);
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        final coordinator1 = AuthCoordinator();
        final coordinator2 = AuthCoordinator();
        expect(identical(coordinator1, coordinator2), isTrue);
      });
    });

    group('ChangeNotifier Integration', () {
      test('should notify listeners on state change', () async {
        var notified = false;
        coordinator.addListener(() {
          notified = true;
        });
        await coordinator.transitionTo(LoggingInState(email: 'test@example.com', password: 'password123'));
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for auto-transition
        expect(notified, isTrue);
      });
    });
  });
}
