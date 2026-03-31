import 'dart:async';
import 'token_manager.dart';

/// Result of a token refresh operation.
class TokenRefreshResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final Duration? expiresIn;
  final String? error;
  final int attempt;

  const TokenRefreshResult({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.error,
    this.attempt = 0,
  });

  factory TokenRefreshResult.success({
    required String accessToken,
    required String refreshToken,
    required Duration expiresIn,
    int attempt = 0,
  }) {
    return TokenRefreshResult(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
      attempt: attempt,
    );
  }

  factory TokenRefreshResult.failure({
    required String error,
    int attempt = 0,
  }) {
    return TokenRefreshResult(
      success: false,
      error: error,
      attempt: attempt,
    );
  }

  @override
  String toString() {
    if (success) {
      return 'TokenRefreshResult.success(attempt: $attempt)';
    } else {
      return 'TokenRefreshResult.failure(error: $error, attempt: $attempt)';
    }
  }
}

/// Service for managing automatic token refresh and rotation.
///
/// Features:
/// - Automatic token refresh before expiry (5 minutes before)
/// - Retry logic with exponential backoff
/// - Refresh token rotation (new refresh token on each refresh)
/// - Coordination with AuthCoordinator state machine
///
/// Security considerations:
/// - Access tokens are short-lived (default 1 hour)
/// - Refresh tokens are rotated on each use
/// - Failed refresh attempts trigger re-authentication flow
/// - Maximum retry attempts prevent infinite loops
class TokenRefreshService {
  /// How long before expiry to trigger refresh (5 minutes)
  static const Duration refreshBuffer = Duration(minutes: 5);

  /// Maximum number of retry attempts for failed refresh
  static const int maxRetryAttempts = 3;

  /// Initial retry delay (1 second)
  static const Duration initialRetryDelay = Duration(seconds: 1);

  /// Maximum retry delay (30 seconds)
  static const Duration maxRetryDelay = Duration(seconds: 30);

  /// Backoff multiplier for exponential backoff
  static const double backoffMultiplier = 2.0;

  final TokenManager _tokenManager;
  final Future<TokenRefreshResult> Function(String refreshToken) _refreshCallback;

  Timer? _refreshTimer;
  Timer? _retryTimer;
  bool _isRefreshing = false;
  int _retryAttempt = 0;
  final StreamController<TokenRefreshResult> _refreshResultsController =
      StreamController<TokenRefreshResult>.broadcast();

  /// Stream of refresh results for UI updates and logging.
  Stream<TokenRefreshResult> get refreshResults => _refreshResultsController.stream;

  /// Whether a refresh operation is currently in progress.
  bool get isRefreshing => _isRefreshing;

  /// Current retry attempt count (0 if not retrying).
  int get retryAttempt => _retryAttempt;

  TokenRefreshService({
    required TokenManager tokenManager,
    required Future<TokenRefreshResult> Function(String refreshToken) refreshCallback,
  })  : _tokenManager = tokenManager,
        _refreshCallback = refreshCallback;

  /// Start automatic token refresh monitoring.
  ///
  /// Schedules a refresh 5 minutes before token expiry.
  /// If token is already expired or will expire soon, refreshes immediately.
  Future<void> startMonitoring() async {
    await stopMonitoring();

    final timeUntilExpiry = _tokenManager.timeUntilExpiry;
    if (timeUntilExpiry == null) {
      // No token available, nothing to monitor
      return;
    }

    if (timeUntilExpiry <= refreshBuffer) {
      // Token expires soon or already expired, refresh immediately
      _scheduleRefresh(Duration.zero);
    } else {
      // Schedule refresh for buffer time before expiry
      final delay = timeUntilExpiry - refreshBuffer;
      _scheduleRefresh(delay);
    }
  }

  /// Stop automatic token refresh monitoring.
  Future<void> stopMonitoring() async {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _isRefreshing = false;
    _retryAttempt = 0;
  }

  /// Manually trigger a token refresh.
  ///
  /// Use this when you need to force a refresh (e.g., after API 401 error).
  /// Returns the refresh result for immediate handling.
  Future<TokenRefreshResult> refreshNow() async {
    if (_isRefreshing) {
      // Already refreshing, return in-progress status
      return TokenRefreshResult.failure(
        error: 'Refresh already in progress',
        attempt: _retryAttempt,
      );
    }

    return await _performRefresh();
  }

  /// Schedule a refresh operation after the specified delay.
  void _scheduleRefresh(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () async {
      await _performRefresh();
    });
  }

  /// Perform the actual token refresh operation.
  Future<TokenRefreshResult> _performRefresh() async {
    if (_isRefreshing) {
      return TokenRefreshResult.failure(
        error: 'Refresh already in progress',
        attempt: _retryAttempt,
      );
    }

    _isRefreshing = true;

    try {
      // Retry loop for failed refresh attempts
      while (_retryAttempt < maxRetryAttempts) {
        // Get refresh token
        final refreshToken = await _tokenManager.getRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          _isRefreshing = false;
          final result = TokenRefreshResult.failure(
            error: 'No refresh token available',
            attempt: _retryAttempt,
          );
          _refreshResultsController.add(result);
          return result;
        }

        // Call refresh callback (API call)
        final result = await _refreshCallback(refreshToken);

        if (result.success) {
          // Success: store new tokens
          await _tokenManager.storeTokens(TokenData(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
            expiresIn: result.expiresIn ?? const Duration(hours: 1),
          ));

          // Reset retry counter
          _retryAttempt = 0;

          // Schedule next refresh
          await startMonitoring();

          _isRefreshing = false;
          _refreshResultsController.add(result);
          return result;
        } else {
          // Failure: increment retry counter
          _retryAttempt++;

          if (_retryAttempt >= maxRetryAttempts) {
            // Max retries reached, give up
            _isRefreshing = false;
            final failureResult = TokenRefreshResult.failure(
              error: 'Max retry attempts reached: ${result.error}',
              attempt: _retryAttempt,
            );
            _refreshResultsController.add(failureResult);
            return failureResult;
          }

          // Calculate exponential backoff delay
          final delay = _calculateBackoffDelay(_retryAttempt);

          // Wait before retrying
          await Future.delayed(delay);
        }
      }

      // Should not reach here, but handle gracefully
      _isRefreshing = false;
      final failureResult = TokenRefreshResult.failure(
        error: 'Max retry attempts reached',
        attempt: _retryAttempt,
      );
      _refreshResultsController.add(failureResult);
      return failureResult;
    } catch (e) {
      // Exception during refresh
      _retryAttempt++;

      if (_retryAttempt >= maxRetryAttempts) {
        _isRefreshing = false;
        final result = TokenRefreshResult.failure(
          error: 'Max retry attempts reached: Exception: $e',
          attempt: _retryAttempt,
        );
        _refreshResultsController.add(result);
        return result;
      }

      // Retry with backoff
      final delay = _calculateBackoffDelay(_retryAttempt);
      await Future.delayed(delay);
      // Continue the retry loop
      return await _performRefresh();
    }
  }

  /// Handle a failed refresh attempt with retry logic.
  Future<TokenRefreshResult> _handleRefreshFailure(String error) async {
    _retryAttempt++;

    if (_retryAttempt >= maxRetryAttempts) {
      // Max retries reached, give up
      _isRefreshing = false;
      final result = TokenRefreshResult.failure(
        error: 'Max retry attempts reached: $error',
        attempt: _retryAttempt,
      );
      _refreshResultsController.add(result);
      return result;
    }

    // Calculate exponential backoff delay
    final delay = _calculateBackoffDelay(_retryAttempt);

    // Schedule retry
    _retryTimer = Timer(delay, () async {
      await _performRefresh();
    });

    final result = TokenRefreshResult.failure(
      error: error,
      attempt: _retryAttempt,
    );
    _refreshResultsController.add(result);

    // Still refreshing while waiting for retry
    // _isRefreshing remains true
    return result;
  }

  /// Calculate exponential backoff delay for retry.
  Duration _calculateBackoffDelay(int attempt) {
    final delay = Duration(
      milliseconds: (initialRetryDelay.inMilliseconds * backoffMultiplier).toInt(),
    );

    final exponentialDelay = Duration(
      milliseconds: (initialRetryDelay.inMilliseconds *
          pow(backoffMultiplier, attempt - 1)).toInt(),
    );

    final clampedDelay = exponentialDelay > maxRetryDelay
        ? maxRetryDelay
        : exponentialDelay;

    return clampedDelay;
  }

  /// Clear retry state and stop monitoring.
  ///
  /// Call this when user logs out or switches accounts.
  Future<void> reset() async {
    await stopMonitoring();
    _retryAttempt = 0;
    _isRefreshing = false;
  }

  /// Dispose of resources.
  void dispose() {
    _refreshTimer?.cancel();
    _retryTimer?.cancel();
    _refreshResultsController.close();
  }
}

/// Power function for exponential backoff calculation.
double pow(double base, int exponent) {
  if (exponent == 0) return 1.0;
  if (exponent == 1) return base;

  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
