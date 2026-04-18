import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/core/config/app_config.dart';

/// Visit API service for creating and managing visits
class VisitApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  VisitApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        )),
        _authService = authService ?? JwtAuthService();

  /// Create a visit record with GPS and odometer data
  ///
  /// Parameters:
  /// - [clientId]: Client ID
  /// - [timeIn]: Visit start time (ISO 8601 string or DateTime)
  /// - [timeOut]: Visit end time (ISO 8601 string or DateTime)
  /// - [odometerArrival]: Odometer reading at arrival
  /// - [odometerDeparture]: Odometer reading at departure
  /// - [photoUrl]: Optional uploaded photo URL (use [photoFile] for FormData upload)
  /// - [photoFile]: Optional photo file to upload with visit data (single request)
  /// - [notes]: Optional visit notes
  /// - [type]: Visit type ('regular_visit' or 'release_loan')
  /// - [latitude]: Optional GPS latitude
  /// - [longitude]: Optional GPS longitude
  /// - [address]: Optional GPS address
  ///
  /// Returns [Map] with visit data, or null if failed
  ///
  /// Note: If [photoFile] is provided, it will be uploaded with the visit data
  /// in a single multipart/form-data request. Otherwise, sends as JSON.
  Future<Map<String, dynamic>?> createVisit({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    String? photoUrl,
    File? photoFile,
    String? notes,
    String? type,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      debugPrint('VisitApiService: Creating visit for client $clientId');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('VisitApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      late final dynamic response;

      // If photo file is provided, use FormData (single request with photo upload)
      if (photoFile != null) {
        debugPrint('VisitApiService: Using FormData with photo upload');

        final formData = FormData.fromMap({
          'client_id': clientId,
          'time_in': timeIn,
          'time_out': timeOut,
          'odometer_arrival': odometerArrival,
          'odometer_departure': odometerDeparture,
          if (notes != null) 'notes': notes,
          if (type != null) 'type': type,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
          'photo': await MultipartFile.fromFile(
            photoFile.path,
            filename: photoFile.path.split('/').last.split('\\').last,
          ),
        });

        debugPrint('VisitApiService: FormData fields prepared');
        debugPrint('VisitApiService: Photo file: ${photoFile.path}');

        response = await _dio.post(
          '${AppConfig.postgresApiUrl}/visits',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              // Don't set Content-Type manually - Dio will set it with proper boundary
            },
          ),
          data: formData,
        );
      } else {
        // Regular JSON request (no photo or photo already uploaded)
        final data = {
          'client_id': clientId,
          'time_in': timeIn,
          'time_out': timeOut,
          'odometer_arrival': odometerArrival,
          'odometer_departure': odometerDeparture,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (notes != null) 'notes': notes,
          if (type != null) 'type': type,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
        };

        response = await _dio.post(
          '${AppConfig.postgresApiUrl}/visits',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
          data: data,
        );
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final visitData = response.data as Map<String, dynamic>;
        debugPrint('VisitApiService: Visit created successfully: ${visitData['id']}');
        return visitData;
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

  /// Fetch all visits for a specific client
  Future<List<Map<String, dynamic>>> getVisitsByClientId(String clientId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) throw ApiException(message: 'Not authenticated');

      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/visits',
        queryParameters: {'client_id': clientId, 'source': 'CMS', 'limit': 100},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) return List<Map<String, dynamic>>.from(data);
        return [];
      }
      return [];
    } on DioException catch (e) {
      debugPrint('VisitApiService: getVisitsByClientId error - ${e.message}');
      return [];
    }
  }
}

/// Provider for VisitApiService
final visitApiServiceProvider = Provider<VisitApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return VisitApiService(authService: jwtAuth);
});
