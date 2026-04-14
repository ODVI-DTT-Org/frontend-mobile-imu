import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/models/call_model.dart';

/// Call API service for backend communication
class CallApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  CallApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch calls for a specific client or all calls for current user
  Future<List<Call>> fetchCalls({
    String? clientId,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      debugPrint('CallApiService: Fetching calls...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('CallApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/calls',
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
        debugPrint('CallApiService: Got ${items.length} calls from API');

        return items.map((item) {
          final callData = item as Map<String, dynamic>;
          return Call.fromRow(callData);
        }).toList();
      } else {
        debugPrint('CallApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch calls: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CallApiService: DioException - ${e.message}');
      debugPrint('CallApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('CallApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch calls',
        originalError: e,
      );
    }
  }

  /// Fetch single call by ID
  Future<Call?> fetchCall(String id) async {
    try {
      debugPrint('CallApiService: Fetching call $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('CallApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/calls/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final callData = response.data as Map<String, dynamic>;
        return Call.fromRow(callData);
      } else if (response.statusCode == 404) {
        debugPrint('CallApiService: Call not found');
        return null;
      } else {
        debugPrint('CallApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch call: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CallApiService: DioException - ${e.message}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('CallApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch call',
        originalError: e,
      );
    }
  }

  /// Create a new call
  Future<Call> createCall(Call call) async {
    try {
      debugPrint('CallApiService: Creating call for client ${call.clientId}...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('CallApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/calls',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: call.toRow(),
      );

      if (response.statusCode == 201) {
        final callData = response.data as Map<String, dynamic>;
        debugPrint('CallApiService: Call created with ID ${callData['id']}');
        return Call.fromRow(callData);
      } else {
        debugPrint('CallApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create call: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CallApiService: DioException - ${e.message}');
      debugPrint('CallApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('CallApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create call',
        originalError: e,
      );
    }
  }

  /// Update an existing call
  Future<Call?> updateCall(String id, Map<String, dynamic> updates) async {
    try {
      debugPrint('CallApiService: Updating call $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('CallApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.patch(
        '${AppConfig.postgresApiUrl}/calls/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: updates,
      );

      if (response.statusCode == 200 || response.statusCode == 206) {
        final callData = response.data as Map<String, dynamic>;
        debugPrint('CallApiService: Call updated');
        return Call.fromRow(callData);
      } else if (response.statusCode == 404) {
        debugPrint('CallApiService: Call not found');
        return null;
      } else {
        debugPrint('CallApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update call: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CallApiService: DioException - ${e.message}');
      debugPrint('CallApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('CallApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update call',
        originalError: e,
      );
    }
  }

  /// Delete a call
  Future<bool> deleteCall(String id) async {
    try {
      debugPrint('CallApiService: Deleting call $id...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('CallApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/calls/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('CallApiService: Call deleted');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('CallApiService: Call not found');
        return false;
      } else {
        debugPrint('CallApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete call: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CallApiService: DioException - ${e.message}');
      debugPrint('CallApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('CallApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete call',
        originalError: e,
      );
    }
  }
}
