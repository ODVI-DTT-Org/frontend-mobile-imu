import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_coordinator_provider.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/services/pin_validation_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Session locked page for SESSION_LOCKED state.
///
/// Shown when app is locked due to 15 minutes of inactivity.
/// User can unlock by entering PIN or using biometric authentication.
class SessionLockedPage extends ConsumerStatefulWidget {
  const SessionLockedPage({super.key});

  @override
  ConsumerState<SessionLockedPage> createState() => _SessionLockedPageState();
}

class _SessionLockedPageState extends ConsumerState<SessionLockedPage> {
  final _pinController = TextEditingController();
  String _currentPin = '';
  bool _isPinVisible = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onPinChanged(String pin) {
    setState(() {
      _currentPin = pin;
      _hasError = false;
      _errorMessage = '';
    });

    // Auto-submit when 6 digits entered
    if (pin.length == PinValidationService.requiredPinLength) {
      _handleUnlock();
    }
  }

  Future<void> _handleUnlock() async {
    final coordinator = ref.read(authCoordinatorProvider);

    try {
      // Transition to authenticated state (PIN validation happens in coordinator)
      await coordinator.transitionTo(
        AuthenticatingWithPinState(pin: _currentPin),
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Incorrect PIN. Please try again.';
        _currentPin = '';
        _pinController.clear();
      });
      await HapticUtils.errorNotification();
    }
  }

  void _togglePinVisibility() {
    setState(() {
      _isPinVisible = !_isPinVisible;
    });
  }

  void _handleBackspace() {
    if (_pinController.text.isNotEmpty) {
      final newText = _pinController.text.substring(0, _pinController.text.length - 1);
      _pinController.text = newText;
      _pinController.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
      _onPinChanged(newText);
    }
  }

  void _handleLogout() async {
    final coordinator = ref.read(authCoordinatorProvider);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await coordinator.transitionTo(NotAuthenticatedState());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const Key('session_locked_page'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              const Icon(
                Icons.lock_clock,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 48),

              // Title
              const Text(
                'Session Locked',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Enter your PIN to unlock',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // PIN Display
              _PinDisplay(
                pin: _currentPin,
                isVisible: _isPinVisible,
                hasError: _hasError,
              ),
              const SizedBox(height: 32),

              // Error message
              if (_hasError) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Number pad
              Expanded(
                child: _NumberPad(
                  onDigit: (digit) {
                    if (_pinController.text.length < PinValidationService.requiredPinLength) {
                      final newText = _pinController.text + digit;
                      _pinController.text = newText;
                      _pinController.selection = TextSelection.fromPosition(
                        TextPosition(offset: newText.length),
                      );
                      _onPinChanged(newText);
                    }
                  },
                  onBackspace: _handleBackspace,
                ),
              ),

              // Show/Hide toggle
              TextButton.icon(
                key: const Key('toggle_pin_visibility'),
                onPressed: _togglePinVisibility,
                icon: Icon(_isPinVisible ? Icons.visibility_off : Icons.visibility),
                label: Text(_isPinVisible ? 'Hide PIN' : 'Show PIN'),
              ),

              const SizedBox(height: 8),

              // Logout button
              TextButton.icon(
                key: const Key('logout_button'),
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display 6 PIN circles.
class _PinDisplay extends StatelessWidget {
  final String pin;
  final bool isVisible;
  final bool hasError;

  const _PinDisplay({
    required this.pin,
    required this.isVisible,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        PinValidationService.requiredPinLength,
        (index) => _PinCircle(
          isFilled: index < pin.length,
          isVisible: isVisible,
          digit: isVisible && index < pin.length ? pin[index] : null,
          hasError: hasError && index >= pin.length && pin.length > 0,
        ),
      ),
    );
  }
}

/// Individual PIN circle.
class _PinCircle extends StatelessWidget {
  final bool isFilled;
  final bool isVisible;
  final String? digit;
  final bool hasError;

  const _PinCircle({
    required this.isFilled,
    required this.isVisible,
    this.digit,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasError ? Colors.red.shade100 : Colors.grey.shade200,
        border: Border.all(
          color: hasError ? Colors.red.shade700 : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Center(
        child: isFilled
            ? isVisible
                ? Text(
                    digit!,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Icon(Icons.circle, size: 16)
            : null,
      ),
    );
  }
}

/// Number pad for PIN entry.
class _NumberPad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;

  const _NumberPad({
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((digit) => _DigitButton(digit: digit, onPressed: onDigit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((digit) => _DigitButton(digit: digit, onPressed: onDigit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((digit) => _DigitButton(digit: digit, onPressed: onDigit)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Spacer
            _DigitButton(digit: '0', onPressed: onDigit),
            _BackspaceButton(onPressed: onBackspace),
          ],
        ),
      ],
    );
  }
}

/// Individual digit button.
class _DigitButton extends StatelessWidget {
  final String digit;
  final void Function(String digit) onPressed;

  const _DigitButton({required this.digit, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        key: Key('digit_$digit'),
        onPressed: () => onPressed(digit),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Backspace button.
class _BackspaceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackspaceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        key: const Key('backspace_button'),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        child: const Icon(Icons.backspace_outlined, size: 28),
      ),
    );
  }
}
