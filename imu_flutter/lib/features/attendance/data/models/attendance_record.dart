/// Attendance record with GPS location tracking
class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final AttendanceLocation? checkInLocation;
  final AttendanceLocation? checkOutLocation;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.id,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    required this.status,
  });

  double? get totalHours {
    if (checkInTime == null || checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime!).inMinutes / 60;
  }

  String get formattedHours {
    final hours = totalHours;
    if (hours == null) return '--';
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    AttendanceLocation? checkInLocation,
    AttendanceLocation? checkOutLocation,
    AttendanceStatus? status,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'checkInTime': checkInTime?.toIso8601String(),
    'checkOutTime': checkOutTime?.toIso8601String(),
    'checkInLocation': checkInLocation?.toJson(),
    'checkOutLocation': checkOutLocation?.toJson(),
    'status': status.name,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      date: DateTime.parse(json['date']),
      checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      checkInLocation: json['checkInLocation'] != null
          ? AttendanceLocation.fromJson(json['checkInLocation'])
          : null,
      checkOutLocation: json['checkOutLocation'] != null
          ? AttendanceLocation.fromJson(json['checkOutLocation'])
          : null,
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.absent,
      ),
    );
  }
}

enum AttendanceStatus {
  absent,      // No check-in
  checkedIn,   // Checked in but not out
  checkedOut,  // Complete day
  incomplete,  // Missing check-out from previous day
}

class AttendanceLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime timestamp;

  AttendanceLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) {
    return AttendanceLocation(
      latitude: json['latitude'] ?? 0,
      longitude: json['longitude'] ?? 0,
      address: json['address'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
