import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/shared/models/bulk_delete_models.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/services/error_logging_helper.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart' show jwtAuthProvider;

/// Bulk Delete API Service
/// Handles bulk delete operations for itineraries and My Day items
class BulkDeleteApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  BulkDeleteApiService({
    required Dio dio,
    required JwtAuthService authService,
  })  : _dio = dio,
        _authService = authService;

  /// Bulk delete itineraries by IDs
  /// Returns [BulkDeleteResult] with success count, error count, and error details
  Future<BulkDeleteResult> bulkDeleteItineraries(List<String> ids) async {
    if (ids.isEmpty) {
      return BulkDeleteResult(
        successCount: 0,
        errorCount: 0,
        errors: [],
      );
    }

    try {
      debugPrint('BulkDeleteApiService: Deleting ${ids.length} itineraries...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('BulkDeleteApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/itineraries/bulk-delete',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {'ids': ids},
      );

      debugPrint('BulkDeleteApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = BulkDeleteResult.fromJson(response.data);
        debugPrint('BulkDeleteApiService: Deleted ${result.successCount} itineraries, ${result.errorCount} failed');
        return result;
      } else {
        debugPrint('BulkDeleteApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to delete itineraries: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('BulkDeleteApiService: DioException - ${e.message}');
      debugPrint('BulkDeleteApiService: Response - ${e.response?.data}');

      // Extract error message from backend response
      String errorMessage = 'Network error: ${e.message}';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }

      ErrorLoggingHelper.logCriticalError(
        operation: 'bulk delete itineraries',
        error: e,
        stackTrace: StackTrace.current,
        context: {'ids': ids},
      );

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    } catch (e) {
      debugPrint('BulkDeleteApiService: Unexpected error - $e');
      ErrorLoggingHelper.logCriticalError(
        operation: 'bulk delete itineraries',
        error: e,
        stackTrace: StackTrace.current,
        context: {'ids': ids},
      );
      throw ApiException(
        message: 'Failed to delete itineraries',
        originalError: e,
      );
    }
  }

  /// Bulk remove clients from My Day by client IDs
  /// Returns [BulkDeleteResult] with success count, error count, and error details
  Future<BulkDeleteResult> bulkRemoveFromMyDay(List<String> clientIds) async {
    if (clientIds.isEmpty) {
      return BulkDeleteResult(
        successCount: 0,
        errorCount: 0,
        errors: [],
      );
    }

    try {
      debugPrint('BulkDeleteApiService: Removing ${clientIds.length} clients from My Day...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('BulkDeleteApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/my-day/bulk-remove',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {'client_ids': clientIds},
      );

      debugPrint('BulkDeleteApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = BulkDeleteResult.fromJson(response.data);
        debugPrint('BulkDeleteApiService: Removed ${result.successCount} clients, ${result.errorCount} failed');
        return result;
      } else {
        debugPrint('BulkDeleteApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to remove from My Day: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('BulkDeleteApiService: DioException - ${e.message}');
      debugPrint('BulkDeleteApiService: Response - ${e.response?.data}');

      // Extract error message from backend response
      String errorMessage = 'Network error: ${e.message}';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        }
      }

      ErrorLoggingHelper.logCriticalError(
        operation: 'bulk remove from my day',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientIds': clientIds},
      );

      throw ApiException(
        message: errorMessage,
        originalError: e,
      );
    } catch (e) {
      debugPrint('BulkDeleteApiService: Unexpected error - $e');
      ErrorLoggingHelper.logCriticalError(
        operation: 'bulk remove from my day',
        error: e,
        stackTrace: StackTrace.current,
        context: {'clientIds': clientIds},
      );
      throw ApiException(
        message: 'Failed to remove from My Day',
        originalError: e,
      );
    }
  }
}

/// Provider for BulkDeleteApiService
final bulkDeleteApiServiceProvider = Provider<BulkDeleteApiService>((ref) {
  // Create Dio instance with base configuration
  final dio = Dio(BaseOptions(
    connectTimeout: AppConfig.apiConnectTimeoutDuration,
    receiveTimeout: AppConfig.apiReceiveTimeoutDuration,
    sendTimeout: AppConfig.apiTimeoutDuration,
  ));

  final authService = ref.watch(jwtAuthProvider);
  return BulkDeleteApiService(
    dio: dio,
    authService: authService,
  );
});
