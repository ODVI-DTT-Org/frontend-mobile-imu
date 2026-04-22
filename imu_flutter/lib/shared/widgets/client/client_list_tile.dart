import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../features/clients/data/providers/client_favorites_provider.dart';
import '../../../core/models/user_role.dart';
import '../../../shared/providers/app_providers.dart' show currentUserRoleProvider;
import '../../../core/utils/app_notification.dart';

/// Unified client list tile used across Clients Page and Client Selector Modal.
///
/// Layout:
///   [Product Type]  [Pension Type]  [Loan Type?]  [STAR]
///   Name
///   [X • Call/Visit]
///   📍 Full address
///   [Schedule Today]  [Schedule Itinerary]
class ClientListTile extends ConsumerWidget {
  final Client client;
  final VoidCallback? onTap;
  final Widget? trailing;
  final List<Widget>? actions;

  // Kept for backwards compatibility — no longer changes layout
  final bool useCardStyle;

  const ClientListTile({
    super.key,
    required this.client,
    this.onTap,
    this.trailing,
    this.actions,
    this.useCardStyle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(currentUserRoleProvider);

    // Check if client is favorited (using optimistic notifier)
    final favorites = ref.watch(clientFavoritesNotifierProvider);
    final isStarred = favorites.contains(client.id ?? '');
    final favoritesNotifier = ref.read(clientFavoritesNotifierProvider.notifier);

    // Address — prefer primary from addresses list, fall back to client fields
    String addressText = '';
    if (client.addresses.isNotEmpty) {
      final primary = client.addresses.firstWhere(
        (a) => a.isPrimary,
        orElse: () => client.addresses.first,
      );
      addressText = [
        if (primary.barangay != null && primary.barangay!.isNotEmpty) primary.barangay,
        if (primary.municipality != null && primary.municipality!.isNotEmpty) primary.municipality,
        if (primary.province != null && primary.province!.isNotEmpty) primary.province,
      ].join(', ');
    }
    if (addressText.isEmpty) {
      addressText = client.fullAddress;
    }

    // Touchpoint progress — show completed count (no limit on touchpoints)
    final nextNumber = client.touchpointNumber >= 0 ? client.touchpointNumber : null;
    // Use client.nextTouchpoint directly (String from API, no strict pattern)
    final nextType = client.nextTouchpoint;
    final completedCount = client.completedTouchpoints;
    String touchpointInfo;
    if (nextType != null) {
      touchpointInfo = '$completedCount • ${nextType.toLowerCase()}';
    } else {
      touchpointInfo = '$completedCount';
    }

    final isCall = nextType?.toLowerCase() == 'call';

    // Check if client has completed all touchpoints (no next type)
    final isCompleted = nextType == null;

    final Color progressColor = isCompleted
        ? Colors.green
        : isCall
            ? Colors.orange
            : Colors.blue;

    // Role-based: can the user record the next touchpoint?
    bool canRecordNext = true;
    // ignore: unnecessary_null_comparison
    if (!isCompleted && nextNumber != null && userRole != null) {
      final validNumbers = _validNumbers(userRole);
      final validTypes = _validTypes(userRole);
      // Convert nextType String to TouchpointType for validation
      final nextTypeEnum = nextType?.toLowerCase() == 'call' ? TouchpointType.call : TouchpointType.visit;
      canRecordNext = validNumbers.contains(nextNumber) && validTypes.contains(nextTypeEnum);
    }

    final Color cardBg = client.loanReleased
        ? const Color(0xFFF0FDF4)   // green-50
        : (canRecordNext && !isCompleted)
            ? const Color(0xFFEFF6FF)  // blue-50
            : const Color(0xFFF3F4F6); // grey-100 — not my turn, no opacity
    final Color cardBorderColor = client.loanReleased
        ? const Color(0xFF86EFAC)   // green-300
        : (canRecordNext && !isCompleted)
            ? const Color(0xFFBFDBFE)  // blue-200
            : const Color(0xFFD1D5DB); // grey-300

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: type badges + star button + optional trailing checkmark
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _TypeBadge(label: client.productTypeDisplay),
                        _TypeBadge(label: client.pensionTypeDisplay),
                        if (client.loanTypeDisplay != null)
                          _TypeBadge(label: client.loanTypeDisplay!, color: Colors.indigo),
                      ],
                    ),
                  ),
                  // Star button (top-right corner)
                  GestureDetector(
                    onTap: () async {
                      try {
                        if (isStarred) {
                          await favoritesNotifier.remove(client.id ?? '');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from favorites')),
                            );
                          }
                        } else {
                          await favoritesNotifier.add(client.id ?? '');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to favorites')),
                            );
                          }
                        }
                      } catch (_) {
                        if (context.mounted) {
                          AppNotification.showError(
                            context,
                            isStarred ? 'Failed to remove from favorites' : 'Failed to add to favorites',
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isStarred ? LucideIcons.star : LucideIcons.star,
                        size: 18,
                        color: isStarred ? Colors.amber : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Name
              Text(
                client.fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Row 3: Loan Released badge OR touchpoint progress badge
              if (client.loanReleased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.checkCircle, size: 11, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'LOAN RELEASED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: canRecordNext
                        ? progressColor.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canRecordNext
                          ? progressColor.withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted
                            ? LucideIcons.checkCircle
                            : isCall
                                ? LucideIcons.phone
                                : LucideIcons.mapPin,
                        size: 11,
                        color: canRecordNext ? progressColor : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        touchpointInfo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: canRecordNext ? progressColor : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),

              // Row 4: Address
              if (addressText.isNotEmpty)
                Row(
                  children: [
                    Icon(LucideIcons.mapPin, size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addressText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Row 5: Action buttons
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions![i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return card;
  }

  List<int> _validNumbers(UserRole role) {
    if (role.isManager) return [1, 2, 3, 4, 5, 6, 7];
    if (role == UserRole.caravan) return [1, 4, 7];
    if (role == UserRole.tele) return [2, 3, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7];
  }

  List<TouchpointType> _validTypes(UserRole role) {
    if (role.isManager) return [TouchpointType.visit, TouchpointType.call];
    if (role == UserRole.caravan) return [TouchpointType.visit];
    if (role == UserRole.tele) return [TouchpointType.call];
    return [TouchpointType.visit, TouchpointType.call];
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _TypeBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.withOpacity(0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c.withOpacity(0.85),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
