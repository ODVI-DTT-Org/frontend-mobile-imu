import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/logger.dart';

/// User model parsed from JWT token
class JwtUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
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
      role: decoded['role'] ?? 'field_agent',
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
    'role': role,
  };

  @override
  String toString() => 'JwtUser(id: $id, email: $email, role: $role)';
}

/// JWT-based authentication service
class JwtAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  JwtUser? _currentUser;

  JwtAuthService({Dio? dio, FlutterSecureStorage? storage})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AppConfig.postgresApiUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),),
        _storage = storage ?? const FlutterSecureStorage();

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

    logDebug('Logout successful');
  }

  /// Refresh access token using refresh token
  Future<void> refreshTokens() async {
    if (_refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      logDebug('Refreshing tokens...');

      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': _refreshToken,
        },
      );

      _accessToken = response.data['access_token'];
      _refreshToken = response.data['refresh_token'];
      _currentUser = JwtUser.fromToken(_accessToken!);

      await _storage.write(key: 'access_token', value: _accessToken);
      await _storage.write(key: 'refresh_token', value: _refreshToken);

      logDebug('Token refresh successful');
    } catch (e) {
      logError('Token refresh failed', e);
      // Clear tokens on refresh failure
      await logout();
      rethrow;
    }
  }

  /// Register new user (for development/testing)
  Future<JwtUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'field_agent',
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

  /// Check if token needs refresh (within 1 hour of expiry)
  bool get needsRefresh {
    if (_currentUser?.expiresAt == null) return false;
    const oneHour = Duration(hours: 1);
    return DateTime.now().add(oneHour).isAfter(_currentUser!.expiresAt!);
  }
}
