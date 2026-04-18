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

  // Tracks transient-error retry count per CRUD batch (keyed by "table:id" of first entry).
  // After _maxTransientRetries failures the batch is skipped so the queue can advance.
  static final Map<String, int> _transientRetryCount = {};
  static const int _maxTransientRetries = 10;

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
    } catch (e) {
      logError('Failed to fetch PowerSync credentials', e);
      return null;
    }
  }

  /// Upload local changes to the backend, routing each CRUD op to the correct REST endpoint.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final token = _authService.accessToken;
    if (token == null) {
      logDebug('No access token - skipping upload');
      return;
    }

    final batch = await database.getCrudBatch();
    if (batch == null) {
      logDebug('No pending uploads');
      return;
    }

    logDebug('Uploading ${batch.crud.length} operations to backend');

    // Use "table:id" of first entry as a stable key for retry tracking.
    final batchKey = batch.crud.isNotEmpty
        ? '${batch.crud.first.table}:${batch.crud.first.id}'
        : 'empty';

    try {
      for (final op in batch.crud) {
        await _uploadOperation(op, token);
      }
      // Success — clear retry counter and complete.
      _transientRetryCount.remove(batchKey);
      await batch.complete();
      logDebug('Upload batch completed successfully');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 4xx (except 401) = bad data that will never succeed — skip it.
      // 401 = auth issue — rethrow so PowerSync can refresh credentials.
      // 5xx / network errors = transient — rethrow so PowerSync retries.
      if (status != null && status >= 400 && status < 500 && status != 401) {
        // Permanent failure — bad data that will never succeed.
        // Skip it by completing the batch. Do NOT write to error_logs via
        // PowerSync here: that would add a new CRUD entry and re-trigger this
        // same loop, causing the pending count to grow on every retry/reopen.
        _transientRetryCount.remove(batchKey);
        logError(
          'Permanent upload error ($status) — skipping: '
          'table=${batch.crud.isNotEmpty ? batch.crud.first.table : "?"} '
          'id=${batch.crud.isNotEmpty ? batch.crud.first.id : "?"} '
          'body=${e.response?.data}',
        );
        await batch.complete();
        return;
      }
      // Transient error (5xx / network) — track retries and skip after max.
      final retries = (_transientRetryCount[batchKey] ?? 0) + 1;
      _transientRetryCount[batchKey] = retries;
      if (retries >= _maxTransientRetries) {
        _transientRetryCount.remove(batchKey);
        logWarning(
          'Transient upload error after $retries retries — skipping: '
          'table=${batch.crud.isNotEmpty ? batch.crud.first.table : "?"} '
          'id=${batch.crud.isNotEmpty ? batch.crud.first.id : "?"} '
          'status=$status',
        );
        await batch.complete();
        return;
      }
      logError('Upload failed with DioException (attempt $retries/$_maxTransientRetries): ${e.message}');
      rethrow;
    } catch (e) {
      final retries = (_transientRetryCount[batchKey] ?? 0) + 1;
      _transientRetryCount[batchKey] = retries;
      if (retries >= _maxTransientRetries) {
        _transientRetryCount.remove(batchKey);
        logWarning('Upload error after $retries retries — skipping: $e');
        await batch.complete();
        return;
      }
      logError('Upload failed (attempt $retries/$_maxTransientRetries): $e');
      rethrow;
    }
  }

  Future<void> _uploadOperation(CrudEntry op, String token) async {
    final data = op.opData ?? {};
    final headers = {'Authorization': 'Bearer $token'};

    logDebug('Uploading op: table=${op.table}, op=${op.op}, id=${op.id}');

    switch (op.table) {
      case 'clients':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients',
          putUrl: '$_apiUrl/clients/${op.id}',
          deleteUrl: '$_apiUrl/clients/${op.id}',
          data: data,
          headers: headers,
        );

      case 'addresses':
        final clientId = data['client_id'] as String?;
        if (clientId == null) throw Exception('addresses op missing client_id');
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients/$clientId/addresses',
          putUrl: '$_apiUrl/clients/$clientId/addresses/${op.id}',
          deleteUrl: '$_apiUrl/clients/$clientId/addresses/${op.id}',
          data: data,
          headers: headers,
        );

      case 'phone_numbers':
        final clientId = data['client_id'] as String?;
        if (clientId == null) throw Exception('phone_numbers op missing client_id');
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/clients/$clientId/phones',
          putUrl: '$_apiUrl/clients/$clientId/phones/${op.id}',
          deleteUrl: '$_apiUrl/clients/$clientId/phones/${op.id}',
          data: data,
          headers: headers,
        );

      case 'itineraries':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/itineraries',
          putUrl: '$_apiUrl/itineraries/${op.id}',
          deleteUrl: '$_apiUrl/itineraries/${op.id}',
          data: data,
          headers: headers,
        );

      case 'visits':
        if (op.op == UpdateType.put) {
          final photoPath = data['_local_photo_path'] as String?;
          final visitData = Map<String, dynamic>.from(data)
            ..remove('_local_photo_path')
            ..['id'] = op.id;
          if (photoPath != null) {
            await _uploadVisitWithPhoto(
              visitData: visitData,
              photoPath: photoPath,
              headers: headers,
            );
          } else {
            await _httpClient.post(
              '$_apiUrl/visits',
              data: visitData,
              options: Options(headers: headers),
            );
          }
        }

      case 'calls':
        if (op.op == UpdateType.put) {
          final callData = Map<String, dynamic>.from(data)..['id'] = op.id;
          await _httpClient.post(
            '$_apiUrl/calls',
            data: callData,
            options: Options(headers: headers),
          );
        } else if (op.op == UpdateType.delete) {
          await _httpClient.delete(
            '$_apiUrl/calls/${op.id}',
            options: Options(headers: headers),
          );
        }

      case 'touchpoints':
        await _uploadCrud(
          op: op,
          postUrl: '$_apiUrl/touchpoints',
          putUrl: '$_apiUrl/touchpoints/${op.id}',
          deleteUrl: '$_apiUrl/touchpoints/${op.id}',
          data: data,
          headers: headers,
        );

      case 'attendance':
        if (op.op == UpdateType.put) {
          await _httpClient.post(
            '$_apiUrl/attendance/check-in',
            data: data,
            options: Options(headers: headers),
          );
        } else if (op.op == UpdateType.patch) {
          await _httpClient.post(
            '$_apiUrl/attendance/check-out',
            data: data,
            options: Options(headers: headers),
          );
        }

      case 'releases':
        if (op.op == UpdateType.put) {
          final releaseData = Map<String, dynamic>.from(data)..['id'] = op.id;
          await _httpClient.post(
            '$_apiUrl/releases',
            data: releaseData,
            options: Options(headers: headers),
          );
        }

      case 'approvals':
        if (op.op == UpdateType.put) {
          await _httpClient.post(
            '$_apiUrl/approvals',
            data: data,
            options: Options(headers: headers),
          );
        }

      default:
        logWarning('uploadData: unhandled table "${op.table}" — skipping');
    }
  }

  Future<void> _uploadCrud({
    required CrudEntry op,
    required String postUrl,
    required String putUrl,
    required String deleteUrl,
    required Map<String, dynamic> data,
    required Map<String, String> headers,
  }) async {
    switch (op.op) {
      case UpdateType.put:
        final postData = Map<String, dynamic>.from(data)..['id'] = op.id;
        await _httpClient.post(postUrl, data: postData, options: Options(headers: headers));
      case UpdateType.patch:
        await _httpClient.put(putUrl, data: data, options: Options(headers: headers));
      case UpdateType.delete:
        await _httpClient.delete(deleteUrl, options: Options(headers: headers));
    }
  }

  Future<void> _uploadVisitWithPhoto({
    required Map<String, dynamic> visitData,
    required String photoPath,
    required Map<String, String> headers,
  }) async {
    final formData = FormData.fromMap({
      ...visitData,
      'photo': await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      ),
    });
    await _httpClient.post(
      '$_apiUrl/visits',
      data: formData,
      options: Options(headers: headers),
    );
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
