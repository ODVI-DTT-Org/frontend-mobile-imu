import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:imu_flutter/services/api/api_exception.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/approvals/data/models/approval_model.dart';

/// Approvals API service
/// Uses REST API backend for approval data
class ApprovalsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ApprovalsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService() {
    if (dio == null) {
      _dio.options.baseUrl = AppConfig.postgresApiUrl;
    }
  }

  /// Fetch pending approvals for current user
  Future<List<Approval>> fetchPendingApprovals() async {
    try {
      debugPrint('ApprovalsApiService: Fetching pending approvals...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final response = await _dio.get(
        '/approvals',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: {
          'status': 'pending',
          'perPage': 100,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final itemsData = data['items'] as List<dynamic>? ?? [];
        debugPrint('ApprovalsApiService: Got ${itemsData.length} pending approvals');

        return itemsData.map((item) {
          final approvalData = item as Map<String, dynamic>;
          return Approval.fromJson(approvalData);
        }).toList();
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch approvals: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch pending approvals',
        originalError: e,
      );
    }
  }

  /// Fetch all approvals for current user
  Future<List<Approval>> fetchAllApprovals({
    ApprovalStatus? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      debugPrint('ApprovalsApiService: Fetching approvals...');

      final token = _authService.accessToken;
      if (token == null) {
        debugPrint('ApprovalsApiService: No access token available');
        throw ApiException(message: 'Not authenticated');
      }

      final queryParams = <String, dynamic>{
        'page': page,
        'perPage': perPage,
      };

      if (status != null) {
        queryParams['status'] = status.value;
      }

      final response = await _dio.get(
        '/approvals',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final itemsData = data['items'] as List<dynamic>? ?? [];
        debugPrint('ApprovalsApiService: Got ${itemsData.length} approvals');

        return itemsData.map((item) {
          final approvalData = item as Map<String, dynamic>;
          return Approval.fromJson(approvalData);
        }).toList();
      } else {
        debugPrint('ApprovalsApiService: API returned status ${response.statusCode}');
        throw ApiException(message: 'Failed to fetch approvals: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('ApprovalsApiService: DioException - ${e.message}');
      debugPrint('ApprovalsApiService: Response - ${e.response?.data}');
      throw ApiException(
        message: 'Network error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      debugPrint('ApprovalsApiService: Unexpected error - $e');
      throw ApiException(
        message: 'Failed to fetch approvals',
        originalError: e,
      );
    }
  }

  /// Get approval counts by status
  Future<Map<ApprovalStatus, int>> getApprovalCounts() async {
    try {
      final pending = await fetchAllApprovals(status: ApprovalStatus.pending, perPage: 1);
      final approved = await fetchAllApprovals(status: ApprovalStatus.approved, perPage: 1);
      final rejected = await fetchAllApprovals(status: ApprovalStatus.rejected, perPage: 1);

      // Note: This is a simplified version. For accurate counts, you'd need to
      // modify the backend to return count information or fetch all items
      return {
        ApprovalStatus.pending: pending.length,
        ApprovalStatus.approved: approved.length,
        ApprovalStatus.rejected: rejected.length,
      };
    } catch (e) {
      debugPrint('Error fetching approval counts: $e');
      return {
        ApprovalStatus.pending: 0,
        ApprovalStatus.approved: 0,
        ApprovalStatus.rejected: 0,
      };
    }
  }
}

/// Provider for ApprovalsApiService
final approvalsApiServiceProvider = Provider<ApprovalsApiService>((ref) {
  return ApprovalsApiService();
});
