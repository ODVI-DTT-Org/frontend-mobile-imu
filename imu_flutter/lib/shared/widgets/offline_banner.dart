import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/services/connectivity_service.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';
import 'package:imu_flutter/core/utils/app_notification.dart';

/// Offline status banner that appears when device is not connected
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) {
        if (status != ConnectivityStatus.offline) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: 40,
          child: Material(
            color: Colors.orange.shade700,
            child: InkWell(
              onTap: () {
                HapticUtils.lightImpact();
                // Show retry snackbar or trigger sync
                AppNotification.showNeutral(
                  context,
                  'Waiting for connection...',
                  duration: const Duration(seconds: 2),
                );
              },
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'You are offline. Some features may be limited.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Wrapper widget that shows offline banner when needed
class OfflineBannerWrapper extends ConsumerWidget {
  final Widget child;

  const OfflineBannerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child),
      ],
    );
  }
}
