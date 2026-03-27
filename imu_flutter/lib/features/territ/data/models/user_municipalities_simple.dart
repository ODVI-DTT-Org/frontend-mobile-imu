import 'package:uuid/uuid.dart';

/// User Municipality assignment model for location-based filtering
/// Uses PSGC municipality IDs
class UserMunicipalitiesSimple {
  final String? id;

  final String userId;

  final String municipalityId;

  final DateTime? assignedAt;

  final String? assignedBy;

  final DateTime? deletedAt;

  UserMunicipalitiesSimple({
    this.id,
    required this.userId,
    required this.municipalityId,
    this.assignedAt,
    this.assignedBy,
    this.deletedAt,
  });

  /// Check if this assignment is active (not soft-deleted)
  bool get isActive => deletedAt == null;

  /// Create from PowerSync/PostgreSQL row
  factory UserMunicipalitiesSimple.fromRow(Map<String, dynamic> row) {
    return UserMunicipalitiesSimple(
      id: row['id'] as String?,
      userId: row['user_id'] as String,
      municipalityId: row['municipality_id'] as String,
      assignedAt: row['assigned_at'] != null
          ? DateTime.parse(row['assigned_at'] as String)
          : null,
      assignedBy: row['assigned_by'] as String?,
      deletedAt: row['deleted_at'] != null
          ? DateTime.parse(row['deleted_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'municipality_id': municipalityId,
        'assigned_at': assignedAt?.toIso8601String(),
        'assigned_by': assignedBy,
        'deleted_at': deletedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return 'UserMunicipalitiesSimple(id: $id, userId: $userId, municipalityId: $municipalityId, isActive: $isActive)';
  }
}
