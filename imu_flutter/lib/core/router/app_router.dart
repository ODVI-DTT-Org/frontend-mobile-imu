import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/pin_entry_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/clients/presentation/pages/clients_page.dart';
import '../../features/clients/presentation/pages/client_detail_page.dart';
import '../../features/clients/presentation/pages/add_prospect_client_page.dart';
import '../../features/clients/presentation/pages/edit_client_page.dart';
import '../../features/itinerary/presentation/pages/itinerary_page.dart';
import '../../features/my_day/presentation/pages/my_day_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/debug/presentation/pages/debug_dashboard_page.dart';
import '../../features/targets/presentation/pages/targets_page.dart';
import '../../features/visits/presentation/pages/missed_visits_page.dart';
import '../../shared/widgets/main_shell.dart';

// Auth state provider
final authStateProvider = StateProvider<bool>((ref) => true); // TODO: Set back to false for production

// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home', // TODO: Set back to '/login' for production
    redirect: (context, state) {
      final isAuth = isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/pin-setup') ||
          state.matchedLocation.startsWith('/pin-entry');

      if (!isAuth && !isAuthRoute) {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
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

      // Main app shell with bottom navigation
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
