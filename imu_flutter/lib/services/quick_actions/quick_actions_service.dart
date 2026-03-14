import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

/// Quick Actions service for app icon shortcuts (iOS/Android)
/// Note: Quick actions are not supported on web platform
class QuickActionsService {
  static final QuickActionsService _instance = QuickActionsService._internal();
  factory QuickActionsService() => _instance;
  QuickActionsService._internal();

  QuickActions? _quickActions;
  bool _initialized = false;

  /// Callback types for navigation
  void Function(String route)? onActionSelected;

  /// Initialize quick actions
  Future<void> initialize({
    required void Function(String route) onActionSelected,
  }) async {
    if (_initialized) {
      debugPrint('QuickActionsService already initialized');
      return;
    }

    this.onActionSelected = onActionSelected;

    // Skip on web platform - quick_actions plugin doesn't support web
    if (kIsWeb) {
      debugPrint('QuickActionsService: Skipping on web platform (not supported)');
      _initialized = true;
      return;
    }

    _quickActions = const QuickActions();

    // Define quick actions
    await _quickActions!.initialize((String shortcutType) {
      debugPrint('Quick action selected: $shortcutType');
      _handleAction(shortcutType);
    });

    // Set the quick actions
    await _quickActions!.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_client',
        localizedTitle: 'Add Client',
        icon: 'ic_quick_add',
      ),
      const ShortcutItem(
        type: 'action_my_day',
        localizedTitle: 'My Day',
        icon: 'ic_quick_today',
      ),
      const ShortcutItem(
        type: 'action_clients',
        localizedTitle: 'My Clients',
        icon: 'ic_quick_clients',
      ),
    ]);

    _initialized = true;
    debugPrint('QuickActionsService initialized with 3 actions');
  }

  /// Handle quick action selection
  void _handleAction(String shortcutType) {
    final route = _getRouteForAction(shortcutType);
    if (route != null && onActionSelected != null) {
      debugPrint('Navigating to route: $route');
      onActionSelected!(route);
    }
  }

  /// Map action type to route
  String? _getRouteForAction(String shortcutType) {
    switch (shortcutType) {
      case 'action_add_client':
        return '/clients/add';
      case 'action_my_day':
        return '/my-day';
      case 'action_clients':
        return '/clients';
      default:
        debugPrint('Unknown quick action: $shortcutType');
        return null;
    }
  }

  /// Clear quick actions (e.g., on logout)
  Future<void> clearActions() async {
    if (_quickActions == null) {
      debugPrint('Quick actions: Skipped clear (not supported on this platform)');
      return;
    }
    await _quickActions!.setShortcutItems(<ShortcutItem>[]);
    debugPrint('Quick actions cleared');
  }

  /// Update action items (e.g., contextual actions)
  Future<void> updateActions(List<ShortcutItem> items) async {
    if (_quickActions == null) {
      debugPrint('Quick actions: Skipped update (not supported on this platform)');
      return;
    }
    await _quickActions!.setShortcutItems(items);
    debugPrint('Quick actions updated: ${items.length} items');
  }
}

/// Provider for QuickActionsService
final quickActionsServiceProvider = Provider<QuickActionsService>((ref) {
  return QuickActionsService();
});
