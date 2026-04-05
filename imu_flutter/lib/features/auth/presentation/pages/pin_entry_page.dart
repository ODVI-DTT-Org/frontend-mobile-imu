import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/user_role.dart' as core_models;
import '../../../../services/auth/secure_storage_service.dart';
import '../../../../services/auth/session_service.dart';
import '../../../../services/auth/auth_service.dart';
import '../../../../services/auth/offline_auth_service.dart';
import '../../../../services/auth/jwt_auth_service.dart';
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/sync/powersync_connector.dart' show powerSyncConnectorProvider;
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/providers/app_providers.dart' show offlineAuthProvider;
import '../../../../core/utils/logger.dart';
import '../../../../services/error_message_mapper.dart';

class PinEntryPage extends ConsumerStatefulWidget {
  const PinEntryPage({super.key});

  @override
  ConsumerState<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends ConsumerState<PinEntryPage> {
  final _secureStorage = SecureStorageService();
  final _sessionService = SessionService();
  final _offlineAuthService = OfflineAuthService();
  final _jwtAuthService = JwtAuthService.instance;

  String _pin = '';
  bool _hasError = false;
  int _attempts = 0;
  bool _isVerifying = false;
  String? _errorMessage;
  bool _isOfflineMode = false;

  @override
  void initState() {
    super.initState();
    // Check if this is offline mode (from query parameter)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final location = GoRouterState.of(context).uri.toString();
      _isOfflineMode = location.contains('offline=true');
      setState(() {});
    });
  }

  void _onPinEntered(String digit) {
    HapticFeedback.lightImpact();

    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
        _hasError = false;
        _errorMessage = null;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();

    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  Future<void> _handleOfflineAuth() async {
    logDebug('Handling offline authentication...');

    // Authenticate with PIN using cached credentials
    final result = await _offlineAuthService.authenticateWithPin(_pin);

    if (!result.success) {
      if (result.requiresReauth) {
        throw Exception('Session expired. Please login with your password.');
      } else {
        throw Exception(result.error ?? 'Authentication failed');
      }
    }

    // Update JWT service with cached token
    final jwtUser = _getUserFromResult(result.user!);
    await _jwtAuthService.setOfflineAuth(
      token: result.token!,
      user: jwtUser,
    );

    // CRITICAL: Update AuthNotifier state so router knows user is authenticated
    final authNotifier = ref.read(authNotifierProvider.notifier);
    // Access the internal state and update it
    // We need to manually update the AuthNotifier since there's no public method for it
    // For now, we'll trigger a status check
    await authNotifier.checkAuthStatus();

    logDebug('Offline authentication successful for ${result.user!.id}');
  }

  Future<void> _handleOnlineAuth() async {
    logDebug('[PIN-ONLINE-AUTH] Handling online authentication...');

    try {
      final authService = ref.read(authServiceProvider);

      // CRITICAL FIX: Ensure JwtAuthService is initialized before any token operations
      logDebug('[PIN-ONLINE-AUTH] Ensuring JwtAuthService is initialized...');
      await _jwtAuthService.initialize();
      logDebug('[PIN-ONLINE-AUTH] JwtAuthService initialization completed');

      // Now check if we have tokens
      logDebug('[PIN-ONLINE-AUTH] Checking token status after initialization...');
      logDebug('[PIN-ONLINE-AUTH] Has access token: ${_jwtAuthService.accessToken != null}');
      logDebug('[PIN-ONLINE-AUTH] Is authenticated: ${authService.isAuthenticated}');
      logDebug('[PIN-ONLINE-AUTH] Needs refresh: ${authService.needsRefresh}');
      logDebug('[PIN-ONLINE-AUTH] Has current user: ${authService.currentUser?.fullName}');
      logDebug('[PIN-ONLINE-AUTH] Token expires at: ${_jwtAuthService.currentUser?.expiresAt}');

      // Check if token is still valid before refreshing
      if (authService.isAuthenticated && !authService.needsRefresh) {
        logDebug('[PIN-ONLINE-AUTH] Token is still valid, skipping refresh');
      } else {
        logDebug('[PIN-ONLINE-AUTH] Refreshing tokens after PIN entry...');

        // Add timeout to prevent hanging
        await authService.refreshToken().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            logWarning('[PIN-ONLINE-AUTH] Token refresh timed out, continuing anyway...');
          },
        );

        logDebug('[PIN-ONLINE-AUTH] Token refresh completed');
        logDebug('[PIN-ONLINE-AUTH] Is authenticated after refresh: ${authService.isAuthenticated}');
        logDebug('[PIN-ONLINE-AUTH] Current user after refresh: ${authService.currentUser?.fullName}');
        // Reset session start time to extend the 8-hour timeout
        _sessionService.resetSessionStartTime();
      }

      // CRITICAL: Update AuthNotifier state so router knows user is authenticated
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.checkAuthStatus();

      logDebug('Online authentication successful');
    } catch (e) {
      logWarning('Online auth had issues but continuing: $e');
      // Don't throw - allow authentication to proceed even if refresh fails
    }
  }

  JwtUser _getUserFromResult(OfflineAuthUser user) {
    return JwtUser(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      role: core_models.UserRole.fromApi(user.role),
      expiresAt: null, // Will be validated when needed
    );
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);

    try {
      await LoadingHelper.withLoading(
        ref: ref,
        message: _isOfflineMode ? 'Authenticating offline...' : 'Verifying PIN...',
        operation: () async {
          logDebug('Starting PIN verification...');
          // Add timeout to PIN verification
          final isValid = await _secureStorage.verifyPin(_pin).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              logError('PIN verification timed out');
              throw Exception('PIN verification timed out. Please try again.');
            },
          );
          logDebug('PIN verification result: $isValid');

          if (isValid) {
            logDebug('PIN is valid, proceeding with authentication...');
            HapticFeedback.mediumImpact();

            // Handle offline authentication
            if (_isOfflineMode) {
              logDebug('Handling offline authentication...');
              await _handleOfflineAuth();
              logDebug('Offline authentication completed');
            } else {
              logDebug('Handling online authentication...');
              await _handleOnlineAuth();
              logDebug('Online authentication completed');
            }

            // Start the session after successful authentication
            logDebug('Starting session...');
            _sessionService.startSession();
            logDebug('Session started');

            // CRITICAL: Wait for router to pick up auth state change
            // This prevents race condition where navigation happens before router sees auth update
            logDebug('Waiting for router to pick up auth state...');
            await Future.delayed(const Duration(milliseconds: 500));
            logDebug('Delay completed, proceeding with navigation setup');

            // Connect to PowerSync in background (non-blocking)
            final connector = ref.read(powerSyncConnectorProvider);
            if (connector != null) {
              logDebug('PowerSync connector found, connecting in background...');
              // Connect to PowerSync in background without blocking
              PowerSyncService.connect(connector: connector).then((_) {
                logDebug('PowerSync connected successfully');
                // Wait for initial sync in background (non-blocking)
                PowerSyncService.waitForInitialSync(
                  timeout: const Duration(seconds: 30),
                ).then((_) {
                  logDebug('PowerSync initial sync completed');
                }).catchError((e) {
                  logWarning('PowerSync initial sync failed (non-critical): $e');
                });
              }).catchError((e) {
                logWarning('PowerSync connection failed (non-critical): $e');
                // Don't block authentication - continue anyway
              });
            }
            logDebug('Authentication flow completed successfully');
          } else {
            logDebug('PIN is invalid, throwing exception');
            throw Exception('Invalid PIN');
          }
        },
        onError: (e) {
          logError('PIN verification error: $e');
          setState(() {
            _isVerifying = false;
            _hasError = true;
            _attempts++;
            // Use ErrorMessageMapper for consistent error messaging
            final errorString = e.toString().toLowerCase();
            if (errorString.contains('invalid pin') || errorString.contains('incorrect')) {
              _errorMessage = ErrorMessageMapper.getMessage('INVALID_CREDENTIALS');
            } else if (errorString.contains('expired') || errorString.contains('session')) {
              _errorMessage = ErrorMessageMapper.getMessage('TOKEN_EXPIRED');
            } else {
              _errorMessage = ErrorMessageMapper.getMessage('UNAUTHORIZED');
            }
            _pin = '';
          });
          HapticFeedback.heavyImpact();
        },
      );

      // Success handling - only navigate if no error
      if (mounted && !_hasError) {
        logDebug('Navigation to /home - mounted: $mounted, hasError: $_hasError');
        // Check auth state before navigating
        final authState = ref.read(authNotifierProvider);
        logDebug('Auth state before navigation: ${authState.isAuthenticated}, user: ${authState.user?.email}');

        // CRITICAL: Explicitly hide loading overlay before navigation
        LoadingHelper.hide(ref);
        logDebug('Loading overlay hidden');

        // Small delay to ensure overlay is removed
        await Future.delayed(const Duration(milliseconds: 100));

        context.go('/sync-loading');
        logDebug('Navigation command sent');
      } else {
        logWarning('Not navigating - mounted: $mounted, hasError: $_hasError');
        LoadingHelper.hide(ref);
      }

      // Check if too many attempts
      if (_attempts >= 3) {
        _showTooManyAttemptsDialog();
      }
    } catch (e) {
      logError('Unexpected error in _verifyPin: $e');
      setState(() {
        _isVerifying = false;
        _hasError = true;
        // Use ErrorMessageMapper for consistent error messaging
        _errorMessage = ErrorMessageMapper.getMessage('INTERNAL_SERVER_ERROR');
        _pin = '';
      });
    }
  }

  void _showTooManyAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Too Many Attempts'),
        content: const Text(
          'You have entered an incorrect PIN too many times. Please log in with your password.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 64),
              // Lock icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.lock,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 6-digit PIN to unlock',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (index) {
                  final isFilled = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError && isFilled
                          ? Colors.red
                          : isFilled
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                      border: Border.all(
                        color: _hasError && !isFilled
                            ? Colors.red
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_hasError) ...[
                const SizedBox(height: 16),
                Text(
                  'Incorrect PIN',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              // Use password instead link
              TextButton(
                onPressed: () => context.go('/login?use_password=true'),
                child: const Text('Use password instead'),
              ),
              const SizedBox(height: 24),
              // Keypad
              _buildKeypad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'backspace']
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key.isEmpty) {
                  return const SizedBox(width: 80, height: 64);
                }
                if (key == 'backspace') {
                  return SizedBox(
                    width: 80,
                    height: 64,
                    child: IconButton(
                      onPressed: _onBackspace,
                      icon: const Icon(LucideIcons.delete, size: 24),
                    ),
                  );
                }
                return SizedBox(
                  width: 80,
                  height: 64,
                  child: TextButton(
                    onPressed: () => _onPinEntered(key),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
