import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';

/// Badge showing last touchpoint status with reason
/// Format: "Reason - Status" or just "Status" if no reason
/// Examples: "Follow-up - Interested", "Completed", "Payment Reminder - Not Interested"
class TouchpointStatusBadge extends StatelessWidget {
  final Client client;

  const TouchpointStatusBadge({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    try {
      if (client.touchpointSummary.isEmpty) {
        return const SizedBox.shrink();
      }

      final lastTouchpoint = client.touchpointSummary.last;
      final reason = lastTouchpoint.reason;
      final status = lastTouchpoint.status;

    // Build label based on reason and status
    String label;
    if (reason != null && status != null) {
      label = '${reason.apiValue} - ${status.apiValue}';
    } else if (reason != null) {
      label = reason.apiValue;
    } else if (status != null) {
      label = status.apiValue;
    } else {
      return const SizedBox.shrink();
    }

    // Get color based on status
    Color badgeColor;
    IconData badgeIcon;

    switch (status) {
      case TouchpointStatus.interested:
        badgeColor = Colors.green;
        badgeIcon = LucideIcons.thumbsUp;
        break;
      case TouchpointStatus.undecided:
        badgeColor = Colors.orange;
        badgeIcon = LucideIcons.helpCircle;
        break;
      case TouchpointStatus.notInterested:
        badgeColor = Colors.red;
        badgeIcon = LucideIcons.thumbsDown;
        break;
      case TouchpointStatus.completed:
        badgeColor = Colors.blue;
        badgeIcon = LucideIcons.checkCircle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      // BUG FIX: Catch any errors parsing touchpoint data and return empty widget
      debugPrint('[TouchpointStatusBadge] Error rendering badge for client ${client.id}: $e');
      return const SizedBox.shrink();
    }
  }
}
