// lib/shared/widgets/client_filter_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/location_filter.dart';
import '../models/client_attribute_filter.dart';
import '../../features/clients/data/models/client_model.dart';

class ClientFilterChips extends ConsumerWidget {
  final LocationFilter locationFilter;
  final ClientAttributeFilter attributeFilter;
  final Function(FilterType)? onRemove;
  final VoidCallback? onClearAll;

  const ClientFilterChips({
    super.key,
    required this.locationFilter,
    required this.attributeFilter,
    this.onRemove,
    this.onClearAll,
  });

  bool get hasFilters =>
      locationFilter.hasFilter || attributeFilter.hasFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasFilters) {
      return const SizedBox.shrink();
    }

    final chips = <Widget>[];

    // Location filter chips
    if (locationFilter.province != null) {
      chips.add(_FilterChip(
        label: locationFilter.getDisplayLabel(),
        onRemove: onRemove != null
            ? () => onRemove!(FilterType.location)
            : null,
      ));
    }

    // Attribute filter chips
    if (attributeFilter.clientType != null) {
      chips.add(_FilterChip(
        label: attributeFilter.clientType!.name.toUpperCase(),
        onRemove: onRemove != null
            ? () => onRemove!(FilterType.clientType)
            : null,
      ));
    }

    if (attributeFilter.marketType != null) {
      chips.add(_FilterChip(
        label: attributeFilter.marketType!.name[0].toUpperCase() +
            attributeFilter.marketType!.name.substring(1),
        onRemove: onRemove != null
            ? () => onRemove!(FilterType.marketType)
            : null,
      ));
    }

    if (attributeFilter.pensionType != null) {
      chips.add(_FilterChip(
        label: attributeFilter.pensionType!.name.toUpperCase(),
        onRemove: onRemove != null
            ? () => onRemove!(FilterType.pensionType)
            : null,
      ));
    }

    if (attributeFilter.productType != null) {
      final label = _getProductTypeLabel(attributeFilter.productType!);
      chips.add(_FilterChip(
        label: label,
        onRemove: onRemove != null
            ? () => onRemove!(FilterType.productType)
            : null,
      ));
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length + (onClearAll != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index < chips.length) {
            return chips[index];
          }
          // Clear All button
          return TextButton(
            onPressed: onClearAll,
            child: const Text('Clear all'),
          );
        },
      ),
    );
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.sssPensioner:
        return 'SSS Pensioner';
      case ProductType.gsisPensioner:
        return 'GSIS Pensioner';
      case ProductType.private:
        return 'Private';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const _FilterChip({
    required this.label,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(LucideIcons.x, size: 14),
      onDeleted: onRemove,
      backgroundColor: Colors.blue.shade50,
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontSize: 12,
      ),
    );
  }
}

enum FilterType {
  location,
  clientType,
  marketType,
  pensionType,
  productType,
}
