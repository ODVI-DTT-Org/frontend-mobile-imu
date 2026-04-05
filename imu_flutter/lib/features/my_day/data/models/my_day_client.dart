import 'package:flutter/foundation.dart';

/// Client model for My Day list display
class MyDayClient {
  final String id; // Itinerary ID
  final String clientId; // Client ID - use this for API calls
  final String fullName;
  final String? agencyName;
  final String? location;
  final int touchpointNumber; // 1-7, 0 if not started
  final String touchpointType; // 'visit' or 'call'
  final bool isTimeIn;
  final String priority; // 'low', 'normal', 'high'
  final String? notes; // Optional notes for the visit
  final String? status; // 'pending', 'in_progress', 'completed'
  final String? scheduledTime; // Scheduled time for the visit (HH:MM format)

  // Previous touchpoint info
  final int? previousTouchpointNumber; // Last completed touchpoint number
  final String? previousTouchpointReason; // Last completed touchpoint reason
  final String? previousTouchpointType; // Last completed touchpoint type (visit/call)
  final DateTime? previousTouchpointDate; // Last completed touchpoint date

  MyDayClient({
    required this.id,
    required this.clientId,
    required this.fullName,
    this.agencyName,
    this.location,
    required this.touchpointNumber,
    required this.touchpointType,
    this.isTimeIn = false,
    this.priority = 'normal',
    this.notes,
    this.status,
    this.scheduledTime,
    this.previousTouchpointNumber,
    this.previousTouchpointReason,
    this.previousTouchpointType,
    this.previousTouchpointDate,
  });

  String get touchpointOrdinal {
    if (touchpointNumber < 1 || touchpointNumber > 7) return '';
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[touchpointNumber - 1];
  }

  factory MyDayClient.fromJson(Map<String, dynamic> json) {
    final clientId = json['client_id'] ?? json['clientId'];
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('clientId is required and cannot be empty');
    }

    // Validate and parse previous touchpoint number (must be 1-7)
    final previousTouchpointNumber = json['previous_touchpoint_number'] ?? json['previousTouchpointNumber'] as int?;
    int? validatedPreviousNumber;
    if (previousTouchpointNumber != null) {
      if (previousTouchpointNumber >= 1 && previousTouchpointNumber <= 7) {
        validatedPreviousNumber = previousTouchpointNumber;
      } else {
        debugPrint('[MyDayClient] Invalid previous touchpoint number: $previousTouchpointNumber (must be 1-7), ignoring');
      }
    }

    return MyDayClient(
      id: json['id'] ?? '',
      clientId: clientId,
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      agencyName: json['agency_name'] ?? json['agencyName'],
      location: json['location'] ?? json['agency_name'],
      touchpointNumber: json['touchpoint_number'] ?? json['touchpointNumber'] ?? 0,
      touchpointType: json['touchpoint_type'] ?? json['touchpointType'] ?? 'visit',
      isTimeIn: json['is_time_in'] ?? json['isTimeIn'] ?? false,
      priority: json['priority'] ?? 'normal',
      notes: json['notes'] ?? json['note'],
      status: json['status'],
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'],
      previousTouchpointNumber: validatedPreviousNumber,
      previousTouchpointReason: json['previous_touchpoint_reason'] ?? json['previousTouchpointReason'],
      previousTouchpointType: json['previous_touchpoint_type'] ?? json['previousTouchpointType'],
      previousTouchpointDate: json['previous_touchpoint_date'] != null
          ? DateTime.parse(json['previous_touchpoint_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'full_name': fullName,
    'agency_name': agencyName,
    'location': location,
    'touchpoint_number': touchpointNumber,
    'touchpoint_type': touchpointType,
    'is_time_in': isTimeIn,
    'priority': priority,
    'notes': notes,
    'status': status,
    'scheduled_time': scheduledTime,
    'previous_touchpoint_number': previousTouchpointNumber,
    'previous_touchpoint_reason': previousTouchpointReason,
    'previous_touchpoint_type': previousTouchpointType,
    'previous_touchpoint_date': previousTouchpointDate?.toIso8601String(),
  };

  MyDayClient copyWith({
    String? id,
    String? clientId,
    String? fullName,
    String? agencyName,
    String? location,
    int? touchpointNumber,
    String? touchpointType,
    bool? isTimeIn,
    String? priority,
    String? notes,
    String? status,
    String? scheduledTime,
    int? previousTouchpointNumber,
    String? previousTouchpointReason,
    String? previousTouchpointType,
    DateTime? previousTouchpointDate,
  }) {
    return MyDayClient(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      fullName: fullName ?? this.fullName,
      agencyName: agencyName ?? this.agencyName,
      location: location ?? this.location,
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      touchpointType: touchpointType ?? this.touchpointType,
      isTimeIn: isTimeIn ?? this.isTimeIn,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      previousTouchpointNumber: previousTouchpointNumber ?? this.previousTouchpointNumber,
      previousTouchpointReason: previousTouchpointReason ?? this.previousTouchpointReason,
      previousTouchpointType: previousTouchpointType ?? this.previousTouchpointType,
      previousTouchpointDate: previousTouchpointDate ?? this.previousTouchpointDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyDayClient &&
          other.id == id &&
          other.clientId == clientId &&
          other.fullName == fullName &&
          other.agencyName == agencyName &&
          other.location == location &&
          other.touchpointNumber == touchpointNumber &&
          other.touchpointType == touchpointType &&
          other.isTimeIn == isTimeIn &&
          other.priority == priority &&
          other.notes == notes &&
          other.status == status &&
          other.scheduledTime == scheduledTime &&
          other.previousTouchpointNumber == previousTouchpointNumber &&
          other.previousTouchpointReason == previousTouchpointReason &&
          other.previousTouchpointType == previousTouchpointType &&
          other.previousTouchpointDate == previousTouchpointDate;

  @override
  int get hashCode => Object.hash(
        id,
        clientId,
        fullName,
        agencyName,
        location,
        touchpointNumber,
        touchpointType,
        isTimeIn,
        priority,
        notes,
        status,
        scheduledTime,
        previousTouchpointNumber,
        previousTouchpointReason,
        previousTouchpointType,
        previousTouchpointDate,
      );

  @override
  String toString() =>
      'MyDayClient(id: $id, fullName: $fullName, touchpoint: $touchpointOrdinal)';
}
