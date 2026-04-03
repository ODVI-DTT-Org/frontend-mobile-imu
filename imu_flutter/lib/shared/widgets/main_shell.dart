import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/haptic_utils.dart';
import 'background_sync_indicator.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(child: child),
              const BottomNavBar(),
            ],
          ),
          // Sync status overlay (top-right)
          const Positioned(
            top: 16,
            right: 16,
            child: _SyncStatusOverlay(),
          ),
        ],
      ),
    );
  }
}

/// Sync status overlay positioned in top-right corner
class _SyncStatusOverlay extends ConsumerWidget {
  const _SyncStatusOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Show sync status sheet
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (context) => const BackgroundSyncSheet(),
        );
      },
      child: const BackgroundSyncIndicator(
        showLabel: false,
        showPendingCount: true,
      ),
    );
  }
}

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/home') {
      return 0;
    } else if (location == '/my-day') {
      return 1;
    } else if (location == '/itinerary') {
      return 2;
    } else if (location == '/clients') {
      return 3;
    } else if (location == '/profile') {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    HapticUtils.lightImpact();
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/my-day');
        break;
      case 2:
        context.go('/itinerary');
        break;
      case 3:
        context.go('/clients');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => _onItemTapped(context, 0),
              ),
              _NavItem(
                icon: LucideIcons.calendarDays,
                label: 'My Day',
                isSelected: currentIndex == 1,
                onTap: () => _onItemTapped(context, 1),
              ),
              _NavItem(
                icon: LucideIcons.mapPin,
                label: 'Itinerary',
                isSelected: currentIndex == 2,
                onTap: () => _onItemTapped(context, 2),
              ),
              _NavItem(
                icon: LucideIcons.users,
                label: 'Clients',
                isSelected: currentIndex == 3,
                onTap: () => _onItemTapped(context, 3),
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profile',
                isSelected: currentIndex == 4,
                onTap: () => _onItemTapped(context, 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Per Figma design: primary color #0F172A
    final color = isSelected
        ? const Color(0xFF0F172A)
        : const Color(0xFF0F172A).withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon - 21.4px per Figma (using 22 for crisp rendering)
              SizedBox(
                width: 44,
                height: 22,
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 7),
              // Label - 10px per Figma
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
