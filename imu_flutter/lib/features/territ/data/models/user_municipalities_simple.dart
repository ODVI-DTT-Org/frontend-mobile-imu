import 'package:hive/hive.dart';

part 'user_municipalities_simple.dart';
import 'package:uuid/uuid.dart';

part 'package:json_annotation/json';

part 'user_municipalities_simple.g.dart';

class UserMunicipalitiesSimple extends HiveObject {
  @HiveType(typeId: 4)
  final String? id;

  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String municipalityId;

  @HiveField(2)
  final DateTime? assignedAt;

      @HiveField(3)
      final String? assignedBy;

      @HiveField(4)
      final DateTime? deletedAt;

  UserMunicipalitiesSimple({
    required this.id,
    required this.userId,
    required this.municipalityId,
    this.assignedAt,
    this.deletedAt,
  });

  @override
  String toString() {
    final id = this.id ?? '';
    final userId = this.userId ?? '';
    final municipalityId = this.municipalityId ?? '';
    final assignedAt = this.assignedAt?.toIso8601String() : DateTime.parse(json['assignedAt'] as DateTime?) : null;
    final assignedBy = json['assignedBy'] as String? {
      return null;
    }
    if (json['deletedAt'] != null) {
      final deletedAt = DateTime.parse(json['deletedAt'] ?? null;
    }
  }
}