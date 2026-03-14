import 'package:flutter/foundation.dart';

/// App flavors configuration
enum AppFlavor {
  development,
  staging,
  production,
}

/// App flavors configuration
class AppFlavors {
  static AppFlavor? _currentFlavor;

  /// Get current flavor
  static AppFlavor get flavor {
    _currentFlavor ??= AppFlavor.development;
    return _currentFlavor!;
  }

  /// Check if development
  static bool get isDevelopment => flavor == AppFlavor.development;

  /// Check if staging
  static bool get isStaging => flavor == AppFlavor.staging;

  /// Check if production
  static bool get isProduction => flavor == AppFlavor.production;

  /// Get flavor name
  static String get flavorName {
    switch (flavor) {
      case AppFlavor.development:
        return 'dev';
      case AppFlavor.staging:
        return 'staging';
      case AppFlavor.production:
        return 'prod';
    }
  }

  /// Get API base URL
  static String get apiBaseUrl {
    switch (flavor) {
      case AppFlavor.development:
        return 'http://localhost:8090';
      case AppFlavor.staging:
        return 'https://staging-api.imu.app';
      case AppFlavor.production:
        return 'https://api.imu.app';
    }
  }

  /// Initialize flavor
  static void initialize(AppFlavor flavor) {
    _currentFlavor = flavor;
    debugPrint('AppFlavors: Initialized with flavor: ${flavor.name}');
  }
}
