import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

void logDebug(String message) {
  if (AppConfig.debugMode) {
    debugPrint('[DEBUG] $message');
  }
}

void logInfo(String message) {
  debugPrint('[INFO] $message');
}

void logWarning(String message) {
  debugPrint('[WARN] $message');
}

void logError(String message, [dynamic error]) {
  debugPrint('[ERROR] $message ${error ?? ''}');
}
