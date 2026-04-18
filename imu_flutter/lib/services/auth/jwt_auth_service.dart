import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/models/user_role.dart' as core_models;
import '../../core/utils/logger.dart';
import '../area/area_filter_service.dart';
import '../error_logging_helper.dart';
import '../permissions/remote_permission_service.dart';
import '../sync/powersync_service.dart';
import 'secure_storage_service.dart';

/// User model parsed from JWT token
class JwtUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final core_models.UserRole role;
  final DateTime? expiresAt;

  JwtUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.expiresAt,
  });

  /// Create JwtUser from JWT token payload
  factory JwtUser.fromToken(String token) {
    final decoded = JwtDecoder.decode(token);
    return JwtUser(
      id: decoded['sub'] ?? '',
      email: decoded['email'] ?? '',
      firstName: decoded['first_name'] ?? '',
      lastName: decoded['last_name'] ?? '',
      role: core_models.UserRole.fromJwt(decoded),
      expiresAt: decoded['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(decoded['exp'] * 1000)
          : null,
    );
  }

  /// Get user's full name
  String get fullName => '$firstName $lastName'.trim();

  /// Check if token is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if user session is valid
  bool get isValid => !isExpired;

  /// Get user data as a map (for backward compatibility)
  Map<String, dynamic> get data => {
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'role': role.apiValue,
  };

  @override
  String toString() => 'JwtUser(id: $id, email: $email, role: ${role.apiValue})';
}

/// JWT-based authentication service
class JwtAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  SharedPreferences? _prefs;  // Fallback storage for Samsung devices

  String? _accessToken;
  String? _refreshToken;
  JwtUser? _currentUser;

  // Refresh lock to prevent concurrent refresh attempts
  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  // Initialize lock to prevent concurrent initialization attempts
  bool _isInitializing = false;
  Completer<void>? _initCompleter;
  bool _isInitialized = false;

  // Singleton instance
  static JwtAuthService? _instance;

  /// Get the singleton instance
  static JwtAuthService get instance {
    _instance ??= JwtAuthService._internal();
    return _instance!;
  }

  /// Private constructor for singleton
  JwtAuthService._internal()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.postgresApiUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),),
        _storage = FlutterSecureStorage() {
    // Initialize SharedPreferences asynchronously
    _initPreferences();
  }

  /// Initialize SharedPreferences
  Future<void> _initPreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      logDebug('[STORAGE] SharedPreferences initialized');
    } catch (e) {
      logError('[STORAGE] Failed to initialize SharedPreferences', e);
    }
  }

  /// Public constructor (for backwards compatibility, returns singleton)
  factory JwtAuthService({Dio? dio, FlutterSecureStorage? storage}) {
    // Ignore dio and storage parameters for singleton pattern
    // This ensures all instances share the same token state
    return instance;
  }

  /// Get current access token
  String? get accessToken => _accessToken;

  /// Get current user
  JwtUser? get currentUser => _currentUser;

  /// Check if user is authenticated with valid token
  bool get isAuthenticated => _accessToken != null && _currentUser?.isValid == true;

  /// Initialize service by loading stored tokens
  Future<void> initialize() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isInitializing) {
      logDebug('[JWT-INIT] Initialization already in progress, waiting...');
      await _initCompleter?.future;
      return;
    }

    // If already initialized, just return
    if (_isInitialized) {
      logDebug('[JWT-INIT] Already initialized, skipping...');
      return;
    }

    // Set initialization lock
    _isInitializing = true;
    _initCompleter = Completer<void>();

    try {
      logDebug('[JWT-INIT] Starting JwtAuthService initialization...');

      // Try FlutterSecureStorage first
      logDebug('[STORAGE-READ] Attempting to read access_token from secure storage...');
      _accessToken = await _storage.read(key: 'access_token');

      // Fallback to SharedPreferences if secure storage is empty (Samsung workaround)
      if (_accessToken == null && _prefs != null) {
        logDebug('[STORAGE-READ] Secure storage empty, trying SharedPreferences...');
        _accessToken = _prefs!.getString('access_token');
        if (_accessToken != null) {
          logDebug('[STORAGE-READ] Access token found in SharedPreferences (fallback worked!)');
          // Restore to secure storage for next time
          await _storage.write(key: 'access_token', value: _accessToken);
          logDebug('[STORAGE-READ] Restored token to secure storage');
        }
      }

      logDebug('[STORAGE-READ] Access token read: ${_accessToken != null ? "YES (" + _accessToken!.substring(0, 20) + "...)" : "NO"}');

      logDebug('[STORAGE-READ] Attempting to read refresh_token from storage...');
      _refreshToken = await _storage.read(key: 'refresh_token');

      // Fallback to SharedPreferences for refresh token
      if (_refreshToken == null && _prefs != null) {
        _refreshToken = _prefs!.getString('refresh_token');
      }

      logDebug('[STORAGE-READ] Refresh token read: ${_refreshToken != null ? "YES" : "NO"}');

      logDebug('[JWT-INIT] Access token found: ${_accessToken != null}');
      logDebug('[JWT-INIT] Refresh token found: ${_refreshToken != null}');

      if (_accessToken != null) {
        _currentUser = JwtUser.fromToken(_accessToken!);
        logDebug('[JWT-INIT] User loaded: ${_currentUser?.fullName}, Token expires at: ${_currentUser?.expiresAt}');

        // If token expired, try to refresh
        if (_currentUser?.isExpired == true && _refreshToken != null) {
          logDebug('Token expired, attempting refresh...');
          await refreshTokens();
        } else {
          logDebug('[JWT-INIT] JwtAuthService initialized, authenticated: $isAuthenticated');
        }
      } else {
        logDebug('[JWT-INIT] No access token found in storage');
      }

      _isInitialized = true;
    } catch (e) {
      logError('[JWT-INIT] Failed to initialize JwtAuthService', e);
    } finally {
      // Always release the lock
      _isInitializing = false;
      _initCompleter?.complete();
      _initCompleter = null;
    }
  }

  /// Login with email and password
  Future<JwtUser> login({required String email, required String password, bool rememberMe = false}) async {
    try {
      logDebug('Attempting login for: $email (rememberMe: $rememberMe)');

      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          if (rememberMe) 'remember_me': true,
        },
      );

      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];

      logDebug('[LOGIN-RESPONSE] Access token received: ${_accessToken != null ? "YES (${_accessToken!.substring(0, 20)}...)" : "NO"}');
      logDebug('[LOGIN-RESPONSE] Refresh token received: ${_refreshToken != null ? "YES" : "NO"}');

      _currentUser = JwtUser.fromToken(_accessToken!);

      // Store tokens securely
      logDebug('[STORAGE] Saving access token to secure storage...');
      await _storage.write(key: 'access_token', value: _accessToken);
      logDebug('[STORAGE] Access token saved successfully');

      // ALSO save to SharedPreferences as fallback for Samsung devices
      if (_prefs != null) {
        await _prefs!.setString('access_token', _accessToken!);
        logDebug('[STORAGE] Access token also saved to SharedPreferences (fallback)');
      }

      // Verify token was actually stored by reading it back immediately
      final verificationToken = await _storage.read(key: 'access_token');
      logDebug('[STORAGE-VERIFY] Token verification read: ${verificationToken != null ? "SUCCESS" : "FAILED"}');
      if (verificationToken != null) {
        logDebug('[STORAGE-VERIFY] Token matches: ${verificationToken == _accessToken ? "YES" : "NO"}');
      }

      if (_refreshToken != null) {
        logDebug('[STORAGE] Saving refresh token to secure storage...');
        await _storage.write(key: 'refresh_token', value: _refreshToken);
        logDebug('[STORAGE] Refresh token saved successfully');

        // ALSO save to SharedPreferences as fallback
        if (_prefs != null) {
          await _prefs!.setString('refresh_token', _refreshToken!);
          logDebug('[STORAGE] Refresh token also saved to SharedPreferences (fallback)');
        }
      } else {
        logDebug('[STORAGE] No refresh token to save (backend did not provide one)');
      }

      // Save login time for offline grace period
      final secureStorage = SecureStorageService();
      await secureStorage.saveLastOnlineLoginTime();
      await secureStorage.saveLastLoginTime();

      // Save credential hash + offline JWT so re-login works after logout (offline)
      try {
        await secureStorage.saveOfflineCredentials(email, password, _accessToken!);
        logDebug('Offline credentials saved for post-logout offline login');
      } catch (e) {
        logError('Failed to save offline credentials (non-critical)', e);
      }

      // Fetch and cache user permissions from backend
      try {
        final permissionService = RemotePermissionService();
        await permissionService.fetchPermissions(_accessToken!);
        logDebug('Permissions fetched and cached successfully');
      } catch (e) {
        logError('Failed to fetch permissions (non-critical)', e);
        // Continue login even if permission fetch fails
      }

      // Fetch and cache user's assigned areas (municipalities)
      try {
        final areaService = AreaFilterService();
        await areaService.fetchUserLocations(_accessToken!, _currentUser!.id);
        logDebug('User locations fetched and cached successfully');
      } catch (e) {
        logError('Failed to fetch user locations (non-critical)', e);
        // Continue login even if area fetch fails
      }

      // Store credentials if remember me is enabled
      if (rememberMe) {
        await storeCredentials(email: email, password: password);
        logDebug('Credentials stored for remember me');
      } else {
        // Clear any previously stored credentials
        await clearStoredCredentials();
        logDebug('Cleared any previously stored credentials');
      }

      logDebug('Login successful for ${_currentUser!.id}');

      // Identify user in PostHog for analytics
      try {
        await Posthog().identify(
          userId: _currentUser!.id,
          userProperties: {
            'email': _currentUser!.email,
            'name': _currentUser!.fullName,
            'role': _currentUser!.role.apiValue,
            'platform': 'mobile',
          },
        );
      } catch (e) {
        logDebug('PostHog identify failed (non-critical): $e');
      }

      return _currentUser!;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Login failed';
      logError('Login failed', e);
      ErrorLoggingHelper.logCriticalError(
        operation: 'user login',
        error: e,
        stackTrace: StackTrace.current,
        context: {'email': email},
      );
      throw Exception(message);
    } catch (e) {
      logError('Login failed', e);
      ErrorLoggingHelper.logCriticalError(
        operation: 'user login',
        error: e,
        stackTrace: StackTrace.current,
        context: {'email': email},
      );
      throw Exception('Login failed: $e');
    }
  }

  /// Logout and clear stored tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _isInitialized = false; // Reset initialization flag so it can be re-initialized

    // Reset PostHog identity on logout
    try {
      await Posthog().reset();
    } catch (e) {
      logDebug('PostHog reset failed (non-critical): $e');
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');

    // Clear stored credentials on logout (security measure)
    await clearStoredCredentials();
    logDebug('Stored credentials cleared on logout');

    // Disconnect and clear PowerSync on logout to prevent credential issues
    try {
      await PowerSyncService.closeAndClear();
      logDebug('PowerSync closed and cleared on logout');
    } catch (e) {
      logError('Failed to close PowerSync', e);
      // Continue logout even if PowerSync close fails
    }

    // Clear permissions cache on logout
    try {
      final permissionService = RemotePermissionService();
      await permissionService.clearCache();
      logDebug('Permissions cache cleared');
    } catch (e) {
      logError('Failed to clear permissions cache', e);
    }

    // Clear area locations cache on logout
    try {
      final areaService = AreaFilterService();
      await areaService.clearCache();
      logDebug('User locations cache cleared');
    } catch (e) {
      logError('Failed to clear user locations cache', e);
    }

    logDebug('Logout successful');
  }

  /// Refresh access token using refresh token
  Future<void> refreshTokens() async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      logDebug('[JWT-REFRESH] Refresh already in progress, waiting...');
      await _refreshCompleter?.future;
      return;
    }

    logDebug('[JWT-REFRESH] Token refresh requested...');
    logDebug('[JWT-REFRESH] Has access token: ${_accessToken != null}');
    logDebug('[JWT-REFRESH] Has refresh token: ${_refreshToken != null}');
    logDebug('[JWT-REFRESH] Current user: ${_currentUser?.fullName}');
    logDebug('[JWT-REFRESH] Token expired: ${_currentUser?.isExpired ?? false}');

    if (_refreshToken == null) {
      logError('[JWT-REFRESH] Cannot refresh: No refresh token available');
      throw Exception('No refresh token available');
    }

    // Check if current token is still valid (not expired yet)
    // If it's still valid, we might not need to refresh yet
    if (_currentUser != null && !_currentUser!.isExpired) {
      logDebug('[JWT-REFRESH] Current token is still valid, skipping unnecessary refresh');
      return;
    }

    // Set refresh lock
    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      logDebug('[JWT-REFRESH] Calling /auth/refresh endpoint...');

      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': _refreshToken,
        },
        options: Options(
          // Add longer timeout for refresh endpoint
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      logDebug('[JWT-REFRESH] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data['access_token'];
        logDebug('[JWT-REFRESH] New access token received');
        // Update refresh token if provided (some APIs rotate refresh tokens)
        if (response.data['refresh_token'] != null) {
          _refreshToken = response.data['refresh_token'];
          logDebug('[JWT-REFRESH] New refresh token received (token rotation)');
        }
        _currentUser = JwtUser.fromToken(_accessToken!);
        logDebug('[JWT-REFRESH] New user: ${_currentUser?.fullName}, expires: ${_currentUser?.expiresAt}');

        await _storage.write(key: 'access_token', value: _accessToken);
        if (response.data['refresh_token'] != null) {
          await _storage.write(key: 'refresh_token', value: _refreshToken);
        }
        logDebug('[JWT-REFRESH] Tokens stored to secure storage');

        // Refresh permissions cache when tokens are refreshed
        try {
          final permissionService = RemotePermissionService();
          await permissionService.fetchPermissions(_accessToken!);
          logDebug('[JWT-REFRESH] Permissions refreshed successfully');
        } catch (e) {
          logError('[JWT-REFRESH] Failed to refresh permissions (non-critical)', e);
          // Continue even if permission refresh fails
        }

        logDebug('[JWT-REFRESH] Token refresh successful');
      } else {
        logError('[JWT-REFRESH] Invalid response from refresh endpoint: ${response.statusCode}');
        throw Exception('Invalid response from refresh endpoint');
      }
    } on DioException catch (e) {
      logError('[JWT-REFRESH] Token refresh failed with DioException', e);

      // Check if it's a network error vs auth error
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        logError('Network error during token refresh - will retry later', e);
        throw Exception('Network error - please check your connection');
      }

      // For auth errors (401, 403), clear tokens
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        logError('Authentication failed during refresh - clearing tokens', e);
        await logout();
        throw Exception('Session expired - please login again');
      }

      // For other errors, don't clear tokens - might be temporary
      logError('Unexpected error during token refresh', e);
      throw Exception('Token refresh failed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      logError('Token refresh failed with unexpected error', e);
      ErrorLoggingHelper.logCriticalError(
        operation: 'token refresh',
        error: e,
        stackTrace: StackTrace.current,
      );
      // Only clear tokens on explicit auth failures, not on network errors
      if (e is! Exception || !e.toString().contains('Network error')) {
        await logout();
      }
      rethrow;
    } finally {
      // Always release the refresh lock
      _isRefreshing = false;
      _refreshCompleter?.complete();
      _refreshCompleter = null;
    }
  }

  /// Ensure token is valid before making API requests
  /// Automatically refreshes if token is near expiry (within 5 minutes)
  Future<void> ensureValidToken() async {
    // If not authenticated, nothing to do
    if (!isAuthenticated) {
      return;
    }

    // If refresh is already in progress, wait for it
    if (_isRefreshing) {
      logDebug('Refresh in progress, waiting for completion...');
      await _refreshCompleter?.future;
      return;
    }

    // Check if token needs refresh (within 5 minutes of expiry)
    if (shouldAttemptRefresh) {
      logDebug('Token near expiry, refreshing before API call...');
      await refreshTokens();
    }
  }

  /// Register new user (for development/testing)
  Future<JwtUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'caravan',
  }) async {
    try {
      logDebug('Attempting registration for: $email');

      await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
        },
      );

      // After registration, login to get tokens
      return await login(email: email, password: password);
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Registration failed';
      logError('Registration failed', e);
      throw Exception(message);
    } catch (e) {
      logError('Registration failed', e);
      throw Exception('Registration failed: $e');
    }
  }

  /// Get authorization header for API requests
  String? get authHeader => _accessToken != null ? 'Bearer $_accessToken' : null;

  /// Check if token needs refresh (within 30 minutes of expiry)
  /// Reduced from 1 hour to 30 minutes to be more proactive
  bool get needsRefresh {
    if (_currentUser?.expiresAt == null) return false;
    const thirtyMinutes = Duration(minutes: 30);
    return DateTime.now().add(thirtyMinutes).isAfter(_currentUser!.expiresAt!);
  }

  /// Check if token is expired or will expire very soon (5 minutes)
  /// Used to determine if we should attempt a refresh before operations
  bool get shouldAttemptRefresh {
    if (_currentUser?.expiresAt == null) return false;
    const fiveMinutes = Duration(minutes: 5);
    return DateTime.now().add(fiveMinutes).isAfter(_currentUser!.expiresAt!);
  }

  /// Get time until token expires
  Duration? get timeUntilExpiry {
    if (_currentUser?.expiresAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_currentUser!.expiresAt!)) return Duration.zero;
    return _currentUser!.expiresAt!.difference(now);
  }

  // ===== OFFLINE AUTHENTICATION SUPPORT =====

  /// Set access token and user from offline authentication
  /// This is used by offline auth service to restore session
  Future<void> setOfflineAuth({required String token, required JwtUser user}) async {
    _accessToken = token;
    _currentUser = user;

    // Also restore refresh token from storage to maintain full session
    _refreshToken = await _storage.read(key: 'refresh_token');

    logDebug('Offline auth restored for ${user.id}');
    logDebug('Refresh token restored: ${_refreshToken != null}');
  }

  /// Update cached tokens (for offline auth service)
  Future<void> updateCachedTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      _accessToken = accessToken;
      await _storage.write(key: 'access_token', value: accessToken);
    }
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }
    logDebug('Cached tokens updated');
  }

  // ===== REMEMBER ME CREDENTIAL STORAGE =====

  /// Store credentials for auto-login (when "Remember me" is enabled)
  Future<void> storeCredentials({required String email, required String password}) async {
    try {
      await _storage.write(key: 'remembered_email', value: email);
      await _storage.write(key: 'remembered_password', value: password);
      logDebug('[REMEMBER-ME] Credentials stored securely');
    } catch (e) {
      logError('[REMEMBER-ME] Failed to store credentials', e);
      // Don't throw - login should succeed even if credential storage fails
    }
  }

  /// Get stored credentials for auto-login
  /// Returns null if no credentials are stored
  Future<Map<String, String>?> getStoredCredentials() async {
    try {
      final email = await _storage.read(key: 'remembered_email');
      final password = await _storage.read(key: 'remembered_password');

      if (email != null && password != null) {
        logDebug('[REMEMBER-ME] Found stored credentials');
        return {'email': email, 'password': password};
      }

      logDebug('[REMEMBER-ME] No stored credentials found');
      return null;
    } catch (e) {
      logError('[REMEMBER-ME] Failed to retrieve stored credentials', e);
      return null;
    }
  }

  /// Check if there are stored credentials available
  Future<bool> hasStoredCredentials() async {
    final creds = await getStoredCredentials();
    return creds != null;
  }

  /// Clear stored credentials (for security)
  Future<void> clearStoredCredentials() async {
    try {
      await _storage.delete(key: 'remembered_email');
      await _storage.delete(key: 'remembered_password');
      logDebug('[REMEMBER-ME] Stored credentials cleared');
    } catch (e) {
      logError('[REMEMBER-ME] Failed to clear stored credentials', e);
      // Don't throw - logout should succeed even if clearing fails
    }
  }

  /// Auto-login using stored credentials
  /// Returns true if login was successful, false otherwise
  Future<bool> autoLogin() async {
    try {
      final creds = await getStoredCredentials();
      if (creds == null) {
        logDebug('[REMEMBER-ME] No stored credentials for auto-login');
        return false;
      }

      logDebug('[REMEMBER-ME] Attempting auto-login with stored credentials');
      await login(email: creds['email']!, password: creds['password']!, rememberMe: true);
      logDebug('[REMEMBER-ME] Auto-login successful');
      return true;
    } catch (e) {
      logError('[REMEMBER-ME] Auto-login failed', e);
      // Clear invalid credentials
      await clearStoredCredentials();
      return false;
    }
  }
}
