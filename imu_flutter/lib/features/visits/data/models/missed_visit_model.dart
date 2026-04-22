import 'package:imu_flutter/features/clients/data/models/client_model.dart';

/// Represents a missed/overdue client visit
class MissedVisit {
  final String id;
  final String clientId;
  final String clientName;
  final int touchpointNumber;
  final TouchpointType touchpointType;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final String? primaryPhone;
  final String? primaryAddress;

  MissedVisit({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.touchpointNumber,
    required this.touchpointType,
    required this.scheduledDate,
    required this.createdAt,
    this.primaryPhone,
    this.primaryAddress,
  });

  /// Calculate days overdue
  int get daysOverdue {
    return DateTime.now().difference(scheduledDate).inDays;
  }

  /// Determine priority based on days overdue
  MissedVisitPriority get priority {
    if (daysOverdue >= 7) return MissedVisitPriority.high;
    if (daysOverdue >= 3) return MissedVisitPriority.medium;
    return MissedVisitPriority.low;
  }

  /// Get ordinal string for touchpoint number (supports unlimited touchpoints)
  String get touchpointOrdinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    if (touchpointNumber >= 1 && touchpointNumber <= ordinals.length) {
      return ordinals[touchpointNumber - 1];
    }
    // For touchpoints beyond our list, use pattern: 11th, 12th, 13th, etc.
    final lastTwo = touchpointNumber % 100;
    if (lastTwo >= 11 && lastTwo <= 13) return '${touchpointNumber}th';
    switch (touchpointNumber % 10) {
      case 1: return '${touchpointNumber}st';
      case 2: return '${touchpointNumber}nd';
      case 3: return '${touchpointNumber}rd';
      default: return '${touchpointNumber}th';
    }
  }

  /// Get touchpoint type label
  String get touchpointTypeLabel {
    return touchpointType == TouchpointType.visit ? 'Visit' : 'Call';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'clientId': clientId,
    'clientName': clientName,
    'touchpointNumber': touchpointNumber,
    'touchpointType': touchpointType.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'primaryPhone': primaryPhone,
    'primaryAddress': primaryAddress,
  };

  factory MissedVisit.fromJson(Map<String, dynamic> json) {
    return MissedVisit(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      clientName: json['clientName'] ?? '',
      touchpointNumber: json['touchpointNumber'] ?? 1,
      touchpointType: TouchpointType.values.firstWhere(
        (e) => e.name == json['touchpointType'],
        orElse: () => TouchpointType.visit,
      ),
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      primaryPhone: json['primaryPhone'],
      primaryAddress: json['primaryAddress'],
    );
  }
}

enum MissedVisitPriority { high, medium, low }
