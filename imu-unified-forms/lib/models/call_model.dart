import '../core/utils/date_utils.dart';

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
    // Validate required fields
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Call: id is required and cannot be empty');
    }

    final clientId = row['client_id']?.toString();
    if (clientId == null || clientId.isEmpty) {
      throw ArgumentError('Call: client_id is required and cannot be empty');
    }

    final userId = row['user_id']?.toString();
    if (userId == null || userId.isEmpty) {
      throw ArgumentError('Call: user_id is required and cannot be empty');
    }

    final phoneNumber = row['phone_number']?.toString();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      throw ArgumentError('Call: phone_number is required and cannot be empty');
    }

    // Validate phone number format (basic validation)
    if (!RegExp(r'^[\d\+\-\(\)\s]+$').hasMatch(phoneNumber)) {
      throw ArgumentError('Call: phone_number contains invalid characters: $phoneNumber');
    }

    // Parse dates safely
    final createdAt = DateUtils.safeParse(row['created_at']);
    if (createdAt == null) {
      throw ArgumentError('Call: created_at is required and must be a valid date');
    }

    final updatedAt = DateUtils.safeParse(row['updated_at']);
    if (updatedAt == null) {
      throw ArgumentError('Call: updated_at is required and must be a valid date');
    }

    // Parse optional date
    final dialTime = DateUtils.safeParse(row['dial_time']);

    // Parse duration safely
    int? duration;
    if (row['duration'] != null) {
      if (row['duration'] is int) {
        duration = row['duration'] as int;
        if (duration < 0) {
          throw ArgumentError('Call: duration cannot be negative, got: $duration');
        }
      } else if (row['duration'] is String) {
        duration = int.tryParse(row['duration'] as String);
        if (duration != null && duration < 0) {
          throw ArgumentError('Call: duration cannot be negative, got: $duration');
        }
      }
    }

    return Call(
      id: id,
      clientId: clientId,
      userId: userId,
      phoneNumber: phoneNumber,
      dialTime: dialTime,
      duration: duration,
      notes: row['notes']?.toString(),
      reason: row['reason']?.toString(),
      status: row['status']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toRow() {
    return {
      'id': id,
      'client_id': clientId,
      'user_id': userId,
      'phone_number': phoneNumber,
      'dial_time': DateUtils.toIso8601String(dialTime),
      'duration': duration,
      'notes': notes,
      'reason': reason,
      'status': status,
    };
  }
}
