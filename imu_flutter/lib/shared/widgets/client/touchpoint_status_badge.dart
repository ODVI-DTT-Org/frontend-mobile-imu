import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../core/utils/logger.dart';

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
      final label = _getLabel(reason, status);
      if (label.isEmpty) {
        return const SizedBox.shrink();
      }

      // Get color based on status
      final badgeColor = _getColor(status);
      final badgeIcon = _getIcon(status);

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
    } catch (e, stackTrace) {
      // Error handling: Log and return empty widget
      logError(
        '[TouchpointStatusBadge] Error rendering badge for client ${client.id}',
        e,
        stackTrace,
      );
      return const SizedBox.shrink();
    }
  }

  /// Get display label based on reason and status.
  String _getLabel(TouchpointReason? reason, TouchpointStatus? status) {
    if (reason != null && status != null) {
      return '${reason.apiValue} - ${status.apiValue}';
    }
    if (reason != null) {
      return reason.apiValue;
    }
    if (status != null) {
      return status.apiValue;
    }
    return '';
  }

  /// Get badge color based on status.
  Color _getColor(TouchpointStatus? status) {
    switch (status) {
      case TouchpointStatus.interested:
        return Colors.green;
      case TouchpointStatus.undecided:
        return Colors.orange;
      case TouchpointStatus.notInterested:
        return Colors.red;
      case TouchpointStatus.completed:
        return Colors.blue;
      case TouchpointStatus.followUpNeeded:
        return Colors.purple;
      case TouchpointStatus.incomplete:
        return Colors.grey;
      case null:
        return Colors.grey;
    }
  }

  /// Get badge icon based on status.
  IconData _getIcon(TouchpointStatus? status) {
    switch (status) {
      case TouchpointStatus.interested:
        return LucideIcons.thumbsUp;
      case TouchpointStatus.undecided:
        return LucideIcons.helpCircle;
      case TouchpointStatus.notInterested:
        return LucideIcons.thumbsDown;
      case TouchpointStatus.completed:
        return LucideIcons.checkCircle;
      case TouchpointStatus.followUpNeeded:
        return LucideIcons.refreshCw;
      case TouchpointStatus.incomplete:
        return LucideIcons.clock;
      case null:
        return LucideIcons.helpCircle;
    }
  }
}
