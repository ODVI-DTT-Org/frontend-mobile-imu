import 'package:dio/dio.dart';
import 'package:powersync/powersync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';
import '../auth/auth_service.dart';
import '../auth/jwt_auth_service.dart';
import '../error_logging_helper.dart';

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
      final accessToken = _authService.accessToken;

      if (accessToken == null) {
        logDebug('No access token - user needs to login');
        return null;
      }

      logDebug('JWT token available, length: ${accessToken.length}');

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

      // Fetch PowerSync-specific token from backend
      // PowerSync requires a token with 'user_id' claim that the SDK extracts
      logDebug('Fetching PowerSync token from backend...');

      final response = await _httpClient.get(
        '$_apiUrl/powersync/token',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode != 200) {
        logError('Failed to fetch PowerSync token: ${response.statusCode}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final powerSyncToken = data['token'] as String?;
      final endpoint = data['endpoint'] as String?;
      final userId = data['userId'] as String?;
      final expiresAt = data['expiresAt'] as int?;

      if (powerSyncToken == null || endpoint == null || userId == null) {
        logError('Invalid PowerSync token response: missing required fields');
        return null;
      }

      logDebug('PowerSync credentials fetched successfully');
      logDebug('Creating PowerSyncCredentials with endpoint: $endpoint, userId: $userId');
      logDebug('PowerSync token length: ${powerSyncToken.length}');
      logDebug('PowerSync token prefix: ${powerSyncToken.substring(0, 20)}...');
      logDebug('PowerSync expiresAt: ${expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(expiresAt) : "null"}');

      // Return credentials with proper userId and expiresAt
      return PowerSyncCredentials(
        endpoint: endpoint,
        token: powerSyncToken,
        userId: userId,
        expiresAt: expiresAt != null ? DateTime.fromMillisecondsSinceEpoch(expiresAt) : null,
      );
    } catch (e, stackTrace) {
      logError('Failed to fetch PowerSync credentials', e);
      // Log non-critical error - PowerSync credential fetch doesn't block app workflow
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'PowerSync credentials fetch',
        error: e,
        stackTrace: stackTrace,
        context: {
          'isAuthenticated': _authService.isAuthenticated,
          'hasAccessToken': _authService.accessToken != null,
        },
      );
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
      logDebug('Upload endpoint: $_apiUrl/upload');
      logDebug('Token length: ${token.length}');

      // Prepare operations for upload
      final operations = batch.crud.map((op) {
        return {
          'table': op.table,
          'op': op.op,
          'id': op.id,
          'data': op.opData,
        };
      }).toList();

      logDebug('Operations prepared: ${operations.length}');

      // Send to backend upload endpoint
      final response = await _httpClient.post(
        '$_apiUrl/upload',
        data: {'operations': operations},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      logDebug('Upload response status: ${response.statusCode}');
      logDebug('Upload response data: ${response.data}');

      if (response.statusCode == 200) {
        // Mark batch as complete
        await batch.complete();
        logDebug('Upload completed successfully');
      } else {
        logError('Upload failed with status: ${response.statusCode}');
        logError('Upload response body: ${response.data}');
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e, stackTrace) {
      logError('Upload failed with DioException', e);
      logError('DioException type: ${e.type}');
      logError('DioException message: ${e.message}');
      logError('DioException response: ${e.response}');
      logError('DioException response data: ${e.response?.data}');
      // Log non-critical error - upload failures don't block app workflow
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'PowerSync data upload',
        error: e,
        stackTrace: stackTrace,
        context: {
          'errorType': 'DioException',
          'responseStatus': e.response?.statusCode?.toString(),
          'responseData': e.response?.data?.toString(),
        },
      );
      // Don't complete the batch - will retry on next sync
      rethrow;
    } catch (e, stackTrace) {
      logError('Upload failed', e);
      logError('Upload error type: ${e.runtimeType}');
      logError('Upload error message: ${e.toString()}');
      // Log non-critical error - upload failures don't block app workflow
      await ErrorLoggingHelper.logNonCriticalError(
        operation: 'PowerSync data upload',
        error: e,
        stackTrace: stackTrace,
        context: {
          'errorType': e.runtimeType.toString(),
          'errorMessage': e.toString(),
        },
      );
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
