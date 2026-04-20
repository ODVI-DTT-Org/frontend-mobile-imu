import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/sync/powersync_connector.dart' show powerSyncConnectorProvider;
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/providers/app_providers.dart' hide assignedMunicipalitiesProvider;
import '../../../../shared/providers/filter_providers.dart';
import '../../../../shared/widgets/permission_widgets.dart';
import '../../../../shared/widgets/permission_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    // Record activity on page load
    _sessionService.recordActivity();
    // Load user's assigned municipalities
    _loadAssignedMunicipalities();
  }

  Future<void> _loadAssignedMunicipalities() async {
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) return;

      final userLocations = await PowerSyncService.query(
        "SELECT province, municipality FROM user_locations WHERE user_id = ? AND deleted_at IS NULL",
        [currentUserId]
      );

      final municipalities = userLocations.map((row) {
        final province = row['province'] as String?;
        final municipality = row['municipality'] as String?;
        if (province != null && municipality != null) {
          return '$province-$municipality';
        }
        return null;
      }).whereType<String>().toList();

      ref.read(assignedMunicipalitiesProvider.notifier).state = municipalities;
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48 : 35,
            vertical: 24,
          ),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Greeting - Centered per Figma design
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: isTablet ? 28 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isTablet ? 72 : 55),

              // Menu Grid - 2 columns per Figma design
              _buildMenuGrid(isTablet),

              SizedBox(height: isTablet ? 72 : 55),

              // Developer Options - Debug info
              _buildDeveloperOptions(context),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildMenuGrid(bool isTablet) {
    final menuItems = _getMenuItems();
    // Per Figma: 2 columns on mobile, gap-8 (32px)
    final crossAxisCount = isTablet ? 4 : 2;
    final itemSize = isTablet ? 100.0 : 80.0;
    final spacing = isTablet ? 24.0 : 32.0; // gap-8 = 32px per Figma

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 0.85,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];

        return _MenuButton(
          icon: item.icon,
          label: item.label,
          size: itemSize,
          onTap: () => _handleNavigation(context, item.id),
        );
      },
    );
  }

  List<_MenuItem> _getMenuItems() {
    return [
      _MenuItem(icon: LucideIcons.sun, label: 'My Day', id: 'my-day'),
      _MenuItem(icon: LucideIcons.users, label: 'My Clients', id: 'clients'),
      _MenuItem(icon: LucideIcons.star, label: 'Starred', id: 'favorites'),
      _MenuItem(icon: LucideIcons.target, label: 'My Targets', id: 'targets'),
      _MenuItem(icon: LucideIcons.mapPin, label: 'Missed Visits', id: 'visits'),
      _MenuItem(icon: LucideIcons.calculator, label: 'Loan Calculator', id: 'calculator'),
      _MenuItem(icon: LucideIcons.clipboardList, label: 'Attendance', id: 'attendance'),
      _MenuItem(icon: LucideIcons.userCog, label: 'My Profile', id: 'profile'),
      _MenuItem(icon: LucideIcons.activity, label: 'My Activity', id: 'activity'),
    ];
  }

  String _getGreeting() {
    final userName = ref.watch(currentUserNameProvider);

    if (userName != null && userName.isNotEmpty) {
      // Format as "Good Day, JC!" per Figma design
      final firstName = userName.split(' ').first;
      return 'Good Day, $firstName!';
    }
    return 'Good Day!';
  }

  void _handleNavigation(BuildContext context, String id) {
    // Record activity for session management
    _sessionService.recordActivity();

    switch (id) {
      case 'my-day':
        context.push('/my-day');
        break;
      case 'clients':
        context.push('/clients');
        break;
      case 'favorites':
        context.push('/favorites');
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
      case 'attendance':
        context.push('/attendance');
        break;
      case 'profile':
        context.push('/profile');
        break;
      case 'activity':
        context.push('/activity');
        break;
      case 'settings':
        context.push('/settings');
        break;
      case 'debug':
        context.push('/debug');
        break;
      case 'developer':
        _showDeveloperOptions(context);
        break;
      default:
        AppNotification.showNeutral(context, '$id feature coming soon');
    }
  }

  void _showDeveloperOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeveloperOptionsSheet(),
    );
  }

  Widget _buildDeveloperOptions(BuildContext context) {
    // Wrap developer options in PermissionWidget - admin only
    return PermissionWidget(
      resource: 'system',
      action: 'read',
      child: GestureDetector(
        onTap: () => _showDeveloperOptions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.bug,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Developer Options',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
      fallback: const SizedBox.shrink(), // Hide completely for non-admin users
    );
  }
}

class _DeveloperOptionsSheet extends ConsumerStatefulWidget {
  const _DeveloperOptionsSheet({super.key});

  @override
  ConsumerState<_DeveloperOptionsSheet> createState() => _DeveloperOptionsSheetState();
}

class _DeveloperOptionsSheetState extends ConsumerState<_DeveloperOptionsSheet> {
  Map<String, int> _tableCounts = {};
  bool _isLoading = true;
  int? _assignedClientsCount;

  @override
  void initState() {
    super.initState();
    _loadTableCounts();
  }

  Future<void> _loadTableCounts() async {
    setState(() => _isLoading = true);

    try {
      final counts = <String, int>{};

      // Get counts from PowerSync
      final tables = [
        'clients',
        'user_locations',
        'user_profiles',
        'psgc',
        'touchpoint_reasons',
        'addresses',
        'phone_numbers',
        'touchpoints',
      ];

      // Get assigned clients count (for current user's municipalities)
      final assignedMunicipalities = ref.watch(assignedMunicipalitiesProvider);
      int? assignedClientsCount;

      if (assignedMunicipalities.isNotEmpty) {
        try {
          final placeholders = List.filled(assignedMunicipalities.length, '?').join(',');
          final assignedResult = await PowerSyncService.query(
            "SELECT COUNT(*) as count FROM clients WHERE municipality IN ($placeholders)",
            assignedMunicipalities
          );
          if (assignedResult.isNotEmpty) {
            assignedClientsCount = assignedResult.first['count'] as int;
          }
        } catch (e) {
          assignedClientsCount = -1;
        }
      }

      // Store assigned clients count
      setState(() {
        _tableCounts = counts;
        _assignedClientsCount = assignedClientsCount;
      });

      for (final table in tables) {
        try {
          final result = await PowerSyncService.query('SELECT COUNT(*) as count FROM $table');
          if (result.isNotEmpty) {
            counts[table] = result.first['count'] as int;
          } else {
            counts[table] = 0;
          }
        } catch (e) {
          counts[table] = -1; // Error
        }
      }

      setState(() {
        _tableCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = PowerSyncService.isConnected;
    final currentUser = ref.watch(currentUserIdProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.bug, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                const Text(
                  'Developer Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PowerSync Status
                  _buildSectionHeader('PowerSync Status'),
                  _buildInfoRow('Connected', isConnected ? 'Yes' : 'No', isConnected ? Colors.green : Colors.red),
                  _buildInfoRow('Current User ID', currentUser ?? 'Not logged in', null),
                  const SizedBox(height: 20),

                  // Table Counts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionHeader('Database Tables'),
                      IconButton(
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        onPressed: _loadTableCounts,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      children: [
                        // Clients Section
                        _buildSectionHeader('Clients'),
                        _buildInfoRow(
                          'All Clients',
                          (_tableCounts['clients'] ?? 0).toString(),
                          (_tableCounts['clients'] ?? 0) == 0 ? Colors.orange : Colors.green,
                        ),
                        if (_assignedClientsCount != null)
                          _buildInfoRow(
                            'Assigned to Me',
                            _assignedClientsCount! >= 0 ? _assignedClientsCount.toString() : 'Error',
                            _assignedClientsCount! == 0 ? Colors.orange : Colors.green,
                          ),
                        const SizedBox(height: 16),

                        // Other Tables
                        _buildSectionHeader('Other Tables'),
                        ..._tableCounts.entries.where((e) => e.key != 'clients').map((entry) {
                          final count = entry.value;
                          final isError = count == -1;
                          final countText = isError ? 'Error' : count.toString();
                          final countColor = isError ? Colors.red : (count == 0 ? Colors.orange : Colors.green);

                          return _buildInfoRow(entry.key, countText, countColor);
                        }).toList(),
                      ],
                    ),

                  const SizedBox(height: 20),

                  // Actions
                  _buildSectionHeader('Actions'),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    icon: LucideIcons.refreshCw,
                    label: 'Refresh Data',
                    color: Colors.blue,
                    onTap: () async {
                      // Trigger a sync by connecting again
                      final connector = ref.read(powerSyncConnectorProvider);
                      if (connector != null) {
                        await PowerSyncService.connect(connector);
                      }
                      _loadTableCounts();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildActionButton(
                    icon: LucideIcons.alertTriangle,
                    label: 'Check Sync Errors',
                    color: Colors.orange,
                    onTap: () {
                      AppNotification.showWarning(context, 'Check console for sync errors');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
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

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.size,
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container - 48px per Figma (w-8 h-8)
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 32, // 32px per Figma (w-8 h-8)
                color: const Color(0xFF0F172A), // Primary color from Figma
              ),
            ),
            const SizedBox(height: 8),
            // Label - 13px per Figma
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF0F172A), // Primary color from Figma
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
