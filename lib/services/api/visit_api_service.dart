import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/models/visit_model.dart';

/// Visit API service for backend communication
class VisitApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  VisitApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch visits for a specific client or all visits for current user
  Future<List<Visit>> fetchVisits({
    String? clientId,
    String? type,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      debugPrint('VisitApiService: Fetching visits...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/visits',
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
          if (type != null) 'type': type,
        },
      );

      if (response.statusCode == 200) {
        final items = response.data as List<dynamic>? ?? [];
        debugPrint('VisitApiService: Got ${items.length} visits from API');

        return items.map((item) {
          final visitData = item as Map<String, dynamic>;
          return Visit.fromRow(visitData);
        }).toList();
      } else {
        debugPrint('VisitApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch visits: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('VisitApiService: DioException - ${e.message}');
      debugPrint('VisitApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('VisitApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch visits',
        originalError: e,
      );
    }
  }

  /// Fetch single visit by ID
  Future<Visit?> fetchVisit(String id) async {
    try {
      debugPrint('VisitApiService: Fetching visit $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/visits/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final visitData = response.data as Map<String, dynamic>;
        return Visit.fromRow(visitData);
      } else if (response.statusCode == 404) {
        debugPrint('VisitApiService: Visit not found');
        return null;
      } else {
        debugPrint('VisitApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('VisitApiService: DioException - ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('VisitApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch visit',
        originalError: e,
      );
    }
  }

  /// Create a new visit
  Future<Visit> createVisit(Visit visit) async {
    try {
      debugPrint('VisitApiService: Creating visit for client ${visit.clientId}...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/visits',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: visit.toRow(),
      );

      if (response.statusCode == 201) {
        final visitData = response.data as Map<String, dynamic>;
        debugPrint('VisitApiService: Visit created with ID ${visitData['id']}');
        return Visit.fromRow(visitData);
      } else {
        debugPrint('VisitApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('VisitApiService: DioException - ${e.message}');
      debugPrint('VisitApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('VisitApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create visit',
        originalError: e,
      );
    }
  }

  /// Update an existing visit
  Future<Visit?> updateVisit(String id, Map<String, dynamic> updates) async {
    try {
      debugPrint('VisitApiService: Updating visit $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.patch(
        '${AppConfig.postgresApiUrl}/visits/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: updates,
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final visitData = response.data as Map<String, dynamic>;
        debugPrint('VisitApiService: Visit updated');
        return Visit.fromRow(visitData);
      } else if (response.statusCode == 404) {
        debugPrint('VisitApiService: Visit not found');
        return null;
      } else {
        debugPrint('VisitApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('VisitApiService: DioException - ${e.message}');
      debugPrint('VisitApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('VisitApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update visit',
        originalError: e,
      );
    }
  }

  /// Delete a visit
  Future<bool> deleteVisit(String id) async {
    try {
      debugPrint('VisitApiService: Deleting visit $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/visits/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('VisitApiService: Visit deleted');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('VisitApiService: Visit not found');
        return false;
      } else {
        debugPrint('VisitApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete visit: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('VisitApiService: DioException - ${e.message}');
      debugPrint('VisitApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('VisitApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete visit',
        originalError: e,
      );
    }
  }
}
