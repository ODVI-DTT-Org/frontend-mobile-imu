import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../services/sync/powersync_service.dart';

/// Sync progress data
class SyncProgress {
  final SyncStage stage;
  final int current;
  final int total;
  final String? currentTable;
  final double percentage;
  final String statusMessage;
  final DateTime updatedAt;

  SyncProgress({
    required this.stage,
    this.current = 0,
    this.total = 0,
    this.currentTable,
    this.percentage = 0.0,
    required this.statusMessage,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get isComplete => stage == SyncStage.complete || stage == SyncStage.error;
  bool get isInProgress => stage == SyncStage.downloading || stage == SyncStage.uploading;
}

enum SyncStage {
  idle,
  preparing,
  uploading,
  downloading,
  complete,
  error,
}

/// Notifier for sync progress
class SyncProgressNotifier extends StateNotifier<SyncProgress> {
  SyncProgressNotifier() : super(SyncProgress(
    stage: SyncStage.idle,
    statusMessage: 'Ready to sync',
  ));

  void updateProgress({
    SyncStage? stage,
    int? current,
    int? total,
    String? currentTable,
    String? statusMessage,
  }) {
    final newCurrent = current ?? state.current;
    final newTotal = total ?? state.total;
    final percentage = newTotal > 0 ? (newCurrent / newTotal) * 100 : 0.0;

    state = SyncProgress(
      stage: stage ?? state.stage,
      current: newCurrent,
      total: newTotal,
      currentTable: currentTable ?? state.currentTable,
      percentage: percentage,
      statusMessage: statusMessage ?? state.statusMessage,
    );

    logDebug('Sync progress: ${state.stage} - ${state.percentage.toStringAsFixed(1)}%');
  }

  void setIdle() {
    state = SyncProgress(
      stage: SyncStage.idle,
      statusMessage: 'Ready to sync',
    );
  }

  void setPreparing() {
    state = SyncProgress(
      stage: SyncStage.preparing,
      statusMessage: 'Preparing sync...',
    );
  }

  void setUploading(int current, int total, {String? table}) {
    updateProgress(
      stage: SyncStage.uploading,
      current: current,
      total: total,
      currentTable: table,
      statusMessage: 'Uploading changes...',
    );
  }

  void setDownloading(int current, int total, {String? table}) {
    updateProgress(
      stage: SyncStage.downloading,
      current: current,
      total: total,
      currentTable: table,
      statusMessage: 'Downloading updates...',
    );
  }

  void setComplete() {
    state = SyncProgress(
      stage: SyncStage.complete,
      statusMessage: 'Sync complete',
      percentage: 100,
    );
  }

  void setError(String error) {
    state = SyncProgress(
      stage: SyncStage.error,
      statusMessage: 'Sync failed: $error',
    );
  }
}

/// Provider for sync progress
final syncProgressProvider =
    StateNotifierProvider<SyncProgressNotifier, SyncProgress>((ref) {
  return SyncProgressNotifier();
});

/// Widget that displays sync progress with detailed information
class SyncProgressWidget extends ConsumerWidget {
  final bool showDetails;
  final bool compact;

  const SyncProgressWidget({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncProgressProvider);

    if (compact) {
      return _buildCompactProgress(context, progress);
    }

    return _buildFullProgress(context, ref, progress);
  }

  Widget _buildCompactProgress(BuildContext context, SyncProgress progress) {
    if (progress.stage == SyncStage.idle) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStageColor(progress.stage).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStageColor(progress.stage).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: _buildProgressIndicator(progress),
          ),
          const SizedBox(width: 8),
          Text(
            '${progress.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getStageColor(progress.stage),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullProgress(
    BuildContext context,
    WidgetRef ref,
    SyncProgress progress,
  ) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildProgressIndicator(progress),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStageTitle(progress.stage),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress.statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (progress.isInProgress)
                  Text(
                    '${progress.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getStageColor(progress.stage),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getStageColor(progress.stage),
                ),
                minHeight: 8,
              ),
            ),
            if (showDetails && progress.isInProgress) ...[
              const SizedBox(height: 12),
              _buildDetailsSection(progress),
            ],
            if (progress.stage == SyncStage.error) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _retrySync(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(SyncProgress progress) {
    if (progress.stage == SyncStage.complete) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 24,
      );
    }

    if (progress.stage == SyncStage.error) {
      return const Icon(
        Icons.error,
        color: Colors.red,
        size: 24,
      );
    }

    if (progress.stage == SyncStage.idle) {
      return const Icon(
        Icons.cloud_done,
        color: Colors.grey,
        size: 24,
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        value: progress.percentage > 0 ? progress.percentage / 100 : null,
        color: _getStageColor(progress.stage),
      ),
    );
  }

  Widget _buildDetailsSection(SyncProgress progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${progress.current} / ${progress.total}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (progress.currentTable != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Table',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  progress.currentTable!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getStageTitle(SyncStage stage) {
    switch (stage) {
      case SyncStage.idle:
        return 'Sync Ready';
      case SyncStage.preparing:
        return 'Preparing Sync';
      case SyncStage.uploading:
        return 'Uploading Changes';
      case SyncStage.downloading:
        return 'Downloading Updates';
      case SyncStage.complete:
        return 'Sync Complete';
      case SyncStage.error:
        return 'Sync Failed';
    }
  }

  Color _getStageColor(SyncStage stage) {
    switch (stage) {
      case SyncStage.idle:
        return Colors.grey;
      case SyncStage.preparing:
        return Colors.blue;
      case SyncStage.uploading:
        return AppColors.primaryBlue;
      case SyncStage.downloading:
        return Colors.green;
      case SyncStage.complete:
        return Colors.green;
      case SyncStage.error:
        return Colors.red;
    }
  }

  void _retrySync(WidgetRef ref) {
    ref.read(syncProgressProvider.notifier).setPreparing();
    // Trigger sync retry
    // This would connect to the actual sync service
    logDebug('Retrying sync...');
  }
}

/// Compact sync status indicator for app bars
class SyncStatusIndicator extends ConsumerWidget {
  final VoidCallback? onTap;

  const SyncStatusIndicator({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(syncProgressProvider);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getBackgroundColor(progress.stage),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(progress.stage),
              size: 16,
              color: _getIconColor(progress.stage),
            ),
            const SizedBox(width: 6),
            Text(
              _getStatusText(progress),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getTextColor(progress.stage),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(SyncStage stage) {
    switch (stage) {
      case SyncStage.idle:
        return Icons.cloud_done;
      case SyncStage.preparing:
      case SyncStage.uploading:
      case SyncStage.downloading:
        return Icons.sync;
      case SyncStage.complete:
        return Icons.check_circle;
      case SyncStage.error:
        return Icons.error_outline;
    }
  }

  String _getStatusText(SyncProgress progress) {
    if (progress.isInProgress) {
      return '${progress.percentage.toStringAsFixed(0)}%';
    }
    switch (progress.stage) {
      case SyncStage.idle:
        return 'Synced';
      case SyncStage.complete:
        return 'Complete';
      case SyncStage.error:
        return 'Error';
      default:
        return 'Syncing';
    }
  }

  Color _getBackgroundColor(SyncStage stage) {
    switch (stage) {
      case SyncStage.error:
        return Colors.red.withOpacity(0.1);
      case SyncStage.complete:
        return Colors.green.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getIconColor(SyncStage stage) {
    switch (stage) {
      case SyncStage.error:
        return Colors.red;
      case SyncStage.complete:
        return Colors.green;
      default:
        return AppColors.primaryBlue;
    }
  }

  Color _getTextColor(SyncStage stage) {
    switch (stage) {
      case SyncStage.error:
        return Colors.red;
      case SyncStage.complete:
        return Colors.green;
      default:
        return Colors.black87;
    }
  }
}
