import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart' hide Column;
import '../../services/api/background_sync_service.dart';
import '../../services/sync/powersync_service.dart';
import '../../services/connectivity_service.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/app_notification.dart';
import '../../shared/providers/app_providers.dart' show refreshAssignedClientsProvider, isOnlineProvider;

/// Compact background sync indicator widget
///
/// Shows sync status with minimal visual footprint:
/// - Spinning icon when syncing
/// - Checkmark when synced
/// - Pending count when items are waiting
/// - Error indicator when sync fails
class BackgroundSyncIndicator extends ConsumerWidget {
  final bool showLabel;
  final bool showPendingCount;
  final VoidCallback? onTap;

  const BackgroundSyncIndicator({
    super.key,
    this.showLabel = false,
    this.showPendingCount = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(backgroundSyncStatusProvider);
    final connectivityStatusAsync = ref.watch(connectivityStatusProvider);

    // Extract connectivity status from AsyncValue, default to online
    final connectivityStatus = connectivityStatusAsync.maybeWhen(
      data: (status) => status,
      orElse: () => ConnectivityStatus.online,
    );

    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context, ref, syncStatus),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(syncStatus, connectivityStatus),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(syncStatus, connectivityStatus),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncStatus, connectivityStatus),
            if (showLabel || (showPendingCount && syncStatus.pendingCount > 0)) ...[
              const SizedBox(width: 6),
              Text(
                _getLabel(syncStatus, connectivityStatus),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(syncStatus, connectivityStatus),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BackgroundSyncStatus syncStatus, ConnectivityStatus connectivityStatus) {
    // Priority: Error > Syncing > Pending > Offline > Connected
    if (syncStatus.lastSyncError != null) {
      return Icon(
        Icons.error_outline,
        size: 14,
        color: _getTextColor(syncStatus, connectivityStatus),
      );
    }

    if (syncStatus.isSyncing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(syncStatus, connectivityStatus)),
        ),
      );
    }

    if (syncStatus.pendingCount > 0) {
      return Icon(
        Icons.cloud_upload,
        size: 14,
        color: _getTextColor(syncStatus, connectivityStatus),
      );
    }

    if (connectivityStatus == ConnectivityStatus.offline) {
      return Icon(
        Icons.cloud_off,
        size: 14,
        color: _getTextColor(syncStatus, connectivityStatus),
      );
    }

    return Icon(
      Icons.cloud_done,
      size: 14,
      color: _getTextColor(syncStatus, connectivityStatus),
    );
  }

  Color _getBackgroundColor(BackgroundSyncStatus syncStatus, ConnectivityStatus connectivityStatus) {
    if (syncStatus.lastSyncError != null) {
      return Colors.red[50]!;
    }
    if (syncStatus.isSyncing) {
      return Colors.blue[50]!;
    }
    if (syncStatus.pendingCount > 0) {
      return Colors.orange[50]!;
    }
    if (connectivityStatus == ConnectivityStatus.offline) {
      return Colors.grey[300]!;
    }
    return Colors.green[50]!;
  }

  Color _getBorderColor(BackgroundSyncStatus syncStatus, ConnectivityStatus connectivityStatus) {
    if (syncStatus.lastSyncError != null) {
      return Colors.red[300]!;
    }
    if (syncStatus.isSyncing) {
      return Colors.blue[300]!;
    }
    if (syncStatus.pendingCount > 0) {
      return Colors.orange[300]!;
    }
    if (connectivityStatus == ConnectivityStatus.offline) {
      return Colors.grey[400]!;
    }
    return Colors.green[300]!;
  }

  Color _getTextColor(BackgroundSyncStatus syncStatus, ConnectivityStatus connectivityStatus) {
    if (syncStatus.lastSyncError != null) {
      return Colors.red[700]!;
    }
    if (syncStatus.isSyncing) {
      return Colors.blue[700]!;
    }
    if (syncStatus.pendingCount > 0) {
      return Colors.orange[700]!;
    }
    if (connectivityStatus == ConnectivityStatus.offline) {
      return Colors.grey[600]!;
    }
    return Colors.green[700]!;
  }

  String _getLabel(BackgroundSyncStatus syncStatus, ConnectivityStatus connectivityStatus) {
    if (syncStatus.lastSyncError != null) {
      return 'Sync failed';
    }
    if (syncStatus.isSyncing) {
      return 'Syncing...';
    }
    if (syncStatus.pendingCount > 0) {
      return '${syncStatus.pendingCount} pending';
    }
    if (connectivityStatus == ConnectivityStatus.offline) {
      return 'Offline';
    }
    return syncStatus.lastSyncFormatted;
  }

  void _handleTap(BuildContext context, WidgetRef ref, BackgroundSyncStatus syncStatus) {
    // Show sync status bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedBackgroundSyncSheet(),
    );
  }
}

/// Enhanced bottom sheet showing detailed sync status
class EnhancedBackgroundSyncSheet extends ConsumerStatefulWidget {
  const EnhancedBackgroundSyncSheet({super.key});

  @override
  ConsumerState<EnhancedBackgroundSyncSheet> createState() => _EnhancedBackgroundSyncSheetState();
}

class _EnhancedBackgroundSyncSheetState extends ConsumerState<EnhancedBackgroundSyncSheet> {
  bool _isFreshSyncing = false;

  Future<void> _handleFreshSync() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      AppNotification.showNeutral(context, 'No internet connection.');
      return;
    }
    setState(() => _isFreshSyncing = true);
    try {
      await ref.read(refreshAssignedClientsProvider)();
      if (mounted) {
        AppNotification.showSuccess(context, 'Client list refreshed from server.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppNotification.showError(context, 'Fresh sync failed: $e');
    } finally {
      if (mounted) setState(() => _isFreshSyncing = false);
    }
  }

  Future<void> _handleCancelPending(BackgroundSyncStatus syncStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Pending Changes?'),
        content: Text(
          'This will discard ${syncStatus.pendingCount} unsynced '
          'item${syncStatus.pendingCount == 1 ? '' : 's'}. '
          'These changes will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await PowerSyncService.clearPendingUploads();
      if (mounted) {
        AppNotification.showSuccess(context, 'Pending changes cancelled.');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(backgroundSyncStatusProvider);
    final connectivityStatusAsync = ref.watch(connectivityStatusProvider);
    final powerSyncDbAsync = ref.watch(powerSyncDatabaseProvider);

    // Extract connectivity status from AsyncValue, default to online
    final connectivityStatus = connectivityStatusAsync.maybeWhen(
      data: (status) => status,
      orElse: () => ConnectivityStatus.online,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sync Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 12),

              // Action buttons
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (syncStatus.pendingCount == 0 || syncStatus.isSyncing || _isFreshSyncing)
                            ? null
                            : () => _handleCancelPending(syncStatus),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: Text(
                          syncStatus.pendingCount > 0
                              ? 'Cancel Pending (${syncStatus.pendingCount})'
                              : 'Cancel Pending',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(
                            color: (syncStatus.pendingCount > 0 && !syncStatus.isSyncing && !_isFreshSyncing)
                                ? Colors.red
                                : Colors.grey[300]!,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (syncStatus.isSyncing || _isFreshSyncing) ? null : _handleFreshSync,
                        icon: _isFreshSyncing
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_download_outlined, size: 16),
                        label: const Text('Fresh Sync', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 12),
              const SizedBox(height: 12),

              // Connection Status Section
              _buildSectionHeader('Connection', Icons.cloud_sync),
              const SizedBox(height: 12),
              _buildConnectionStatusCard(context, connectivityStatus, powerSyncDbAsync),
              const SizedBox(height: 24),

              // Sync Status Section
              _buildSectionHeader('Data Sync', Icons.sync),
              const SizedBox(height: 12),
              _buildSyncStatusCard(context, syncStatus),
              const SizedBox(height: 24),

              // Services Section
              _buildSectionHeader('Services', Icons.settings),
              const SizedBox(height: 12),
              _buildServicesCard(context),
              const SizedBox(height: 24),

              // Last Sync Info
              _buildSectionHeader('Last Sync', Icons.schedule),
              const SizedBox(height: 12),
              _buildLastSyncCard(context, syncStatus),
              const SizedBox(height: 24),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatusCard(
    BuildContext context,
    ConnectivityStatus connectivityStatus,
    AsyncValue<PowerSyncDatabase> powerSyncDbAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Server Status (Backend API)
          _buildStatusRow(
            icon: Icons.dns,
            label: 'Server',
            value: connectivityStatus == ConnectivityStatus.online ? 'Connected' : 'Offline',
            color: connectivityStatus == ConnectivityStatus.online ? Colors.green[700]! : Colors.grey[500]!,
            showBorder: true,
            subtitle: _getBackendUrl(),
          ),
          const SizedBox(height: 12),

          // PowerSync Status
          powerSyncDbAsync.when(
            data: (db) {
              final isConnected = db.connected;
              return _buildStatusRow(
                icon: Icons.sync_alt,
                label: 'PowerSync',
                value: isConnected ? 'Connected' : 'Disconnected',
                color: isConnected ? Colors.green[700]! : Colors.orange[700]!,
                showBorder: true,
                subtitle: AppConfig.powerSyncUrl.replaceAll('https://', '').replaceAll('http://', ''),
              );
            },
            loading: () => _buildStatusRow(
              icon: Icons.sync_alt,
              label: 'PowerSync',
              value: 'Initializing...',
              color: Colors.grey[500]!,
              showBorder: true,
              showSpinner: true,
            ),
            error: (_, __) => _buildStatusRow(
              icon: Icons.sync_alt,
              label: 'PowerSync',
              value: 'Error',
              color: Colors.red[700]!,
              showBorder: true,
            ),
          ),

          // Network Status
          _buildStatusRow(
            icon: connectivityStatus == ConnectivityStatus.online ? Icons.wifi : Icons.wifi_off,
            label: 'Network',
            value: connectivityStatus == ConnectivityStatus.online ? 'Online' : 'Offline',
            color: connectivityStatus == ConnectivityStatus.online ? Colors.green[700]! : Colors.grey[500]!,
            showBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(BuildContext context, BackgroundSyncStatus syncStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Sync Status
          _buildStatusRow(
            icon: _getSyncStatusIcon(syncStatus),
            label: 'Status',
            value: syncStatus.statusMessage,
            color: _getSyncStatusColor(syncStatus),
            showBorder: true,
            showSpinner: syncStatus.isSyncing,
          ),
          const SizedBox(height: 12),

          // Pending Items
          _buildStatusRow(
            icon: Icons.pending_actions,
            label: 'Pending',
            value: '${syncStatus.pendingCount} items',
            color: syncStatus.pendingCount > 0 ? Colors.orange[700]! : Colors.green[700]!,
            showBorder: true,
          ),
          const SizedBox(height: 12),

          // Upload/Download Status
          Row(
            children: [
              Expanded(
                child: _buildStatusRow(
                  icon: Icons.cloud_upload,
                  label: 'Uploads',
                  value: syncStatus.pendingCount > 0 ? 'Pending' : 'Complete',
                  color: syncStatus.pendingCount > 0 ? Colors.orange[700]! : Colors.green[700]!,
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatusRow(
                  icon: Icons.cloud_download,
                  label: 'Downloads',
                  value: 'Complete',
                  color: Colors.green[700]!,
                  showBorder: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            icon: Icons.api,
            label: 'Backend API',
            value: AppConfig.backendApiUrl.replaceAll('https://', '').replaceAll('http://', ''),
            color: Colors.grey[700]!,
            showBorder: true,
            subtitle: 'REST API v1',
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.storage,
            label: 'Database',
            value: 'PowerSync SQLite',
            color: Colors.grey[700]!,
            showBorder: true,
            subtitle: 'Local offline storage',
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.phone_android,
            label: 'App Version',
            value: _getAppVersion(),
            color: Colors.grey[700]!,
            showBorder: false,
            subtitle: AppConfig.environment.toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSyncCard(BuildContext context, BackgroundSyncStatus syncStatus) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            icon: Icons.access_time,
            label: 'Last Sync',
            value: syncStatus.lastSyncFormatted,
            color: Colors.grey[700]!,
            showBorder: true,
          ),
          if (syncStatus.lastSyncError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error: ${syncStatus.lastSyncError}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool showBorder = false,
    bool showSpinner = false,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            )
          : null,
      child: Row(
        children: [
          // Icon
          SizedBox(
            width: 20,
            height: 20,
            child: showSpinner
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  )
                : Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),

          // Label and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSyncStatusIcon(BackgroundSyncStatus status) {
    if (status.lastSyncError != null) {
      return Icons.error_outline;
    }
    if (status.isSyncing) {
      return Icons.sync;
    }
    if (status.pendingCount > 0) {
      return Icons.pending_actions;
    }
    return Icons.cloud_done;
  }

  Color _getSyncStatusColor(BackgroundSyncStatus status) {
    if (status.lastSyncError != null) {
      return Colors.red;
    }
    if (status.isSyncing) {
      return Colors.blue;
    }
    if (status.pendingCount > 0) {
      return Colors.orange;
    }
    return Colors.green;
  }

  String _getBackendUrl() {
    try {
      final uri = Uri.parse(AppConfig.backendApiUrl);
      return '${uri.host}:${uri.port}';
    } catch (e) {
      logWarning('Failed to parse backend URL: $e');
      return AppConfig.backendApiUrl;
    }
  }

  String _getAppVersion() {
    // TODO: Get from pubspec.yaml or package_info
    return '1.0.0';
  }
}

/// Snackbar widget to show sync notifications
///
/// **DEPRECATED:** Use [AppNotification] instead for unified top-positioned notifications.
/// This class is kept for backward compatibility.
@Deprecated('Use AppNotification instead')
class SyncNotification {
  const SyncNotification._();

  /// Show success notification at the top
  static void showSuccess(BuildContext context, String message) {
    AppNotification.showSuccess(context, message);
  }

  /// Show error notification at the top
  static void showError(BuildContext context, String message) {
    AppNotification.showError(context, message);
  }

  /// Show info notification at the top (neutral/gray)
  static void showInfo(BuildContext context, String message) {
    AppNotification.showNeutral(context, message);
  }
}
