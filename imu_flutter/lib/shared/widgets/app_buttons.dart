import 'package:flutter/material.dart';

/// Consistent button styling library for the IMU app.
///
/// Provides standardized button variants with consistent sizing,
/// styling, and behavior across the app.
///
/// Usage:
/// ```dart
/// AppButtons.primary(
///   label: 'Submit',
///   onPressed: () => handleSubmit(),
/// );
///
/// AppButtons.secondary(
///   label: 'Cancel',
///   onPressed: () => Navigator.pop(context),
/// );
///
/// AppButtons.danger(
///   label: 'Delete',
///   onPressed: () => handleDelete(),
///   isLoading: isDeleting,
/// );
///
/// AppButtons.text(
///   label: 'Learn More',
///   onPressed: () => showHelp(),
/// );
/// ```
class AppButtons {
  /// Primary button - main action, dark background.
  ///
  /// Use for primary actions like Submit, Save, Confirm.
  static Widget primary({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    Widget? icon,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Text(label),
                    ],
                  )
                : Text(label),
      ),
    );
  }

  /// Secondary button - outlined style.
  ///
  /// Use for secondary actions like Cancel, Back, Skip.
  static Widget secondary({
    required String label,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
    Widget? icon,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }

  /// Danger button - for destructive actions.
  ///
  /// Use for dangerous actions like Delete, Remove, Discard.
  static Widget danger({
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 44,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.red.shade200,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }

  /// Text button - minimal style, no border.
  ///
  /// Use for tertiary actions like Learn More, Help, Terms.
  static Widget text({
    required String label,
    required VoidCallback? onPressed,
    Color? color,
    bool isDense = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? const Color(0xFF0F172A),
        minimumSize: isDense ? const Size(0, 32) : const Size(64, 44),
        tapTargetSize: isDense ? MaterialTapTargetSize.shrinkWrap : null,
      ),
      child: Text(label),
    );
  }

  /// Icon button - square button with icon only.
  ///
  /// Use for icon-only actions like Edit, Delete, Close.
  static Widget icon({
    required IconData iconData,
    required VoidCallback? onPressed,
    Color? color,
    String? tooltip,
  }) {
    final button = IconButton(
      icon: Icon(iconData),
      onPressed: onPressed,
      color: color ?? const Color(0xFF0F172A),
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
    );

    return tooltip != null
        ? Tooltip(
            message: tooltip,
            child: button,
          )
        : button;
  }

  /// Small button - compact size for tight spaces.
  ///
  /// Use for inline actions in tables, lists, cards.
  static Widget small({
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
              ),
            ),
    );
  }
}
