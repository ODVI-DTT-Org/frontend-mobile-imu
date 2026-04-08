class Visit {
  final String id;
  final String clientId;
  final String userId;
  final String type; // regular_visit | release_loan
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? odometerArrival;
  final String? odometerDeparture;
  final String? photoUrl;
  final String? notes;
  final String? reason;
  final String? status;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visit({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.type,
    this.timeIn,
    this.timeOut,
    this.odometerArrival,
    this.odometerDeparture,
    this.photoUrl,
    this.notes,
    this.reason,
    this.status,
    this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  Visit copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? type,
    DateTime? timeIn,
    DateTime? timeOut,
    String? odometerArrival,
    String? odometerDeparture,
    String? photoUrl,
    String? notes,
    String? reason,
    String? status,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timeIn: timeIn ?? this.timeIn,
      timeOut: timeOut ?? this.timeOut,
      odometerArrival: odometerArrival ?? this.odometerArrival,
      odometerDeparture: odometerDeparture ?? this.odometerDeparture,
      photoUrl: photoUrl ?? this.photoUrl,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Visit.fromRow(Map<String, dynamic> row) {
    return Visit(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      type: row['type'] as String? ?? 'regular_visit',
      timeIn: row['time_in'] != null ? DateTime.parse(row['time_in'] as String) : null,
      timeOut: row['time_out'] != null ? DateTime.parse(row['time_out'] as String) : null,
      odometerArrival: row['odometer_arrival'] as String?,
      odometerDeparture: row['odometer_departure'] as String?,
      photoUrl: row['photo_url'] as String?,
      notes: row['notes'] as String?,
      reason: row['reason'] as String?,
      status: row['status'] as String?,
      address: row['address'] as String?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'type': type,
      'time_in': timeIn?.toIso8601String(),
      'time_out': timeOut?.toIso8601String(),
      'odometer_arrival': odometerArrival,
      'odometer_departure': odometerDeparture,
      'photo_url': photoUrl,
      'notes': notes,
      'reason': reason,
      'status': status,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
