import 'package:flutter/material.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';

class ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 18, color: item.statusColor),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + timestamp row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Text(
                        item.formattedTime,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),

                  // Client name
                  if (item.clientName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.clientName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],

                  // Detail line
                  if (item.detail != null && item.detail!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.detail!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Status badge
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item.statusColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
