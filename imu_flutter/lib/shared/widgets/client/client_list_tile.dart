import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../features/clients/data/models/client_model.dart';
import '../../../core/models/user_role.dart';
import '../../../shared/providers/app_providers.dart' show currentUserRoleProvider;

/// Unified client list tile with minimal information
///
/// Shows only:
/// - Client name
/// - Address
/// - Touchpoint number (e.g., "2/7")
/// - Next touchpoint type (e.g., "Call")
/// - Touchpoint reason (e.g., "Follow-up")
/// - Status (e.g., "Interested")
class ClientListTile extends ConsumerWidget {
  final Client client;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool useCardStyle;
  final List<Widget>? actions;

  const ClientListTile({
    super.key,
    required this.client,
    this.onTap,
    this.trailing,
    this.useCardStyle = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryAddress = client.addresses.isNotEmpty
        ? client.addresses.firstWhere(
            (a) => a.isPrimary,
            orElse: () => client.addresses.first,
          )
        : null;

    final lastTouchpoint = client.touchpointSummary.isNotEmpty
        ? client.touchpointSummary.last
        : null;

    final nextNumber = client.nextTouchpointNumber;
    final nextType = client.nextTouchpointType;
    final userRole = ref.watch(currentUserRoleProvider);

    // Build address text
    String addressText = '';
    if (primaryAddress != null) {
      addressText = [
        if (primaryAddress.barangay != null) primaryAddress.barangay,
        if (primaryAddress.municipality != null && primaryAddress.municipality!.isNotEmpty)
          primaryAddress.municipality,
        if (primaryAddress.province != null) primaryAddress.province,
      ].join(', ');
    }

    // Build touchpoint info
    String touchpointInfo = '';
    if (nextNumber != null && nextType != null) {
      final typeLabel = nextType == TouchpointType.visit ? 'Visit' : 'Call';
      touchpointInfo = '$nextNumber/7 • $typeLabel';
    } else if (nextNumber == null) {
      touchpointInfo = 'Completed';
    }

    // Build reason and status
    String? reason;
    String? status;
    if (lastTouchpoint != null) {
      reason = lastTouchpoint.reason?.apiValue;
      status = lastTouchpoint.status?.apiValue;
    }

    // Check if user can create the next touchpoint
    bool canRecordNext = true;
    if (nextNumber != null && nextType != null && userRole != null) {
      final validNumbers = _getValidTouchpointNumbers(userRole);
      final validTypes = _getValidTouchpointTypes(userRole);
      canRecordNext = validNumbers.contains(nextNumber) && validTypes.contains(nextType);
    }

    if (useCardStyle) {
      return _buildCardStyle(
        context,
        client.fullName,
        addressText,
        touchpointInfo,
        reason,
        status,
        canRecordNext,
      );
    }

    return _buildListTileStyle(
      context,
      client.fullName,
      addressText,
      touchpointInfo,
      reason,
      status,
      canRecordNext,
    );
  }

  Widget _buildListTileStyle(
    BuildContext context,
    String name,
    String addressText,
    String touchpointInfo,
    String? reason,
    String? status,
    bool canRecordNext,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and touchpoint number
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (touchpointInfo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: canRecordNext
                            ? const Color(0xFF3B82F6).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: canRecordNext
                              ? const Color(0xFF3B82F6).withOpacity(0.3)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        touchpointInfo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: canRecordNext ? const Color(0xFF3B82F6) : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 8),
              // Address
              if (addressText.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        addressText,
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
              // Reason and Status
              if (reason != null || status != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (reason != null)
                      _buildInfoChip(
                        icon: LucideIcons.messageCircle,
                        label: reason!,
                        color: const Color(0xFF64748B),
                      ),
                    if (status != null)
                      _buildStatusChip(status!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardStyle(
    BuildContext context,
    String name,
    String addressText,
    String touchpointInfo,
    String? reason,
    String? status,
    bool canRecordNext,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and touchpoint number
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (touchpointInfo.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: canRecordNext
                          ? const Color(0xFF3B82F6).withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: canRecordNext
                            ? const Color(0xFF3B82F6).withOpacity(0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      touchpointInfo,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: canRecordNext ? const Color(0xFF3B82F6) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
            // Address
            if (addressText.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      addressText,
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
            // Reason and Status
            if (reason != null || status != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (reason != null)
                    _buildInfoChip(
                      icon: LucideIcons.messageCircle,
                      label: reason!,
                      color: const Color(0xFF64748B),
                    ),
                  if (status != null)
                    _buildStatusChip(status!),
                ],
              ),
            ],
            // Action buttons (if provided)
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: actions!
                    .map((action) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: action,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'interested':
        color = const Color(0xFF22C55E);
        icon = LucideIcons.thumbsUp;
        break;
      case 'undecided':
        color = const Color(0xFFF59E0B);
        icon = LucideIcons.helpCircle;
        break;
      case 'not interested':
        color = const Color(0xFFEF4444);
        icon = LucideIcons.thumbsDown;
        break;
      case 'completed':
        color = const Color(0xFF3B82F6);
        icon = LucideIcons.checkCircle;
        break;
      default:
        color = const Color(0xFF64748B);
        icon = LucideIcons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getValidTouchpointNumbers(UserRole role) {
    if (role.isManager) return [1, 2, 3, 4, 5, 6, 7];
    if (role == UserRole.caravan) return [1, 4, 7];
    if (role == UserRole.tele) return [2, 3, 5, 6];
    return [1, 2, 3, 4, 5, 6, 7];
  }

  List<TouchpointType> _getValidTouchpointTypes(UserRole role) {
    if (role.isManager) return [TouchpointType.visit, TouchpointType.call];
    if (role == UserRole.caravan) return [TouchpointType.visit];
    if (role == UserRole.tele) return [TouchpointType.call];
    return [TouchpointType.visit, TouchpointType.call];
  }
}
