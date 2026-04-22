import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../core/models/user_role.dart';
import '../../../models/client_status.dart';

/// Badge showing client's overall status for itinerary purposes
/// Shows one of: "Already added", "Visited today", "Call Touchpoint", "Loan Released"
class ClientStatusBadge extends StatelessWidget {
  final Client client;
  final ClientStatus? status;
  final UserRole? currentUserRole;
  final bool wasVisitedToday;

  const ClientStatusBadge({
    super.key,
    required this.client,
    this.status,
    this.currentUserRole,
    this.wasVisitedToday = false,
  });

  @override
  Widget build(BuildContext context) {
    // Check if client was visited today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if last touchpoint was today
    bool visitedToday = false;
    if (client.touchpointSummary.isNotEmpty && client.touchpointSummary.length > 0) {
      try {
        final lastTouchpoint = client.touchpointSummary.last;
        final lastTouchpointDate = DateTime(
          lastTouchpoint.date.year,
          lastTouchpoint.date.month,
          lastTouchpoint.date.day,
        );
        visitedToday = lastTouchpointDate.isAtSameMomentAs(today);
      } catch (e) {
        // If there's an error accessing the touchpoint, assume not visited today
        debugPrint('ClientStatusBadge: Error checking touchpoint date - $e');
        visitedToday = false;
      }
    }

    // Priority 1: Loan released
    if (client.loanReleased) {
      return _buildBadge(
        label: 'Loan Released',
        color: Colors.red,
        icon: LucideIcons.ban,
      );
    }

    // Priority 2: Visited today
    if (visitedToday || wasVisitedToday) {
      return _buildBadge(
        label: 'Visited today',
        color: Colors.green,
        icon: LucideIcons.checkCircle,
      );
    }

    // Priority 3: Already in itinerary
    if (status?.inItinerary == true) {
      return _buildBadge(
        label: 'Already added',
        color: Colors.orange,
        icon: LucideIcons.calendarCheck,
      );
    }

    // Priority 4: Call Touchpoint (for Caravan users only)
    if (currentUserRole == UserRole.caravan) {
      // Show Call badge if there's a next touchpoint and it's a call type
      if (client.nextTouchpoint != null) {
        final nextType = client.nextTouchpoint?.toLowerCase();
        if (nextType == 'call') {
          return _buildBadge(
            label: 'Call Touchpoint',
            color: Colors.orange,
            icon: LucideIcons.phone,
          );
        }
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData icon,
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
