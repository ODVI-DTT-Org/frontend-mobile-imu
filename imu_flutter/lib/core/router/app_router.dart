import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/auth/presentation/pages/permission_request_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/agencies/presentation/pages/add_prospect_agency_page.dart';
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
import '../../features/agencies/presentation/pages/agencies_page.dart';
import '../../features/call_log/presentation/pages/call_log_page.dart';
import '../../shared/widgets/main_shell.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/secure_storage_service.dart';

// Auth state provider - derives from AuthNotifier
final authStateProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

// Has PIN provider - check secure storage
final hasPinProvider = FutureProvider<bool>((ref) async {
  final secureStorage = SecureStorageService();
  return await secureStorage.hasPin();
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

      // Not authenticated and trying to access protected route -> go to login
      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      // Authenticated but haven't set up PIN yet -> go to PIN setup (unless on permissions page)
      if (isAuth && !hasPin.hasValue) {
        // Still loading, stay on current route
        return null;
      }

      // Don't redirect away from permissions page - user needs to grant permissions first
      if (isAuth && state.matchedLocation.startsWith('/permissions')) {
        return null;
      }

      if (isAuth && hasPin.hasValue && !hasPin.value! &&
          !state.matchedLocation.startsWith('/pin-setup') &&
          !state.matchedLocation.startsWith('/permissions')) {
        return '/pin-setup';
      }

      // Authenticated and has PIN, but on PIN entry route -> go to home
      if (isAuth && hasPin.hasValue && hasPin.value! && state.matchedLocation == '/pin-entry') {
        return '/home';
      }

      // Authenticated and on auth route -> go to PIN entry or home
      if (isAuth && isAuthRoute && !state.matchedLocation.startsWith('/pin')) {
        // If has PIN, go to PIN entry, otherwise home
        if (hasPin.hasValue && hasPin.value!) {
          return '/pin-entry';
        }
        return '/home';
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

      // Main app shell with bottom navigation (5 tabs: Home, Agencies, My Day, Itinerary, Call)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/agencies',
            builder: (context, state) => const AgenciesPage(),
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
            path: '/call-log',
            builder: (context, state) => const CallLogPage(),
          ),
        ],
      ),

      // Client routes (no bottom nav)
      GoRoute(
        path: '/clients',
        builder: (context, state) => const ClientsPage(),
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
