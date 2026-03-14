import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/providers/app_providers.dart';

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
    // Per Figma: 6 items in 2 columns (3 rows of 2)
    return [
      _MenuItem(icon: LucideIcons.users, label: 'My Clients', id: 'clients'),
      _MenuItem(icon: LucideIcons.target, label: 'My Targets', id: 'targets'),
      _MenuItem(icon: LucideIcons.mapPin, label: 'Missed Visits', id: 'visits'),
      _MenuItem(icon: LucideIcons.calculator, label: 'Loan Calculator', id: 'calculator'),
      _MenuItem(icon: LucideIcons.clipboardList, label: 'Attendance', id: 'attendance'),
      _MenuItem(icon: LucideIcons.userCog, label: 'My Profile', id: 'profile'),
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
      case 'attendance':
        context.push('/attendance');
        break;
      case 'profile':
        context.push('/profile');
        break;
      case 'settings':
        context.push('/settings');
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
