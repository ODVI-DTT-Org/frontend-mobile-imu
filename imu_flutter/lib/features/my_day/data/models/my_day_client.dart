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
          other.notes == notes;

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
      );

  @override
  String toString() =>
      'MyDayClient(id: $id, fullName: $fullName, touchpoint: $touchpointOrdinal)';
}
