import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Polished empty state widget for displaying when content is unavailable.
///
/// Features:
/// - Large icon with brand color
/// - Title and message
/// - Optional action button
/// - Consistent styling across the app
///
/// Usage:
/// ```dart
/// EmptyState(
///   icon: LucideIcons.inbox,
///   title: 'No Activity',
///   message: 'There are no activities to display for this period.',
///   action: EmptyStateAction(
///     label: 'Refresh',
///     onPressed: () => refresh(),
///   ),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final EmptyStateAction? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? const Color(0xFF94A3B8);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: effectiveIconColor,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button (if provided)
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Action button for empty state.
class EmptyStateAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  const EmptyStateAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        side: BorderSide(color: Colors.grey.shade300),
        minimumSize: const Size(120, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}

/// Pre-configured empty states for common scenarios.
class EmptyStates {
  /// Empty state for no items/records.
  static const noItems = EmptyState(
    icon: LucideIcons.inbox,
    title: 'No Items Found',
    message: 'There are no items to display at the moment.',
  );

  /// Empty state for search with no results.
  static const noSearchResults = EmptyState(
    icon: LucideIcons.search,
    title: 'No Results Found',
    message: 'Try adjusting your search or filters to find what you\'re looking for.',
  );

  /// Empty state for network error.
  static const networkError = EmptyState(
    icon: LucideIcons.wifiOff,
    title: 'Connection Error',
    message: 'Unable to load content. Please check your internet connection.',
  );

  /// Empty state for generic error.
  static const error = EmptyState(
    icon: LucideIcons.alertCircle,
    title: 'Something Went Wrong',
    message: 'An error occurred while loading the content. Please try again.',
  );

  /// Empty state for no favorites.
  static const noFavorites = EmptyState(
    icon: LucideIcons.star,
    title: 'No Favorites',
    message: 'You haven\'t added any items to your favorites yet.',
  );

  /// Empty state for no activity.
  static const noActivity = EmptyState(
    icon: LucideIcons.activity,
    title: 'No Activity',
    message: 'There are no activities to display for this period.',
  );

  /// Empty state for no clients.
  static const noClients = EmptyState(
    icon: LucideIcons.users,
    title: 'No Clients',
    message: 'No clients found. Try adjusting your filters or add a new client.',
  );

  /// Empty state for no itinerary.
  static const noItinerary = EmptyState(
    icon: LucideIcons.calendar,
    title: 'No Scheduled Visits',
    message: 'You don\'t have any visits scheduled for this day.',
  );

  /// Empty state for no notifications.
  static const noNotifications = EmptyState(
    icon: LucideIcons.bell,
    title: 'No Notifications',
    message: 'You\'re all caught up! No new notifications to show.',
  );

  /// Empty state for no touchpoints.
  static const noTouchpoints = EmptyState(
    icon: LucideIcons.mapPin,
    title: 'No Touchpoints',
    message: 'No touchpoints recorded yet. Start by adding your first touchpoint.',
  );
}
