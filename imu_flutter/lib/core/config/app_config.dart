import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AWS S3 configuration loaded from environment variables
class AwsConfig {
  AwsConfig._();

  static String get accessKeyId =>
    const String.fromEnvironment('AWS_ACCESS_KEY_ID', defaultValue: '');

  static String get secretAccessKey =>
    const String.fromEnvironment('AWS_SECRET_ACCESS_KEY', defaultValue: '');

  static String get region =>
    const String.fromEnvironment('AWS_REGION', defaultValue: 'ap-southeast-1');

  static String get bucket =>
    const String.fromEnvironment('AWS_S3_BUCKET', defaultValue: '');

  static bool get isConfigured =>
    accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty && bucket.isNotEmpty;
}

/// Application configuration for PowerSync + PostgreSQL
class AppConfig {
  AppConfig._();

  // PowerSync
  static late String _powerSyncUrl;

  // PostgreSQL API
  static late String _postgresApiUrl;

  // API Timeouts
  static const int _apiConnectTimeout = 15000; // 15 seconds
  static const int _apiReceiveTimeout = 15000; // 15 seconds
  static const int _apiTimeout = 30000; // 30 seconds

  // JWT Auth
  static late String _jwtSecret;
  static late int _jwtExpiryHours;

  // General
  static late String _appName;
  static late bool _debugMode;
  static late String _logLevel;
  static String _environment = 'dev';

  /// Initialize configuration from environment file
  static Future<void> initialize({String environment = 'dev'}) async {
    _environment = environment;
    final envFile = switch (environment) {
      'prod' => '.env.prod',
      'qa' => '.env.qa',
      _ => '.env.dev',
    };

    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      debugPrint('Warning: Could not load $envFile: $e');
    }

    // On web, use production API directly since .env files don't work
    // On mobile, try to load from .env file
    if (kIsWeb) {
      _postgresApiUrl = 'https://imu-api.cfbtools.app/api';
      _powerSyncUrl = dotenv.env['POWERSYNC_URL'] ?? '';
      _jwtSecret = dotenv.env['JWT_SECRET'] ?? 'dev-secret';
      _jwtExpiryHours = 24;
      _appName = 'IMU Web';
      _debugMode = false;
      _logLevel = 'info';
    } else {
      _powerSyncUrl = dotenv.env['POWERSYNC_URL'] ?? '';
      _postgresApiUrl = dotenv.env['POSTGRES_API_URL'] ?? 'https://imu-api.cfbtools.app/api';
      _jwtSecret = dotenv.env['JWT_SECRET'] ?? 'dev-secret';
      _jwtExpiryHours = int.tryParse(dotenv.env['JWT_EXPIRY_HOURS'] ?? '24') ?? 24;
      _appName = dotenv.env['APP_NAME'] ?? 'IMU';
      _debugMode = dotenv.env['DEBUG_MODE'] == 'true';
      _logLevel = dotenv.env['LOG_LEVEL'] ?? 'info';
    }

    debugPrint('AppConfig initialized:');
    debugPrint('  Environment: $environment');
    debugPrint('  Platform: ${kIsWeb ? 'web' : 'mobile'}');
    debugPrint('  PowerSync URL: $_powerSyncUrl');
    debugPrint('  PostgreSQL API: $_postgresApiUrl');
  }

  // Getters

  /// PowerSync instance URL
  static String get powerSyncUrl => _powerSyncUrl;

  /// PostgreSQL API endpoint URL
  static String get postgresApiUrl => _postgresApiUrl;

  /// API base URL (alias for postgresApiUrl)
  static String get apiBaseUrl => _postgresApiUrl;

  /// API connect timeout in milliseconds
  static int get apiConnectTimeout => _apiConnectTimeout;

  /// API receive timeout in milliseconds
  static int get apiReceiveTimeout => _apiReceiveTimeout;

  /// API timeout in milliseconds
  static int get apiTimeout => _apiTimeout;

  /// Whether detailed logging is enabled
  static bool get enableLogging => _debugMode;

  /// JWT secret key for authentication
  static String get jwtSecret => _jwtSecret;

  /// JWT token expiry duration in hours
  static int get jwtExpiryHours => _jwtExpiryHours;

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
