import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/sync/sync_service.dart';

/// Sync status indicator widget
class SyncStatusWidget extends ConsumerWidget {
  final bool showLabel;
  final VoidCallback? onTap;

  const SyncStatusWidget({
    super.key,
    this.showLabel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

    return GestureDetector(
      onTap: onTap ?? () => _handleTap(context, syncService),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(syncService.status),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncService.status),
            if (showLabel) ...[
              const SizedBox(width: 6),
              Text(
                _getLabel(syncService),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(syncService.status),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncStatusEnum status) {
    if (status == SyncStatusEnum.syncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(status)),
        ),
      );
    }

    return Icon(
      _getIconData(status),
      size: 16,
      color: _getTextColor(status),
    );
  }

  IconData _getIconData(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.idle:
        return Icons.cloud_done;
      case SyncStatusEnum.syncing:
        return Icons.sync;
      case SyncStatusEnum.success:
        return Icons.check_circle;
      case SyncStatusEnum.error:
        return Icons.error_outline;
      case SyncStatusEnum.offline:
        return Icons.cloud_off;
    }
  }

  Color _getBackgroundColor(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.idle:
        return Colors.grey[200]!;
      case SyncStatusEnum.syncing:
        return Colors.blue[100]!;
      case SyncStatusEnum.success:
        return Colors.green[100]!;
      case SyncStatusEnum.error:
        return Colors.red[100]!;
      case SyncStatusEnum.offline:
        return Colors.orange[100]!;
    }
  }

  Color _getTextColor(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.idle:
        return Colors.grey[700]!;
      case SyncStatusEnum.syncing:
        return Colors.blue[700]!;
      case SyncStatusEnum.success:
        return Colors.green[700]!;
      case SyncStatusEnum.error:
        return Colors.red[700]!;
      case SyncStatusEnum.offline:
        return Colors.orange[700]!;
    }
  }

  String _getLabel(SyncService syncService) {
    if (syncService.pendingCount > 0 && syncService.status != SyncStatusEnum.syncing) {
      return '${syncService.pendingCount} pending';
    }
    return syncService.statusMessage;
  }

  void _handleTap(BuildContext context, SyncService syncService) {
    if (syncService.status == SyncStatusEnum.offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Changes will sync when online.'),
        ),
      );
    } else if (syncService.pendingCount > 0) {
      syncService.syncNow();
    }
  }
}

/// Connectivity banner that shows when offline
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

    if (syncService.status != SyncStatusEnum.offline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange[100],
      child: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are offline. Changes will be saved locally and synced when connected.',
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sync status bottom sheet
class SyncStatusSheet extends ConsumerWidget {
  const SyncStatusSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

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
            icon: syncService.status == SyncStatusEnum.offline
                ? Icons.cloud_off
                : Icons.cloud_done,
            label: 'Connection',
            value: syncService.status == SyncStatusEnum.offline
                ? 'Offline'
                : 'Connected',
            color: syncService.status == SyncStatusEnum.offline
                ? Colors.orange
                : Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.sync,
            label: 'Status',
            value: syncService.statusMessage,
            color: _getStatusColor(syncService.status),
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.pending_actions,
            label: 'Pending',
            value: '${syncService.pendingCount} items',
            color: syncService.pendingCount > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            icon: Icons.schedule,
            label: 'Last Sync',
            value: syncService.lastSyncFormatted,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          if (syncService.pendingCount > 0 &&
              syncService.status != SyncStatusEnum.offline)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncService.isSyncing
                    ? null
                    : () {
                        syncService.syncNow();
                      },
                icon: syncService.isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(syncService.isSyncing ? 'Syncing...' : 'Sync Now'),
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
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
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

  Color _getStatusColor(SyncStatusEnum status) {
    switch (status) {
      case SyncStatusEnum.idle:
        return Colors.grey;
      case SyncStatusEnum.syncing:
        return Colors.blue;
      case SyncStatusEnum.success:
        return Colors.green;
      case SyncStatusEnum.error:
        return Colors.red;
      case SyncStatusEnum.offline:
        return Colors.orange;
    }
  }

  /// Show the sync status sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const SyncStatusSheet(),
    );
  }
}
