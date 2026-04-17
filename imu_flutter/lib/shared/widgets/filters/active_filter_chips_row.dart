import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../shared/providers/client_attribute_filter_provider.dart';
import '../../../shared/providers/location_filter_providers.dart';
import '../filters/client_attribute_filter_helpers.dart';

class ActiveFilterChipsRow extends ConsumerWidget {
  const ActiveFilterChipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationFilterProvider);
    final attrs = ref.watch(clientAttributeFilterProvider);
    final attrNotifier = ref.read(clientAttributeFilterProvider.notifier);
    final locationNotifier = ref.read(locationFilterProvider.notifier);

    final chips = <Widget>[];

    // Location chip
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
      ));
    }

    // Attribute chips
    for (final t in attrs.clientTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatClientType(t),
        onRemove: () => attrNotifier.toggleClientType(t),
      ));
    }
    for (final t in attrs.marketTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatMarketType(t),
        onRemove: () => attrNotifier.toggleMarketType(t),
      ));
    }
    for (final t in attrs.pensionTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatPensionType(t),
        onRemove: () => attrNotifier.togglePensionType(t),
      ));
    }
    for (final t in attrs.productTypes ?? []) {
      chips.add(_ActiveChip(
        label: formatProductType(t),
        onRemove: () => attrNotifier.toggleProductType(t),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    if (chips.length >= 3) {
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
