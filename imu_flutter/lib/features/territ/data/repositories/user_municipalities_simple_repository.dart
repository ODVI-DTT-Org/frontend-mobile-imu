import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/sync/powersync_service.dart';
import '../models/user_municipalities_simple.dart';

/// Repository for managing user municipality assignments
/// Uses PowerSync for data access
class UserMunicipalitiesSimpleRepository {
  final PowerSyncDatabase _db;

  UserMunicipalitiesSimpleRepository(this._db);

  /// Get all active municipality assignments for a user
  Future<List<UserMunicipalitiesSimple>> getAssignedMunicipalities(String userId) async {
    final results = await _db.getAll(
      'SELECT * FROM user_municipalities_simple WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    return results.map((row) => UserMunicipalitiesSimple.fromRow(row)).toList();
  }

  /// Get specific municipality IDs from assignments
  Future<List<String>> getAssignedMunicipalityIds(String userId) async {
    final assignments = await getAssignedMunicipalities(userId);
    if (assignments.isEmpty) {
      return [];
    }
    return assignments.map((a) => a.municipalityId).toList();
  }

  /// Check if user has any municipality assignments
  Future<bool> hasAssignments(String userId) async {
    final results = await _db.getAll(
      'SELECT COUNT(*) as count FROM user_municipalities_simple WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    if (results.isEmpty) return false;
    return (results.first['count'] as int? ?? 0) > 0;
  }

  /// Watch municipality assignments for a user (reactive)
  Stream<List<UserMunicipalitiesSimple>> watchAssignedMunicipalities(String userId) {
    return _db.watch(
      'SELECT * FROM user_municipalities_simple WHERE user_id = ? AND deleted_at IS NULL ORDER BY assigned_at DESC',
      [userId],
    ).map((results) => results.map((row) => UserMunicipalitiesSimple.fromRow(row)).toList());
  }

  /// Create a new municipality assignment for a user
  Future<void> createAssignment({
    required String userId,
    required String municipalityId,
    String? assignedBy,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.execute(
      '''INSERT INTO user_municipalities_simple (id, user_id, municipality_id, assigned_at, assigned_by)
         VALUES (?, ?, ?, ?, ?)''',
      [id, userId, municipalityId, DateTime.now().toIso8601String(), assignedBy],
    );
  }

  /// Soft delete a municipality assignment for a user
  Future<void> softDeleteMunicipality(String userId, String municipalityId) async {
    await _db.execute(
      'UPDATE user_municipalities_simple SET deleted_at = ? WHERE user_id = ? AND municipality_id = ? AND deleted_at IS NULL',
      [DateTime.now().toIso8601String(), userId, municipalityId],
    );
  }

  /// Restore a soft-deleted municipality assignment
  Future<void> restoreMunicipality(String userId, String municipalityId) async {
    await _db.execute(
      'UPDATE user_municipalities_simple SET deleted_at = NULL WHERE user_id = ? AND municipality_id = ?',
      [userId, municipalityId],
    );
  }

  /// Clear all municipality assignments for a given user (soft delete)
  Future<void> clearAllForUser(String userId) async {
    await _db.execute(
      'UPDATE user_municipalities_simple SET deleted_at = ? WHERE user_id = ? AND deleted_at IS NULL',
      [DateTime.now().toIso8601String(), userId],
    );
  }
}

/// Provider for UserMunicipalitiesSimpleRepository
final userMunicipalitiesRepositoryProvider = FutureProvider<UserMunicipalitiesSimpleRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return UserMunicipalitiesSimpleRepository(db);
});

/// Provider for current user's assigned municipalities
final userAssignedMunicipalitiesProvider = FutureProvider<List<UserMunicipalitiesSimple>>((ref) async {
  // Get current user ID from auth
  final userProfile = ref.watch(userProfileProvider);
  if (userProfile == null || userProfile.value == null) {
    return [];
  }

  final repository = await ref.watch(userMunicipalitiesRepositoryProvider.future);
  return repository.getAssignedMunicipalities(userProfile.value!.userId);
});

/// Provider for current user's assigned municipality IDs (for filtering)
final userAssignedMunicipalityIdsProvider = FutureProvider<List<String>>((ref) async {
  final assignments = await ref.watch(userAssignedMunicipalitiesProvider.future);
  return assignments.map((a) => a.municipalityId).toList();
});

/// Placeholder for userProfileProvider - should be defined in auth module
final userProfileProvider = StateProvider<dynamic>((ref) {
  return null;
});
