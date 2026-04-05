import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/api/background_sync_service.dart';
import '../../../../services/sync/sync_preferences_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

/// Sync loading state
class SyncLoadingState {
  final bool isSyncing;
  final bool syncNeeded;
  final int pendingCount;
  final double progress;
  final String currentStep;

  const SyncLoadingState({
    this.isSyncing = true,
    this.syncNeeded = true,
    this.pendingCount = 0,
    this.progress = 0.0,
    this.currentStep = 'Preparing sync...',
  });

  SyncLoadingState copyWith({
    bool? isSyncing,
    bool? syncNeeded,
    int? pendingCount,
    double? progress,
    String? currentStep,
  }) {
    return SyncLoadingState(
      isSyncing: isSyncing ?? this.isSyncing,
      syncNeeded: syncNeeded ?? this.syncNeeded,
      pendingCount: pendingCount ?? this.pendingCount,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// Sync loading state notifier
class SyncLoadingNotifier extends StateNotifier<SyncLoadingState> {
  final BackgroundSyncService _syncService;
  final SyncPreferencesService _preferencesService;

  SyncLoadingNotifier(this._syncService)
      : _preferencesService = SyncPreferencesService(),
        super(const SyncLoadingState()) {
    _init();
  }

  void _init() async {
    // Log API configuration for debugging
    logDebug('[SyncLoadingPage] API Configuration:');
    logDebug('[SyncLoadingPage]   Backend API: ${AppConfig.backendApiUrl}');
    logDebug('[SyncLoadingPage]   PowerSync URL: ${AppConfig.powerSyncUrl}');
    logDebug('[SyncLoadingPage]   Environment: ${AppConfig.environment}');
    logDebug('[SyncLoadingPage]   Debug Mode: ${AppConfig.debugMode}');

    // Check if sync is needed
    final syncNeeded = await _preferencesService.shouldSync();

    if (!syncNeeded) {
      // Sync not needed - navigate immediately
      state = SyncLoadingState(
        isSyncing: false,
        syncNeeded: false,
        currentStep: 'Data is up to date',
        progress: 1.0,
      );
      return;
    }

    // Listen to sync service changes
    _syncService.addListener(_onSyncServiceChanged);
    _startSync();
  }

  void _onSyncServiceChanged() {
    if (!mounted) return;

    // Update pending count
    final pendingCount = _syncService.pendingCount;

    // Calculate progress (inverse of pending count)
    // Assume max 100 pending items for progress calculation
    final progress = pendingCount > 0
        ? (1.0 - (pendingCount / 100.0)).clamp(0.0, 0.95)
        : 1.0;

    // Update current step
    final currentStep = pendingCount > 0
        ? 'Syncing data... ($pendingCount remaining)'
        : 'Finalizing...';

    state = state.copyWith(
      pendingCount: pendingCount,
      progress: progress,
      currentStep: currentStep,
    );
  }

  Future<void> _startSync() async {
    try {
      state = state.copyWith(
        currentStep: 'Connecting to sync service...',
        progress: 0.1,
      );

      final result = await _syncService.performSync();

      if (result.success) {
        // Save last sync time
        await _preferencesService.saveLastSyncTime();

        state = state.copyWith(
          isSyncing: false,
          currentStep: 'Sync complete!',
          progress: 1.0,
        );
      } else {
        state = state.copyWith(
          isSyncing: false,
          currentStep: 'Sync failed: ${result.errorMessage}',
          progress: 1.0,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        currentStep: 'Sync error: ${e.toString()}',
        progress: 1.0,
      );
    }
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncServiceChanged);
    super.dispose();
  }
}

/// Provider for sync loading state
final syncLoadingProvider = StateNotifierProvider<SyncLoadingNotifier, SyncLoadingState>((ref) {
  final syncService = ref.watch(backgroundSyncServiceProvider);
  return SyncLoadingNotifier(syncService);
});

/// Provider to prevent duplicate navigation
final _isNavigatingProvider = StateProvider<bool>((ref) => false);

/// Provider for sync preferences service
final syncPreferencesProvider = Provider<SyncPreferencesService>((ref) {
  return SyncPreferencesService();
});

/// Sync loading page
class SyncLoadingPage extends ConsumerStatefulWidget {
  const SyncLoadingPage({super.key});

  @override
  ConsumerState<SyncLoadingPage> createState() => _SyncLoadingPageState();
}

class _SyncLoadingPageState extends ConsumerState<SyncLoadingPage> {
  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(syncLoadingProvider);
    final isNavigating = ref.watch(_isNavigatingProvider);

    // Auto-navigate when sync completes or is not needed
    ref.listen<SyncLoadingState>(syncLoadingProvider, (prev, next) {
      if (!next.isSyncing && !isNavigating && mounted) {
        // If sync is not needed, navigate immediately
        // Otherwise wait a moment to show completion state
        final delay = next.syncNeeded ? const Duration(milliseconds: 500) : Duration.zero;

        Future.delayed(delay, () {
          if (mounted) {
            ref.read(_isNavigatingProvider.notifier).state = true;
            context.go('/home');
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sync,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                syncState.syncNeeded ? 'Syncing your data' : 'Up to date',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),

              // Current step
              Text(
                syncState.currentStep,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Progress bar
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: syncState.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress percentage
              Text(
                '${(syncState.progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 48),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      syncState.syncNeeded ? Icons.info_outline : Icons.check_circle_outline,
                      color: syncState.syncNeeded ? Colors.grey[600] : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        syncState.syncNeeded
                            ? 'This may take a moment. Please wait while we sync your data.'
                            : 'Your data is up to date. Taking you to the home screen...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
