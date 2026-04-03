import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/quick_actions/quick_actions_service.dart';
import 'services/auth/session_service.dart';
import 'shared/widgets/loading_widget.dart';
import 'shared/providers/app_providers.dart';
import 'shared/utils/loading_helper.dart';

class IMUApp extends ConsumerStatefulWidget {
  const IMUApp({super.key});

  @override
  ConsumerState<IMUApp> createState() => _IMUAppState();
}

class _IMUAppState extends ConsumerState<IMUApp> with WidgetsBindingObserver {
  final QuickActionsService _quickActionsService = QuickActionsService();
  final SessionService _sessionService = SessionService();
  BackgroundSyncService? _backgroundSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuickActions();
    _startSessionMonitoring();
    _initializeBackgroundSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Initialize background sync service
  void _initializeBackgroundSync() {
    // Get the background sync service and initialize it
    _backgroundSyncService = ref.read(backgroundSyncServiceProvider);

    // Initialize the service (starts timers and listeners)
    // Run silently in background without blocking UI
    Future.microtask(() async {
      try {
        await _backgroundSyncService!.initialize();
        debugPrint('IMUApp: Background sync service initialized');
      } catch (e) {
        debugPrint('IMUApp: Failed to initialize background sync: $e');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    // Notify background sync service
    _backgroundSyncService?.handleAppLifecycleChange(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - check if session is locked
        _checkSessionStatus();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _startSessionMonitoring() {
    // Periodically check session status
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _checkSessionStatus();
        return true;
      }
      return false;
    });
  }

  void _checkSessionStatus() {
    // If session is locked, navigate to PIN entry
    if (_sessionService.isLocked && _sessionService.isSessionValid) {
      // Use post-frame callback to ensure we're in the build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final router = GoRouter.of(context);
          // Only navigate if not already on PIN entry or auth routes
          final currentLocation = router.routeInformationProvider.value.uri.path;
          if (!currentLocation.startsWith('/pin-entry') &&
              !currentLocation.startsWith('/login') &&
              !currentLocation.startsWith('/forgot-password') &&
              !currentLocation.startsWith('/pin-setup')) {
            router.go('/pin-entry');
          }
        }
      });
    }
  }

  Future<void> _initializeQuickActions() async {
    try {
      // Run silently in background without blocking UI
      await _quickActionsService.initialize(
        onActionSelected: (route) {
          // Navigate using the router
          if (mounted) {
            context.go(route);
          }
        },
      );
      debugPrint('IMUApp: Quick actions initialized');
    } catch (e) {
      debugPrint('Failed to initialize quick actions: $e');
      // Continue without quick actions - not critical for app functionality
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isLoadingVisible = ref.watch(isLoadingOverlayVisibleProvider);
    final loadingMessage = ref.watch(loadingMessageProvider);

    return MaterialApp.router(
      title: 'IMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            if (isLoadingVisible)
              LoadingOverlay(
                message: loadingMessage,
                showProgress: true,
              ),
          ],
        );
      },
    );
  }
}

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
