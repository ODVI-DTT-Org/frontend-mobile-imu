import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/background_sync_service.dart';

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

    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context, ref, syncStatus),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(syncStatus),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(syncStatus),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncStatus),
            if (showLabel || (showPendingCount && syncStatus.pendingCount > 0)) ...[
              const SizedBox(width: 6),
              Text(
                _getLabel(syncStatus),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(syncStatus),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BackgroundSyncStatus status) {
    if (status.isSyncing) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(status)),
        ),
      );
    }

    return Icon(
      _getIconData(status),
      size: 14,
      color: _getTextColor(status),
    );
  }

  IconData _getIconData(BackgroundSyncStatus status) {
    if (status.lastSyncError != null) {
      return Icons.error_outline;
    }
    if (status.pendingCount > 0) {
      return Icons.cloud_upload;
    }
    if (status.lastSyncTime != null) {
      return Icons.cloud_done;
    }
    return Icons.cloud_sync;
  }

  Color _getBackgroundColor(BackgroundSyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue[50]!;
    }
    if (status.lastSyncError != null) {
      return Colors.red[50]!;
    }
    if (status.pendingCount > 0) {
      return Colors.orange[50]!;
    }
    return Colors.green[50]!;
  }

  Color _getBorderColor(BackgroundSyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue[300]!;
    }
    if (status.lastSyncError != null) {
      return Colors.red[300]!;
    }
    if (status.pendingCount > 0) {
      return Colors.orange[300]!;
    }
    return Colors.green[300]!;
  }

  Color _getTextColor(BackgroundSyncStatus status) {
    if (status.isSyncing) {
      return Colors.blue[700]!;
    }
    if (status.lastSyncError != null) {
      return Colors.red[700]!;
    }
    if (status.pendingCount > 0) {
      return Colors.orange[700]!;
    }
    return Colors.green[700]!;
  }

  String _getLabel(BackgroundSyncStatus status) {
    if (status.isSyncing) {
      return 'Syncing...';
    }
    if (status.lastSyncError != null) {
      return 'Sync failed';
    }
    if (status.pendingCount > 0) {
      return '${status.pendingCount} pending';
    }
    return status.lastSyncFormatted;
  }

  void _handleTap(BuildContext context, WidgetRef ref, BackgroundSyncStatus status) {
    // Show sync status bottom sheet
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const BackgroundSyncSheet(),
    );
  }
}

/// Bottom sheet showing detailed sync status
class BackgroundSyncSheet extends ConsumerWidget {
  const BackgroundSyncSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(backgroundSyncStatusProvider);
    final syncService = ref.watch(backgroundSyncServiceProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            icon: syncStatus.isSyncing ? Icons.sync : Icons.cloud_done,
            label: 'Status',
            value: syncStatus.statusMessage,
            color: _getStatusColor(syncStatus),
            isSpinning: syncStatus.isSyncing,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.pending_actions,
            label: 'Pending',
            value: '${syncStatus.pendingCount} items',
            color: syncStatus.pendingCount > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.schedule,
            label: 'Last Sync',
            value: syncStatus.lastSyncFormatted,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: syncStatus.isSyncing
                  ? null
                  : () {
                      syncService.performSync();
                      Navigator.pop(context);
                    },
              icon: syncStatus.isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(syncStatus.isSyncing ? 'Syncing...' : 'Sync Now'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSpinning = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: isSpinning
              ? CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(color),
                )
              : Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BackgroundSyncStatus status) {
    if (status.isSyncing) return Colors.blue;
    if (status.lastSyncError != null) return Colors.red;
    if (status.pendingCount > 0) return Colors.orange;
    return Colors.green;
  }
}

/// Snackbar widget to show sync notifications
class SyncNotification {
  const SyncNotification._();

  /// Show success notification
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error notification
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info notification
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
