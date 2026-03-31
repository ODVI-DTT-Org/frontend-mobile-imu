import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/auth_coordinator.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_providers.dart';

/// Provider for the AuthCoordinator singleton.
///
/// This provider exposes the AuthCoordinator instance to the Flutter app
/// through Riverpod's dependency injection system.
///
/// The coordinator is initialized with the auth repository to enable
/// login functionality.
///
/// Example usage:
/// ```dart
/// class LoginPage extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final coordinator = ref.watch(authCoordinatorProvider);
///     final authState = ref.watch(authStateProvider);
///     // ...
///   }
/// }
/// ```
final authCoordinatorProvider = ChangeNotifierProvider<AuthCoordinator>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final coordinator = AuthCoordinator();

  // Initialize the coordinator with the auth repository
  coordinator.initialize(authRepository);

  // Note: We don't dispose the coordinator since it's a singleton
  // The coordinator manages its own resources and should be disposed
  // when the app terminates, not when the provider is disposed

  return coordinator;
});

/// Stream provider that emits state change events.
///
/// This provider allows widgets and services to react to authentication
/// state changes in real-time.
///
/// Example usage:
/// ```dart
/// class StateListenerWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final stateChanges = ref.watch(authStateChangeProvider);
///
///     return stateChanges.when(
///       data: (event) => Text('State: ${event.toState}'),
///       loading: () => CircularProgressIndicator(),
///       error: (err, stack) => Text('Error: $err'),
///     );
///   }
/// }
/// ```
final authStateChangeProvider = StreamProvider<StateChangeEvent>((ref) {
  final coordinator = ref.watch(authCoordinatorProvider);
  return coordinator.stateChangeStream;
});

/// Provider for the current authentication state.
///
/// This provider automatically updates whenever the AuthCoordinator's
/// current state changes, ensuring UI always reflects the latest state.
///
/// Example usage:
/// ```dart
/// class AuthAwareWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final authState = ref.watch(authStateProvider);
///
///     return authState.type == AuthStateType.authenticated
///         ? HomeScreen()
///         : LoginScreen();
///   }
/// }
/// ```
final authStateProvider = Provider<AuthState>((ref) {
  // Watch the ChangeNotifierProvider to get state updates
  final coordinator = ref.watch(authCoordinatorProvider);
  return coordinator.currentState;
});

/// Provider for the current authentication state type.
///
/// This is a convenience provider that provides direct access to the
/// state type enum value, useful for simple state checking.
///
/// Example usage:
/// ```dart
/// class MyWidget extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final stateType = ref.watch(authStateTypeProvider);
///
///     return switch (stateType) {
///       AuthStateType.authenticated => HomeScreen(),
///       AuthStateType.notAuthenticated => LoginScreen(),
///       AuthStateType.pinEntry => PinEntryScreen(),
///       _ => LoadingScreen(),
///     };
///   }
/// }
/// ```
final authStateTypeProvider = Provider<AuthStateType>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.type;
});
