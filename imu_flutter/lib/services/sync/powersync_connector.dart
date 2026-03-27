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

      logDebug('JWT token available, length: ${token.length}');

      // Check if token needs refresh (only if not already expired)
      if (_authService.needsRefresh && _authService.currentUser?.isValid == true) {
        logDebug('Token needs refresh, refreshing...');
        try {
          await _authService.refreshTokens();
          logDebug('Token refreshed successfully for PowerSync');
        } catch (e) {
          logWarning('Failed to refresh token for PowerSync, using existing token: $e');
          // Continue with existing token if it's still valid
          if (!_authService.isAuthenticated) {
            logError('Cannot fetch credentials - no valid token');
            return null;
          }
        }
      }

      // Check if we have a valid token after refresh attempt
      if (!_authService.isAuthenticated) {
        logError('Cannot fetch credentials - token is invalid');
        return null;
      }

      // Return the credentials for PowerSync authentication
      logDebug('PowerSync credentials fetched successfully');
      final endpoint = _powersyncUrl.isNotEmpty ? _powersyncUrl : '';
      final accessToken = _authService.accessToken!;

      if (endpoint.isEmpty) {
        logError('PowerSync URL is empty');
        return null;
      }

      logDebug('Creating PowerSyncCredentials with endpoint: $endpoint');
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
    // DON'T logout the user - PowerSync auth failures shouldn't affect app authentication
    // Just log the error and disconnect PowerSync
    logWarning('PowerSync credentials invalidated - disconnecting PowerSync only (user session preserved)');

    // Note: We don't call _authService.logout() here because:
    // 1. PowerSync auth failures are non-critical for app functionality
    // 2. User should remain logged in even if sync fails
    // 3. App can still function with REST API even if PowerSync fails
    // 4. Automatic logout creates a bad user experience

    // The PowerSyncService will handle disconnection when credentials fail
    // This just prevents the automatic logout that was causing the loop
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
