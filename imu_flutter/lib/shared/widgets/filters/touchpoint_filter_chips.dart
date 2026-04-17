import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/touchpoint_filter_provider.dart';
import '../../../core/utils/haptic_utils.dart';

class TouchpointFilterChips extends ConsumerWidget {
  const TouchpointFilterChips({super.key});

  static const _chips = [
    _ChipDef(n: 1, label: '1st', icon: LucideIcons.mapPin),
    _ChipDef(n: 2, label: '2nd', icon: LucideIcons.phone),
    _ChipDef(n: 3, label: '3rd', icon: LucideIcons.phone),
    _ChipDef(n: 4, label: '4th', icon: LucideIcons.mapPin),
    _ChipDef(n: 5, label: '5th', icon: LucideIcons.phone),
    _ChipDef(n: 6, label: '6th', icon: LucideIcons.phone),
    _ChipDef(n: 7, label: '7th', icon: LucideIcons.mapPin),
    _ChipDef(n: 8, label: 'Archive', icon: LucideIcons.archive),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(touchpointFilterProvider);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final isActive = filter.selectedNumbers.contains(chip.n);
          return _TouchpointChip(
            chip: chip,
            isActive: isActive,
            onTap: () {
              HapticUtils.lightImpact();
              ref.read(touchpointFilterProvider.notifier).toggle(chip.n);
            },
          );
        },
      ),
    );
  }
}

class _ChipDef {
  final int n;
  final String label;
  final IconData icon;
  const _ChipDef({required this.n, required this.label, required this.icon});
}

class _TouchpointChip extends StatelessWidget {
  final _ChipDef chip;
  final bool isActive;
  final VoidCallback onTap;

  const _TouchpointChip({
    required this.chip,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF0F172A) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              chip.icon,
              size: 12,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              chip.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
