import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/models/release_model.dart';

/// Release API service for backend communication
class ReleaseApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ReleaseApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch releases for a specific client or all releases for current user
  Future<List<Release>> fetchReleases({
    String? clientId,
    String? status,
    String? productType,
    String? loanType,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      debugPrint('ReleaseApiService: Fetching releases...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/releases',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'page': page,
          'perPage': perPage,
          if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
          if (status != null) 'status': status,
          if (productType != null) 'product_type': productType,
          if (loanType != null) 'loan_type': loanType,
        },
      );

      if (response.statusCode == 200) {
        final items = response.data as List<dynamic>? ?? [];
        debugPrint('ReleaseApiService: Got ${items.length} releases from API');

        return items.map((item) {
          final releaseData = item as Map<String, dynamic>;
          return Release.fromRow(releaseData);
        }).toList();
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch releases: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch releases',
        originalError: e,
      );
    }
  }

  /// Fetch single release by ID
  Future<Release?> fetchRelease(String id) async {
    try {
      debugPrint('ReleaseApiService: Fetching release $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/releases/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final releaseData = response.data as Map<String, dynamic>;
        return Release.fromRow(releaseData);
      } else if (response.statusCode == 404) {
        debugPrint('ReleaseApiService: Release not found');
        return null;
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch release',
        originalError: e,
      );
    }
  }

  /// Create a new release
  Future<Release> createRelease(Release release) async {
    try {
      debugPrint('ReleaseApiService: Creating release for client ${release.clientId}...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/releases',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: release.toRow(),
      );

      if (response.statusCode == 201) {
        final releaseData = response.data as Map<String, dynamic>;
        debugPrint('ReleaseApiService: Release created with ID ${releaseData['id']}');
        return Release.fromRow(releaseData);
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create release',
        originalError: e,
      );
    }
  }

  /// Update an existing release
  Future<Release?> updateRelease(String id, Map<String, dynamic> updates) async {
    try {
      debugPrint('ReleaseApiService: Updating release $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.patch(
        '${AppConfig.postgresApiUrl}/releases/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: updates,
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final releaseData = response.data as Map<String, dynamic>;
        debugPrint('ReleaseApiService: Release updated');
        return Release.fromRow(releaseData);
      } else if (response.statusCode == 404) {
        debugPrint('ReleaseApiService: Release not found');
        return null;
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update release',
        originalError: e,
      );
    }
  }

  /// Approve a release
  Future<Release?> approveRelease(String id, {String? notes}) async {
    try {
      debugPrint('ReleaseApiService: Approving release $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/releases/$id/approve',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: notes != null ? {'notes': notes} : {},
      );

      if (response.statusCode == 200) {
        final releaseData = response.data as Map<String, dynamic>;
        debugPrint('ReleaseApiService: Release approved');
        return Release.fromRow(releaseData);
      } else if (response.statusCode == 404) {
        debugPrint('ReleaseApiService: Release not found');
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('ReleaseApiService: Permission denied');
        throw ApiException(message: 'You do not have permission to approve releases');
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to approve release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to approve release',
        originalError: e,
      );
    }
  }

  /// Reject a release
  Future<Release?> rejectRelease(String id, {String? notes}) async {
    try {
      debugPrint('ReleaseApiService: Rejecting release $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/releases/$id/reject',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: notes != null ? {'notes': notes} : {},
      );

      if (response.statusCode == 200) {
        final releaseData = response.data as Map<String, dynamic>;
        debugPrint('ReleaseApiService: Release rejected');
        return Release.fromRow(releaseData);
      } else if (response.statusCode == 404) {
        debugPrint('ReleaseApiService: Release not found');
        return null;
      } else if (response.statusCode == 403) {
        debugPrint('ReleaseApiService: Permission denied');
        throw ApiException(message: 'You do not have permission to reject releases');
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to reject release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to reject release',
        originalError: e,
      );
    }
  }

  /// Delete a release
  Future<bool> deleteRelease(String id) async {
    try {
      debugPrint('ReleaseApiService: Deleting release $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/releases/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('ReleaseApiService: Release deleted');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('ReleaseApiService: Release not found');
        return false;
      } else {
        debugPrint('ReleaseApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ReleaseApiService: DioException - ${e.message}');
      debugPrint('ReleaseApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ReleaseApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete release',
        originalError: e,
      );
    }
  }
}
