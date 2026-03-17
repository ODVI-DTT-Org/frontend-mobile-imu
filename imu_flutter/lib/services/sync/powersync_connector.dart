import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/utils/logger.dart';

/// Backend connector for PowerSync authentication
/// This connector handles token refresh and credential management for PowerSync
class IMUPowerSyncConnector {
  final Dio _httpClient;
  final FlutterSecureStorage _secureStorage;
  final String _powersyncUrl;
  final String _authUrl;

  IMUPowerSyncConnector({
    required String powersyncUrl,
    required String authUrl,
  })  : _powersyncUrl = powersyncUrl,
        _authUrl = authUrl,
        _httpClient = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _secureStorage = const FlutterSecureStorage();

  /// Fetch PowerSync authentication credentials
  Future<String?> fetchCredentials() async {
    try {
      // Get stored refresh token
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      if (refreshToken == null) {
        logDebug('No refresh token found - user needs to login');
        return null;
      }

      // Refresh the PowerSync token
      final response = await _httpClient.post(
        '$_authUrl/token/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['token'] != null) {
        final token = response.data['token'] as String;
        await _secureStorage.write(key: 'powersync_token', value: token);
        logDebug('PowerSync token refreshed successfully');
        return token;
      }

      logDebug('Token refresh failed: ${response.statusCode}');
      return null;
    } catch (e) {
      logError('Failed to fetch PowerSync credentials', e);
      return null;
    }
  }

  /// Invalidate stored credentials
  Future<void> invalidateCredentials() async {
    await _secureStorage.delete(key: 'powersync_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'access_token');
    logDebug('Credentials invalidated');
  }

  /// Get the PowerSync URI
  Uri get powersyncUri => Uri.parse(_powersyncUrl);
}

/// Provider for PowerSync connector
final powerSyncConnectorProvider = Provider<IMUPowerSyncConnector>((ref) {
  final powersyncUrl = dotenv.env['POWERSYNC_URL'] ?? 'https://your-instance.powersync.co';
  final authUrl = dotenv.env['AUTH_URL'] ?? 'https://your-auth-server.com';

  return IMUPowerSyncConnector(
    powersyncUrl: powersyncUrl,
    authUrl: authUrl,
  );
});
