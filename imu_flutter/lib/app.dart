import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'services/quick_actions/quick_actions_service.dart';

class IMUApp extends ConsumerStatefulWidget {
  const IMUApp({super.key});

  @override
  ConsumerState<IMUApp> createState() => _IMUAppState();
}

class _IMUAppState extends ConsumerState<IMUApp> {
  final QuickActionsService _quickActionsService = QuickActionsService();

  @override
  void initState() {
    super.initState();
    _initializeQuickActions();
  }

  Future<void> _initializeQuickActions() async {
    try {
      await _quickActionsService.initialize(
        onActionSelected: (route) {
          // Navigate using the router
          if (mounted) {
            context.go(route);
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize quick actions: $e');
      // Continue without quick actions - not critical for app functionality
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'IMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// Theme mode provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
