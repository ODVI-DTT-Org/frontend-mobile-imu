import '../services/token_manager.dart';

/// Repository interface for authentication operations.
///
/// This abstract class defines the contract for authentication
/// operations, allowing for different implementations (e.g., mock
/// for testing, remote for production).
abstract class AuthRepository {
  /// Token manager for accessing and managing tokens
  ///
  /// Exposed for use by services that need direct token access
  /// (e.g., TokenRefreshService, Dio interceptors).
  TokenManager get tokenManager;

  /// Authenticate user with email and password.
  ///
  /// Returns [TokenData] on successful authentication.
  /// Throws [AuthException] on authentication failure.
  Future<TokenData> login(String email, String password);

  /// Refresh the access token using refresh token.
  ///
  /// Returns new [TokenData] on success.
  /// Throws [AuthException] if refresh token is invalid.
  Future<TokenData> refreshToken(String refreshToken);

  /// Logout current user.
  ///
  /// Clears tokens and invalidates the session.
  Future<void> logout();

  /// Check if user is currently authenticated.
  ///
  /// Returns true if valid tokens exist.
  Future<bool> isAuthenticated();

  /// Get the current user's ID.
  ///
  /// Returns null if no user is logged in.
  Future<String?> getCurrentUserId();
}
