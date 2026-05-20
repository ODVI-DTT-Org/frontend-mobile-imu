import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../../../shared/utils/address_display.dart';

/// Client model for My Day list display
class MyDayClient {
  final String id; // Itinerary ID
  final String clientId; // Client ID - use this for API calls
  final String fullName;
  final String? agencyName;
  final String? location;
  final int touchpointNumber; // Next touchpoint number, 0 if not started (unlimited)
  final String touchpointType; // 'visit' or 'call'
  final bool isTimeIn;
  final String priority; // 'low', 'normal', 'high'
  final String? notes; // Optional notes for the visit
  final String? status; // 'pending', 'in_progress', 'completed'
  final String? scheduledTime; // Scheduled time for the visit (HH:MM format)
  final int? nextTouchpointNumber; // Backend-calculated next touchpoint number (unlimited, null if complete)
  final String? nextTouchpointType; // Next touchpoint type ('Visit' or 'Call')

  final String? assignedByName;

  // Previous touchpoint info
  final int? previousTouchpointNumber; // Last completed touchpoint number
  final String? previousTouchpointStatus; // Last completed touchpoint status (Interested, Undecided, etc.)
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
  final bool loanReleased;    // Whether the client's loan has been released

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
    this.previousTouchpointStatus,
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
    this.loanReleased = false,
  });

  String get touchpointOrdinal {
    if (touchpointNumber < 1) return '';
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th'];
    if (touchpointNumber <= ordinals.length) {
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

  factory MyDayClient.fromJson(Map<String, dynamic> json) {
    final clientId = json['client_id'] ?? json['clientId'];
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('clientId is required and cannot be empty');
    }

    // Validate and parse previous touchpoint number (must be positive)
    final previousTouchpointNumber = json['previous_touchpoint_number'] ?? json['previousTouchpointNumber'] as int?;
    int? validatedPreviousNumber;
    if (previousTouchpointNumber != null) {
      if (previousTouchpointNumber >= 1) {
        validatedPreviousNumber = previousTouchpointNumber;
      } else {
        debugPrint('[MyDayClient] Invalid previous touchpoint number: $previousTouchpointNumber (must be positive), ignoring');
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
      previousTouchpointStatus: json['previous_touchpoint_status'] ?? json['previousTouchpointStatus'],
      previousTouchpointReason: json['previous_touchpoint_reason'] ?? json['previousTouchpointReason'],
      previousTouchpointType: json['previous_touchpoint_type'] ?? json['previousTouchpointType'],
      previousTouchpointDate: json['previous_touchpoint_date'] != null
          ? DateTime.tryParse(json['previous_touchpoint_date'])
          : null,
      productType: (json['client'] as Map<String, dynamic>?)?['product_type'] as String?,
      pensionType: (json['client'] as Map<String, dynamic>?)?['pension_type'] as String?,
      loanType: (json['client'] as Map<String, dynamic>?)?['loan_type'] as String?,
      address: () {
        final client = json['client'] as Map<String, dynamic>?;
        final primaryAddress = selectPrimaryAddressMap(client?['addresses']);
        return resolveAddressDisplay(
          fullAddress: client?['full_address'],
          region: client?['region'] ?? client?['psgc_region'],
          province: client?['province'] ?? client?['psgc_province'],
          municipality: client?['municipality'] ?? client?['municipality_id'],
          barangay: client?['barangay'] ?? client?['psgc_barangay'],
          addressStreet: primaryAddress?['street'],
          addressBarangay: primaryAddress?['barangay'],
          addressCity: primaryAddress?['city'],
          addressProvince: primaryAddress?['province'],
          fallbackAddress: resolveAddressDisplay(
                fullAddress: json['full_address'],
                region: json['region'] ?? json['psgc_region'],
                province: json['province'] ?? json['psgc_province'],
                municipality: json['municipality'] ?? json['municipality_id'],
                barangay: json['barangay'] ?? json['psgc_barangay'],
                addressStreet: json['address_street'],
                addressBarangay: json['address_barangay'],
                addressCity: json['address_city'],
                addressProvince: json['address_province'],
                fallbackAddress: json['address'],
              ) ??
              json['address'],
        );
      }(),
      loanReleased: _parseBool((json['client'] as Map<String, dynamic>?)?['loan_released']),
    );
  }

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

    // Use next_touchpoint and next_touchpoint_number from enriched row (backend-determined)
    final nextNum = row['next_touchpoint_number'] as int?;
    final nextType = row['next_touchpoint'] as String?;
    final currentNum = nextNum ?? 0;
    final currentType = nextType?.toLowerCase() ?? 'visit';

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
      previousTouchpointStatus: lastTouchpoint?['status'] as String?,
      previousTouchpointReason: lastTouchpoint?['reason'] as String?,
      previousTouchpointType: lastTouchpoint?['type'] as String?,
      previousTouchpointDate: previousDate,
      firstName: row['first_name'] as String?,
      lastName: row['last_name'] as String?,
      productType: row['product_type'] as String?,
      pensionType: row['pension_type'] as String?,
      loanType: row['loan_type'] as String?,
      address: resolveAddressDisplayFromRow(row),
      loanReleased: _parseBool(row['loan_released']),
    );
  }

  /// SQLite stores booleans as integers (0/1), but PostgREST returns true bools.
  /// Cope with both shapes.
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
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
    'previous_touchpoint_status': previousTouchpointStatus,
    'previous_touchpoint_reason': previousTouchpointReason,
    'previous_touchpoint_type': previousTouchpointType,
    'previous_touchpoint_date': previousTouchpointDate?.toIso8601String(),
    'product_type': productType,
    'pension_type': pensionType,
    'loan_type': loanType,
    'address': address,
    'loan_released': loanReleased,
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
    String? previousTouchpointStatus,
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
    bool? loanReleased,
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
      previousTouchpointStatus: previousTouchpointStatus ?? this.previousTouchpointStatus,
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
      loanReleased: loanReleased ?? this.loanReleased,
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
          other.previousTouchpointStatus == previousTouchpointStatus &&
          other.previousTouchpointReason == previousTouchpointReason &&
          other.previousTouchpointType == previousTouchpointType &&
          other.previousTouchpointDate == previousTouchpointDate &&
          other.productType == productType &&
          other.pensionType == pensionType &&
          other.loanType == loanType &&
          other.address == address &&
          other.loanReleased == loanReleased;

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
        previousTouchpointStatus,
        previousTouchpointReason,
        previousTouchpointType,
        previousTouchpointDate,
        productType,
        pensionType,
        loanType,
        address,
        loanReleased,
      ]);

  @override
  String toString() =>
      'MyDayClient(id: $id, fullName: $fullName, touchpoint: $touchpointOrdinal)';
}
