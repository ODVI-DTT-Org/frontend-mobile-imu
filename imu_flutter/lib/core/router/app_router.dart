import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
// PIN SETUP/ENTRY DISABLED - Commenting out to focus on core authentication
// import '../../features/auth/presentation/pages/pin_setup_page.dart';
// import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/auth/presentation/pages/permission_request_page.dart';
import '../../features/sync/presentation/pages/sync_loading_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/agencies/presentation/pages/add_prospect_agency_page.dart';
import '../../features/agencies/presentation/pages/agency_detail_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/itineraries/presentation/pages/itinerary_detail_page.dart';
import '../../features/clients/presentation/widgets/edit_client_form_v2.dart';
import '../../features/clients/presentation/pages/add_client_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_page.dart';
import '../../features/my_day/presentation/pages/my_day_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/debug/presentation/pages/debug_dashboard_page.dart';
import '../../features/targets/presentation/pages/targets_page.dart';
import '../../features/visits/presentation/pages/missed_visits_page.dart';
import '../../features/calculator/presentation/pages/loan_calculator_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/record_forms/presentation/widgets/record_touchpoint_form.dart';
import '../../features/record_forms/presentation/widgets/record_visit_only_form.dart';
import '../../features/record_forms/presentation/widgets/release_loan_form.dart';
import '../../shared/widgets/main_shell.dart';
import '../../shared/providers/app_providers.dart' show authNotifierProvider, clientByIdProvider;
import '../../services/auth/auth_service.dart' show AuthState;
// import '../../services/auth/secure_storage_service.dart'; // PIN functionality disabled

// Auth state provider - watches full AuthState (including isLoading)
// This is critical for token persistence - router must wait for initialization to complete
final authStateProvider = Provider<AuthState>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState;
});

// PIN FUNCTIONALITY DISABLED - Commenting out to focus on core authentication
// // PIN state notifier
// class PinStateNotifier extends StateNotifier<AsyncValue<bool>> {
//   final SecureStorageService _secureStorage;
//
//   PinStateNotifier(this._secureStorage) : super(const AsyncValue.loading()) {
//     // Check PIN status on initialization (independent of auth state)
//     checkPinStatus();
//   }
//
//   Future<void> checkPinStatus() async {
//     state = const AsyncValue.loading();
//     try {
//       final hasPin = await _secureStorage.hasPin();
//       state = AsyncValue.data(hasPin);
//     } catch (e, st) {
//       state = AsyncValue.error(e, st);
//     }
//   }
//
//   void setHasPin(bool value) {
//     state = AsyncValue.data(value);
//   }
// }
//
// // Has PIN provider - uses StateNotifier for refreshable state
// // Checks PIN status on initialization and when auth state changes
// final pinStateProvider = StateNotifierProvider<PinStateNotifier, AsyncValue<bool>>((ref) {
//   final notifier = PinStateNotifier(SecureStorageService());
//
//   // Refresh PIN status when auth state changes (for logout scenarios)
//   ref.listen(authStateProvider, (previous, next) {
//     if (previous != next) {
//       notifier.checkPinStatus();
//     }
//   });
//
//   return notifier;
// });
//
// // Legacy provider for backwards compatibility
// final hasPinProvider = Provider<AsyncValue<bool>>((ref) {
//   return ref.watch(pinStateProvider);
// });

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isAuth = authState.isAuthenticated;
  final isLoading = authState.isLoading;

  // PIN FUNCTIONALITY DISABLED - Focus on core JWT authentication
  // final hasPin = ref.watch(hasPinProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      debugPrint('[ROUTER] redirect called: location=${state.matchedLocation}, isLoading=$isLoading, isAuthenticated=$isAuth');

      // CRITICAL: Wait for auth initialization to complete before redirecting
      // This fixes the token persistence bug where router redirects to /login
      // before checkAuthStatus() completes loading tokens from storage
      if (isLoading) {
        debugPrint('[ROUTER] Waiting for initialization (isLoading=true)');
        return null; // Still initializing - wait for completion
      }

      debugPrint('[ROUTER] Initialization complete, isLoading=$isLoading, isAuthenticated=$isAuth');

      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          // PIN SETUP/ENTRY DISABLED
          // state.matchedLocation.startsWith('/pin-setup') ||
          // state.matchedLocation.startsWith('/pin-entry') ||
          state.matchedLocation.startsWith('/permissions');

      // PIN FUNCTIONALITY DISABLED - Skip PIN status check
      // // Wait for PIN status to load before making routing decisions
      // if (!hasPin.hasValue) {
      //   return null; // Still loading PIN status
      // }

      // NOT AUTHENTICATED FLOW
      if (!isAuth) {
        // Trying to access protected route -> go to login
        if (!isAuthRoute) {
          debugPrint('[ROUTER] Not authenticated, redirecting to /login');
          return '/login';
        }
        // Let user stay on auth routes (forgot-password, login)
        debugPrint('[ROUTER] On auth route, staying put');
        return null;
      }

      // AUTHENTICATED FLOW
      // Don't redirect away from permissions page - user needs to grant permissions first
      if (state.matchedLocation.startsWith('/permissions')) {
        return null;
      }

      // PIN SETUP DISABLED - Skip PIN setup flow, go directly to sync loading
      // // Authenticated user without PIN needs to go through setup flow
      // if (hasPin.value == false) {
      //   // User just logged in (on login page) -> go to permissions first
      //   if (state.matchedLocation.startsWith('/login')) {
      //     return '/permissions';
      //   }
      //   // User is on other auth routes, let them stay
      //   if (state.matchedLocation.startsWith('/pin-setup') ||
      //       state.matchedLocation.startsWith('/pin-entry') ||
      //       state.matchedLocation.startsWith('/forgot-password')) {
      //     return null;
      //   }
      //   // User trying to access protected route without PIN -> go to pin setup
      //   return '/pin-setup';
      // }

      // Authenticated and on auth route -> go to sync loading or home
      if (isAuthRoute) {
        // If user just successfully logged in on /login page, go to sync loading
        if (state.matchedLocation.startsWith('/login')) {
          return '/sync-loading';
        }
        // PIN ENTRY DISABLED - Go directly to sync loading instead of PIN entry
        // return '/pin-entry';
        return '/sync-loading';
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
      // PIN SETUP/ENTRY DISABLED - Commenting out to focus on core authentication
      // GoRoute(
      //   path: '/pin-setup',
      //   builder: (context, state) => const PinSetupPage(),
      // ),
      // GoRoute(
      //   path: '/pin-entry',
      //   builder: (context, state) => const PinEntryPage(),
      // ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionRequestPage(),
      ),
      GoRoute(
        path: '/sync-loading',
        builder: (context, state) => const SyncLoadingPage(),
      ),

      // Main app shell with bottom navigation (5 tabs: Home, My Day, Itinerary, Clients, Profile)
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
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/clients/add',
        builder: (context, state) => const AddClientPage(),
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
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Edit Client'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Client',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Client'),
                        content: const Text('Are you sure you want to delete this client?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      // Handle delete - you may want to add a callback or navigate
                      context.pop();
                    }
                  },
                ),
              ],
            ),
            body: EditClientFormV2(
              clientId: clientId,
              onSave: (savedClient) {
                // Return to client detail after saving
                context.pop();
                return true;
              },
            ),
          );
        },
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

      // Record forms routes
      GoRoute(
        path: '/record-touchpoint/:clientId',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return RecordTouchpointFormLoader(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/record-visit-only/:clientId',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return RecordVisitOnlyFormLoader(clientId: clientId);
        },
      ),
      GoRoute(
        path: '/release-loan/:clientId',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return ReleaseLoanFormLoader(clientId: clientId);
        },
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

// Form loaders for deep linking
class RecordTouchpointFormLoader extends ConsumerWidget {
  final String clientId;

  const RecordTouchpointFormLoader({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    return clientAsync.when(
      data: (client) => RecordTouchpointForm(client: client),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading client: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/clients'),
                child: const Text('Back to Clients'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecordVisitOnlyFormLoader extends ConsumerWidget {
  final String clientId;

  const RecordVisitOnlyFormLoader({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    return clientAsync.when(
      data: (client) => RecordVisitOnlyForm(client: client),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading client: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/clients'),
                child: const Text('Back to Clients'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReleaseLoanFormLoader extends ConsumerWidget {
  final String clientId;

  const ReleaseLoanFormLoader({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientByIdProvider(clientId));
    return clientAsync.when(
      data: (client) => ReleaseLoanForm(client: client),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading client: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/clients'),
                child: const Text('Back to Clients'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
