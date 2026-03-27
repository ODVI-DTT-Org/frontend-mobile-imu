import 'package:flutter/foundation.dart';

/// Simple logging utility for the IMU app
/// This can be extended to use a proper logging package if needed

/// Log a debug message
void logDebug(String message) {
  debugPrint('[DEBUG] $message');
}

/// Log an info message
void logInfo(String message) {
  debugPrint('[INFO] $message');
}

/// Log a warning message with optional error object
void logWarning(String message, [Object? error, StackTrace? stackTrace]) {
  debugPrint('[WARN] $message');
  if (error != null) {
    debugPrint('  Warning: $error');
  }
  if (stackTrace != null) {
    debugPrint('  Stack: $stackTrace');
  }
}

/// Log an error message with optional error object
void logError(String message, [Object? error, StackTrace? stackTrace]) {
  debugPrint('[ERROR] $message');
  if (error != null) {
    debugPrint('  Error: $error');
  }
  if (stackTrace != null) {
    debugPrint('  Stack: $stackTrace');
  }
}
