import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationFilterIcon extends ConsumerWidget {
  final VoidCallback onTap;

  const LocationFilterIcon({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationFilter = ref.watch(locationFilterProvider);
    final hasFilter = locationFilter.hasFilter;

    return IconButton(
      icon: Icon(
        LucideIcons.mapPin,
        color: hasFilter ? const Color(0xFF0F172A) : Colors.grey,
      ),
      onPressed: onTap,
      tooltip: hasFilter ? 'Location filter active' : 'Filter by location',
    );
  }
}
