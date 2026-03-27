import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

/// Utility class for showing/hiding loading overlay
/// This provides a global loading state that can be triggered from anywhere
///
/// Usage:
/// ```dart
/// // Show loading with message
/// LoadingHelper.show(ref, message: 'Saving...');
///
/// // Hide loading
/// LoadingHelper.hide(ref);
///
/// // Execute async operation with loading (recommended)
/// final result = await LoadingHelper.withLoading(
///   ref: ref,
///   message: 'Loading data...',
///   operation: () async {
///     return await fetchData();
///   },
/// );
///
/// // Execute with custom error handling
/// await LoadingHelper.withLoading(
///   ref: ref,
///   message: 'Saving...',
///   operation: () async => await saveData(),
///   onError: (e) {
///     // Custom error handling
///     showSnackBar('Error: $e');
///   },
/// );
/// ```
class LoadingHelper {
  /// Show loading overlay with optional message
  /// If message is null, shows default "Loading..." text
  static void show(WidgetRef ref, {String? message}) {
    ref.read(loadingMessageProvider.notifier).state = message;
    ref.read(isLoadingOverlayVisibleProvider.notifier).state = true;
    debugPrint('🔄 Loading shown: ${message ?? "Loading..."}');
  }

  /// Hide loading overlay
  static void hide(WidgetRef ref) {
    ref.read(isLoadingOverlayVisibleProvider.notifier).state = false;
    ref.read(loadingMessageProvider.notifier).state = null;
    debugPrint('✅ Loading hidden');
  }

  /// Update loading message without hiding the overlay
  static void updateMessage(WidgetRef ref, String message) {
    ref.read(loadingMessageProvider.notifier).state = message;
    debugPrint('🔄 Loading message updated: $message');
  }

  /// Check if loading is currently visible
  static bool isLoading(WidgetRef ref) {
    return ref.read(isLoadingOverlayVisibleProvider);
  }

  /// Execute async operation with loading overlay
  /// Shows loading before operation and hides after completion
  ///
  /// Automatically handles:
  /// - Showing loading before operation
  /// - Hiding loading after completion (success or error)
  /// - Error rethrowing for caller to handle
  static Future<T?> withLoading<T>({
    required WidgetRef ref,
    required Future<T> Function() operation,
    String? message,
    bool showError = true,
    Function(Object)? onError,
  }) async {
    try {
      show(ref, message: message);
      final result = await operation();
      hide(ref);
      return result;
    } catch (e) {
      hide(ref);
      if (showError || onError != null) {
        debugPrint('❌ Error in withLoading: $e');
        onError?.call(e);
      }
      rethrow;
    }
  }

  /// Execute multiple async operations with a single loading overlay
  /// Useful for batch operations
  static Future<void> withLoadingBatch({
    required WidgetRef ref,
    required String message,
    required List<Future<void> Function()> operations,
    bool showError = true,
  }) async {
    await withLoading(
      ref: ref,
      message: message,
      operation: () async {
        for (final op in operations) {
          await op();
        }
      },
      showError: showError,
    );
  }

  /// Execute operation with progress tracking
  /// Updates loading message as progress changes
  static Future<T?> withLoadingProgress<T>({
    required WidgetRef ref,
    required String baseMessage,
    required Future<T> Function(Function(String) updateProgress) operation,
  }) async {
    try {
      show(ref, message: baseMessage);
      final result = await operation((progress) {
        updateMessage(ref, '$baseMessage\n$progress');
      });
      hide(ref);
      return result;
    } catch (e) {
      hide(ref);
      debugPrint('❌ Error in withLoadingProgress: $e');
      rethrow;
    }
  }

  /// Execute operation with timeout
  /// Shows loading and automatically cancels if operation takes too long
  static Future<T?> withLoadingTimeout<T>({
    required WidgetRef ref,
    required Future<T> Function() operation,
    required String message,
    required Duration timeout,
    String timeoutMessage = 'Operation timed out. Please try again.',
  }) async {
    try {
      show(ref, message: message);
      final result = await operation().timeout(
        timeout,
        onTimeout: () {
          throw TimeoutException(timeoutMessage, timeout);
        },
      );
      hide(ref);
      return result;
    } catch (e) {
      hide(ref);
      debugPrint('❌ Error in withLoadingTimeout: $e');
      rethrow;
    }
  }
}
