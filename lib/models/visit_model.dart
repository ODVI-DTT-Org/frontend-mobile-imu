import '../core/utils/date_utils.dart';

class Visit {
  final String id;
  final String clientId;
  final String userId;
  final String type; // regular_visit | release_loan
  final String? timeArrival;
  final String? timeDeparture;
  final String? odometerArrival;
  final String? odometerDeparture;
  final String photoUrl; // REQUIRED by qa2 database
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
    this.timeArrival,
    this.timeDeparture,
    this.odometerArrival,
    this.odometerDeparture,
    required this.photoUrl,
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
    String? timeArrival,
    String? timeDeparture,
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
      timeArrival: timeArrival ?? this.timeArrival,
      timeDeparture: timeDeparture ?? this.timeDeparture,
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
    // Validate required fields
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Visit: id is required and cannot be empty');
    }

    final clientId = row['client_id']?.toString();
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('Visit: client_id is required and cannot be empty');
    }

    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('Visit: user_id is required and cannot be empty');
    }

    // Validate type enum
    final type = row['type']?.toString() ?? 'regular_visit';
    if (type != 'regular_visit' && type != 'release_loan') {
      throw ArgumentError('Visit: type must be "regular_visit" or "release_loan", got: $type');
    }

    // Parse dates safely
    final createdAt = DateUtils.safeParse(row['created_at']);
    if (createdAt == null) {
      throw ArgumentError('Visit: created_at is required and must be a valid date');
    }

    final updatedAt = DateUtils.safeParse(row['updated_at']);
    if (updatedAt == null) {
      throw ArgumentError('Visit: updated_at is required and must be a valid date');
    }

    // Parse optional time fields (text format, not DateTime)
    final timeArrival = row['time_arrival']?.toString();
    final timeDeparture = row['time_departure']?.toString();

    // Parse optional coordinates safely
    double? latitude;
    if (row['latitude'] != null) {
      if (row['latitude'] is num) {
        latitude = (row['latitude'] as num).toDouble();
      } else if (row['latitude'] is String) {
        latitude = double.tryParse(row['latitude'] as String);
      }
    }

    double? longitude;
    if (row['longitude'] != null) {
      if (row['longitude'] is num) {
        longitude = (row['longitude'] as num).toDouble();
      } else if (row['longitude'] is String) {
        longitude = double.tryParse(row['longitude'] as String);
      }
    }

    // Validate coordinate ranges if present
    if (latitude != null && (latitude < -90 || latitude > 90)) {
      throw ArgumentError('Visit: latitude must be between -90 and 90, got: $latitude');
    }
    if (longitude != null && (longitude < -180 || longitude > 180)) {
      throw ArgumentError('Visit: longitude must be between -180 and 180, got: $longitude');
    }

    // Validate photo_url (required by qa2 database)
    final photoUrl = row['photo_url']?.toString();
    if (photoUrl == null || photoUrl.isEmpty) {
      throw ArgumentError('Visit: photo_url is required and cannot be empty');
    }

    return Visit(
      id: id,
      clientId: clientId,
      userId: userId,
      type: type,
      timeArrival: timeArrival,
      timeDeparture: timeDeparture,
      odometerArrival: row['odometer_arrival']?.toString(),
      odometerDeparture: row['odometer_departure']?.toString(),
      photoUrl: photoUrl,
      notes: row['notes']?.toString(),
      reason: row['reason']?.toString(),
      status: row['status']?.toString(),
      address: row['address']?.toString(),
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'type': type,
      'time_arrival': timeArrival,
      'time_departure': timeDeparture,
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
