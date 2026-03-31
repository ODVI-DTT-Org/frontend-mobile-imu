import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Skeleton offline auth page for OFFLINE_AUTH state.
///
/// This page will be fully implemented in Phase 6 (Offline Authentication).
/// Currently provides basic structure for offline mode indicator.
class OfflineAuthPage extends ConsumerWidget {
  const OfflineAuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: const Key('offline_auth_page'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Offline Mode',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'You are currently offline. Some features may be limited.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              // TODO: Add grace period countdown (Phase 6)
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  key: const Key('continue_offline_button'),
                  onPressed: () {
                    // TODO: Continue in offline mode (Phase 6)
                  },
                  child: const Text('Continue Offline'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
