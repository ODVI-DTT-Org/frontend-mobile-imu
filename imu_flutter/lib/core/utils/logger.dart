import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Simple logging utility for the IMU app
/// In production, debug and info logs are suppressed to reduce noise
/// Warnings and errors are always logged

/// Log a debug message (only in debug mode)
void logDebug(String message) {
  if (AppConfig.debugMode) {
    debugPrint('[DEBUG] $message');
  }
}

/// Log an info message (only in debug mode)
void logInfo(String message) {
  if (AppConfig.debugMode) {
    debugPrint('[INFO] $message');
  }
}

/// Log a warning message with optional error object (always logged)
void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
  debugPrint('[WARN] $message');
  if (error != null) {
    debugPrint('  Warning: $error');
  }
  if (stackTrace != null) {
    debugPrint('  Stack: $stackTrace');
  }
}

/// Log an error message with optional error object (always logged)
void logError(String message, [Object? error, StackTrace? stackTrace]) {
  debugPrint('[ERROR] $message');
  if (error != null) {
    debugPrint('  Error: $error');
  }
  if (stackTrace != null) {
    debugPrint('  Stack: $stackTrace');
  }
}
