import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../auth/jwt_auth_service.dart';
import '../../core/config/app_config.dart';

class NotificationsApiPage {
  final List<Map<String, dynamic>> notifications;
  final int total;
  final int unread;

  const NotificationsApiPage({
    required this.notifications,
    required this.total,
    required this.unread,
  });
}

class NotificationsApiService {
  final Dio _dio;
  final JwtAuthService _authService;

  NotificationsApiService({Dio? dio, JwtAuthService? authService})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.postgresApiUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
            )),
        _authService = authService ?? JwtAuthService.instance;

  Map<String, String> get _authHeaders {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated');
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 100,
    int offset = 0,
  }) async {
    final page = await fetchNotificationsPage(limit: limit, offset: offset);
    return page.notifications;
  }

  Future<NotificationsApiPage> fetchNotificationsPage({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
      options: Options(headers: _authHeaders),
    );

    final data = response.data as Map<String, dynamic>;
    final notifications = data['notifications'] as List? ?? const [];
    return NotificationsApiPage(
      notifications: notifications
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      total: data['total'] as int? ?? notifications.length,
      unread: data['unread'] as int? ?? 0,
    );
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

  Future<int> clearAll() async {
    final response = await _dio.delete(
      '/notifications',
      options: Options(headers: _authHeaders),
    );
    final data = response.data as Map<String, dynamic>;
    return data['deleted'] as int? ?? 0;
  }

  Future<int> clearRead() async {
    final response = await _dio.delete(
      '/notifications/read',
      options: Options(headers: _authHeaders),
    );
    final data = response.data as Map<String, dynamic>;
    return data['deleted'] as int? ?? 0;
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _dio.post(
      '/notifications/device-token',
      data: {'token': token, 'platform': platform},
      options: Options(headers: _authHeaders),
    );
  }

  Future<void> unregisterDeviceToken({required String token}) async {
    await _dio.delete(
      '/notifications/device-token',
      data: {'token': token},
      options: Options(headers: _authHeaders),
    );
  }
}

final notificationsApiServiceProvider = Provider<NotificationsApiService>((ref) {
  return NotificationsApiService();
});
