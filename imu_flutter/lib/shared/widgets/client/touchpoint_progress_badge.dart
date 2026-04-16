import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';

/// Badge showing touchpoint progress in format "X/7 • Type"
/// Examples: "2/7 • Call", "3/7 • Visit", "7/7 • Completed"
class TouchpointProgressBadge extends StatelessWidget {
  final Client client;
  final bool showCompletedLabel;
  final int? touchpointCount;  // NEW: Optional pre-fetched count

  const TouchpointProgressBadge({
    super.key,
    required this.client,
    this.showCompletedLabel = true,
    this.touchpointCount,  // NEW
  });

  /// Internal getter that uses provided count or falls back to client.completedTouchpoints
  int get _displayedCount => touchpointCount ?? client.completedTouchpoints;

  /// Calculate next touchpoint type based on displayed count
  TouchpointType? get _nextTouchpointType {
    final next = _displayedCount;
    if (next >= 7) return null;
    return TouchpointPattern.types[next];
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _displayedCount;
    final totalCount = 7;

    // All touchpoints completed
    if (completedCount >= totalCount) {
      if (!showCompletedLabel) return const SizedBox.shrink();
      return _buildBadge(
        label: 'Completed',
        color: Colors.green,
        icon: LucideIcons.checkCircle,
        context: context,
      );
    }

    // Get next touchpoint type
    final nextType = _nextTouchpointType;

    return _buildBadge(
      label: '$completedCount/$totalCount • ${nextType?.name ?? 'Touchpoint'}',
      color: nextType == TouchpointType.call
          ? Colors.orange
          : Colors.blue,
      icon: nextType == TouchpointType.call
          ? LucideIcons.phone
          : LucideIcons.mapPin,
      context: context,
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
