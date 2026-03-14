import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration loaded from environment files
class AppConfig {
  AppConfig._();

  static late String _pocketbaseUrl;
  static late String _appName;
  static late bool _debugMode;
  static late String _logLevel;
  static String _environment = 'dev';

  /// Initialize configuration from environment file
  static Future<void> initialize({String environment = 'dev'}) async {
    _environment = environment;
    final envFile = environment == 'prod' ? '.env.prod' : '.env.dev';

    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      debugPrint('Warning: Could not load $envFile, using defaults: $e');
    }

    _pocketbaseUrl = dotenv.env['POCKETBASE_URL'] ?? 'http://localhost:8090';
    _appName = dotenv.env['APP_NAME'] ?? 'IMU';
    _debugMode = dotenv.env['DEBUG_MODE'] == 'true';
    _logLevel = dotenv.env['LOG_LEVEL'] ?? 'info';

    debugPrint('AppConfig initialized:');
    debugPrint('  Environment: $environment');
    debugPrint('  PocketBase URL: $_pocketbaseUrl');
    debugPrint('  App Name: $_appName');
    debugPrint('  Debug Mode: $_debugMode');
  }

  /// PocketBase backend URL
  static String get pocketbaseUrl => _pocketbaseUrl;

  /// Application display name
  static String get appName => _appName;

  /// Whether debug mode is enabled
  static bool get debugMode => _debugMode;

  /// Logging level (debug, info, warning, error)
  static String get logLevel => _logLevel;

  /// Current environment (dev/prod)
  static String get environment => _environment;

  /// Whether running in production environment
  static bool get isProduction => !_debugMode;

  /// Whether running in development environment
  static bool get isDevelopment => _debugMode;
}
