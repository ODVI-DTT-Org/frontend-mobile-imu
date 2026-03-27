import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/auth/presentation/pages/permission_request_page.dart';
import '../../features/sync/presentation/pages/sync_loading_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/agencies/presentation/pages/add_prospect_agency_page.dart';
import '../../features/agencies/presentation/pages/agency_detail_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/itineraries/presentation/pages/itinerary_detail_page.dart';
import '../../features/clients/presentation/pages/edit_client_page.dart';
import '../../features/clients/presentation/pages/add_prospect_client_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_page.dart';
import '../../features/my_day/presentation/pages/my_day_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/debug/presentation/pages/debug_dashboard_page.dart';
import '../../features/targets/presentation/pages/targets_page.dart';
import '../../features/visits/presentation/pages/missed_visits_page.dart';
import '../../features/calculator/presentation/pages/loan_calculator_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/secure_storage_service.dart';

// Auth state provider - derives from AuthNotifier
final authStateProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

// PIN state notifier
class PinStateNotifier extends StateNotifier<AsyncValue<bool>> {
  final SecureStorageService _secureStorage;

  PinStateNotifier(this._secureStorage) : super(const AsyncValue.loading()) {
    // Check PIN status on initialization (independent of auth state)
    checkPinStatus();
  }

  Future<void> checkPinStatus() async {
    state = const AsyncValue.loading();
    try {
      final hasPin = await _secureStorage.hasPin();
      state = AsyncValue.data(hasPin);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setHasPin(bool value) {
    state = AsyncValue.data(value);
  }
}

// Has PIN provider - uses StateNotifier for refreshable state
// Checks PIN status on initialization and when auth state changes
final pinStateProvider = StateNotifierProvider<PinStateNotifier, AsyncValue<bool>>((ref) {
  final notifier = PinStateNotifier(SecureStorageService());

  // Refresh PIN status when auth state changes (for logout scenarios)
  ref.listen(authStateProvider, (previous, next) {
    if (previous != next) {
      notifier.checkPinStatus();
    }
  });

  return notifier;
});

// Legacy provider for backwards compatibility
final hasPinProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(pinStateProvider);
});

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authStateProvider);
  final hasPin = ref.watch(hasPinProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/pin-setup') ||
          state.matchedLocation.startsWith('/pin-entry') ||
          state.matchedLocation.startsWith('/permissions');

      // Wait for PIN status to load before making routing decisions
      if (!hasPin.hasValue) {
        return null; // Still loading PIN status
      }

      // NOT AUTHENTICATED FLOW
      if (!isAuth) {
        // Trying to access protected route -> determine login method
        if (!isAuthRoute) {
          // If PIN exists, go to PIN entry for quick login
          if (hasPin.value == true) {
            return '/pin-entry';
          }
          // Otherwise go to email/password login
          return '/login';
        }

        // On login page but PIN exists -> allow staying on login page if user chose "Use password instead"
        // Check for query parameter that indicates user wants to use password
        final usePassword = state.uri.queryParameters['use_password'] == 'true';
        if (state.matchedLocation.startsWith('/login') && hasPin.value == true && !usePassword) {
          return '/pin-entry';
        }

        // Let user stay on other auth routes (forgot-password, pin-entry, pin-setup)
        return null;
      }

      // AUTHENTICATED FLOW
      // Don't redirect away from permissions page - user needs to grant permissions first
      if (state.matchedLocation.startsWith('/permissions')) {
        return null;
      }

      // Authenticated user without PIN needs to go through setup flow
      if (hasPin.value == false) {
        // User just logged in (on login page) -> go to permissions first
        if (state.matchedLocation.startsWith('/login')) {
          return '/permissions';
        }
        // User is on other auth routes, let them stay
        if (state.matchedLocation.startsWith('/pin-setup') ||
            state.matchedLocation.startsWith('/pin-entry') ||
            state.matchedLocation.startsWith('/forgot-password')) {
          return null;
        }
        // User trying to access protected route without PIN -> go to pin setup
        return '/pin-setup';
      }

      // Authenticated and on auth route (with PIN) -> go to sync loading, PIN entry, or home
      // Note: We don't redirect away from /pin-entry - user needs to verify their PIN
      if (isAuthRoute && !state.matchedLocation.startsWith('/pin')) {
        // If user just successfully logged in on /login page, go to sync loading
        // Otherwise (fresh app start), go to PIN entry for quick login
        if (state.matchedLocation.startsWith('/login')) {
          return '/sync-loading';
        }
        return '/pin-entry';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupPage(),
      ),
      GoRoute(
        path: '/pin-entry',
        builder: (context, state) => const PinEntryPage(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionRequestPage(),
      ),
      GoRoute(
        path: '/sync-loading',
        builder: (context, state) => const SyncLoadingPage(),
      ),

      // Main app shell with bottom navigation (4 tabs: Home, My Day, Itinerary, Clients)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/my-day',
            builder: (context, state) => const MyDayPage(),
          ),
          GoRoute(
            path: '/itinerary',
            builder: (context, state) => const ItineraryPage(),
          ),
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/clients/:id',
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          return ClientDetailPage(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/clients/:id/edit',
        builder: (context, state) {
          final clientId = state.pathParameters['id']!;
          return EditClientPage(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/clients/add',
        builder: (context, state) => const AddProspectClientPage(),
      ),

      // Agency routes
      GoRoute(
        path: '/agencies/add',
        builder: (context, state) => const AddProspectAgencyPage(),
      ),
      GoRoute(
        path: '/agencies/:id',
        builder: (context, state) {
          final agencyId = state.pathParameters['id']!;
          return AgencyDetailPage(agencyId: agencyId);
        },
      ),

      // Group routes
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) {
          final groupId = state.pathParameters['id']!;
          return GroupDetailPage(groupId: groupId);
        },
      ),

      // Itinerary routes
      GoRoute(
        path: '/itineraries/:id',
        builder: (context, state) {
          final itineraryId = state.pathParameters['id']!;
          return ItineraryDetailPage(itineraryId: itineraryId);
        },
      ),

      // Settings route
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Profile route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Missed visits route
      GoRoute(
        path: '/visits',
        builder: (context, state) => const MissedVisitsPage(),
      ),

      // Targets route
      GoRoute(
        path: '/targets',
        builder: (context, state) => const TargetsPage(),
      ),

      // Calculator route
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const LoanCalculatorPage(),
      ),

      // Attendance route
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendancePage(),
      ),

      // Debug route (development only)
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugDashboardPage(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
});

// 404 Page
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page not found'),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
