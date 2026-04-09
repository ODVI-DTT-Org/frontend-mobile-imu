import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;
import 'package:imu_flutter/features/clients/data/models/phone_number_model.dart';

/// List tile widget for displaying a phone number in a list
/// Shows label, formatted number, and primary badge with action buttons
class PhoneNumberListTile extends StatelessWidget {
  final PhoneNumber phone;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final bool showActions;

  const PhoneNumberListTile({
    super.key,
    required this.phone,
    this.isPrimary = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetPrimary,
    this.onCall,
    this.onMessage,
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
            child: Row(
              children: [
                // Phone Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPhoneIcon(phone.label),
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),

                const SizedBox(width: 12),

                // Phone Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row with number and badges
                      Row(
                        children: [
                          Text(
                            phone.displayNumber,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (phone.label != PhoneLabel.mobile) ...[
                            const SizedBox(width: 8),
                            _buildLabelBadge(context, phone.label.displayName),
                          ],
                          if (isPrimary) ...[
                            const SizedBox(width: 8),
                            _buildPrimaryBadge(context),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (showActions) ...[
                  if (onCall != null)
                    _buildActionButton(
                      context,
                      icon: LucideIcons.phone,
                      tooltip: 'Call',
                      onPressed: onCall,
                    ),
                  if (onMessage != null)
                    _buildActionButton(
                      context,
                      icon: LucideIcons.messageSquare,
                      tooltip: 'Message',
                      onPressed: onMessage,
                    ),
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

  IconData _getPhoneIcon(PhoneLabel label) {
    switch (label) {
      case PhoneLabel.mobile:
        return LucideIcons.smartphone;
      case PhoneLabel.home:
        return LucideIcons.phone;
      case PhoneLabel.work:
        return LucideIcons.phoneCall;
    }
  }
}
