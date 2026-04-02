import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:powersync/powersync.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';
import '../models/user_municipalities_simple.dart';

/// Repository for managing user location assignments
/// Uses PowerSync for data access
class UserLocationRepository {
  final PowerSyncDatabase _db;

  UserLocationRepository(this._db);

  /// Get all active location assignments for a user
  Future<List<UserLocation>> getAssignedLocations(String userId) async {
    // PostgreSQL schema format: province and municipality columns
    final results = await _db.getAll(
      'SELECT * FROM user_locations WHERE user_id = ? AND deleted_at IS NULL ORDER BY assigned_at DESC',
      [userId],
    );

    // Parse using the standard fromRow method which uses province and municipality columns
    return results.map((row) => UserLocation.fromRow(row)).toList();
  }

  /// Get specific municipality IDs from assignments (legacy format for backward compatibility)
  Future<List<String>> getAssignedMunicipalityIds(String userId) async {
    final assignments = await getAssignedLocations(userId);
    if (assignments.isEmpty) {
      return [];
    }
    // Generate legacy format: "province-municipality"
    return assignments.map((a) => '${a.province}-${a.municipality}').toList();
  }

  /// Get assigned provinces and municipalities as a set for efficient lookup
  Future<Set<String>> getAssignedLocationKeys(String userId) async {
    final assignments = await getAssignedLocations(userId);
    if (assignments.isEmpty) {
      return {};
    }
    // Return set of "province-municipality" keys for easy matching
    return assignments.map((a) => '${a.province}-${a.municipality}').toSet();
  }

  /// Check if a client is in the user's assigned territories
  Future<bool> isClientInAssignedTerritories(
    String userId,
    String? clientProvince,
    String? clientMunicipality,
  ) async {
    if (clientProvince == null || clientMunicipality == null) {
      return false;
    }

    final assignments = await getAssignedLocations(userId);
    return assignments.any((assignment) =>
      assignment.province == clientProvince &&
      assignment.municipality == clientMunicipality
    );
  }

  /// Check if user has any location assignments
  Future<bool> hasAssignments(String userId) async {
    final results = await _db.getAll(
      'SELECT COUNT(*) as count FROM user_locations WHERE user_id = ? AND deleted_at IS NULL',
      [userId],
    );
    if (results.isEmpty) return false;
    return (results.first['count'] as int? ?? 0) > 0;
  }

  /// Watch location assignments for a user (reactive)
  Stream<List<UserLocation>> watchAssignedLocations(String userId) {
    return _db.watch(
      'SELECT * FROM user_locations WHERE user_id = ? AND deleted_at IS NULL ORDER BY assigned_at DESC',
      parameters: [userId],
    ).map((results) {
      // PostgreSQL schema format: province and municipality columns
      return results.map((row) => UserLocation.fromRow(row)).toList();
    });
  }

  /// Create a new location assignment for a user
  Future<void> createAssignment({
    required String userId,
    required String province,
    required String municipality,
    String? assignedBy,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.execute(
      '''INSERT INTO user_locations (id, user_id, province, municipality, assigned_at, assigned_by)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [id, userId, province, municipality, DateTime.now().toIso8601String(), assignedBy],
    );
  }

  /// Create a new location assignment using province and municipality
  Future<void> createAssignmentWithId({
    required String userId,
    required String municipalityId,
    String? assignedBy,
  }) async {
    // Parse municipality_id to get province and municipality
    final parts = municipalityId.split('-');
    if (parts.length < 2) {
      throw ArgumentError('Invalid municipality_id format. Expected "province-municipality"');
    }
    final province = parts[0];
    final municipality = parts.slice(1).join('-');

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _db.execute(
      '''INSERT INTO user_locations (id, user_id, province, municipality, assigned_at, assigned_by)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [id, userId, province, municipality, DateTime.now().toIso8601String(), assignedBy],
    );
  }

  /// Soft delete a location assignment for a user (by province and municipality)
  Future<void> softDeleteLocation(String userId, String province, String municipality) async {
    await _db.execute(
      'UPDATE user_locations SET deleted_at = ? WHERE user_id = ? AND province = ? AND municipality = ? AND deleted_at IS NULL',
      [DateTime.now().toIso8601String(), userId, province, municipality],
    );
  }

  /// Soft delete a location assignment using municipality_id directly
  Future<void> softDeleteLocationById(String userId, String municipalityId) async {
    // Parse municipality_id to get province and municipality
    final parts = municipalityId.split('-');
    if (parts.length < 2) {
      throw ArgumentError('Invalid municipality_id format. Expected "province-municipality"');
    }
    final province = parts[0];
    final municipality = parts.slice(1).join('-');

    await _db.execute(
      'UPDATE user_locations SET deleted_at = ? WHERE user_id = ? AND province = ? AND municipality = ? AND deleted_at IS NULL',
      [DateTime.now().toIso8601String(), userId, province, municipality],
    );
  }

  /// Restore a soft-deleted location assignment
  Future<void> restoreLocation(String userId, String province, String municipality) async {
    await _db.execute(
      'UPDATE user_locations SET deleted_at = NULL WHERE user_id = ? AND province = ? AND municipality = ?',
      [userId, province, municipality],
    );
  }

  /// Restore a soft-deleted location assignment using municipality_id
  Future<void> restoreLocationById(String userId, String municipalityId) async {
    // Parse municipality_id to get province and municipality
    final parts = municipalityId.split('-');
    if (parts.length < 2) {
      throw ArgumentError('Invalid municipality_id format. Expected "province-municipality"');
    }
    final province = parts[0];
    final municipality = parts.slice(1).join('-');

    await _db.execute(
      'UPDATE user_locations SET deleted_at = NULL WHERE user_id = ? AND province = ? AND municipality = ?',
      [userId, province, municipality],
    );
  }

  /// Clear all location assignments for a given user (soft delete)
  Future<void> clearAllForUser(String userId) async {
    await _db.execute(
      'UPDATE user_locations SET deleted_at = ? WHERE user_id = ? AND deleted_at IS NULL',
      [DateTime.now().toIso8601String(), userId],
    );
  }
}

/// Provider for UserLocationRepository
final userLocationRepositoryProvider = FutureProvider<UserLocationRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return UserLocationRepository(db);
});

/// Provider for current user's assigned locations
final userAssignedLocationsProvider = FutureProvider<List<UserLocation>>((ref) async {
  // Get current user ID from auth
  final userProfile = ref.watch(userProfileProvider);
  if (userProfile == null || userProfile.value == null) {
    return [];
  }

  final repository = await ref.watch(userLocationRepositoryProvider.future);
  return repository.getAssignedLocations(userProfile.value!.userId);
});

/// Provider for current user's assigned location keys (for filtering)
final userAssignedLocationKeysProvider = FutureProvider<Set<String>>((ref) async {
  // Get current user ID from auth
  final userProfile = ref.watch(userProfileProvider);
  if (userProfile == null || userProfile.value == null) {
    return {};
  }

  final repository = await ref.watch(userLocationRepositoryProvider.future);
  return repository.getAssignedLocationKeys(userProfile.value!.userId);
});

/// Legacy provider aliases for backward compatibility
final userMunicipalitiesRepositoryProvider = userLocationRepositoryProvider;
final userAssignedMunicipalitiesProvider = userAssignedLocationsProvider;
final userAssignedMunicipalityIdsProvider = userAssignedLocationKeysProvider;

/// Placeholder for userProfileProvider - should be defined in auth module
final userProfileProvider = StateProvider<dynamic>((ref) {
  return null;
});
