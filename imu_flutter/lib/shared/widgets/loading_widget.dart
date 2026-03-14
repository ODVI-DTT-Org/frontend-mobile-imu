import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Loading overlay widget
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool showProgress;

  const LoadingOverlay({
    super.key,
    this.message,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const CircularProgressIndicator()
            else
              const SizedBox(
                width: 24,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            const SizedBox(height: 16),
            Text(
              message ?? 'Loading...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading button widget
class LoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const LoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(
              LucideIcons.loader2,
              size: 20,
              color: Colors.white,
            ),
      label: Text(
        isLoading ? 'Loading...' : label,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
