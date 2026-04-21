import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';

/// Badge showing touchpoint progress in format "X • Type"
/// Examples: "2 • Call", "3 • Visit", "10 • Visit"
/// No limit on number of touchpoints - shows actual count
class TouchpointProgressBadge extends StatelessWidget {
  final Client client;
  final bool showCompletedLabel;
  final int? touchpointCount;

  const TouchpointProgressBadge({
    super.key,
    required this.client,
    this.showCompletedLabel = true,
    this.touchpointCount,
  });

  /// Internal getter that uses provided count or falls back to client.completedTouchpoints
  int get _displayedCount => touchpointCount ?? client.completedTouchpoints;

  @override
  Widget build(BuildContext context) {
    final completedCount = _displayedCount;

    // Use client's nextTouchpoint field directly (no pattern enforcement)
    final nextTouchpoint = client.nextTouchpoint;

    if (nextTouchpoint != null) {
      final isCall = nextTouchpoint.toLowerCase() == 'call';
      return _buildBadge(
        label: '$completedCount • ${nextTouchpoint.toLowerCase()}',
        color: isCall
            ? Colors.orange
            : Colors.blue,
        icon: isCall
            ? LucideIcons.phone
            : LucideIcons.mapPin,
        context: context,
      );
    }

    // Fallback: just show count without type
    return _buildBadge(
      label: '$completedCount',
      color: Colors.blue,
      icon: LucideIcons.mapPin,
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
