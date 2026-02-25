import 'package:flutter/services.dart';

/// Haptic feedback utilities for the IMU app
class HapticUtils {
  HapticUtils._();

  /// Light impact - for button taps, selections
  static Future<void> lightImpact() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact - for successful actions, confirmations
  static Future<void> mediumImpact() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact - for destructive actions, warnings
  static Future<void> heavyImpact() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection click - for tab changes, slider movements
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Success notification - for completed operations
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  /// Warning notification - for warnings
  static Future<void> warning() async {
    await HapticFeedback.heavyImpact();
  }

  /// Error notification - for errors
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Double tap feedback
  static Future<void> doubleTap() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Pattern feedback for special actions
  static Future<void> pattern(List<Duration> delays) async {
    for (final delay in delays) {
      await HapticFeedback.lightImpact();
      await Future.delayed(delay);
    }
  }

  /// Swipe action feedback
  static Future<void> swipe() async {
    await HapticFeedback.mediumImpact();
  }

  /// Delete action feedback
  static Future<void> delete() async {
    await HapticFeedback.heavyImpact();
  }

  /// Toggle feedback
  static Future<void> toggle() async {
    await HapticFeedback.selectionClick();
  }

  /// Pull to refresh feedback
  static Future<void> pullToRefresh() async {
    await HapticFeedback.mediumImpact();
  }
}

/// Haptic feedback types for different UI events
enum HapticType {
  light,
  medium,
  heavy,
  selection,
  success,
  warning,
  error,
  toggle,
  delete,
}

/// Extension to trigger haptic easily
extension HapticExtension on HapticType {
  Future<void> trigger() async {
    switch (this) {
      case HapticType.light:
        await HapticUtils.lightImpact();
        break;
      case HapticType.medium:
        await HapticUtils.mediumImpact();
        break;
      case HapticType.heavy:
        await HapticUtils.heavyImpact();
        break;
      case HapticType.selection:
        await HapticUtils.selectionClick();
        break;
      case HapticType.success:
        await HapticUtils.success();
        break;
      case HapticType.warning:
        await HapticUtils.warning();
        break;
      case HapticType.error:
        await HapticUtils.error();
        break;
      case HapticType.toggle:
        await HapticUtils.toggle();
        break;
      case HapticType.delete:
        await HapticUtils.delete();
        break;
    }
  }
}

/// Mixin for widgets that need haptic feedback
mixin HapticFeedbackMixin {
  /// Trigger haptic on tap
  Future<void> hapticTap() async {
    await HapticUtils.lightImpact();
  }

  /// Trigger haptic on success
  Future<void> hapticSuccess() async {
    await HapticUtils.success();
  }

  /// Trigger haptic on error
  Future<void> hapticError() async {
    await HapticUtils.error();
  }

  /// Trigger haptic on delete
  Future<void> hapticDelete() async {
    await HapticUtils.delete();
  }
}
