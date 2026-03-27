import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:powersync/powersync.dart';
import '../../core/utils/logger.dart';
import '../../features/profile/data/models/user_profile.dart';
import 'powersync_service.dart';

/// Service for handling offline authentication
class OfflineAuthService {
  final FlutterSecureStorage _secureStorage;
  final PowerSyncDatabase _db;

  OfflineAuthService(this._secureStorage, this._db);

  /// Check if user can access app offline
  Future<bool> canAccessOffline() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      if (accessToken == null) {
        return false;
      }

      // Check if token is expired (with 5 minute buffer)
      if (JwtDecoder.isExpired(accessToken)) {
        // Token expired - try to refresh if online
        return false;
      }

      return true;
    } catch (e) {
      logError('Failed to check offline access', e);
      return false;
    }
  }

  /// Get cached user profile for offline access
  Future<UserProfile?> getCachedUserProfile() async {
    try {
      final results = await _db.getAll(
        'SELECT * FROM user_profiles LIMIT 1',
      );

      if (results.isEmpty) return null;

      final row = results.first;
      // Convert the row to a Map<String, dynamic> for fromJson
      final json = <String, dynamic>{
        'id': row['id'] as String? ?? row['user_id'] as String,
        'employeeId': row['employee_id'] as String? ?? '',
        'firstName': row['first_name'] as String? ?? (row['name'] as String?)?.split(' ').first ?? '',
        'lastName': row['last_name'] as String? ?? (row['name'] as String?)?.split(' ').last ?? '',
        'email': row['email'] as String,
        'phone': row['phone'] as String? ?? '',
        'role': row['role'] as String?,
        'profilePhotoUrl': row['profile_photo_url'] as String? ?? row['avatar_url'] as String?,
        'createdAt': DateTime.now().toIso8601String(),
      };
      return UserProfile.fromJson(json);
    } catch (e) {
      logError('Failed to get cached user profile', e);
      return null;
    }
  }

  /// Store tokens after successful login
  Future<void> storeAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    logDebug('Auth tokens stored');
  }

  /// Clear all auth data (logout)
  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'powersync_token');
    logDebug('Auth data cleared');
  }

  /// Cache user profile for offline access
  Future<void> cacheUserProfile(UserProfile profile) async {
    await _db.execute(
      '''INSERT OR REPLACE INTO user_profiles
      (id, employee_id, first_name, last_name, email, phone, role, profile_photo_url, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        profile.id,
        profile.employeeId,
        profile.firstName,
        profile.lastName,
        profile.email,
        profile.phone,
        profile.role,
        profile.profilePhotoUrl,
        profile.createdAt.toIso8601String(),
      ],
    );
    logDebug('User profile cached');
  }

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');
      if (accessToken == null) return null;

      final decodedToken = JwtDecoder.decode(accessToken);
      final exp = decodedToken['exp'] as int?;
      if (exp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      logError('Failed to get token expiry', e);
      return null;
    }
  }

  /// Check if token needs refresh (within 5 minutes of expiry)
  Future<bool> needsRefresh() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    final now = DateTime.now();
    final threshold = const Duration(minutes: 5);

    return now.add(threshold).isAfter(expiry);
  }
}

/// Provider for offline auth service
final offlineAuthProvider = FutureProvider<OfflineAuthService>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return OfflineAuthService(
    const FlutterSecureStorage(),
    db,
  );
});
