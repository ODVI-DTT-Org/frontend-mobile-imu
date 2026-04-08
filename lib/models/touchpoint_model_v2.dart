import '../core/utils/date_utils.dart';

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
    // Validate required fields
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('TouchpointV2: id is required and cannot be empty');
    }

    final clientId = row['client_id']?.toString();
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('TouchpointV2: client_id is required and cannot be empty');
    }

    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('TouchpointV2: user_id is required and cannot be empty');
    }

    // Validate type enum
    final type = row['type']?.toString();
    if (type == null || (type != 'Visit' && type != 'Call')) {
      throw ArgumentError('TouchpointV2: type must be "Visit" or "Call", got: $type');
    }

    // Parse and validate touchpoint number
    final touchpointNumberValue = row['touchpoint_number'];
    int touchpointNumber;
    if (touchpointNumberValue == null) {
      throw ArgumentError('TouchpointV2: touchpoint_number is required');
    } else if (touchpointNumberValue is int) {
      touchpointNumber = touchpointNumberValue;
    } else if (touchpointNumberValue is String) {
      touchpointNumber = int.tryParse(touchpointNumberValue) ??
                       (throw ArgumentError('TouchpointV2: touchpoint_number must be a valid integer, got: $touchpointNumberValue'));
    } else {
      throw ArgumentError('TouchpointV2: touchpoint_number must be an integer, got: ${touchpointNumberValue.runtimeType}');
    }

    if (touchpointNumber < 1 || touchpointNumber > 7) {
      throw ArgumentError('TouchpointV2: touchpoint_number must be between 1 and 7, got: $touchpointNumber');
    }

    // Parse dates safely
    final createdAt = DateUtils.safeParse(row['created_at']);
    if (createdAt == null) {
      throw ArgumentError('TouchpointV2: created_at is required and must be a valid date');
    }

    final updatedAt = DateUtils.safeParse(row['updated_at']);
    if (updatedAt == null) {
      throw ArgumentError('TouchpointV2: updated_at is required and must be a valid date');
    }

    // Validate that either visitId or callId is set, but not both
    final visitId = row['visit_id']?.toString();
    final callId = row['call_id']?.toString();

    if (visitId != null && callId != null) {
      throw ArgumentError('TouchpointV2: cannot have both visit_id and call_id set');
    }

    if (visitId == null && callId == null) {
      throw ArgumentError('TouchpointV2: must have either visit_id or call_id set');
    }

    // Validate type matches the foreign key
    if (type == 'Visit' && visitId == null) {
      throw ArgumentError('TouchpointV2: type is "Visit" but visit_id is null');
    }
    if (type == 'Call' && callId == null) {
      throw ArgumentError('TouchpointV2: type is "Call" but call_id is null');
    }

    return TouchpointV2(
      id: id,
      clientId: clientId,
      userId: userId,
      visitId: visitId,
      callId: callId,
      touchpointNumber: touchpointNumber,
      type: type,
      rejectionReason: row['rejection_reason']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
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

  /// Check if this touchpoint is a visit
  bool get isVisit => type == 'Visit';

  /// Check if this touchpoint is a call
  bool get isCall => type == 'Call';

  /// Get the foreign key ID (either visitId or callId)
  String? get foreignKeyId => isVisit ? visitId : callId;

  /// Get the next touchpoint number
  int get nextTouchpointNumber {
    if (touchpointNumber >= 7) return 7;
    return touchpointNumber + 1;
  }

  /// Check if this is the last touchpoint
  bool get isLastTouchpoint => touchpointNumber == 7;

  /// Get the expected type for the next touchpoint
  String get nextTouchpointType {
    // Touchpoint pattern: Visit(1) -> Call(2) -> Call(3) -> Visit(4) -> Call(5) -> Call(6) -> Visit(7)
    switch (touchpointNumber) {
      case 1:
      case 3:
      case 6:
        return 'Call';
      case 2:
      case 5:
        return 'Call';
      case 4:
        return 'Call';
      case 7:
        return 'Visit'; // Completed
      default:
        return 'Visit';
    }
  }
}
