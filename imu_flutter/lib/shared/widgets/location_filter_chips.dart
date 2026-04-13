import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/shared/models/location_filter.dart';
import 'package:imu_flutter/shared/providers/location_filter_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LocationFilterChips extends ConsumerWidget {
  const LocationFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationFilter = ref.watch(locationFilterProvider);

    if (!locationFilter.hasFilter) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _buildFilterChip(
            label: locationFilter.getDisplayLabel(),
            onRemove: () {
              ref.read(locationFilterProvider.notifier).clear();
            },
          ),
          _buildClearAllChip(
            onClear: () {
              ref.read(locationFilterProvider.notifier).clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onRemove}) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F172A).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.x,
              size: 14,
              color: Color(0xFF0F172A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAllChip({required VoidCallback onClear}) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.x,
              size: 14,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            const Text(
              'Clear All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
