import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:dio/dio.dart';

final touchpointReasonsApiServiceProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    baseUrl: AppConfig.postgresApiUrl,
  ),);

  final authService = ref.watch(jwtAuthProvider);
  final token = authService.accessToken;

  if (token != null) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  return dio;
});

/// Touchpoint reasons provider - fetches from API
final touchpointReasonsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final dio = ref.watch(touchpointReasonsApiServiceProvider);

  try {
    final response = await dio.get(
      '/api/touchpoint-reasons',
      queryParameters: {
        'role': 'caravan',
        'touchpoint_type': 'Visit',
      },
    );

    if (response.statusCode == 200) {
      final items = response.data['items'] as List? ?? [];
      final reasons = items
          .map((e) => e['value'] as String) // API returns 'value' field (not 'reason_code')
          .toList()
        ..sort();
      return reasons;
    }

    return [];
  } catch (e) {
    // Return empty list on error
    return [];
  }
});
