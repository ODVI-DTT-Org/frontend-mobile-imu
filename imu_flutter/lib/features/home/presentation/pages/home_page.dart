import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/sync/sync_service.dart';
import '../../../../services/local_storage/hive_service.dart' show SyncStatus;
import '../../../../services/auth/session_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/providers/app_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SyncService _syncService = SyncService();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    // Record activity on page load
    _sessionService.recordActivity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header with sync status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Greeting
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Sync Status Indicator
                  _buildSyncStatusIndicator(),
                ],
              ),
              const SizedBox(height: 48),
              // Menu Grid - 3 columns, 2 rows per Figma design
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: _menuItems.map((item) {
                  return _MenuButton(
                    icon: item.icon,
                    label: item.label,
                    onTap: () => _handleNavigation(context, item.id),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    return ListenableBuilder(
      listenable: _syncService,
      builder: (context, child) {
        return GestureDetector(
          onTap: () async {
            HapticUtils.lightImpact();
            if (!_syncService.isSyncing && _syncService.isOnline) {
              await _syncService.syncNow();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_syncService.status == SyncStatus.success
                        ? 'Data synced successfully'
                        : 'Sync failed. Will retry later.'),
                    backgroundColor: _syncService.status == SyncStatus.success
                        ? Colors.green
                        : Colors.orange,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getSyncStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getSyncStatusColor().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_syncService.isSyncing)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                else
                  Icon(
                    _getSyncStatusIcon(),
                    size: 14,
                    color: _getSyncStatusColor(),
                  ),
                const SizedBox(width: 6),
                Text(
                  _syncService.statusMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getSyncStatusColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_syncService.pendingCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_syncService.pendingCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSyncStatusColor() {
    switch (_syncService.status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
    }
  }

  IconData _getSyncStatusIcon() {
    switch (_syncService.status) {
      case SyncStatus.idle:
        return LucideIcons.cloud;
      case SyncStatus.syncing:
        return LucideIcons.loader2;
      case SyncStatus.success:
        return LucideIcons.check;
      case SyncStatus.error:
        return LucideIcons.cloudOff;
      case SyncStatus.offline:
        return LucideIcons.cloudOff;
    }
  }

  void _handleMenuTap() {
    _sessionService.recordActivity();
    HapticUtils.lightImpact();
  }

  String _getGreeting() {
    final userName = ref.watch(currentUserNameProvider);
    final hour = DateTime.now().hour;

    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    if (userName != null && userName.isNotEmpty) {
      return '$greeting, $userName!';
    }
    return '$greeting!';
  }

  void _handleNavigation(BuildContext context, String id) {
    // Record activity for session management
    _sessionService.recordActivity();

    switch (id) {
      case 'clients':
        context.push('/clients');
        break;
      case 'visits':
        context.push('/visits');
        break;
      case 'targets':
        context.push('/targets');
        break;
      case 'calculator':
        context.push('/calculator');
        break;
      case 'debug':
        context.push('/debug');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$id feature coming soon'),
          ),
        );
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String id;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.id,
  });
}

final _menuItems = [
  _MenuItem(icon: LucideIcons.users, label: 'My Clients', id: 'clients'),
  _MenuItem(icon: LucideIcons.target, label: 'My Targets', id: 'targets'),
  _MenuItem(icon: LucideIcons.mapPin, label: 'Missed Visits', id: 'visits'),
  _MenuItem(icon: LucideIcons.calculator, label: 'Loan Calculator', id: 'calculator'),
  _MenuItem(icon: LucideIcons.clipboardList, label: 'Attendance', id: 'attendance'),
  _MenuItem(icon: LucideIcons.userCog, label: 'My Profile', id: 'profile'),
  // Debug item - only visible in debug mode
  _MenuItem(icon: LucideIcons.bug, label: 'Debug', id: 'debug'),
];

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticUtils.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
