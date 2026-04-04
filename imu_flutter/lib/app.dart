import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/quick_actions/quick_actions_service.dart';
// SESSION/PIN MONITORING DISABLED - Commenting out to focus on core authentication
// import 'services/auth/session_service.dart';
import 'shared/widgets/loading_widget.dart';
import 'shared/providers/app_providers.dart';

class IMUApp extends ConsumerStatefulWidget {
  const IMUApp({super.key});

  @override
  ConsumerState<IMUApp> createState() => _IMUAppState();
}

class _IMUAppState extends ConsumerState<IMUApp> with WidgetsBindingObserver {
  final QuickActionsService _quickActionsService = QuickActionsService();
  // SESSION/PIN MONITORING DISABLED - Commenting out to focus on core authentication
  // final SessionService _sessionService = SessionService();
  BackgroundSyncService? _backgroundSyncService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeQuickActions();
    // _startSessionMonitoring(); // SESSION MONITORING DISABLED
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

    // SESSION/PIN MONITORING DISABLED - Commenting out to focus on core authentication
    // switch (state) {
    //   case AppLifecycleState.resumed:
    //     // App came to foreground - check if session is locked
    //     _checkSessionStatus();
    //     break;
    //   case AppLifecycleState.inactive:
    //   case AppLifecycleState.paused:
    //   case AppLifecycleState.detached:
    //   case AppLifecycleState.hidden:
    //     break;
    // }
  }

  // SESSION/PIN MONITORING DISABLED - Commenting out to focus on core authentication
  // void _startSessionMonitoring() {
  //   // Periodically check session status
  //   Future.doWhile(() async {
  //     await Future.delayed(const Duration(seconds: 1));
  //     if (mounted) {
  //       _checkSessionStatus();
  //       return true;
  //     }
  //     return false;
  //   });
  // }

  // void _checkSessionStatus() {
  //   // If session is locked, navigate to PIN entry
  //   if (_sessionService.isLocked && _sessionService.isSessionValid) {
  //     // Use post-frame callback to ensure we're in the build cycle
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       if (mounted) {
  //         final router = GoRouter.of(context);
  //         // Only navigate if not already on PIN entry or auth routes
  //         final currentLocation = router.routeInformationProvider.value.uri.path;
  //         if (!currentLocation.startsWith('/pin-entry') &&
  //             !currentLocation.startsWith('/login') &&
  //             !currentLocation.startsWith('/forgot-password') &&
  //             !currentLocation.startsWith('/pin-setup')) {
  //           router.go('/pin-entry');
  //         }
  //       }
  //     });
  //   }
  // }

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
        return _ToastOverlay(
          key: toastNotificationKey,
          child: Stack(
            children: [
              child!,
              if (isLoadingVisible)
                LoadingOverlay(
                  message: loadingMessage,
                  showProgress: true,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Toast overlay widget that displays notifications at the top
class _ToastOverlay extends StatefulWidget {
  final Widget child;
  final Key? key;

  const _ToastOverlay({required this.child, this.key});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  String? _toastMessage;

  void showToast(String message) {
    setState(() {
      _toastMessage = message;
    });
    // Auto-hide after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _toastMessage == message) {
        setState(() {
          _toastMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_toastMessage != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _ToastNotification(
                message: _toastMessage!,
                onDismiss: () {
                  setState(() {
                    _toastMessage = null;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom toast notification widget displayed at the top
class _ToastNotification extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ToastNotification({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, -_animation.value * 50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Toast notification key for overlay
final toastNotificationKey = GlobalKey<_ToastOverlayState>();

/// Global toast function - shows toast notification at the top
void showToast(String message) {
  final overlay = toastNotificationKey.currentState;
  if (overlay != null) {
    overlay.showToast(message);
  }
}
