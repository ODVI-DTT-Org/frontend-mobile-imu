import 'dart:convert';
import 'package:dio/dio.dart';
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
    ];

    final token = _authService.accessToken;
    if (token == null) {
      throw Exception('Not authenticated');
    }

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

    return ClientFilterOptions.fromAPIResponse(response.data);
  }
}
