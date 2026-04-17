import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/api/upload_api_service.dart';
import 'package:imu_flutter/services/api/client_api_service.dart';
import 'package:imu_flutter/services/api/visit_api_service.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/core/config/app_config.dart';

/// Release API service for creating and managing loan releases
class ReleaseApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ReleaseApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        )),
        _authService = authService ?? JwtAuthService();

  /// Create a loan release record
  ///
  /// Parameters:
  /// - [clientId]: Client ID
  /// - [visitId]: Visit ID to link release to
  /// - [productType]: Product type (PUSU, LIKA, SUB2K)
  /// - [loanType]: Loan type (NEW, ADDITIONAL, RENEWAL, PRETERM)
  /// - [udiNumber]: UDI number
  /// - [approvalNotes]: Optional approval notes
  /// - [amount]: Loan amount (optional, defaults to 0)
  ///
  /// Returns [Map] with release data, or null if failed
  Future<Map<String, dynamic>?> createRelease({
    required String clientId,
    required String visitId,
    required String productType,
    required String loanType,
    int? udiNumber,
    String? approvalNotes,
    double amount = 0,
  }) async {
    try {
      debugPrint('ReleaseApiService: Creating release for client $clientId');

      // Get the access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ReleaseApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      // Prepare request data
      final data = {
        'client_id': clientId,
        'visit_id': visitId,
        'product_type': productType,
        'loan_type': loanType,
        'amount': amount,
        if (udiNumber != null) 'udi_number': udiNumber,
        if (approvalNotes != null && approvalNotes.isNotEmpty) 'approval_notes': approvalNotes,
      };

      // Make the API request
      final response = await _dio.post(
        '${AppConfig.postgresApiUrl}/releases',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final releaseData = response.data as Map<String, dynamic>;
        debugPrint('ReleaseApiService: Release created successfully: ${releaseData['id']}');
        return releaseData;
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

  /// Create a complete loan release (visit + release + client update)
  ///
  /// This is a convenience method that orchestrates the full loan release flow:
  /// 1. Creates a visit record with photo upload (single FormData request)
  /// 2. Creates a release record linked to the visit
  /// 3. Updates the client's loan_released flag
  ///
  /// Parameters:
  /// - [clientId]: Client ID
  /// - [timeIn]: Visit start time (HH:MM format)
  /// - [timeOut]: Visit end time (HH:MM format)
  /// - [odometerArrival]: Odometer reading at arrival
  /// - [odometerDeparture]: Odometer reading at departure
  /// - [productType]: Product type (PUSU, LIKA, SUB2K)
  /// - [loanType]: Loan type (NEW, ADDITIONAL, RENEWAL, PRETERM)
  /// - [udiNumber]: UDI number
  /// - [remarks]: Optional remarks
  /// - [photoPath]: Optional local photo path to upload
  /// - [latitude]: Optional GPS latitude
  /// - [longitude]: Optional GPS longitude
  /// - [address]: Optional GPS address
  ///
  /// Returns [Map] with release data, or null if failed
  Future<Map<String, dynamic>?> createCompleteLoanRelease({
    required String clientId,
    required String timeIn,
    required String timeOut,
    required String odometerArrival,
    required String odometerDeparture,
    required String productType,
    required String loanType,
    int? udiNumber,
    String? remarks,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      debugPrint('ReleaseApiService: Creating complete loan release for client $clientId');

      // Step 1: Create visit with photo upload (single FormData request)
      final visitApiService = VisitApiService(authService: _authService, dio: _dio);

      // Prepare photo file if provided
      File? photoFile;
      if (photoPath != null && photoPath.isNotEmpty) {
        photoFile = File(photoPath);
      }

      final visit = await visitApiService.createVisit(
        clientId: clientId,
        timeIn: timeIn,
        timeOut: timeOut,
        odometerArrival: odometerArrival,
        odometerDeparture: odometerDeparture,
        photoFile: photoFile, // Photo uploaded with visit data in single request
        notes: remarks,
        type: 'release_loan',
        latitude: latitude,
        longitude: longitude,
        address: address,
      );

      if (visit == null) {
        debugPrint('ReleaseApiService: Failed to create visit');
        return null;
      }

      final visitId = visit['id'] as String;

      // Step 2: Create release
      final release = await createRelease(
        clientId: clientId,
        visitId: visitId,
        productType: productType,
        loanType: loanType,
        udiNumber: udiNumber,
        approvalNotes: remarks,
      );

      if (release == null) {
        debugPrint('ReleaseApiService: Failed to create release');
        return null;
      }

      // Step 3: Update client's loan_released flag (existing behavior)
      final clientApiService = ClientApiService(authService: _authService, dio: _dio);
      await clientApiService.releaseLoan(clientId);

      debugPrint('ReleaseApiService: Complete loan release finished successfully');
      return release;
    } catch (e) {
      debugPrint('ReleaseApiService: Error in complete loan release - $e');
      rethrow;
    }
  }
}

/// Provider for ReleaseApiService
final releaseApiServiceProvider = Provider<ReleaseApiService>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);
  return ReleaseApiService(authService: jwtAuth);
});
