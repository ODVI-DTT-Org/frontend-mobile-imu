import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';

/// Reusable client list tile with enhanced details display
///
/// Shows:
/// - Client name
/// - Location/address
/// - Touchpoint summary (e.g., "3rd Call - 2 days ago")
/// - Touchpoint reason
/// - "NEW" badge for first-time clients
/// - Star indicator for starred clients
class ClientListTile extends StatelessWidget {
  final Client client;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStar;
  final bool showNewBadge;
  final bool showTouchpointSummary;
  final bool showLocation;

  const ClientListTile({
    super.key,
    required this.client,
    this.onTap,
    this.trailing,
    this.showStar = true,
    this.showNewBadge = true,
    this.showTouchpointSummary = true,
    this.showLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFirstTime = client.touchpoints.isEmpty;
    final lastTouchpoint = client.touchpoints.isNotEmpty
        ? client.touchpoints.last
        : null;
    final primaryAddress = client.addresses.isNotEmpty
        ? client.addresses.firstWhere(
            (a) => a.isPrimary,
            orElse: () => client.addresses.first,
          )
        : null;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: _buildLeading(context, isFirstTime),
      title: _buildTitle(context, isFirstTime),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLocation && primaryAddress != null)
            _buildLocation(primaryAddress),
          if (showTouchpointSummary && lastTouchpoint != null)
            _buildTouchpointSummary(lastTouchpoint),
          if (showTouchpointSummary && lastTouchpoint != null)
            _buildTouchpointReason(lastTouchpoint),
        ],
      ),
      trailing: trailing ??
          (showStar && client.isStarred
              ? const Icon(Icons.star, color: Colors.amber, size: 20)
              : null),
    );
  }

  Widget _buildLeading(BuildContext context, bool isFirstTime) {
    final initials = _getInitials();
    final bgColor = isFirstTime
        ? Colors.green.shade100
        : const Color(0xFF0F172A).withOpacity(0.1);

    return CircleAvatar(
      backgroundColor: bgColor,
      child: Text(
        initials,
        style: TextStyle(
          color: isFirstTime ? Colors.green.shade700 : const Color(0xFF0F172A),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, bool isFirstTime) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            client.fullName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showNewBadge && isFirstTime) ...[
          const SizedBox(width: 4),
          _NewBadge(),
        ],
        if (showStar && client.isStarred && trailing == null) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.star,
            size: 14,
            color: Colors.amber.shade700,
          ),
        ],
      ],
    );
  }

  Widget _buildLocation(Address address) {
    final locationText = [
      if (address.barangay != null) address.barangay,
      if (address.city.isNotEmpty) address.city,
      if (address.province != null) address.province,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(
            LucideIcons.mapPin,
            size: 14,
            color: Color(0xFF0F172A),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              locationText.isNotEmpty ? locationText : 'No location',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpointSummary(Touchpoint touchpoint) {
    final summary = _getTouchpointSummary(touchpoint);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            touchpoint.type == TouchpointType.visit
                ? LucideIcons.mapPin
                : LucideIcons.phone,
            size: 14,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpointReason(Touchpoint touchpoint) {
    // TouchpointReason is an enum, check if null
    if (touchpoint.reason == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          const Icon(
            LucideIcons.messageCircle,
            size: 14,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              touchpoint.reason.apiValue, // Use apiValue for display
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final firstNameInitial = client.firstName.isNotEmpty
        ? client.firstName[0].toUpperCase()
        : '';
    final lastNameInitial = client.lastName.isNotEmpty
        ? client.lastName[0].toUpperCase()
        : '';
    return '$firstNameInitial$lastNameInitial';
  }

  String _getTouchpointSummary(Touchpoint touchpoint) {
    final ordinal = _getOrdinal(touchpoint.touchpointNumber);
    final type = touchpoint.type == TouchpointType.visit ? 'Visit' : 'Call';
    final timeAgo = _getTimeAgo(touchpoint.date);
    return '${touchpoint.touchpointNumber}$ordinal $type - $timeAgo';
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return 'th';
    }
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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes <= 1 ? 'just now' : '$minutes min ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'last week' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'last month' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? 'last year' : '$years years ago';
    }
  }
}

class _NewBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
