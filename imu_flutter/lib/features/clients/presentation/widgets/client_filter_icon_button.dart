// lib/features/clients/presentation/widgets/client_filter_icon_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:badges/badges.dart' as badges;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/providers/client_attribute_filter_provider.dart';

class ClientFilterIconButton extends ConsumerWidget {
  final VoidCallback onPressed;
  final bool showLocationOnly;
  final bool showAttributeOnly;

  const ClientFilterIconButton({
    super.key,
    required this.onPressed,
    this.showLocationOnly = false,
    this.showAttributeOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activeFilterCountProvider);

    // Determine which icon to show
    IconData icon;
    if (showLocationOnly) {
      icon = LucideIcons.navigation; // GPS icon
    } else if (showAttributeOnly) {
      icon = LucideIcons.users;
    } else {
      // Default: show attribute filter icon
      icon = LucideIcons.users;
    }

    final button = IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
    );

    // Show badge if there are active filters
    if (activeCount > 0) {
      return badges.Badge(
        badgeContent: Text(
          activeCount.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
        position: badges.BadgePosition.topEnd(top: -8, end: -8),
        child: button,
      );
    }

    return button;
  }
}
