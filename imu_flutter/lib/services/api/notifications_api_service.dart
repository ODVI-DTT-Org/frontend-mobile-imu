import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../auth/jwt_auth_service.dart';
import '../../core/config/app_config.dart';

class NotificationsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  NotificationsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.postgresApiUrl,
              connectTimeout: const Duration(seconds: 30),
            )),
        _authService = authService ?? JwtAuthService.instance;

  Map<String, String> get _authHeaders {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated');
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> markRead(String notificationId) async {
    await _dio.patch(
      '/notifications/$notificationId/read',
      options: Options(headers: _authHeaders),
    );
  }

  Future<void> markAllRead() async {
    await _dio.patch(
      '/notifications/read-all',
      options: Options(headers: _authHeaders),
    );
  }
}

final notificationsApiServiceProvider = Provider<NotificationsApiService>((ref) {
  return NotificationsApiService();
});
