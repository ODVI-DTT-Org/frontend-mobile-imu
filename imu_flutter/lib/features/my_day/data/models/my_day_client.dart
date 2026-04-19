import 'dart:convert';

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
  final int? nextTouchpointNumber; // Backend-calculated next touchpoint number (1-7 or null if complete)
  final String? nextTouchpointType; // Next touchpoint type ('Visit' or 'Call')

  final String? assignedByName;

  // Previous touchpoint info
  final int? previousTouchpointNumber; // Last completed touchpoint number
  final String? previousTouchpointReason; // Last completed touchpoint reason
  final String? previousTouchpointType; // Last completed touchpoint type (visit/call)
  final DateTime? previousTouchpointDate; // Last completed touchpoint date

  // Display fields for ClientListTile
  final String? firstName;
  final String? lastName;
  final String? middleName;
  final String? productType;  // raw e.g. 'SSS_PENSIONER'
  final String? pensionType;  // raw e.g. 'GSIS'
  final String? loanType;     // raw e.g. 'SALARY'
  final String? address;      // flat string e.g. 'San Jose, Ilocos Norte'

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
    this.nextTouchpointNumber,
    this.nextTouchpointType,
    this.assignedByName,
    this.previousTouchpointNumber,
    this.previousTouchpointReason,
    this.previousTouchpointType,
    this.previousTouchpointDate,
    this.firstName,
    this.lastName,
    this.middleName,
    this.productType,
    this.pensionType,
    this.loanType,
    this.address,
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
      nextTouchpointNumber: json['nextTouchpointNumber'] ?? json['next_touchpoint_number'] as int?,
      nextTouchpointType: json['nextTouchpointType'] ?? json['next_touchpoint_type'] as String?,
      assignedByName: json['assigned_by_name'] as String?,
      previousTouchpointNumber: validatedPreviousNumber,
      previousTouchpointReason: json['previous_touchpoint_reason'] ?? json['previousTouchpointReason'],
      previousTouchpointType: json['previous_touchpoint_type'] ?? json['previousTouchpointType'],
      previousTouchpointDate: json['previous_touchpoint_date'] != null
          ? DateTime.parse(json['previous_touchpoint_date'])
          : null,
      productType: (json['client'] as Map<String, dynamic>?)?['product_type'] as String?,
      pensionType: (json['client'] as Map<String, dynamic>?)?['pension_type'] as String?,
      loanType: (json['client'] as Map<String, dynamic>?)?['loan_type'] as String?,
      address: (json['client'] as Map<String, dynamic>?)?['full_address'] as String?
          ?? json['address'] as String?,
    );
  }

  static const List<String> _sequence = [
    'Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'
  ];

  static String _buildFullName(String? lastName, String? firstName, {String? middleName}) {
    final last = (lastName ?? '').trim();
    final first = (firstName ?? '').trim();
    final middle = (middleName ?? '').trim();
    if (last.isEmpty && first.isEmpty) return '';
    final firstMiddle = [if (first.isNotEmpty) first, if (middle.isNotEmpty) middle].join(' ');
    if (last.isEmpty) return firstMiddle;
    if (firstMiddle.isEmpty) return last;
    return '$last, $firstMiddle';
  }

  factory MyDayClient.fromRow(Map<String, dynamic> row) => MyDayClient.fromPowerSync(row);

  /// Create from PowerSync JOIN row (itineraries + clients tables)
  factory MyDayClient.fromPowerSync(Map<String, dynamic> row) {
    final clientId = row['client_id'] as String?;
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('clientId is required and cannot be empty');
    }

    final summaryJson = row['touchpoint_summary'] as String?;
    List<Map<String, dynamic>> touchpoints = [];
    if (summaryJson != null && summaryJson.isNotEmpty && summaryJson != 'null') {
      try {
        final decoded = jsonDecode(summaryJson);
        if (decoded is List) {
          touchpoints = decoded.whereType<Map<String, dynamic>>().toList();
        }
      } catch (_) {}
    }

    final completedNumbers = touchpoints
        .map((t) => (t['touchpoint_number'] as num?)?.toInt() ?? 0)
        .where((n) => n > 0)
        .toSet();

    int? nextNum;
    for (int i = 1; i <= 7; i++) {
      if (!completedNumbers.contains(i)) {
        nextNum = i;
        break;
      }
    }

    final nextType = nextNum != null ? _sequence[nextNum - 1] : null;
    final currentNum = nextNum ?? 0;
    final currentType = nextNum != null ? nextType!.toLowerCase() : 'visit';

    Map<String, dynamic>? lastTouchpoint;
    if (touchpoints.isNotEmpty) {
      touchpoints.sort((a, b) =>
          ((b['touchpoint_number'] as num?)?.toInt() ?? 0)
              .compareTo((a['touchpoint_number'] as num?)?.toInt() ?? 0));
      lastTouchpoint = touchpoints.first;
    }

    DateTime? previousDate;
    if (lastTouchpoint?['date'] != null) {
      try {
        previousDate = DateTime.parse(lastTouchpoint!['date'] as String);
      } catch (_) {}
    }

    final municipality = row['municipality'] as String?;
    final province = row['province'] as String?;
    final addressParts = [
      if (municipality != null && municipality.isNotEmpty) municipality,
      if (province != null && province.isNotEmpty) province,
    ];
    final addressStr = addressParts.isEmpty ? null : addressParts.join(', ');

    return MyDayClient(
      id: row['id'] as String,
      clientId: clientId,
      fullName: _buildFullName(row['last_name'] as String?, row['first_name'] as String?, middleName: row['middle_name'] as String?),
      middleName: row['middle_name'] as String?,
      agencyName: null,
      location: null,
      touchpointNumber: currentNum,
      touchpointType: currentType,
      priority: row['priority'] as String? ?? 'normal',
      notes: row['notes'] as String?,
      status: row['status'] as String?,
      scheduledTime: row['scheduled_time'] as String?,
      nextTouchpointNumber: nextNum,
      nextTouchpointType: nextType,
      previousTouchpointNumber: (lastTouchpoint?['touchpoint_number'] as num?)?.toInt(),
      previousTouchpointReason: lastTouchpoint?['reason'] as String?,
      previousTouchpointType: lastTouchpoint?['type'] as String?,
      previousTouchpointDate: previousDate,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      productType: row['product_type'] as String?,
      pensionType: row['pension_type'] as String?,
      loanType: row['loan_type'] as String?,
      address: addressStr,
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
    'next_touchpoint_number': nextTouchpointNumber,
    'next_touchpoint_type': nextTouchpointType,
    'assigned_by_name': assignedByName,
    'previous_touchpoint_number': previousTouchpointNumber,
    'previous_touchpoint_reason': previousTouchpointReason,
    'previous_touchpoint_type': previousTouchpointType,
    'previous_touchpoint_date': previousTouchpointDate?.toIso8601String(),
    'product_type': productType,
    'pension_type': pensionType,
    'loan_type': loanType,
    'address': address,
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
    int? nextTouchpointNumber,
    String? nextTouchpointType,
    String? assignedByName,
    int? previousTouchpointNumber,
    String? previousTouchpointReason,
    String? previousTouchpointType,
    DateTime? previousTouchpointDate,
    String? firstName,
    String? lastName,
    String? middleName,
    String? productType,
    String? pensionType,
    String? loanType,
    String? address,
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
      nextTouchpointNumber: nextTouchpointNumber ?? this.nextTouchpointNumber,
      nextTouchpointType: nextTouchpointType ?? this.nextTouchpointType,
      assignedByName: assignedByName ?? this.assignedByName,
      previousTouchpointNumber: previousTouchpointNumber ?? this.previousTouchpointNumber,
      previousTouchpointReason: previousTouchpointReason ?? this.previousTouchpointReason,
      previousTouchpointType: previousTouchpointType ?? this.previousTouchpointType,
      previousTouchpointDate: previousTouchpointDate ?? this.previousTouchpointDate,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      productType: productType ?? this.productType,
      pensionType: pensionType ?? this.pensionType,
      loanType: loanType ?? this.loanType,
      address: address ?? this.address,
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
          other.nextTouchpointNumber == nextTouchpointNumber &&
          other.nextTouchpointType == nextTouchpointType &&
          other.assignedByName == assignedByName &&
          other.previousTouchpointNumber == previousTouchpointNumber &&
          other.previousTouchpointReason == previousTouchpointReason &&
          other.previousTouchpointType == previousTouchpointType &&
          other.previousTouchpointDate == previousTouchpointDate &&
          other.productType == productType &&
          other.pensionType == pensionType &&
          other.loanType == loanType &&
          other.address == address;

  @override
  int get hashCode => Object.hashAll([
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
        nextTouchpointNumber,
        nextTouchpointType,
        assignedByName,
        previousTouchpointNumber,
        previousTouchpointReason,
        previousTouchpointType,
        previousTouchpointDate,
        productType,
        pensionType,
        loanType,
        address,
      ]);

  @override
  String toString() =>
      'MyDayClient(id: $id, fullName: $fullName, touchpoint: $touchpointOrdinal)';
}
