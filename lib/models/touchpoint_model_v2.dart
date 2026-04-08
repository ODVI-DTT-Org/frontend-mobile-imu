class TouchpointV2 {
  final String id;
  final String clientId;
  final String userId;
  final String? visitId;
  final String? callId;
  final int touchpointNumber;
  final String type; // Visit | Call
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  TouchpointV2({
    required this.id,
    required this.clientId,
    required this.userId,
    this.visitId,
    this.callId,
    required this.touchpointNumber,
    required this.type,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  TouchpointV2 copyWith({
    String? id,
    String? clientId,
    String? userId,
    String? visitId,
    String? callId,
    int? touchpointNumber,
    String? type,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TouchpointV2(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      visitId: visitId ?? this.visitId,
      callId: callId ?? this.callId,
      touchpointNumber: touchpointNumber ?? this.touchpointNumber,
      type: type ?? this.type,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory TouchpointV2.fromRow(Map<String, dynamic> row) {
    return TouchpointV2(
      id: row['id'] as String,
      clientId: row['client_id'] as String,
      userId: row['user_id'] as String,
      visitId: row['visit_id'] as String?,
      callId: row['call_id'] as String?,
      touchpointNumber: row['touchpoint_number'] as int,
      type: row['type'] as String,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'visit_id': visitId,
      'call_id': callId,
      'touchpoint_number': touchpointNumber,
      'type': type,
      'rejection_reason': rejectionReason,
    };
  }
}
