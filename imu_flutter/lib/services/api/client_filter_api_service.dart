import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:imu_flutter/services/auth/jwt_auth_service.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import '../../shared/models/client_filter_options.dart';

class ClientFilterApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  ClientFilterApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 30))),
        _authService = authService ?? JwtAuthService();

  Future<ClientFilterOptions> fetchFilterOptions() async {
    final filters = [
      {'table': 'clients', 'column': 'client_type'},
      {'table': 'clients', 'column': 'market_type'},
      {'table': 'clients', 'column': 'pension_type'},
      {'table': 'clients', 'column': 'product_type'},
      {'table': 'clients', 'column': 'loan_type'},
    ];

    final token = _authService.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Fetch client filter options
    final response = await _dio.get(
      '${AppConfig.postgresApiUrl}/filters/batch',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
      queryParameters: {
        'filters': jsonEncode(filters),
        'withCounts': 'false',
        'includeNull': 'false',
        'includeAll': 'false',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch filter options: ${response.statusCode}');
    }

    final options = ClientFilterOptions.fromAPIResponse(response.data);

    // Fetch touchpoint reasons separately
    try {
      final touchpointsResponse = await _dio.get(
        '${AppConfig.postgresApiUrl}/touchpoint-reasons',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (touchpointsResponse.statusCode == 200 && touchpointsResponse.data['success'] == true) {
        final items = touchpointsResponse.data['data'] as List;
        final touchpointReasons = items
            .map((e) => e['value'] as String)
            .toList()
          ..sort();
        return options.copyWith(touchpointReasons: touchpointReasons);
      }
    } catch (e) {
      // If touchpoint reasons fetch fails, return options without them
      debugPrint('[ClientFilterApiService] Failed to fetch touchpoint reasons: $e');
    }

    return options;
  }
}
