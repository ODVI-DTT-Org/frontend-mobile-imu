import 'package:imu_flutter/features/psgc/data/models/psgc_models.dart';

/// User Municipality assignment model for location-based filtering
/// Uses separate province and municipality columns for efficient querying
class UserLocation {
  final String? id;

  final String userId;

  final String province;

  final String municipality;

  final DateTime? assignedAt;

  final String? assignedBy;

  final DateTime? deletedAt;

  UserLocation({
    this.id,
    required this.userId,
    required this.province,
    required this.municipality,
    this.assignedAt,
    this.assignedBy,
    this.deletedAt,
  });

  /// Check if this assignment is active (not soft-deleted)
  bool get isActive => deletedAt == null;

  /// Get legacy municipality ID format for backward compatibility
  String get municipalityId => '$province-$municipality';

  /// Check if a client matches this location assignment
  bool matchesClient(String? clientProvince, String? clientMunicipality) {
    return clientProvince == province && clientMunicipality == municipality;
  }

  /// Check if a PSGC municipality matches this location assignment
  bool matchesPsgcMunicipality(PsgcMunicipality mun) {
    return mun.province == province && mun.municipality == municipality;
  }

  /// Create from PowerSync/PostgreSQL row (uses province and municipality columns)
  factory UserLocation.fromRow(Map<String, dynamic> row) {
    return UserLocation(
      id: row['id'] as String?,
      userId: row['user_id'] as String,
      province: row['province'] as String? ?? '',
      municipality: row['municipality'] as String? ?? '',
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
    return 'UserLocation(id: $id, userId: $userId, province: $province, municipality: $municipality, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserLocation &&
        other.id == id &&
        other.userId == userId &&
        other.province == province &&
        other.municipality == municipality &&
        other.assignedAt == assignedAt &&
        other.assignedBy == assignedBy &&
        other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        province.hashCode ^
        municipality.hashCode ^
        assignedAt.hashCode ^
        assignedBy.hashCode ^
        deletedAt.hashCode;
  }
}

/// Legacy alias for backward compatibility
typedef UserMunicipalitiesSimple = UserLocation;
