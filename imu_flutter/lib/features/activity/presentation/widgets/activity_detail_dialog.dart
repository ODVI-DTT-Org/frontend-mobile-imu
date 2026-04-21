import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

class ActivityDetailDialog extends StatelessWidget {
  final ActivityItem item;

  const ActivityDetailDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, {required ActivityItem item}) {
    return showDialog(
      context: context,
      builder: (context) => ActivityDetailDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 24, color: item.statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(height: 24),

            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: item.statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(item.status),
                        size: 14,
                        color: item.statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (item.clientName != null) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: LucideIcons.user,
                label: 'Client',
                value: item.clientName!,
              ),
            ],

            if (item.detail != null && item.detail!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailRow(
                icon: LucideIcons.alignLeft,
                label: 'Details',
                value: item.detail!,
              ),
            ],

            // Activity type info
            const SizedBox(height: 16),
            _DetailRow(
              icon: LucideIcons.tag,
              label: 'Type',
              value: _getTypeLabel(item.type),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dt);
  }

  IconData _getStatusIcon(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.pending:
        return LucideIcons.clock;
      case ActivityStatus.syncing:
        return LucideIcons.refreshCw;
      case ActivityStatus.completed:
      case ActivityStatus.approved:
        return LucideIcons.checkCircle;
      case ActivityStatus.rejected:
      case ActivityStatus.failed:
        return LucideIcons.xCircle;
    }
  }

  String _getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.approval:
        return 'Approval';
      case ActivityType.touchpoint:
        return 'Touchpoint';
      case ActivityType.visit:
        return 'Visit';
      case ActivityType.call:
        return 'Call';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
