import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Loading overlay widget
/// Displays a full-screen overlay that blocks user interaction while loading
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool showProgress;
  final bool dismissible;

  const LoadingOverlay({
    super.key,
    this.message,
    this.showProgress = true,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !dismissible, // Block all interaction when not dismissible
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showProgress)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const SizedBox(
                    width: 24,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(height: 16),
                Text(
                  message ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
