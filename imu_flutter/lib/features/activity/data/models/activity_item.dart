import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ActivityType { approval, touchpoint, visit, call }

enum ActivityStatus { pending, syncing, completed, approved, rejected, failed }

enum ActivitySubtype {
  // Approvals
  clientCreate,
  clientEdit,
  clientDelete,
  addressAdd,
  addressEdit,
  addressDelete,
  phoneAdd,
  phoneEdit,
  phoneDelete,
  loanRelease,
  // Touchpoints
  touchpointVisit,
  touchpointCall,
  // Standalone visit/call records
  visit,
  call;

  static ActivitySubtype fromApproval({
    required String type,
    required String? reason,
  }) {
    switch (type) {
      case 'client':
        return reason == 'Client Edit Request'
            ? ActivitySubtype.clientEdit
            : ActivitySubtype.clientCreate;
      case 'client_delete':
        return ActivitySubtype.clientDelete;
      case 'address_add':
        return ActivitySubtype.addressAdd;
      case 'address_edit':
        return ActivitySubtype.addressEdit;
      case 'address_delete':
        return ActivitySubtype.addressDelete;
      case 'phone_add':
        return ActivitySubtype.phoneAdd;
      case 'phone_edit':
        return ActivitySubtype.phoneEdit;
      case 'phone_delete':
        return ActivitySubtype.phoneDelete;
      case 'loan_release':
      case 'loan_release_v2':
        return ActivitySubtype.loanRelease;
      default:
        return ActivitySubtype.clientCreate;
    }
  }
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final ActivitySubtype subtype;
  final String? clientName;
  final String? detail;
  final ActivityStatus status;
  final DateTime createdAt;

  ActivityItem({
    required this.id,
    required this.type,
    required this.subtype,
    this.clientName,
    this.detail,
    required this.status,
    required this.createdAt,
  });

  String get displayTitle {
    switch (subtype) {
      case ActivitySubtype.clientCreate:    return 'Add Client';
      case ActivitySubtype.clientEdit:      return 'Edit Client';
      case ActivitySubtype.clientDelete:    return 'Delete Client';
      case ActivitySubtype.addressAdd:      return 'Add Address';
      case ActivitySubtype.addressEdit:     return 'Edit Address';
      case ActivitySubtype.addressDelete:   return 'Delete Address';
      case ActivitySubtype.phoneAdd:        return 'Add Phone';
      case ActivitySubtype.phoneEdit:       return 'Edit Phone';
      case ActivitySubtype.phoneDelete:     return 'Delete Phone';
      case ActivitySubtype.loanRelease:     return 'Loan Release';
      case ActivitySubtype.touchpointVisit: return 'Visit';
      case ActivitySubtype.touchpointCall:  return 'Call';
      case ActivitySubtype.visit:           return 'Visit Logged';
      case ActivitySubtype.call:            return 'Call Logged';
    }
  }

  IconData get icon {
    switch (subtype) {
      case ActivitySubtype.clientCreate:   return LucideIcons.userPlus;
      case ActivitySubtype.clientEdit:     return LucideIcons.userCog;
      case ActivitySubtype.clientDelete:   return LucideIcons.userX;
      case ActivitySubtype.addressAdd:
      case ActivitySubtype.addressEdit:
      case ActivitySubtype.addressDelete:  return LucideIcons.mapPin;
      case ActivitySubtype.phoneAdd:
      case ActivitySubtype.phoneEdit:
      case ActivitySubtype.phoneDelete:    return LucideIcons.phone;
      case ActivitySubtype.loanRelease:    return LucideIcons.fileText;
      case ActivitySubtype.touchpointVisit:
      case ActivitySubtype.visit:          return LucideIcons.mapPin;
      case ActivitySubtype.touchpointCall:
      case ActivitySubtype.call:           return LucideIcons.phone;
    }
  }

  Color get statusColor {
    switch (status) {
      case ActivityStatus.pending:   return Colors.amber;
      case ActivityStatus.syncing:   return Colors.blue;
      case ActivityStatus.completed:
      case ActivityStatus.approved:  return Colors.green;
      case ActivityStatus.rejected:
      case ActivityStatus.failed:    return Colors.red;
    }
  }

  String get statusLabel {
    switch (status) {
      case ActivityStatus.pending:   return 'PENDING';
      case ActivityStatus.syncing:   return 'SYNCING';
      case ActivityStatus.completed: return 'COMPLETED';
      case ActivityStatus.approved:  return 'APPROVED';
      case ActivityStatus.rejected:  return 'REJECTED';
      case ActivityStatus.failed:    return 'FAILED';
    }
  }

  /// Cached formatted time string for display.
  /// Computed once per instance and reused.
  late final String formattedTime = _computeFormattedTime();

  String _computeFormattedTime() {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday ${DateFormat('h:mm a').format(createdAt)}';
    return DateFormat('MMM d, h:mm a').format(createdAt);
  }
}
