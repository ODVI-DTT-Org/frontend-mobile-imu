import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/auth/secure_storage_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../core/router/app_router.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _secureStorage = SecureStorageService();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _hasError = false;
  bool _isSaving = false;

  void _onPinEntered(String digit) {
    HapticFeedback.lightImpact();

    if (_isConfirmStep) {
      if (_confirmPin.length < 6) {
        setState(() {
          _confirmPin += digit;
          _hasError = false;
        });

        if (_confirmPin.length == 6) {
          _verifyPin();
        }
      }
    } else {
      if (_pin.length < 6) {
        setState(() {
          _pin += digit;
        });

        if (_pin.length == 6) {
          setState(() => _isConfirmStep = true);
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();

    if (_isConfirmStep) {
      if (_confirmPin.isNotEmpty) {
        setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
      }
    } else {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    }
  }

  Future<void> _verifyPin() async {
    if (_pin == _confirmPin) {
      HapticFeedback.mediumImpact();

      setState(() => _isSaving = true);

      try {
        // Get current user ID
        final userId = ref.read(currentUserIdProvider);

        // Save PIN securely (hashed)
        await _secureStorage.savePin(_pin, userId: userId);

        // NOTE: PIN state provider is disabled - router doesn't check for PIN
        // ref.read(pinStateProvider.notifier).setHasPin(true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN set successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to PIN entry so user must verify the PIN they just set
          context.go('/pin-entry');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PIN: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isSaving = false);
        }
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
        _confirmPin = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PINs do not match. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: _isConfirmStep
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () {
                  setState(() {
                    _isConfirmStep = false;
                    _confirmPin = '';
                    _hasError = false;
                  });
                },
              )
            : null,
        title: Text(_isConfirmStep ? 'Re-enter PIN' : 'Setup your 6 digit PIN'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                _isConfirmStep
                    ? 'Re-enter 6 digit PIN'
                    : 'Enter 6 digit PIN',
                textAlign: TextAlign.center,
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
                  final isFilled = index < currentPin.length;
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
                  'PINs do not match',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
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
