import '../../core/utils/logger.dart';

/// Service to check ownership of resources
///
/// Used to enforce ownership-based access control for non-admin users.
/// Caravan and tele users can only edit their own touchpoints, itineraries, etc.
class OwnershipService {
  OwnershipService._();

  /// Check if a user owns a specific resource
  ///
  /// Returns true if:
  /// - The resource's userId matches the current userId, OR
  /// - The user is an admin or manager (they can edit any resource)
  static bool isOwner({
    required String? resourceUserId,
    required String? currentUserId,
    required String currentUserRole,
  }) {
    // Admin and managers can access any resource
    if (currentUserRole == 'admin' ||
        currentUserRole == 'area_manager' ||
        currentUserRole == 'assistant_area_manager') {
      return true;
    }

    // Caravan and tele users can only access their own resources
    if (resourceUserId == null || currentUserId == null) {
      logDebug('Ownership check failed: missing user IDs');
      return false;
    }

    return resourceUserId == currentUserId;
  }

  /// Check if user can edit a touchpoint
  ///
  /// Caravan/tele users can only edit their own touchpoints.
  /// Admin/managers can edit any touchpoint.
  static bool canEditTouchpoint({
    required String? touchpointUserId,
    required String? currentUserId,
    required String currentUserRole,
  }) {
    return isOwner(
      resourceUserId: touchpointUserId,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
    );
  }

  /// Check if user can edit an itinerary
  ///
  /// Caravan/tele users can only edit their own itineraries.
  /// Admin/managers can edit any itinerary.
  static bool canEditItinerary({
    required String? itineraryUserId,
    required String? currentUserId,
    required String currentUserRole,
  }) {
    return isOwner(
      resourceUserId: itineraryUserId,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
    );
  }

  /// Check if user can edit a client
  ///
  /// Caravan users can only edit their own clients (they created).
  /// Admin/managers can edit any client.
  static bool canEditClient({
    required String? clientCreatedBy,
    required String? currentUserId,
    required String currentUserRole,
  }) {
    return isOwner(
      resourceUserId: clientCreatedBy,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
    );
  }

  /// Filter list of items by ownership
  ///
  /// Returns only items that belong to the user (or all items for admins/managers).
  /// Items must have a 'user_id' or 'userId' field.
  static List<T> filterByOwnership<T extends Map<String, dynamic>>({
    required List<T> items,
    required String? currentUserId,
    required String currentUserRole,
  }) {
    // Admin and managers see all items
    if (currentUserRole == 'admin' ||
        currentUserRole == 'area_manager' ||
        currentUserRole == 'assistant_area_manager') {
      return items;
    }

    // Caravan and tele users only see their own items
    if (currentUserId == null) {
      return [];
    }

    return items.where((item) {
      final userId = item['user_id'] ?? item['userId'];
      return userId == currentUserId;
    }).toList();
  }

  /// Check if user can delete a resource
  ///
  /// Only admins can delete resources.
  /// Caravan/tele users cannot delete.
  static bool canDelete({
    required String currentUserRole,
  }) {
    return currentUserRole == 'admin';
  }

  /// Get ownership error message
  static String getOwnershipError({
    required String resourceType,
    required String currentUserRole,
  }) {
    if (currentUserRole == 'caravan') {
      return 'You can only edit your own $resourceType';
    } else if (currentUserRole == 'tele') {
      return 'You can only edit your own $resourceType';
    } else {
      return 'You do not have permission to edit this $resourceType';
    }
  }
}
