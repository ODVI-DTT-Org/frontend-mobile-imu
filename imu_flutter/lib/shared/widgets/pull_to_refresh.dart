import 'package:flutter/material.dart';
import '../../core/utils/haptic_utils.dart';
import '../../services/sync/sync_service.dart';

/// Pull to refresh wrapper with sync integration
class PullToRefresh extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final String? refreshMessage;

  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
    this.refreshMessage,
  });

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticUtils.pullToRefresh();

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      displacement: 40,
      strokeWidth: 2,
      child: widget.child,
    );
  }
}

/// Sync-enabled pull to refresh
class SyncPullToRefresh extends StatelessWidget {
  final Widget child;
  final SyncService? syncService;

  const SyncPullToRefresh({
    super.key,
    required this.child,
    this.syncService,
  });

  Future<void> _handleRefresh() async {
    final service = syncService ?? SyncService();
    await service.syncNow();
    HapticUtils.success();
  }

  @override
  Widget build(BuildContext context) {
    return PullToRefresh(
      onRefresh: _handleRefresh,
      refreshMessage: 'Syncing data...',
      child: child,
    );
  }
}

/// Custom refresh indicator with sync status
class CustomRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? indicatorColor;

  const CustomRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.indicatorColor,
  });

  @override
  State<CustomRefreshIndicator> createState() => _CustomRefreshIndicatorState();
}

class _CustomRefreshIndicatorState extends State<CustomRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _controller.repeat();
        try {
          await widget.onRefresh();
        } finally {
          _controller.stop();
          _controller.value = 0;
        }
      },
      color: widget.indicatorColor ?? Theme.of(context).colorScheme.primary,
      child: widget.child,
    );
  }
}
