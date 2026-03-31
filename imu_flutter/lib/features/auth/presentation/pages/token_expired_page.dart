import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skeleton token expired page for TOKEN_EXPIRED state.
///
/// This page will be fully implemented in Phase 5 (Token Refresh & Expiry).
/// Currently provides basic structure for token expired screen.
class TokenExpiredPage extends ConsumerWidget {
  const TokenExpiredPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const Key('token_expired_page'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.timer_off,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Session Expired',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your session has expired. Please log in again to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  key: const Key('login_again_button'),
                  onPressed: () {
                    // TODO: Navigate to login (Phase 5)
                  },
                  child: const Text('Login Again'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
