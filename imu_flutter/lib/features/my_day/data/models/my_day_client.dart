/// Client model for My Day list display
class MyDayClient {
  final String id;
  final String fullName;
  final String? agencyName;
  final String? location;
  final int touchpointNumber; // 1-7, 0 if not started
  final String touchpointType; // 'visit' or 'call'
  final bool isTimeIn;

  MyDayClient({
    required this.id,
    required this.fullName,
    this.agencyName,
    this.location,
    required this.touchpointNumber,
    required this.touchpointType,
    this.isTimeIn = false,
  });

  String get touchpointOrdinal {
    if (touchpointNumber == 0) return '';
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[touchpointNumber - 1];
  }

  factory MyDayClient.fromJson(Map<String, dynamic> json) {
    return MyDayClient(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? json['fullName'] ?? '',
      agencyName: json['agency_name'] ?? json['agencyName'],
      location: json['location'] ?? json['agency_name'],
      touchpointNumber: json['touchpoint_number'] ?? json['touchpointNumber'] ?? 0,
      touchpointType: json['touchpoint_type'] ?? json['touchpointType'] ?? 'visit',
      isTimeIn: json['is_time_in'] ?? json['isTimeIn'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'agency_name': agencyName,
    'location': location,
    'touchpoint_number': touchpointNumber,
    'touchpoint_type': touchpointType,
    'is_time_in': isTimeIn,
  };

  MyDayClient copyWith({
    String? id,
    String? fullName,
    String? agencyName,
    String? location,
    int? touchpointNumber,
    String? touchpointType,
    bool? isTimeIn,
  }) {
    return MyDayClient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      agencyName: agencyName ?? this.agencyName,
      location: location ?? this.location,
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      touchpointType: touchpointType ?? this.touchpointType,
      isTimeIn: isTimeIn ?? this.isTimeIn,
    );
  }
}
