import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';

/// Touchpoint API service
class TouchpointApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  TouchpointApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  /// Fetch touchpoints for a specific client or all touchpoints for current user
  Future<List<Touchpoint>> fetchTouchpoints({
    String? clientId,
    int page = 1,
    int perPage = 50,
    String? sort,
    String? expand,
  }) async {
    try {
      debugPrint('TouchpointApiService: Fetching touchpoints...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
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
          if (sort != null) 'sort': sort,
          if (expand != null) 'expand': expand,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('TouchpointApiService: Got ${items.length} touchpoints from API');

        return items.map((item) {
          final touchpointData = item as Map<String, dynamic>;
          debugPrint('TouchpointApiService: Processing touchpoint: ${touchpointData['id']}');
          // Use fromJson to handle both snake_case and camelCase
          return Touchpoint.fromJson(touchpointData);
        }).toList();
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch touchpoints: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoints',
        originalError: e,
      );
    }
  }

  /// Fetch single touchpoint by ID
  Future<Touchpoint?> fetchTouchpoint(String id) async {
    try {
      debugPrint('TouchpointApiService: Fetching touchpoint $id...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
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
        debugPrint('TouchpointApiService: Got touchpoint: ${touchpointData['id']}');
        return Touchpoint.fromJson(touchpointData);
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Touchpoint not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch touchpoint',
        originalError: e,
      );
    }
  }

  /// Create touchpoint
  Future<Touchpoint?> createTouchpoint(Touchpoint touchpoint) async {
    try {
      debugPrint('TouchpointApiService: Creating touchpoint...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Convert Touchpoint model to API request format (snake_case)
      final requestData = {
        'client_id': touchpoint.clientId,
        'touchpoint_number': touchpoint.touchpointNumber,
        'type': touchpoint.type.apiValue,
        'date': touchpoint.date.toIso8601String(),
        if (touchpoint.address != null) 'address': touchpoint.address,
        if (touchpoint.timeArrival != null) 'time_arrival': '${touchpoint.timeArrival!.hour}:${touchpoint.timeArrival!.minute.toString().padLeft(2, '0')}',
        if (touchpoint.timeDeparture != null) 'time_departure': '${touchpoint.timeDeparture!.hour}:${touchpoint.timeDeparture!.minute.toString().padLeft(2, '0')}',
        if (touchpoint.odometerArrival != null) 'odometer_arrival': touchpoint.odometerArrival,
        if (touchpoint.odometerDeparture != null) 'odometer_departure': touchpoint.odometerDeparture,
        'reason': touchpoint.reason.apiValue,
        'status': touchpoint.status.apiValue,
        if (touchpoint.nextVisitDate != null) 'next_visit_date': touchpoint.nextVisitDate!.toIso8601String(),
        if (touchpoint.remarks != null) 'notes': touchpoint.remarks,
        if (touchpoint.photoPath != null) 'photo_url': touchpoint.photoPath,
        if (touchpoint.audioPath != null) 'audio_url': touchpoint.audioPath,
        if (touchpoint.latitude != null) 'latitude': touchpoint.latitude,
        if (touchpoint.longitude != null) 'longitude': touchpoint.longitude,
        // Time In/Out fields
        if (touchpoint.timeIn != null) 'time_in': touchpoint.timeIn!.toIso8601String(),
        if (touchpoint.timeInGpsLat != null) 'time_in_gps_lat': touchpoint.timeInGpsLat,
        if (touchpoint.timeInGpsLng != null) 'time_in_gps_lng': touchpoint.timeInGpsLng,
        if (touchpoint.timeInGpsAddress != null) 'time_in_gps_address': touchpoint.timeInGpsAddress,
        if (touchpoint.timeOut != null) 'time_out': touchpoint.timeOut!.toIso8601String(),
        if (touchpoint.timeOutGpsLat != null) 'time_out_gps_lat': touchpoint.timeOutGpsLat,
        if (touchpoint.timeOutGpsLng != null) 'time_out_gps_lng': touchpoint.timeOutGpsLng,
        if (touchpoint.timeOutGpsAddress != null) 'time_out_gps_address': touchpoint.timeOutGpsAddress,
      };

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/touchpoints',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 201) {
        final touchpointData = response.data as Map<String, dynamic>;
        debugPrint('TouchpointApiService: Touchpoint created successfully: ${touchpointData['id']}');
        return Touchpoint.fromJson(touchpointData);
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to create touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to create touchpoint',
        originalError: e,
      );
    }
  }

  /// Update touchpoint
  Future<Touchpoint?> updateTouchpoint(Touchpoint touchpoint) async {
    try {
      debugPrint('TouchpointApiService: Updating touchpoint ${touchpoint.id}...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Convert Touchpoint model to API request format (snake_case)
      final requestData = {
        'client_id': touchpoint.clientId,
        'touchpoint_number': touchpoint.touchpointNumber,
        'type': touchpoint.type.apiValue,
        'date': touchpoint.date.toIso8601String(),
        if (touchpoint.address != null) 'address': touchpoint.address,
        if (touchpoint.timeArrival != null) 'time_arrival': '${touchpoint.timeArrival!.hour}:${touchpoint.timeArrival!.minute.toString().padLeft(2, '0')}',
        if (touchpoint.timeDeparture != null) 'time_departure': '${touchpoint.timeDeparture!.hour}:${touchpoint.timeDeparture!.minute.toString().padLeft(2, '0')}',
        if (touchpoint.odometerArrival != null) 'odometer_arrival': touchpoint.odometerArrival,
        if (touchpoint.odometerDeparture != null) 'odometer_departure': touchpoint.odometerDeparture,
        'reason': touchpoint.reason.apiValue,
        'status': touchpoint.status.apiValue,
        if (touchpoint.nextVisitDate != null) 'next_visit_date': touchpoint.nextVisitDate!.toIso8601String(),
        if (touchpoint.remarks != null) 'notes': touchpoint.remarks,
        if (touchpoint.photoPath != null) 'photo_url': touchpoint.photoPath,
        if (touchpoint.audioPath != null) 'audio_url': touchpoint.audioPath,
        if (touchpoint.latitude != null) 'latitude': touchpoint.latitude,
        if (touchpoint.longitude != null) 'longitude': touchpoint.longitude,
        // Time In/Out fields
        if (touchpoint.timeIn != null) 'time_in': touchpoint.timeIn!.toIso8601String(),
        if (touchpoint.timeInGpsLat != null) 'time_in_gps_lat': touchpoint.timeInGpsLat,
        if (touchpoint.timeInGpsLng != null) 'time_in_gps_lng': touchpoint.timeInGpsLng,
        if (touchpoint.timeInGpsAddress != null) 'time_in_gps_address': touchpoint.timeInGpsAddress,
        if (touchpoint.timeOut != null) 'time_out': touchpoint.timeOut!.toIso8601String(),
        if (touchpoint.timeOutGpsLat != null) 'time_out_gps_lat': touchpoint.timeOutGpsLat,
        if (touchpoint.timeOutGpsLng != null) 'time_out_gps_lng': touchpoint.timeOutGpsLng,
        if (touchpoint.timeOutGpsAddress != null) 'time_out_gps_address': touchpoint.timeOutGpsAddress,
      };

      // Make the API request
      final response = await _dio.put(
        '${AppConfig.postgresApiUrl}/touchpoints/${touchpoint.id}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: requestData,
      );

      if (response.statusCode == 200) {
        final touchpointData = response.data as Map<String, dynamic>;
        debugPrint('TouchpointApiService: Touchpoint updated successfully: ${touchpointData['id']}');
        return Touchpoint.fromJson(touchpointData);
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to update touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Touchpoint not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to update touchpoint',
        originalError: e,
      );
    }
  }

  /// Delete touchpoint
  Future<void> deleteTouchpoint(String id) async {
    try {
      debugPrint('TouchpointApiService: Deleting touchpoint $id...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.delete(
        '${AppConfig.postgresApiUrl}/touchpoints/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        debugPrint('TouchpointApiService: Touchpoint deleted successfully');
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete touchpoint: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to delete touchpoint',
        originalError: e,
      );
    }
  }

  /// Get next expected touchpoint info for a client
  Future<NextTouchpointInfo?> getNextTouchpointInfo(String clientId) async {
    try {
      debugPrint('TouchpointApiService: Getting next touchpoint info for client $clientId...');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('TouchpointApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Make the API request
      final response = await _dio.get(
        '${AppConfig.postgresApiUrl}/touchpoints/next/$clientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('TouchpointApiService: Got next touchpoint info: ${data['nextTouchpointNumber']}');
        return NextTouchpointInfo.fromJson(data);
      } else {
        debugPrint('TouchpointApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to get next touchpoint info: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('TouchpointApiService: DioException - ${e.message}');
      debugPrint('TouchpointApiService: Response - ${e.response?.data}');
      if (e.response?.statusCode == 404) {
        return null; // Client not found
      }
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('TouchpointApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to get next touchpoint info',
        originalError: e,
      );
    }
  }
}

/// Model for next touchpoint info response
class NextTouchpointInfo {
  final int? nextTouchpointNumber;
  final String? nextTouchpointType;
  final int completedTouchpoints;
  final List<String>? sequence;
  final bool? canCreate;
  final String? message;
  final List<Map<String, dynamic>>? existingTouchpoints;

  NextTouchpointInfo({
    this.nextTouchpointNumber,
    this.nextTouchpointType,
    required this.completedTouchpoints,
    this.sequence,
    this.canCreate,
    this.message,
    this.existingTouchpoints,
  });

  factory NextTouchpointInfo.fromJson(Map<String, dynamic> json) {
    return NextTouchpointInfo(
      nextTouchpointNumber: json['nextTouchpointNumber'] as int?,
      nextTouchpointType: json['nextTouchpointType'] as String?,
      completedTouchpoints: json['completedTouchpoints'] as int? ?? 0,
      sequence: (json['sequence'] as List<dynamic>?)?.cast<String>(),
      canCreate: json['canCreate'] as bool?,
      message: json['message'] as String?,
      existingTouchpoints: (json['existingTouchpoints'] as List<dynamic>?)
          ?.cast<Map<String, dynamic>>(),
    );
  }

  /// Check if all touchpoints are completed
  bool get isCompleted => nextTouchpointNumber == null;

  /// Get the display string for the next touchpoint
  String? get nextTouchpointDisplay {
    if (nextTouchpointNumber == null || nextTouchpointType == null) return null;
    final ordinal = _getOrdinal(nextTouchpointNumber!);
    return '$ordinal $nextTouchpointType';
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}

/// Provider for TouchpointApiService
final touchpointApiServiceProvider = Provider<TouchpointApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return TouchpointApiService(authService: jwtAuth);
});
