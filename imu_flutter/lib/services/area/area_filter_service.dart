import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../services/auth/jwt_auth_service.dart';

/// User location/assignment model
/// Supports both new format (separate province, municipality) and legacy format (municipality_id)
class UserLocation {
  final String? userId; // Optional - not returned by backend
  final String province; // Province code (e.g., "CEBU")
  final String municipality; // Municipality name (e.g., "CEBU CITY")
  final String? municipalityName; // Alias for municipality (for backward compatibility)
  final DateTime? assignedAt;

  const UserLocation({
    this.userId,
    required this.province,
    required this.municipality,
    this.municipalityName,
    this.assignedAt,
  });

  /// Computed municipalityId for backward compatibility
  /// Format: "PROVINCE-MUNICIPALITY"
  String get municipalityId => '$province-$municipality';

  /// Create from JSON (supports both new and legacy formats)
  factory UserLocation.fromJson(Map<String, dynamic> json) {
    // Try new format first (separate province, municipality)
    if (json.containsKey('province') && json.containsKey('municipality_name')) {
      return UserLocation(
        userId: json['user_id'] as String?,
        province: json['province'] as String? ?? '',
        municipality: json['municipality_name'] as String? ?? '',
        municipalityName: json['municipality_name'] as String?,
        assignedAt: json['assigned_at'] != null
            ? DateTime.parse(json['assigned_at'] as String)
            : null,
      );
    }

    // Fall back to legacy format (municipality_id)
    final municipalityId = json['municipality_id'] as String? ?? '';
    final parts = municipalityId.split('-');
    return UserLocation(
      userId: json['user_id'] as String?,
      province: parts.isNotEmpty ? parts[0] : '',
      municipality: parts.length > 1 ? parts.sublist(1).join('-') : '',
      municipalityName: json['municipality_name'] as String?,
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : null,
    );
  }

  @override
  String toString() => 'UserLocation(province: $province, municipality: $municipality)';
}

/// Service to fetch and cache user's assigned areas (municipalities)
class AreaFilterService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  static const _locationsKey = 'user_locations';
  static const _locationsTimestampKey = 'user_locations_timestamp';
  static const _cacheExpiry = Duration(hours: 6); // Cache for 6 hours

  AreaFilterService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.postgresApiUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        )),
        _storage = storage ?? const FlutterSecureStorage();

  /// Fetch user's assigned municipalities from backend
  Future<List<UserLocation>> fetchUserLocations(String accessToken, String userId) async {
    try {
      logDebug('Fetching user locations from backend...');

      final response = await _dio.get(
        '/users/$userId/municipalities',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> locationsJson = response.data['items'] ?? [];
        final locations = locationsJson
            .map((json) => UserLocation.fromJson(json as Map<String, dynamic>))
            .toList();

        logDebug('Fetched ${locations.length} locations from backend');
        await _cacheLocations(locations);
        return locations;
      } else {
        logError('Failed to fetch user locations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      logError('Error fetching user locations from backend', e);
      // Return cached locations if available
      return await getCachedLocations();
    }
  }

  /// Get cached locations from secure storage
  Future<List<UserLocation>> getCachedLocations() async {
    try {
      final locationsJson = await _storage.read(key: _locationsKey);
      final timestampJson = await _storage.read(key: _locationsTimestampKey);

      if (locationsJson == null || timestampJson == null) {
        return [];
      }

      // Check if cache is expired
      final timestamp = DateTime.parse(timestampJson);
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        logDebug('User locations cache expired');
        await clearCache();
        return [];
      }

      final List<dynamic> locationsList = jsonDecode(locationsJson) as List<dynamic>;
      return locationsList
          .map((json) => UserLocation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logError('Error reading cached locations', e);
      return [];
    }
  }

  /// Cache locations in secure storage
  Future<void> _cacheLocations(List<UserLocation> locations) async {
    try {
      final locationsJson = jsonEncode(
        locations.map((l) => {
          if (l.userId != null) 'user_id': l.userId,
          'province': l.province,
          'municipality': l.municipality,
          'municipality_name': l.municipalityName ?? l.municipality,
          'municipality_id': l.municipalityId, // For backward compatibility
          'assigned_at': l.assignedAt?.toIso8601String(),
        }).toList(),
      );

      final timestamp = DateTime.now().toIso8601String();

      await _storage.write(key: _locationsKey, value: locationsJson);
      await _storage.write(key: _locationsTimestampKey, value: timestamp);

      logDebug('Cached ${locations.length} user locations');
    } catch (e) {
      logError('Error caching user locations', e);
    }
  }

  /// Clear cached locations
  Future<void> clearCache() async {
    try {
      await _storage.delete(key: _locationsKey);
      await _storage.delete(key: _locationsTimestampKey);
      logDebug('Cleared user locations cache');
    } catch (e) {
      logError('Error clearing user locations cache', e);
    }
  }

  /// Get list of assigned municipality IDs
  Future<List<String>> getAssignedMunicipalityIds() async {
    final locations = await getCachedLocations();
    return locations.map((l) => l.municipalityId).toSet().toList();
  }

  /// Check if a municipality is assigned to the user
  Future<bool> isMunicipalityAssigned(String municipalityId) async {
    final assignedIds = await getAssignedMunicipalityIds();
    return assignedIds.contains(municipalityId);
  }

  /// Filter clients by assigned municipalities
  /// Returns list of client IDs that are in assigned municipalities
  Future<List<String>> filterClientsByMunicipality(List<Map<String, dynamic>> clients) async {
    final assignedIds = await getAssignedMunicipalityIds();

    if (assignedIds.isEmpty) {
      // No area restriction, return all clients
      return clients.map((c) => c['id'] as String).toList();
    }

    // Filter clients by assigned municipalities
    return clients
        .where((client) {
          final clientMunicipality = client['municipality_id'] as String?;
          return clientMunicipality != null && assignedIds.contains(clientMunicipality);
        })
        .map((c) => c['id'] as String)
        .toList();
  }
}

/// Provider for AreaFilterService
final areaFilterServiceProvider = Provider<AreaFilterService>((ref) {
  return AreaFilterService();
});
