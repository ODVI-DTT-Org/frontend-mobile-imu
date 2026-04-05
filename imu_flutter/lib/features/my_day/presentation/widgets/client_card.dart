import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/widgets/previous_touchpoint_badge.dart';
import '../../data/models/my_day_client.dart';

/// Client card widget for My Day list
/// Displays client info with previous touchpoint details
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection checkmark indicator and Previous touchpoint badge row
            Row(
              children: [
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
                PreviousTouchpointBadge(
                  touchpointNumber: client.previousTouchpointNumber,
                  touchpointType: client.previousTouchpointType,
                  touchpointReason: client.previousTouchpointReason,
                ),
                const Spacer(),
                if (client.previousTouchpointDate != null)
                  Text(
                    DateFormat('MMM d').format(client.previousTouchpointDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Client name
            Text(
              client.fullName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            // Previous reason
            if (client.previousTouchpointReason != null && client.previousTouchpointReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                client.previousTouchpointReason!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Notes
            if (client.notes != null && client.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    LucideIcons.stickyNote,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Location (optional, below notes)
            if (client.location != null && client.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.location!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
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
