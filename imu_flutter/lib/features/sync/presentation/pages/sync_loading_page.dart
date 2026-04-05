import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' hide Column, SyncStatus;
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/api/background_sync_service.dart';
import '../../../../services/sync/sync_preferences_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';

/// Table sync status
class TableSyncStatus {
  final String tableName;
  final int rowCount;
  final bool isLoaded;
  final bool isLoading;

  const TableSyncStatus({
    required this.tableName,
    this.rowCount = 0,
    this.isLoaded = false,
    this.isLoading = false,
  });

  TableSyncStatus copyWith({
    String? tableName,
    int? rowCount,
    bool? isLoaded,
    bool? isLoading,
  }) {
    return TableSyncStatus(
      tableName: tableName ?? this.tableName,
      rowCount: rowCount ?? this.rowCount,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Enhanced sync loading state with table progress
class EnhancedSyncLoadingState {
  final bool isInitializing;
  final bool isSyncing;
  final bool isConnected;
  final bool syncComplete;
  final double progress;
  final String currentStep;
  final String errorMessage;
  final List<TableSyncStatus> tableStatus;

  const EnhancedSyncLoadingState({
    this.isInitializing = true,
    this.isSyncing = false,
    this.isConnected = false,
    this.syncComplete = false,
    this.progress = 0.0,
    this.currentStep = 'Initializing PowerSync...',
    this.errorMessage = '',
    this.tableStatus = const [],
  });

  EnhancedSyncLoadingState copyWith({
    bool? isInitializing,
    bool? isSyncing,
    bool? isConnected,
    bool? syncComplete,
    double? progress,
    String? currentStep,
    String? errorMessage,
    List<TableSyncStatus>? tableStatus,
  }) {
    return EnhancedSyncLoadingState(
      isInitializing: isInitializing ?? this.isInitializing,
      isSyncing: isSyncing ?? this.isSyncing,
      isConnected: isConnected ?? this.isConnected,
      syncComplete: syncComplete ?? this.syncComplete,
      progress: progress ?? this.progress,
      currentStep: currentStep ?? this.currentStep,
      errorMessage: errorMessage ?? this.errorMessage,
      tableStatus: tableStatus ?? this.tableStatus,
    );
  }
}

/// Tables to sync with display names
const Map<String, String> _tableDisplayNames = {
  'clients': 'Clients',
  'addresses': 'Addresses',
  'phone_numbers': 'Phone Numbers',
  'touchpoints': 'Touchpoints',
  'itineraries': 'Itineraries',
  'user_profiles': 'User Profiles',
  'user_locations': 'User Locations',
  'approvals': 'Approvals',
  'psgc': 'PSGC (Locations)',
  'touchpoint_reasons': 'Touchpoint Reasons',
  'error_logs': 'Error Logs',
};

/// Enhanced sync loading state notifier
class EnhancedSyncLoadingNotifier extends StateNotifier<EnhancedSyncLoadingState> {
  final PowerSyncDatabase _powerSyncDb;
  final SyncPreferencesService _preferencesService;

  StreamSubscription? _syncStatusSubscription;
  bool _hasNavigated = false;

  EnhancedSyncLoadingNotifier(this._powerSyncDb)
      : _preferencesService = SyncPreferencesService(),
        super(const EnhancedSyncLoadingState()) {
    _init();
  }

  void _init() async {
    // Log API configuration for debugging
    logDebug('[SyncLoadingPage] API Configuration:');
    logDebug('[SyncLoadingPage]   Backend API: ${AppConfig.backendApiUrl}');
    logDebug('[SyncLoadingPage]   PowerSync URL: ${AppConfig.powerSyncUrl}');
    logDebug('[SyncLoadingPage]   Environment: ${AppConfig.environment}');
    logDebug('[SyncLoadingPage]   Debug Mode: ${AppConfig.debugMode}');

    // Initialize table status list
    final initialTableStatus = _tableDisplayNames.entries.map((entry) {
      return TableSyncStatus(
        tableName: entry.value,
        isLoading: false,
        isLoaded: false,
        rowCount: 0,
      );
    }).toList();

    state = state.copyWith(
      tableStatus: initialTableStatus,
      currentStep: 'Connecting to PowerSync...',
    );

    // Check if already synced recently
    final lastSync = await _preferencesService.getLastSyncTime();
    if (lastSync != null) {
      final syncAge = DateTime.now().difference(lastSync);
      if (syncAge.inMinutes < 5) {
        // Synced recently, skip PowerSync sync
        logDebug('[SyncLoadingPage] Synced recently (${syncAge.inMinutes} minutes ago), skipping...');
        state = state.copyWith(
          isInitializing: false,
          isSyncing: false,
          isConnected: true,
          syncComplete: true,
          progress: 1.0,
          currentStep: 'Data is up to date',
        );
        // Navigation handled by widget
        return;
      }
    }

    // Start sync process
    await _startPowerSyncSync();
  }

  Future<void> _startPowerSyncSync() async {
    try {
      // Step 1: Wait for PowerSync to connect
      state = state.copyWith(
        currentStep: 'Connecting to PowerSync service...',
        progress: 0.1,
      );

      // Wait for connection (with timeout)
      final connected = await _waitForConnection(timeout: const Duration(seconds: 10));

      if (!connected) {
        state = state.copyWith(
          isInitializing: false,
          isSyncing: false,
          isConnected: false,
          errorMessage: 'Failed to connect to PowerSync. Please check your connection.',
          progress: 0.0,
        );
        return;
      }

      state = state.copyWith(
        isConnected: true,
        isInitializing: false,
        isSyncing: true,
        currentStep: 'Syncing data...',
        progress: 0.2,
      );

      // Step 2: Listen to sync status
      _listenToSyncStatus();

      // Step 3: Wait for initial sync to complete
      await PowerSyncService.waitForInitialSync(timeout: const Duration(seconds: 60));

      // Step 4: Count rows in each table
      await _countTableRows();

      // Step 5: Save sync time
      await _preferencesService.saveLastSyncTime();

      state = state.copyWith(
        isSyncing: false,
        syncComplete: true,
        currentStep: 'Sync complete!',
        progress: 1.0,
      );

      // Navigate to home after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        // Navigation handled by widget
      });

    } catch (e) {
      logError('[SyncLoadingPage] Sync failed', e);
      state = state.copyWith(
        isInitializing: false,
        isSyncing: false,
        errorMessage: 'Sync failed: ${e.toString()}',
        progress: 0.0,
      );
    }
  }

  Future<bool> _waitForConnection({required Duration timeout}) async {
    final completer = Completer<bool>();
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    StreamSubscription? subscription;
    subscription = _powerSyncDb.statusStream.listen((status) {
      if (status.connected) {
        timer.cancel();
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Check current status immediately
    if (_powerSyncDb.connected) {
      timer.cancel();
      subscription?.cancel();
      return true;
    }

    return completer.future;
  }

  void _listenToSyncStatus() {
    _syncStatusSubscription = _powerSyncDb.statusStream.listen((status) {
      if (!mounted) return;

      final isDownloading = status.downloading;
      final isUploading = status.uploading;

      String stepMessage;
      double progress;

      if (isDownloading) {
        stepMessage = 'Downloading data from server...';
        progress = 0.3;
      } else if (isUploading) {
        stepMessage = 'Uploading local changes...';
        progress = 0.7;
      } else {
        stepMessage = 'Sync complete!';
        progress = 1.0;
      }

      // Update table status based on sync state
      final updatedTableStatus = state.tableStatus.map((tableStatus) {
        if (isDownloading && !tableStatus.isLoaded) {
          return tableStatus.copyWith(isLoading: true);
        } else if (!isDownloading && tableStatus.isLoading) {
          return tableStatus.copyWith(isLoading: false, isLoaded: true);
        }
        return tableStatus;
      }).toList();

      state = state.copyWith(
        currentStep: stepMessage,
        progress: progress,
        tableStatus: updatedTableStatus,
      );
    });
  }

  Future<void> _countTableRows() async {
    final updatedTableStatus = <TableSyncStatus>[];

    for (final entry in _tableDisplayNames.entries) {
      final tableName = entry.key;
      final displayName = entry.value;

      try {
        final result = await _powerSyncDb.getAll('SELECT COUNT(*) as count FROM $tableName');
        final rowCount = result.first['count'] as int;
        logDebug('[SyncLoadingPage] $displayName: $rowCount rows loaded');

        updatedTableStatus.add(TableSyncStatus(
          tableName: displayName,
          rowCount: rowCount,
          isLoaded: true,
          isLoading: false,
        ));
      } catch (e) {
        logWarning('[SyncLoadingPage] Failed to count rows for $displayName: $e');
        updatedTableStatus.add(TableSyncStatus(
          tableName: displayName,
          rowCount: 0,
          isLoaded: true,
          isLoading: false,
        ));
      }
    }

    state = state.copyWith(tableStatus: updatedTableStatus);
  }

  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for enhanced sync loading state
final enhancedSyncLoadingProvider = StateNotifierProvider.family<EnhancedSyncLoadingNotifier, EnhancedSyncLoadingState, PowerSyncDatabase>((ref, database) {
  return EnhancedSyncLoadingNotifier(database);
});

/// Provider to prevent duplicate navigation
final _isNavigatingProvider = StateProvider<bool>((ref) => false);

/// Sync loading page with PowerSync progress
class SyncLoadingPage extends ConsumerStatefulWidget {
  const SyncLoadingPage({super.key});

  @override
  ConsumerState<SyncLoadingPage> createState() => _SyncLoadingPageState();
}

class _SyncLoadingPageState extends ConsumerState<SyncLoadingPage> {
  @override
  Widget build(BuildContext context) {
    final powerSyncDb = ref.watch(powerSyncDatabaseProvider);
    final isNavigating = ref.watch(_isNavigatingProvider);

    return powerSyncDb.when(
      data: (db) {
        final syncState = ref.watch(enhancedSyncLoadingProvider(db));

        // Auto-navigate when sync completes
        ref.listen<EnhancedSyncLoadingState>(enhancedSyncLoadingProvider(db), (prev, next) {
          if (next.syncComplete && !isNavigating && mounted) {
            ref.read(_isNavigatingProvider.notifier).state = true;
            // Navigate to home after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                context.go('/home');
              }
            });
          }
        });

        return _buildSyncScreen(context, syncState);
      },
      loading: () => _buildLoadingScreen(),
      error: (error, stack) => _buildErrorScreen(error.toString()),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Initializing...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[700],
                ),
                const SizedBox(height: 24),
                Text(
                  'Sync Error',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Continue to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncScreen(BuildContext context, EnhancedSyncLoadingState syncState) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              _buildHeader(context, syncState),

              const SizedBox(height: 24),

              // Progress bar
              _buildProgressBar(context, syncState),

              const SizedBox(height: 32),

              // Table sync status
              Expanded(
                child: _buildTableStatusList(context, syncState),
              ),

              // Footer info
              _buildFooter(context, syncState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EnhancedSyncLoadingState syncState) {
    return Column(
      children: [
        // Logo/Icon
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getStatusColor(syncState).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getStatusIcon(syncState),
              color: _getStatusColor(syncState),
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          syncState.syncComplete
              ? 'Sync Complete!'
              : syncState.errorMessage.isNotEmpty
                  ? 'Sync Failed'
                  : 'Syncing Your Data',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),

        // Current step
        Text(
          syncState.errorMessage.isNotEmpty
              ? syncState.errorMessage
              : syncState.currentStep,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, EnhancedSyncLoadingState syncState) {
    return Column(
      children: [
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
                    color: _getStatusColor(syncState),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Progress percentage
        Text(
          '${(syncState.progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _getStatusColor(syncState),
          ),
        ),
      ],
    );
  }

  Widget _buildTableStatusList(BuildContext context, EnhancedSyncLoadingState syncState) {
    if (syncState.tableStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        itemCount: syncState.tableStatus.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tableStatus = syncState.tableStatus[index];
          return _buildTableStatusItem(context, tableStatus);
        },
      ),
    );
  }

  Widget _buildTableStatusItem(BuildContext context, TableSyncStatus tableStatus) {
    return Row(
      children: [
        // Status icon
        Icon(
          _getTableStatusIcon(tableStatus),
          size: 20,
          color: _getTableStatusColor(tableStatus),
        ),
        const SizedBox(width: 12),

        // Table name
        Expanded(
          child: Text(
            tableStatus.tableName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),

        // Row count or loading indicator
        if (tableStatus.isLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (tableStatus.isLoaded)
          Text(
            '${tableStatus.rowCount} loaded',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Text(
            'Waiting...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, EnhancedSyncLoadingState syncState) {
    String infoText;
    Color? infoColor;

    if (syncState.errorMessage.isNotEmpty) {
      infoText = 'Please try again or contact support if the problem persists.';
      infoColor = Colors.red[700];
    } else if (syncState.syncComplete) {
      infoText = 'Taking you to the home screen...';
      infoColor = Colors.green[700];
    } else if (syncState.isInitializing) {
      infoText = 'Please wait while we initialize PowerSync...';
      infoColor = Colors.grey[600];
    } else {
      infoText = 'Please wait while we sync your data. This may take a moment.';
      infoColor = Colors.grey[600];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: infoColor?.withOpacity(0.1) ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            syncState.errorMessage.isNotEmpty
                ? Icons.error_outline
                : syncState.syncComplete
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
            color: infoColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              infoText,
              style: TextStyle(
                fontSize: 13,
                color: infoColor?.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(EnhancedSyncLoadingState state) {
    if (state.errorMessage.isNotEmpty) return Icons.error_outline;
    if (state.syncComplete) return Icons.check_circle;
    if (state.isConnected) return Icons.cloud_sync;
    return Icons.sync;
  }

  Color _getStatusColor(EnhancedSyncLoadingState state) {
    if (state.errorMessage.isNotEmpty) return Colors.red[700]!;
    if (state.syncComplete) return Colors.green[700]!;
    if (state.isConnected) return Theme.of(context).colorScheme.primary;
    return Colors.grey[400]!;
  }

  IconData _getTableStatusIcon(TableSyncStatus tableStatus) {
    if (tableStatus.isLoading) return Icons.hourglass_empty;
    if (tableStatus.isLoaded) return Icons.check_circle;
    return Icons.circle_outlined;
  }

  Color _getTableStatusColor(TableSyncStatus tableStatus) {
    if (tableStatus.isLoading) return Colors.orange[700]!;
    if (tableStatus.isLoaded) return Colors.green[700]!;
    return Colors.grey[300]!;
  }
}
