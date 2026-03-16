import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/logger.dart';

/// Service for managing token refresh with smart retry logic
class TokenRefreshService {
  final Dio _httpClient;
  final FlutterSecureStorage _secureStorage;

  // Configuration
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);

  // State
  int _retryCount = 0;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  final Random _random = Random();

  TokenRefreshService({
    Dio? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Attempt to refresh the token with exponential backoff and jitter
  Future<String?> refreshToken() async {
    if (_isRefreshing) return null;

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        logDebug('No refresh token available');
        _isRefreshing = false;
        return null;
      }

      final authUrl = dotenv.env['AUTH_URL'] ?? 'https://your-auth-server.com';

      logDebug(
          'Attempting token refresh (attempt ${_retryCount + 1})');

      final response = await _httpClient.post(
        '$authUrl/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final newToken = response.data['token'] as String;
        await _secureStorage.write(key: 'access_token', value: newToken);
        await _secureStorage.write(key: 'powersync_token', value: newToken);

        _retryCount = 0;
        _isRefreshing = false;

        logDebug('Token refresh successful');
        return newToken;
      }

      throw Exception('Token refresh failed: ${response.statusCode}');
    } catch (e) {
      _retryCount++;

      if (_retryCount >= _maxRetries) {
        logError('Token refresh failed after $_maxRetries attempts', e);
        await _secureStorage.delete(key: 'refresh_token');
        await _secureStorage.delete(key: 'access_token');
        await _secureStorage.delete(key: 'powersync_token');
        _retryCount = 0;
        _isRefreshing = false;
        return null;
      }

      // Schedule retry
      _scheduleRetry();
      _isRefreshing = false;
      return null;
    }
  }

  /// Calculate delay with exponential backoff and jitter
  Duration _calculateDelay() {
    // Exponential backoff: base_delay * 2^retryCount
    // Add jitter: random delay between 0-1000ms
    final jitter = _random.nextInt(1000);
    final exponentialDelay = _baseDelay.inMilliseconds * (1 << _retryCount);
    final delayMs = min(exponentialDelay + jitter, _maxDelay.inMilliseconds);
    return Duration(milliseconds: delayMs);
  }

  /// Schedule a retry after failure
  void _scheduleRetry() {
    _refreshTimer?.cancel();
    final delay = _calculateDelay();
    logDebug('Scheduling token refresh retry in ${delay.inSeconds}s');

    _refreshTimer = Timer(delay, () async {
      await refreshToken();
    });
  }

  /// Force refresh (user-initiated)
  Future<String?> forceRefresh() async {
    _retryCount = 0;
    _refreshTimer?.cancel();
    return await refreshToken();
  }

  /// Clear state on logout
  Future<void> dispose() async {
    _refreshTimer?.cancel();
    _isRefreshing = false;
    _retryCount = 0;
  }
}

/// Provider for Dio HTTP client
final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));
});

/// Provider for secure storage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for token refresh service
final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  final service = TokenRefreshService(
    httpClient: ref.watch(dioProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});
