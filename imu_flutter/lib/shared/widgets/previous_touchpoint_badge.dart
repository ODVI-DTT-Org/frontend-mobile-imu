import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Previous touchpoint badge widget for displaying last completed touchpoint info
///
/// Shows either:
/// - "Last: Nth Visit/Call" for clients with previous touchpoints
/// - "New Client" for clients with no previous touchpoints
///
/// Used in both My Day and Itinerary list displays.
class PreviousTouchpointBadge extends StatelessWidget {
  /// Last completed touchpoint number (unlimited)
  final int? touchpointNumber;

  /// Last completed touchpoint type (visit/call)
  final String? touchpointType;

  /// Optional custom reason to display
  final String? touchpointReason;

  const PreviousTouchpointBadge({
    super.key,
    this.touchpointNumber,
    this.touchpointType,
    this.touchpointReason,
  });

  static String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _formatTouchpointType() {
    if (touchpointType?.toLowerCase() == 'call') return 'Call';
    return 'Visit';
  }

  @override
  Widget build(BuildContext context) {
    // Show "New Client" badge for clients with no previous touchpoints
    if (touchpointNumber == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'New Client',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    // Show previous touchpoint badge with icon and details
    final isVisit = touchpointType?.toLowerCase() == 'visit';
    final badgeColor = isVisit ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVisit ? LucideIcons.mapPin : LucideIcons.phone,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Last: $touchpointNumber${_getOrdinal(touchpointNumber!)} ${_formatTouchpointType()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}
