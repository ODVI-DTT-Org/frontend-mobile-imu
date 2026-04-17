import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../clients/data/models/client_model.dart';

/// Touchpoint History Expansion Panel
/// Displays the 7-step touchpoint sequence with status indicators
class TouchpointHistoryExpansionPanel extends StatelessWidget {
  final Client client;
  final List<Touchpoint> touchpoints;

  const TouchpointHistoryExpansionPanel({
    super.key,
    required this.client,
    required this.touchpoints,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'TOUCHPOINT HISTORY',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        '7 steps',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7-STEP TOUCHPOINT SEQUENCE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(7, (index) => _buildTouchpointTile(index + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTouchpointTile(int touchpointNumber) {
    final touchpoint = touchpoints.cast<Touchpoint?>().firstWhere(
          (tp) => tp?.touchpointNumber == touchpointNumber,
          orElse: () => null,
        );

    final type = _getExpectedType(touchpointNumber);
    final status = _getTouchpointStatus(touchpoint);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'TP$touchpointNumber: ${type.name}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (touchpoint != null) ...[
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(touchpoint!.date)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            if (touchpoint.userId != null)
              Text(
                'Agent: ${touchpoint.userId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            if (touchpoint.status != null)
              Text(
                'Status: ${touchpoint.status?.name ?? '—'}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
          ] else if (status == 'Pending') ...[
            const SizedBox(height: 4),
            Text(
              'Scheduled: ${_getScheduledDate(touchpointNumber)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  TouchpointType _getExpectedType(int number) {
    // Touchpoint sequence pattern: Visit → Call → Call → Visit → Call → Call → Visit
    switch (number) {
      case 1:
      case 4:
      case 7:
        return TouchpointType.visit;
      case 2:
      case 3:
      case 5:
      case 6:
        return TouchpointType.call;
      default:
        return TouchpointType.visit;
    }
  }

  String _getTouchpointStatus(Touchpoint? touchpoint) {
    if (touchpoint == null) {
      // Check if this is the next pending touchpoint
      if (client.nextTouchpointNumber != null &&
          touchpoints.length < client.nextTouchpointNumber!) {
        return 'Pending';
      }
      return 'Not Started';
    }
    return 'Completed';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return LucideIcons.checkCircle;
      case 'Pending':
        return LucideIcons.clock;
      default:
        return LucideIcons.circle;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getScheduledDate(int touchpointNumber) {
    // Calculate expected date based on previous touchpoint dates
    // This is a simplified calculation - you may want to enhance this
    final lastTouchpoint = touchpoints.isNotEmpty ? touchpoints.last : null;
    if (lastTouchpoint != null) {
      final scheduledDate = lastTouchpoint.date.add(const Duration(days: 7));
      return '${scheduledDate.month}/${scheduledDate.day}/${scheduledDate.year}';
    }
    return 'TBD';
  }
}
