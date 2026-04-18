class Visit {
  final String id;
  final String clientId;
  final String userId;
  final String type; // 'regular_visit' | 'release_loan'
  final String? odometerArrival;
  final String? odometerDeparture;
  final String? photoUrl;
  final String? notes;
  final String? reason;
  final String? status;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? source; // 'IMU' | 'CMS'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Visit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.type,
    this.odometerArrival,
    this.odometerDeparture,
    this.photoUrl,
    this.notes,
    this.reason,
    this.status,
    this.address,
    this.latitude,
    this.longitude,
    this.timeIn,
    this.timeOut,
    this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReleaseVisit => type == 'release_loan';
  bool get isCmsRecord => source == 'CMS';

  factory Visit.fromRow(Map<String, dynamic> row) {
    return Visit(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      type: row['type'] as String? ?? 'regular_visit',
      odometerArrival: row['odometer_arrival'] as String?,
      odometerDeparture: row['odometer_departure'] as String?,
      photoUrl: row['photo_url'] as String?,
      notes: row['notes'] as String?,
      reason: row['reason'] as String?,
      status: row['status'] as String?,
      address: row['address'] as String?,
      latitude: row['latitude'] != null ? (row['latitude'] as num).toDouble() : null,
      longitude: row['longitude'] != null ? (row['longitude'] as num).toDouble() : null,
      timeIn: row['time_in'] != null ? DateTime.tryParse(row['time_in'] as String) : null,
      timeOut: row['time_out'] != null ? DateTime.tryParse(row['time_out'] as String) : null,
      source: row['source'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'client_id': clientId,
    'user_id': userId,
    'type': type,
    'odometer_arrival': odometerArrival,
    'odometer_departure': odometerDeparture,
    'photo_url': photoUrl,
    'notes': notes,
    'reason': reason,
    'status': status,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'time_in': timeIn?.toIso8601String(),
    'time_out': timeOut?.toIso8601String(),
    'source': source,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
