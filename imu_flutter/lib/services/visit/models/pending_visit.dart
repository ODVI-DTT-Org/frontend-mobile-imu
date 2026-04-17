/// Pending visit stored in Hive when offline
class PendingVisit {
  final String id;
  final String clientId;
  final String timeIn;
  final String timeOut;
  final String odometerArrival;
  final String odometerDeparture;
  final String? photoPath;
  final String? notes;
  final String type;
  final DateTime createdAt;

  PendingVisit({
    required this.id,
    required this.clientId,
    required this.timeIn,
    required this.timeOut,
    required this.odometerArrival,
    required this.odometerDeparture,
    this.photoPath,
    this.notes,
    this.type = 'regular_visit',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'timeIn': timeIn,
        'timeOut': timeOut,
        'odometerArrival': odometerArrival,
        'odometerDeparture': odometerDeparture,
        'photoPath': photoPath,
        'notes': notes,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingVisit.fromJson(Map<String, dynamic> json) => PendingVisit(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        timeIn: json['timeIn'] as String,
        timeOut: json['timeOut'] as String,
        odometerArrival: json['odometerArrival'] as String,
        odometerDeparture: json['odometerDeparture'] as String,
        photoPath: json['photoPath'] as String?,
        notes: json['notes'] as String?,
        type: json['type'] as String? ?? 'regular_visit',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
