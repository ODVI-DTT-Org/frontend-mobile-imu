import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/config/app_config.dart';
import '../../core/models/user_role.dart' as core_models;
import '../../core/utils/logger.dart';
import '../area/area_filter_service.dart';
import '../permissions/remote_permission_service.dart';
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

  String? _accessToken;
  String? _refreshToken;
  JwtUser? _currentUser;

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
        )),
        _storage = const FlutterSecureStorage();

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
    try {
      _accessToken = await _storage.read(key: 'access_token');
      _refreshToken = await _storage.read(key: 'refresh_token');

      if (_accessToken != null) {
        _currentUser = JwtUser.fromToken(_accessToken!);

        // If token expired, try to refresh
        if (_currentUser?.isExpired == true && _refreshToken != null) {
          logDebug('Token expired, attempting refresh...');
          await refreshTokens();
        } else {
          logDebug('JwtAuthService initialized, authenticated: $isAuthenticated');
        }
      }
    } catch (e) {
      logError('Failed to initialize JwtAuthService', e);
    }
  }

  /// Login with email and password
  Future<JwtUser> login({required String email, required String password}) async {
    try {
      logDebug('Attempting login for: $email');

      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      _currentUser = JwtUser.fromToken(_accessToken!);

      // Store tokens securely
      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);

      // Save login time for offline grace period
      final secureStorage = SecureStorageService();
      await secureStorage.saveLastOnlineLoginTime();
      await secureStorage.saveLastLoginTime();

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

      logDebug('Login successful for ${_currentUser!.id}');
      return _currentUser!;
    } on DioException catch (e) {
      final message = e.response?.data['message'] ?? 'Login failed';
      logError('Login failed', e);
      throw Exception(message);
    } catch (e) {
      logError('Login failed', e);
      throw Exception('Login failed: $e');
    }
  }

  /// Logout and clear stored tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');

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
    if (_refreshToken == null) {
      logError('Cannot refresh: No refresh token available');
      throw Exception('No refresh token available');
    }

    // Check if current token is still valid (not expired yet)
    // If it's still valid, we might not need to refresh yet
    if (_currentUser != null && !_currentUser!.isExpired) {
      logDebug('Current token is still valid, skipping unnecessary refresh');
      return;
    }

    try {
      logDebug('Refreshing tokens...');

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

      if (response.statusCode == 200 && response.data != null) {
        _accessToken = response.data['access_token'];
        // Update refresh token if provided (some APIs rotate refresh tokens)
        if (response.data['refresh_token'] != null) {
          _refreshToken = response.data['refresh_token'];
        }
        _currentUser = JwtUser.fromToken(_accessToken!);

        await _storage.write(key: 'access_token', value: _accessToken);
        if (response.data['refresh_token'] != null) {
          await _storage.write(key: 'refresh_token', value: _refreshToken);
        }

        // Refresh permissions cache when tokens are refreshed
        try {
          final permissionService = RemotePermissionService();
          await permissionService.fetchPermissions(_accessToken!);
          logDebug('Permissions refreshed successfully');
        } catch (e) {
          logError('Failed to refresh permissions (non-critical)', e);
          // Continue even if permission refresh fails
        }

        logDebug('Token refresh successful');
      } else {
        throw Exception('Invalid response from refresh endpoint');
      }
    } on DioException catch (e) {
      logError('Token refresh failed with DioException', e);

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
      // Only clear tokens on explicit auth failures, not on network errors
      if (e is! Exception || !e.toString().contains('Network error')) {
        await logout();
      }
      rethrow;
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
}
