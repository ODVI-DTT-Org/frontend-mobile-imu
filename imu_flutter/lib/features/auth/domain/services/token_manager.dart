import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../entities/auth_state.dart';

/// Manages authentication tokens with secure storage.
///
/// Security model:
/// - Access token: Memory + Secure storage (persistent, encrypted, for JwtAuthService compatibility)
/// - Refresh token: Secure storage (persistent, encrypted)
/// - Token expiry: Tracked in memory
class TokenManager {
  final FlutterSecureStorage _secureStorage;
  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiryTime;
  Timer? _refreshTimer;

  TokenManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Store tokens from successful authentication.
  ///
  /// Access token is stored in both memory and secure storage.
  /// - Memory: Fast access, volatile
  /// - Secure storage: Persistent, for JwtAuthService compatibility
  /// Refresh token is encrypted and stored persistently.
  Future<void> storeTokens(TokenData tokens) async {
    _accessToken = tokens.accessToken;
    _expiryTime = DateTime.now().add(tokens.expiresIn);

    // Store access token in secure storage (for JwtAuthService compatibility)
    // JwtAuthService uses key 'auth_token' for access tokens
    await _secureStorage.write(
      key: 'auth_token',
      value: tokens.accessToken,
    );

    // Store refresh token securely
    await _secureStorage.write(
      key: 'refresh_token',
      value: tokens.refreshToken,
    );

    // Store user ID for session recovery
    if (tokens.userId != null) {
      await _secureStorage.write(
        key: 'user_id',
        value: tokens.userId!,
      );
    }
  }

  /// Get the current access token.
  ///
  /// Checks memory first for fast access. If not in memory or expired,
  /// loads from secure storage (for JwtAuthService compatibility).
  ///
  /// Returns null if no token is available or token has expired.
  Future<String?> getAccessToken() async {
    // Check memory first
    if (_accessToken != null && !isTokenExpired()) {
      return _accessToken;
    }

    // If not in memory or expired, try loading from secure storage
    // This ensures compatibility with JwtAuthService which uses key 'auth_token'
    final storedToken = await _secureStorage.read(key: 'auth_token');
    if (storedToken != null && storedToken.isNotEmpty) {
      _accessToken = storedToken;
      // Note: We can't determine expiry from stored token without additional metadata
      // Assuming token is valid if it exists in storage
      return _accessToken;
    }

    return null;
  }

  /// Get the refresh token from secure storage.
  Future<String?> getRefreshToken() async {
    // Check memory first
    if (_refreshToken != null) return _refreshToken;

    // Load from secure storage
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    return _refreshToken;
  }

  /// Check if the access token has expired.
  bool isTokenExpired() {
    if (_expiryTime == null) return true;
    return DateTime.now().isAfter(_expiryTime!);
  }

  /// Check if the token will expire soon (within 5 minutes).
  bool willExpireSoon() {
    if (_expiryTime == null) return true;
    return DateTime.now().add(const Duration(minutes: 5)).isAfter(_expiryTime!);
  }

  /// Get the remaining time until token expiry.
  Duration? get timeUntilExpiry {
    if (_expiryTime == null) return null;
    final remaining = _expiryTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Clear all tokens from memory and storage.
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _expiryTime = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;

    // Clear all tokens from secure storage
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_id');
  }

  /// Get the stored user ID.
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }

  /// Check if a refresh token is available.
  Future<bool> hasRefreshToken() async {
    final token = await getRefreshToken();
    return token != null && token.isNotEmpty;
  }

  /// Dispose of resources (cancel timers).
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}

/// Data class for token information from authentication response.
class TokenData {
  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
  final String? userId;

  TokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.userId,
  });

  /// Create TokenData from API response JSON.
  factory TokenData.fromJson(Map<String, dynamic> json) {
    return TokenData(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: Duration(
        seconds: json['expires_in'] as int? ?? 3600,
      ),
      userId: json['user_id'] as String?,
    );
  }

  /// Convert to JSON for storage/transmission.
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn.inSeconds,
      if (userId != null) 'user_id': userId,
    };
  }
}
