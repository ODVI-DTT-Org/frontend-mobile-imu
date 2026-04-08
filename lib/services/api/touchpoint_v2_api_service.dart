import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/models/touchpoint_model_v2.dart';

/// Touchpoint V2 API service for normalized touchpoints with visit/call references
class TouchpointV2ApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  TouchpointV2ApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch touchpoints for a specific client or all touchpoints for current user
  Future<List<TouchpointV2>> fetchTouchpoints({
    String? clientId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      debugPrint('TouchpointV2ApiService: Fetching touchpoints...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointV2ApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/touchpoints',
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
        },
      );

      if (response.statusCode == 200) {
        final items = response.data as List<dynamic>? ?? [];
        debugPrint('TouchpointV2ApiService: Got ${items.length} touchpoints from API');

        return items.map((item) {
          final touchpointData = item as Map<String, dynamic>;
          return TouchpointV2.fromRow(touchpointData);
        }).toList();
      } else {
        debugPrint('TouchpointV2ApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch touchpoints: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointV2ApiService: DioException - ${e.message}');
      debugPrint('TouchpointV2ApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointV2ApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoints',
        originalError: e,
      );
    }
  }

  /// Fetch single touchpoint by ID
  Future<TouchpointV2?> fetchTouchpoint(String id) async {
    try {
      debugPrint('TouchpointV2ApiService: Fetching touchpoint $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointV2ApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/touchpoints/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final touchpointData = response.data as Map<String, dynamic>;
        return TouchpointV2.fromRow(touchpointData);
      } else if (response.statusCode == 404) {
        debugPrint('TouchpointV2ApiService: Touchpoint not found');
        return null;
      } else {
        debugPrint('TouchpointV2ApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointV2ApiService: DioException - ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointV2ApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoint',
        originalError: e,
      );
    }
  }

  /// Create a new touchpoint (links to existing visit or call)
  Future<TouchpointV2> createTouchpoint(TouchpointV2 touchpoint) async {
    try {
      debugPrint('TouchpointV2ApiService: Creating touchpoint for client ${touchpoint.clientId}...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointV2ApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/touchpoints',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: touchpoint.toRow(),
      );

      if (response.statusCode == 201) {
        final touchpointData = response.data as Map<String, dynamic>;
        debugPrint('TouchpointV2ApiService: Touchpoint created with ID ${touchpointData['id']}');
        return TouchpointV2.fromRow(touchpointData);
      } else {
        debugPrint('TouchpointV2ApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointV2ApiService: DioException - ${e.message}');
      debugPrint('TouchpointV2ApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointV2ApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create touchpoint',
        originalError: e,
      );
    }
  }

  /// Update an existing touchpoint
  Future<TouchpointV2?> updateTouchpoint(String id, Map<String, dynamic> updates) async {
    try {
      debugPrint('TouchpointV2ApiService: Updating touchpoint $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointV2ApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/touchpoints/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: updates,
      );

      if (response.statusCode == 200) {
        final touchpointData = response.data as Map<String, dynamic>;
        debugPrint('TouchpointV2ApiService: Touchpoint updated');
        return TouchpointV2.fromRow(touchpointData);
      } else if (response.statusCode == 404) {
        debugPrint('TouchpointV2ApiService: Touchpoint not found');
        return null;
      } else {
        debugPrint('TouchpointV2ApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointV2ApiService: DioException - ${e.message}');
      debugPrint('TouchpointV2ApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointV2ApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update touchpoint',
        originalError: e,
      );
    }
  }

  /// Delete a touchpoint
  Future<bool> deleteTouchpoint(String id) async {
    try {
      debugPrint('TouchpointV2ApiService: Deleting touchpoint $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointV2ApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/touchpoints/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('TouchpointV2ApiService: Touchpoint deleted');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('TouchpointV2ApiService: Touchpoint not found');
        return false;
      } else {
        debugPrint('TouchpointV2ApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointV2ApiService: DioException - ${e.message}');
      debugPrint('TouchpointV2ApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointV2ApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete touchpoint',
        originalError: e,
      );
    }
  }

  /// Link touchpoint to visit
  Future<TouchpointV2?> linkToVisit(String touchpointId, String visitId) async {
    return updateTouchpoint(touchpointId, {'visit_id': visitId, 'call_id': null});
  }

  /// Link touchpoint to call
  Future<TouchpointV2?> linkToCall(String touchpointId, String callId) async {
    return updateTouchpoint(touchpointId, {'call_id': callId, 'visit_id': null});
  }
}
