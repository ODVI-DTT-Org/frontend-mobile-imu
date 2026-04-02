// New authentication router using state machine architecture.
//
// This router will be integrated with the main router in Phase 9 (Cleanup & Removal).
// Currently provides routing for the new state machine-based auth pages.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
// TEMPORARILY DISABLED: PIN setup/entry functionality
// import '../../features/auth/presentation/pages/pin_setup_page.dart';
// import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/auth/presentation/pages/session_locked_page.dart';
import '../../features/auth/presentation/pages/token_expired_page.dart';
import '../../features/auth/presentation/pages/offline_auth_page.dart';
import '../../features/auth/presentation/providers/auth_coordinator_provider.dart';
import '../../features/auth/domain/entities/auth_state.dart';

/// State-based redirect logic for the new authentication state machine.
///
/// This function will be integrated into the main router's redirect logic
/// when the new auth system is fully implemented (Phase 9).
String? newAuthStateRedirect(
  WidgetRef ref,
  GoRouterState state, {
  bool useNewAuthSystem = false, // Feature flag for gradual rollout
}) {
  // If new auth system is not enabled, use old routing
  if (!useNewAuthSystem) {
    return null;
  }

  final authStateType = ref.watch(authStateTypeProvider);
  final currentLocation = state.matchedLocation;

  // Define auth routes (new system)
  const authRoutes = {
    '/login',
    // TEMPORARILY DISABLED: PIN setup/entry functionality
    // '/pin-setup',
    // '/pin-entry',
    '/session-locked',
    '/token-expired',
    '/offline-auth',
  };

  final isAuthRoute = authRoutes.any((route) => currentLocation.startsWith(route));

  // State-based routing rules
  switch (authStateType) {
    case AuthStateType.notAuthenticated:
      if (!currentLocation.startsWith('/login')) {
        return '/login';
      }
      break;

    case AuthStateType.loggingIn:
      // Stay on current page (loading overlay handles it)
      break;

    case AuthStateType.refreshingToken:
      // Stay on current page (silent refresh in background)
      break;

    // TEMPORARILY DISABLED: PIN setup/entry functionality
    case AuthStateType.checkPinSetup:
      // Internal state, no route
      break;
    //
    // case AuthStateType.pinSetup:
    //   if (currentLocation != '/pin-setup') {
    //     return '/pin-setup';
    //   }
    //   break;
    //
    case AuthStateType.pinSetup:
    //   if (currentLocation != '/pin-setup') {
    //     return '/pin-setup';
    //   }
    //   break;

    case AuthStateType.authenticated:
      // If on auth page, redirect to home
      if (isAuthRoute) {
        return '/home';
      }
      break;

    // TEMPORARILY DISABLED: PIN setup/entry functionality
    // case AuthStateType.pinEntry:
    //   if (currentLocation != '/pin-entry') {
    //     return '/pin-entry';
    //   }
    //   break;

    case AuthStateType.pinEntry:
    //   if (currentLocation != '/pin-entry') {
    //     return '/pin-entry';
    //   }
    //   break;

    case AuthStateType.tokenRefreshFailed:
      // Stay on current page, show error snackbar
      break;

    case AuthStateType.tokenExpired:
      if (currentLocation != '/token-expired') {
        return '/token-expired';
      }
      break;

    case AuthStateType.sessionLocked:
      if (currentLocation != '/session-locked') {
        return '/session-locked';
      }
      break;

    case AuthStateType.offlineAuth:
      // Stay on current page, show offline banner
      break;

    case AuthStateType.error:
      // Stay on current page, show error snackbar
      break;
  }

  return null; // No redirect
}

/// Routes for the new authentication state machine pages.
///
/// These will be merged into the main router in Phase 9.
final newAuthRoutes = [
  // Auth routes (new state machine)
  GoRoute(
    path: '/login',
    builder: (context, state) => const LoginPage(),
  ),
  // TEMPORARILY DISABLED: PIN setup/entry functionality
  // GoRoute(
  //   path: '/pin-setup',
  //   builder: (context, state) => const PinSetupPage(),
  // ),
  // GoRoute(
  //   path: '/pin-entry',
  //   builder: (context, state) => const PinEntryPage(),
  // ),
  GoRoute(
    path: '/session-locked',
    builder: (context, state) => const SessionLockedPage(),
  ),
  GoRoute(
    path: '/token-expired',
    builder: (context, state) => const TokenExpiredPage(),
  ),
  GoRoute(
    path: '/offline-auth',
    builder: (context, state) => const OfflineAuthPage(),
  ),
];
