import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';
import '../../../shared/providers/location_filter_providers.dart';

class ActiveFilterChipsRow extends ConsumerWidget {
  const ActiveFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationFilterProvider);
    final attrs = ref.watch(clientAttributeFilterProvider);
    final attrNotifier = ref.read(clientAttributeFilterProvider.notifier);
    final locationNotifier = ref.read(locationFilterProvider.notifier);

    final chips = <Widget>[];

    if (location.province != null) {
      final label = location.municipalities == null || location.municipalities!.isEmpty
          ? location.province!
          : location.municipalities!.length > 1
              ? '${location.province} • ${location.municipalities!.length} cities'
              : '${location.province} • ${location.municipalities!.first}';
      chips.add(_ActiveChip(
        label: label,
        icon: Icons.location_on,
        onRemove: () => locationNotifier.clear(),
      ),);
    }

    for (final v in attrs.clientTypes ?? []) {
      chips.add(_ActiveChip(label: _label(v), onRemove: () => attrNotifier.toggleClientType(v)));
    }
    for (final v in attrs.marketTypes ?? []) {
      chips.add(_ActiveChip(label: _label(v), onRemove: () => attrNotifier.toggleMarketType(v)));
    }
    for (final v in attrs.pensionTypes ?? []) {
      chips.add(_ActiveChip(label: _label(v), onRemove: () => attrNotifier.togglePensionType(v)));
    }
    for (final v in attrs.productTypes ?? []) {
      chips.add(_ActiveChip(label: _label(v), onRemove: () => attrNotifier.toggleProductType(v)));
    }
    for (final v in attrs.loanTypes ?? []) {
      chips.add(_ActiveChip(label: _label(v), onRemove: () => attrNotifier.toggleLoanType(v)));
    }
    for (final v in attrs.touchpointStatuses ?? []) {
      chips.add(_ActiveChip(
        label: _label(v.replaceAll('_', ' ')),
        icon: Icons.star_outline,
        onRemove: () => attrNotifier.toggleTouchpointStatus(v),
      ),);
    }

    // Touchpoint reason chips (show up to 3)
    for (final reason in (attrs.touchpointReasons ?? []).take(3)) {
      chips.add(_ActiveChip(
        label: _formatReason(reason),
        icon: LucideIcons.messageSquare,
        onRemove: () {
          ref.read(clientAttributeFilterProvider.notifier).toggleTouchpointReason(reason);
        },
      ),);
    }

    // Date range chip
    if (attrs.touchpointDateFrom != null || attrs.touchpointDateTo != null) {
      chips.add(_ActiveChip(
        label: _formatDateRange(attrs.touchpointDateFrom, attrs.touchpointDateTo),
        icon: LucideIcons.calendar,
        onRemove: () {
          ref.read(clientAttributeFilterProvider.notifier).clearDateRange();
        },
      ),);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    if (chips.length >= 2) {
      chips.add(
        TextButton(
          onPressed: () {
            attrNotifier.clear();
            locationNotifier.clear();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
          child: const Text('Clear all', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips
            .map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c))
            .toList(),
      ),
    );
  }

  /// Title-case a DB uppercase string for display (e.g. "BFP ACTIVE" → "BFP Active")
  String _label(String raw) {
    return raw
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatReason(String reason) {
    return reason.split('_').map((w) =>
      w.isEmpty ? w : w[0] + w.substring(1).toLowerCase(),
    ).join(' ');
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (from != null && to != null) {
      final fromDate = DateTime(from.year, from.month, from.day);
      final toDate = DateTime(to.year, to.month, to.day);

      final daysDiff = toDate.difference(fromDate).inDays + 1;

      if (daysDiff == 7 && fromDate == today.subtract(const Duration(days: 6))) {
        return 'Last 7 days';
      }
      if (daysDiff == 30 && fromDate == today.subtract(const Duration(days: 29))) {
        return 'Last 30 days';
      }
      if (daysDiff == 90 && fromDate == today.subtract(const Duration(days: 89))) {
        return 'Last 90 days';
      }

      return '${DateFormat('MMM dd').format(from)} - ${DateFormat('MMM dd').format(to)}';
    }

    if (from != null) {
      return 'From ${DateFormat('MMM dd').format(from)}';
    }
    if (to != null) {
      return 'Until ${DateFormat('MMM dd').format(to)}';
    }

    return 'Any Time';
  }
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onRemove;

  const _ActiveChip({
    required this.label,
    required this.onRemove,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      avatar: icon != null ? Icon(icon, size: 14) : null,
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}
