import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../features/clients/data/models/touchpoint_validation_model.dart';
import 'touchpoint_progress_badge.dart';
import 'touchpoint_status_badge.dart';
import 'client_status_badge.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../shared/providers/app_providers.dart' show currentUserRoleProvider;
import '../../../services/api/itinerary_api_service.dart';

/// Reusable client card widget for My Day and Itinerary pages.
///
/// Provides consistent client display with multi-select support,
/// matching the design of the Clients page reference implementation.
///
/// Can work with both Client model and MyDayClient through override parameters.
class ClientListCard extends ConsumerWidget {
  final Client client;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;
  final bool isSelected;
  final bool isMultiSelectMode;
  final bool enableSwipeToDismiss;
  final bool showInMyDayBadge;
  final int? touchpointCount;
  final String? scheduledDate;

  // Override parameters for MyDayClient compatibility
  final String? overrideFullName;
  final String? overrideFullAddress;
  final List<Touchpoint>? overrideTouchpoints;
  final bool? overrideLoanReleased;
  final String? overrideUdi;

  const ClientListCard({
    super.key,
    required this.client,
    this.onTap,
    this.onLongPress,
    this.onRemove,
    this.isSelected = false,
    this.isMultiSelectMode = false,
    this.enableSwipeToDismiss = false,
    this.showInMyDayBadge = false,
    this.touchpointCount,
    this.scheduledDate,
    this.overrideFullName,
    this.overrideFullAddress,
    this.overrideTouchpoints,
    this.overrideLoanReleased,
    this.overrideUdi,
  });

  /// Factory constructor for MyDayClient compatibility
  factory ClientListCard.fromMyDayClient({
    required dynamic myDayClient,
    required String clientId,
    required String fullName,
    required String? location,
    int? touchpointNumber,
    String? touchpointType,
    int? previousTouchpointNumber,
    String? previousTouchpointReason,
    String? previousTouchpointType,
    DateTime? previousTouchpointDate,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onRemove,
    bool isSelected = false,
    bool isMultiSelectMode = false,
    bool enableSwipeToDismiss = true,
    bool showInMyDayBadge = true,
    int? touchpointCount,
    String? scheduledDate,
  }) {
    // Create a minimal Client object with required fields
    final client = Client(
      id: clientId,
      firstName: '', // Will be overridden
      middleName: null,
      lastName: '', // Will be overridden
      clientType: ClientType.existing,
      productType: ProductType.bfpActive,
      pensionType: PensionType.private,
      createdAt: DateTime.now(),
    );

    // Create synthetic touchpoints list if previous touchpoint exists
    List<Touchpoint>? syntheticTouchpoints;
    if (previousTouchpointNumber != null) {
      syntheticTouchpoints = [
        Touchpoint(
          id: '',
          clientId: clientId,
          touchpointNumber: previousTouchpointNumber!,
          type: touchpointType?.toLowerCase() == 'visit'
              ? TouchpointType.visit
              : TouchpointType.call,
          date: previousTouchpointDate ?? DateTime.now(),
          reason: TouchpointReason.interested, // Default reason
          status: TouchpointStatus.interested,
          createdAt: DateTime.now(),
        ),
      ];
    }

    return ClientListCard(
      client: client,
      onTap: onTap,
      onLongPress: onLongPress,
      onRemove: onRemove,
      isSelected: isSelected,
      isMultiSelectMode: isMultiSelectMode,
      enableSwipeToDismiss: enableSwipeToDismiss,
      showInMyDayBadge: showInMyDayBadge,
      touchpointCount: touchpointCount,
      scheduledDate: scheduledDate,
      overrideFullName: fullName,
      overrideFullAddress: location,
      overrideTouchpoints: syntheticTouchpoints,
      overrideLoanReleased: false,
      overrideUdi: null,
    );
  }

  /// Factory constructor for ItineraryItem compatibility
  factory ClientListCard.fromItineraryItem({
    required ItineraryItem itineraryItem,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onRemove,
    bool isSelected = false,
    bool isMultiSelectMode = false,
    bool enableSwipeToDismiss = false,
    bool showInMyDayBadge = false,
    int? touchpointCount,
    String? scheduledDate,
  }) {
    // Create a minimal Client object with required fields
    final client = Client(
      id: itineraryItem.clientId,
      firstName: '', // Will be overridden
      middleName: null,
      lastName: '', // Will be overridden
      clientType: ClientType.existing,
      productType: ProductType.bfpActive,
      pensionType: PensionType.private,
      createdAt: DateTime.now(),
    );

    // Create synthetic touchpoints list
    // Priority: previous touchpoint > next touchpoint > empty
    List<Touchpoint>? syntheticTouchpoints;
    if (itineraryItem.previousTouchpointNumber != null) {
      // Show previous completed touchpoint
      syntheticTouchpoints = [
        Touchpoint(
          id: '',
          clientId: itineraryItem.clientId,
          touchpointNumber: itineraryItem.previousTouchpointNumber!,
          type: itineraryItem.previousTouchpointType?.toLowerCase() == 'visit'
              ? TouchpointType.visit
              : TouchpointType.call,
          date: itineraryItem.previousTouchpointDate ?? DateTime.now(),
          reason: TouchpointReason.interested, // Default reason
          status: TouchpointStatus.interested,
          createdAt: DateTime.now(),
        ),
      ];
    } else if (itineraryItem.touchpointNumber != null) {
      // Show next touchpoint to record (for first-time clients)
      syntheticTouchpoints = [
        Touchpoint(
          id: '',
          clientId: itineraryItem.clientId,
          touchpointNumber: itineraryItem.touchpointNumber!,
          type: itineraryItem.touchpointType?.toLowerCase() == 'visit'
              ? TouchpointType.visit
              : TouchpointType.call,
          date: DateTime.now(),
          reason: TouchpointReason.interested,
          status: TouchpointStatus.interested,
          createdAt: DateTime.now(),
        ),
      ];
    }

    return ClientListCard(
      client: client,
      onTap: onTap,
      onLongPress: onLongPress,
      onRemove: onRemove,
      isSelected: isSelected,
      isMultiSelectMode: isMultiSelectMode,
      enableSwipeToDismiss: enableSwipeToDismiss,
      showInMyDayBadge: showInMyDayBadge,
      touchpointCount: touchpointCount,
      scheduledDate: scheduledDate ?? DateFormat('MMM d, yyyy').format(itineraryItem.scheduledDate),
      overrideFullName: itineraryItem.clientName,
      overrideFullAddress: itineraryItem.address,
      overrideTouchpoints: syntheticTouchpoints,
      overrideLoanReleased: false,
      overrideUdi: null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use override parameters if provided, otherwise use client properties
    final effectiveFullName = overrideFullName ?? client.fullName;
    final effectiveFullAddress = overrideFullAddress ?? client.fullAddress;
    final effectiveTouchpoints = overrideTouchpoints ?? client.touchpointSummary;
    final effectiveLoanReleased = overrideLoanReleased ?? client.loanReleased;
    final effectiveUdi = overrideUdi ?? client.udi;

    final latestTouchpoint = effectiveTouchpoints.isNotEmpty
        ? effectiveTouchpoints.last
        : null;
    final isFirstTime = effectiveTouchpoints.isEmpty;

    // Check if client is in today's itinerary
    final todayItineraryAsync = ref.watch(todayItineraryProvider);
    final today = DateTime.now();

    bool isInMyDay = false;
    todayItineraryAsync.when(
      data: (items) {
        isInMyDay = items.any((item) =>
          item.clientId == client.id &&
          item.scheduledDate.year == today.year &&
          item.scheduledDate.month == today.month &&
          item.scheduledDate.day == today.day
        );
      },
      loading: () => isInMyDay = false,
      error: (_, __) => isInMyDay = false,
    );

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFEFF6FF)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Multi-select checkbox overlay
          if (isMultiSelectMode) ...[
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isSelected
                        ? LucideIcons.checkSquare
                        : LucideIcons.square,
                    size: 18,
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ],

          // Card content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap != null
                  ? () {
                      HapticUtils.lightImpact();
                      onTap!();
                    }
                  : null,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.only(
                  left: isMultiSelectMode ? 36 : 16,
                  right: 16,
                  top: 16,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: badge + name + status
                    Row(
                      children: [
                        // Touchpoint badge or NEW badge
                        if (isFirstTime) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ] else if (latestTouchpoint != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              latestTouchpoint.ordinal,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Client name with optional "In My Day" badge
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  effectiveFullName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showInMyDayBadge && isInMyDay)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.check,
                                        size: 10,
                                        color: const Color(0xFF22C55E),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'In My Day',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF22C55E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Chevron
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Touchpoint progress and status badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: [
                        TouchpointProgressBadge(
                          client: client,
                          touchpointCount: touchpointCount,
                        ),
                        TouchpointStatusBadge(client: client),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Loan Released badge (if applicable)
                    if (effectiveLoanReleased && effectiveUdi != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.dollarSign,
                              size: 11,
                              color: const Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Loan Released: $effectiveUdi',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Address row
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            effectiveFullAddress ?? 'No address',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Touchpoint summary (if not first time)
                    if (!isFirstTime && latestTouchpoint != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            latestTouchpoint.type == TouchpointType.visit
                                ? LucideIcons.mapPin
                                : LucideIcons.phone,
                            size: 12,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _getTouchpointSummary(latestTouchpoint),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Touchpoint reason (if available)
                    if (!isFirstTime && latestTouchpoint != null && latestTouchpoint.reason != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.messageCircle,
                            size: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              latestTouchpoint.reason!.apiValue,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Wrap with dismissible if enabled
    if (enableSwipeToDismiss && onRemove != null) {
      return Dismissible(
        key: Key(client.id ?? 'client_${client.hashCode}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.trash2, color: Colors.red.shade600),
              const SizedBox(height: 4),
              Text(
                'Remove',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  String _getTouchpointSummary(Touchpoint touchpoint) {
    final ordinal = touchpoint.ordinal;
    final type = touchpoint.type == TouchpointType.visit ? 'Visit' : 'Call';
    final timeAgo = _getTimeAgo(touchpoint.date);
    return '$ordinal $type - $timeAgo';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes <= 1 ? 'just now' : '${minutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1w ago' : '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1mo ago' : '${months}mo ago';
    }
  }
}
