// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

void logDebug(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

void logInfo(String message) {
  assert(() {
    debugPrint('[INFO] $message');
    return true;
  }());
}

void logError(String message, [Object? error]) {
  assert(() {
    debugPrint('[ERROR] $message${error != null ? ' - $error' : ''}');
    return true;
  }());
}