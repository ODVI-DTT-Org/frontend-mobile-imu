class Call {
  final String id;
  final String clientId;
  final String userId;
  final String phoneNumber;
  final DateTime? dialTime;
  final int? duration;
  final String? notes;
  final String? reason;
  final String? status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Call({
    required this.id,
    required this.clientId,
    required this.userId,
    required this.phoneNumber,
    this.dialTime,
    this.duration,
    this.notes,
    this.reason,
    this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Call copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? phoneNumber,
    DateTime? dialTime,
    int? duration,
    String? notes,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Call(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dialTime: dialTime ?? this.dialTime,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Call.fromRow(Map<String, dynamic> row) {
    return Call(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      phoneNumber: row['phone_number'] as String,
      dialTime: row['dial_time'] != null ? DateTime.parse(row['dial_time'] as String) : null,
      duration: row['duration'] as int?,
      notes: row['notes'] as String?,
      reason: row['reason'] as String?,
      status: row['status'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'phone_number': phoneNumber,
      'dial_time': dialTime?.toIso8601String(),
      'duration': duration,
      'notes': notes,
      'reason': reason,
      'status': status,
    };
  }
}
