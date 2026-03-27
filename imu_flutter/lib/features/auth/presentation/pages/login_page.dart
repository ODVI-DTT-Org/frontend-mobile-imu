import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/services/auth/auth_service.dart';
import 'package:imu_flutter/services/auth/offline_auth_service.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';
import 'package:imu_flutter/shared/utils/loading_helper.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  // Offline auth state
  final _offlineAuthService = OfflineAuthService();
  bool _canLoginOffline = false;
  Duration? _gracePeriodRemaining;

  @override
  void initState() {
    super.initState();
    _checkOfflineCapability();
  }

  Future<void> _checkOfflineCapability() async {
    final canOffline = await _offlineAuthService.canLoginOffline();
    final gracePeriod = await _offlineAuthService.getGracePeriodRemaining();
    // Check if widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _canLoginOffline = canOffline;
        _gracePeriodRemaining = gracePeriod;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticUtils.lightImpact();

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Signing in...',
      operation: () async {
        await ref.read(authNotifierProvider.notifier).login(
              _emailController.text.trim(),
              _passwordController.text,
            );
      },
      onError: (e) {
        HapticUtils.error();
      },
    );

    // Navigation is handled automatically by the router based on auth state
    // No manual navigation needed here
  }

  Future<void> _handleOfflineLogin() async {
    HapticUtils.lightImpact();

    // Navigate to PIN entry for offline authentication
    if (mounted) {
      context.go('/pin-entry?offline=true');
    }
  }

  String _formatGracePeriod(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes min';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isOnline = ref.watch(isOnlineProvider);

    // Listen to auth state changes for error handling
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(next.error!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).clearError();
                  },
                ),
              ),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Offline banner with login option
                if (!isOnline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _canLoginOffline ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _canLoginOffline ? Colors.green.shade200 : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _canLoginOffline ? Icons.lock_open : Icons.cloud_off,
                          color: _canLoginOffline ? Colors.green.shade700 : Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _canLoginOffline
                                    ? 'Offline login available!'
                                    : 'You are offline. Login requires internet connection.',
                                style: TextStyle(
                                  color: _canLoginOffline ? Colors.green.shade700 : Colors.orange.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_canLoginOffline && _gracePeriodRemaining != null)
                                Text(
                                  'Grace period: ${_formatGracePeriod(_gracePeriodRemaining!)} remaining',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_canLoginOffline)
                          ElevatedButton.icon(
                            onPressed: _handleOfflineLogin,
                            icon: const Icon(Icons.fingerprint, size: 16),
                            label: const Text('PIN Login'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Logo
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Center(
                  child: Text(
                    'Itinerary Manager - Uniformed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Please enter your details to login.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'user@example.com',
                    prefixIcon: Icon(LucideIcons.mail),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !authState.isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: '••••••••••••',
                    prefixIcon: const Icon(LucideIcons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  enabled: !authState.isLoading,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: authState.isLoading
                        ? null
                        : () => context.go('/forgot-password'),
                    child: const Text('Forgot your password?'),
                  ),
                ),
                const SizedBox(height: 16),

                // Login button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: authState.isLoading || !isOnline
                        ? null
                        : _handleLogin,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('LOGIN'),
                  ),
                ),

                // Debug info (only in development)
                if (const bool.fromEnvironment('dart.vm.product') == false) ...[
                  const SizedBox(height: 48),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Debug Info',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Test credentials:\nadmin@imu.local / Admin123!',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
