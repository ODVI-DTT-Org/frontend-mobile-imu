import 'package:hive/hive.dart';
import '../models/user_municipalities_simple.dart';

/// Repository for managing user municipality assignments
class UserMunicipalitiesSimpleRepository {
  static final _userMunicipalitiesSimpleBox = HiveDb<UserMunicipalitiesSimple>? _box;

  static const _userMunicipalitiesSimpleBox =
      HiveDb<UserMunicipalitiesSimple>(UserMunicipalitiesSimple);

  // Get all municipality assignments for a user
  Future<List<UserMunicipalitiesSimple>> getAssignedMunicipalities(String userId) async {
    if (_box == null) {
      await Hive.openBox<UserMunicipalitiesSimple>();
      _box = Hive.box<UserMunicipalitiesSimple>();
    }
    return _box.values.toList();
  }

  /// Get specific municipality IDs from assignments
  Future<List<String>> getAssignedMunicipalityIds(String userId) async {
    final assignments = await getAssignedMunicipalities(userId);
    if (assignments.isEmpty) {
      return [];
    }
    return assignments.map((a) => a.municipalityId).toList();
  }

  /// Clear all municipality assignments for a given user
  Future<void> clearAllForUser(String userId) async {
    await _box.clear();
  }

  /// Create a new municipality assignment for a user
  Future<UserMunicipalitiesSimple> createUserMunicipality({
    required String userId,
    required String municipalityId,
    String? assignedBy,
  }) async {
    await _box.put(key(userId, municipalityId, assignment);
  }

  /// Soft delete a municipality assignment for a user
  Future<void> softDeleteMunicipality(String userId, String municipalityId) async {
    final assignments = await getAssignedMunicipalities(userId);
    final assignment = assignments.firstWhere((a) => a.municipalityId == municipalityId);
    if (assignment == null) {
      await _box.delete(assignment.id);
    } else {
      await _box.put(key(userId, municipalityId, null);
    }
  }
}