import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../core/models/user_role.dart';
import '../../../shared/providers/app_providers.dart' show currentUserRoleProvider;

/// Unified client list tile used across Clients Page and Client Selector Modal.
///
/// Layout:
///   [Product Type]  [Pension Type]  [Loan Type?]
///   Name
///   [X/7 • Call/Visit]
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

    // Touchpoint progress
    // nextTouchpointNumber is the next step to record (e.g. 3 if 2 are done).
    // touchpointNumber is the completed count — add +1 for the fallback so it
    // matches the semantics of nextTouchpointNumber (completed + 1 = next step).
    final nextNumber = client.nextTouchpointNumber ??
        (client.touchpointNumber >= 0 && client.touchpointNumber < 7 ? client.touchpointNumber + 1 : null);
    final nextType = client.nextTouchpointType;
    final isCompleted = client.completedTouchpoints >= 7;
    String touchpointInfo;
    if (isCompleted) {
      touchpointInfo = 'Completed';
    } else if (nextNumber != null && nextType != null) {
      touchpointInfo = '$nextNumber/7 • ${nextType == TouchpointType.visit ? 'Visit' : 'Call'}';
    } else {
      touchpointInfo = '0/7 • Visit';
    }

    final isCall = nextType == TouchpointType.call;

    Color progressColor = isCompleted
        ? Colors.green
        : isCall
            ? Colors.orange
            : Colors.blue;

    // Role-based: can the user record the next touchpoint?
    bool canRecordNext = true;
    if (!isCompleted && nextNumber != null && nextType != null && userRole != null) {
      final validNumbers = _validNumbers(userRole);
      final validTypes = _validTypes(userRole);
      canRecordNext = validNumbers.contains(nextNumber) && validTypes.contains(nextType);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
              // Row 1: type badges + optional trailing checkmark
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
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
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

              // Row 3: Touchpoint progress badge
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
