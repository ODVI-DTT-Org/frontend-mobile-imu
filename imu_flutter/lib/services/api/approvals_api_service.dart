import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../auth/jwt_auth_service.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

/// Service for approval-related API calls
class ApprovalsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ApprovalsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.postgresApiUrl,
          connectTimeout: const Duration(seconds: 30),
        )),
        _authService = authService ?? JwtAuthService.instance;

  /// Submit loan release for approval
  ///
  /// Creates a UDI approval request for loan release.
  /// Only available for Caravan and Tele users.
  ///
  /// Parameters:
  /// - [clientId] The UUID of the client to release loan for
  /// - [udiNumber] The UDI (Unique Document Identifier) number (required)
  /// - [notes] Optional notes about the loan release
  ///
  /// Returns approval data if successful
  Future<Map<String, dynamic>> submitLoanRelease({
    required String clientId,
    required String udiNumber,
    String? notes,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Submitting loan release for client: $clientId');
      debugPrint('ApprovalsApiService: UDI Number: $udiNumber');

      // Get access token
      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw Exception('Not authenticated');
      }

      // Validate UDI number
      if (udiNumber.trim().isEmpty) {
        debugPrint('ApprovalsApiService: UDI number is required');
        throw Exception('UDI number is required');
      }

      if (udiNumber.trim().length > 50) {
        debugPrint('ApprovalsApiService: UDI number must be 50 characters or less');
        throw Exception('UDI number must be 50 characters or less');
      }

      // Make API request
      final response = await _dio.post(
        '/approvals/loan-release',
        data: {
          'client_id': clientId,
          'udi_number': udiNumber.trim(),
          if (notes != null) 'notes': notes,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('ApprovalsApiService: Loan release submitted successfully');
        return data;
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw Exception('Failed to submit loan release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw Exception(
        'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Error - $e');
      rethrow;
    }
  }

  /// Get all approvals (optional method for listing approvals)
  Future<Map<String, dynamic>> getApprovals({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Fetching approvals...');

      final token = _authService.accessToken;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final queryParameters = <String, dynamic>{
        'page': page.toString(),
        'perPage': perPage.toString(),
      };

      if (status != null) {
        queryParameters['status'] = status;
      }

      final response = await _dio.get(
        '/approvals',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('ApprovalsApiService: Fetched ${data['items']?.length ?? 0} approvals');
        return data;
      } else {
        throw Exception('Failed to fetch approvals: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ApprovalsApiService: Error fetching approvals - $e');
      rethrow;
    }
  }

  /// Approve an approval request
  ///
  /// For UDI approvals: marks as approved, updates client's UDI number
  /// For client edit approvals: applies the client changes
  ///
  /// Parameters:
  /// - [id] The approval ID to approve
  /// - [notes] Optional notes for the approval
  ///
  /// Returns the updated approval data
  Future<Map<String, dynamic>> approveApproval({
    required String id,
    String? notes,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Approving approval $id');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw Exception('Not authenticated');
      }

      final response = await _dio.post(
        '/approvals/$id/approve',
        data: {
          if (notes != null) 'notes': notes,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('ApprovalsApiService: Approval $id approved successfully');
        return data;
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw Exception('Failed to approve approval: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw Exception(
        'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Error - $e');
      rethrow;
    }
  }

  /// Reject an approval request
  ///
  /// Parameters:
  /// - [id] The approval ID to reject
  /// - [rejectionReason] The reason for rejection (required)
  ///
  /// Returns the updated approval data
  Future<Map<String, dynamic>> rejectApproval({
    required String id,
    required String rejectionReason,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Rejecting approval $id');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw Exception('Not authenticated');
      }

      if (rejectionReason.trim().isEmpty) {
        throw Exception('Rejection reason is required');
      }

      final response = await _dio.post(
        '/approvals/$id/reject',
        data: {
          'rejection_reason': rejectionReason.trim(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('ApprovalsApiService: Approval $id rejected successfully');
        return data;
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw Exception('Failed to reject approval: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw Exception(
        'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Error - $e');
      rethrow;
    }
  }

  /// Submit loan release v2 with full form data (Admin approval required)
  ///
  /// This endpoint accepts all fields from the new ReleaseLoanForm and creates
  /// an approval request. When approved by admin, it creates a visit record
  /// (not a touchpoint) and marks the client as loan_released.
  ///
  /// Parameters:
  /// - [clientId] The UUID of the client to release loan for
  /// - [udiNumber] The UDI (Unique Document Identifier) number (required)
  /// - [productType] Optional product type
  /// - [loanType] Optional loan type
  /// - [timeIn] Optional time in (HH:MM format)
  /// - [timeOut] Optional time out (HH:MM format)
  /// - [odometerIn] Optional odometer reading at arrival
  /// - [odometerOut] Optional odometer reading at departure
  /// - [latitude] Optional GPS latitude
  /// - [longitude] Optional GPS longitude
  /// - [address] Optional GPS address
  /// - [photoUrl] Optional photo URL
  /// - [remarks] Optional remarks
  ///
  /// Returns approval data if successful
  Future<Map<String, dynamic>> submitLoanReleaseV2({
    required String clientId,
    required String udiNumber,
    String? productType,
    String? loanType,
    String? timeIn,
    String? timeOut,
    String? odometerIn,
    String? odometerOut,
    double? latitude,
    double? longitude,
    String? address,
    String? photoUrl,
    String? remarks,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Submitting loan release v2 for client: $clientId');
      debugPrint('ApprovalsApiService: UDI Number: $udiNumber');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw Exception('Not authenticated');
      }

      // Validate UDI number
      if (udiNumber.trim().isEmpty) {
        debugPrint('ApprovalsApiService: UDI number is required');
        throw Exception('UDI number is required');
      }

      if (udiNumber.trim().length > 50) {
        debugPrint('ApprovalsApiService: UDI number must be 50 characters or less');
        throw Exception('UDI number must be 50 characters or less');
      }

      // Make API request
      final response = await _dio.post(
        '/approvals/loan-release-v2',
        data: {
          'client_id': clientId,
          'udi_number': udiNumber.trim(),
          if (productType != null) 'product_type': productType,
          if (loanType != null) 'loan_type': loanType,
          if (timeIn != null) 'time_in': timeIn,
          if (timeOut != null) 'time_out': timeOut,
          if (odometerIn != null) 'odometer_in': odometerIn,
          if (odometerOut != null) 'odometer_out': odometerOut,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (address != null) 'address': address,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (remarks != null) 'remarks': remarks,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('ApprovalsApiService: Loan release v2 submitted successfully');
        return data;
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw Exception('Failed to submit loan release: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw Exception(
        'Network error: ${e.message}',
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Error - $e');
      rethrow;
    }
  }
}

/// Provider for ApprovalsApiService
final approvalsApiServiceProvider = Provider<ApprovalsApiService>((ref) {
  return ApprovalsApiService();
});
