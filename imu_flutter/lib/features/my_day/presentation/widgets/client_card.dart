import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../data/models/my_day_client.dart';

/// Priority badge widget for displaying visit priority
class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444); // Red
      case 'normal':
        return const Color(0xFF3B82F6); // Blue
      case 'low':
        return const Color(0xFF64748B); // Slate
      default:
        return Colors.grey;
    }
  }

  String _formatPriority() {
    switch (priority.toLowerCase()) {
      case 'high':
        return 'HIGH';
      case 'normal':
        return 'NORMAL';
      case 'low':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _getPriorityColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _formatPriority(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: _getPriorityColor(),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Simplified client card widget for My Day list
/// Displays client info with map pin icon, touchpoint badge, and navigation chevron
/// Includes swipe-to-dismiss functionality for removing from My Day
/// Supports multi-select mode with long press and visual feedback
class ClientCard extends StatelessWidget {
  final MyDayClient client;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isMultiSelectMode;

  const ClientCard({
    super.key,
    required this.client,
    this.onTap,
    this.onRemove,
    this.onLongPress,
    this.isSelected = false,
    this.isMultiSelectMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTap?.call();
      },
      onLongPress: () {
        HapticUtils.mediumImpact();
        onLongPress?.call();
      },
      onDoubleTap: () {
        // Explicitly ignore double tap - do nothing
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection checkmark indicator (shown in multi-select mode when selected)
            if (isMultiSelectMode)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.check,
                  size: 14,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            if (isMultiSelectMode) const SizedBox(width: 12),
            // Map pin icon container
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Touchpoint badge and Priority badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (client.touchpointNumber > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      client.touchpointOrdinal,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                _PriorityBadge(priority: client.priority),
              ],
            ),
            const SizedBox(width: 8),
            // Client name, location, and notes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    client.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (client.location != null && client.location!.isNotEmpty)
                    Text(
                      client.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (client.notes != null && client.notes!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      client.notes!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron navigation icon
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );

    // Only enable swipe-to-dismiss when NOT in multi-select mode
    if (isMultiSelectMode) {
      return cardContent;
    }

    return Dismissible(
      key: Key('client_${client.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        HapticUtils.mediumImpact();
        onRemove?.call();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              LucideIcons.trash2,
              color: Colors.white,
            ),
          ],
        ),
      ),
      child: cardContent,
    );
  }
}
