// lib/shared/widgets/filters/attribute_filter_chip.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Attribute filter chip widget for displaying active filters on the main screen
/// Used in Option 1: Compact Dropdown Chips design
class AttributeFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemoved;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AttributeFilterChip({
    super.key,
    required this.label,
    required this.onRemoved,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBgColor = backgroundColor ?? theme.colorScheme.primaryContainer;
    final defaultTextColor = textColor ?? theme.colorScheme.onPrimaryContainer;

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: defaultBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: defaultTextColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: defaultTextColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemoved,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: defaultTextColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 14,
                color: defaultTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
