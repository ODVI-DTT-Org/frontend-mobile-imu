import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/address_model.dart';

/// List tile widget for displaying an address in a list
/// Shows label, full address, and primary badge with action buttons
class AddressListTile extends StatelessWidget {
  final Address address;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;
  final bool showActions;

  const AddressListTile({
    super.key,
    required this.address,
    this.isPrimary = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetPrimary,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPrimary
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: isPrimary ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with label and badges
                Row(
                  children: [
                    if (address.label != AddressLabel.home)
                      _buildLabelBadge(context, address.label.displayName),
                    if (isPrimary) ...[
                      if (address.label != AddressLabel.home) const SizedBox(width: 8),
                      _buildPrimaryBadge(context),
                    ],
                    const Spacer(),
                    if (showActions) ...[
                      if (!isPrimary && onSetPrimary != null)
                        _buildActionButton(
                          context,
                          icon: LucideIcons.star,
                          tooltip: 'Set as Primary',
                          onPressed: onSetPrimary,
                        ),
                      if (onEdit != null)
                        _buildActionButton(
                          context,
                          icon: LucideIcons.pencil,
                          tooltip: 'Edit',
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        _buildActionButton(
                          context,
                          icon: LucideIcons.trash2,
                          tooltip: 'Delete',
                          onPressed: onDelete,
                          isDestructive: true,
                        ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // Street Address
                if (address.streetAddress != null && address.streetAddress!.isNotEmpty)
                  Text(
                    address.streetAddress!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                if (address.streetAddress != null && address.streetAddress!.isNotEmpty)
                  const SizedBox(height: 4),

                // Full Address (PSGC data)
                Text(
                  address.fullAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                // Postal Code
                if (address.postalCode != null && address.postalCode!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    address.postalCode!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                // Coordinates (if available)
                if (address.latitude != null && address.longitude != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.map,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${address.latitude!.toStringAsFixed(6)}, ${address.longitude!.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelBadge(BuildContext context, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPrimaryBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.star,
            size: 12,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Primary',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
