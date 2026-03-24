import 'package:dio/dio.dart';
import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../auth/auth_service.dart';
import '../auth/jwt_auth_service.dart';

/// Backend connector for PowerSync
/// Handles authentication credentials and data upload to PostgreSQL backend
class IMUPowerSyncConnector extends PowerSyncBackendConnector {
  final Dio _httpClient;
  final JwtAuthService _authService;
  final String _powersyncUrl;
  final String _apiUrl;

  IMUPowerSyncConnector({
    required JwtAuthService authService,
    required String powersyncUrl,
    required String apiUrl,
    Dio? httpClient,
  })  : _authService = authService,
        _powersyncUrl = powersyncUrl,
        _apiUrl = apiUrl,
        _httpClient = httpClient ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  /// Fetch PowerSync authentication credentials
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    try {
      // Get the current access token from JWT auth service
      final token = _authService.accessToken;

      if (token == null) {
        logDebug('No access token - user needs to login');
        return null;
      }

      // Check if token needs refresh
      if (_authService.needsRefresh) {
        logDebug('Token needs refresh, refreshing...');
        await _authService.refreshTokens();
      }

      // Return the credentials for PowerSync authentication
      logDebug('PowerSync credentials fetched successfully');
      final endpoint = _powersyncUrl.isNotEmpty ? _powersyncUrl : '';
      final accessToken = _authService.accessToken;

      if (endpoint.isEmpty || accessToken == null) {
        return null;
      }

      return PowerSyncCredentials(
        endpoint: endpoint,
        token: accessToken,
      );
    } catch (e) {
      logError('Failed to fetch PowerSync credentials', e);
      return null;
    }
  }

  /// Upload local changes to the backend
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        logDebug('No access token - skipping upload');
        return;
      }

      // Get pending CRUD operations
      final batch = await database.getCrudBatch();
      if (batch == null) {
        logDebug('No pending uploads');
        return;
      }

      logDebug('Uploading ${batch.crud.length} operations to backend');

      // Prepare operations for upload
      final operations = batch.crud.map((op) {
        return {
          'table': op.table,
          'op': op.op,
          'id': op.id,
          'data': op.opData,
        };
      }).toList();

      // Send to backend upload endpoint
      final response = await _httpClient.post(
        '$_apiUrl/upload',
        data: {'operations': operations},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        // Mark batch as complete
        await batch.complete();
        logDebug('Upload completed successfully');
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      logError('Upload failed with DioException', e);
      // Don't complete the batch - will retry on next sync
      rethrow;
    } catch (e) {
      logError('Upload failed', e);
      rethrow;
    }
  }

  /// Get the PowerSync URI
  Uri get powersyncUri => Uri.parse(_powersyncUrl);

  /// Invalidate stored credentials
  @override
  Future<void> invalidateCredentials() async {
    await _authService.logout();
    logDebug('Credentials invalidated');
  }
}

/// Provider for PowerSync connector
final powerSyncConnectorProvider = Provider<IMUPowerSyncConnector>((ref) {
  final jwtAuth = ref.watch(jwtAuthProvider);

  return IMUPowerSyncConnector(
    authService: jwtAuth,
    powersyncUrl: AppConfig.powerSyncUrl,
    apiUrl: AppConfig.postgresApiUrl,
  );
});
