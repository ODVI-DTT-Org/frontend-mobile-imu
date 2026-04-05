import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/map_config.dart';
import 'services/location/geolocation_service.dart';
import 'services/connectivity_service.dart';
import 'core/utils/notification_utils.dart';
import 'features/touchpoints/services/form_draft_service.dart';
import 'services/sync/powersync_service.dart';
import 'services/sync/powersync_connector.dart';
import 'services/auth/jwt_auth_service.dart';
import 'services/error_reporter_service.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No local seeding - use Digital Ocean data via PowerSync
  // Run app with splash screen
  runApp(const ProviderScope(child: IMUAppWithSplash()));
}

/// App wrapper that shows splash screen during initialization
class IMUAppWithSplash extends ConsumerStatefulWidget {
  const IMUAppWithSplash({super.key});

  @override
  ConsumerState<IMUAppWithSplash> createState() => _IMUAppWithSplashState();
}

class _IMUAppWithSplashState extends ConsumerState<IMUAppWithSplash> {
  bool _isInitialized = false;
  String _initMessage = 'Initializing...';
  String? _initSubMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _initMessage = 'Initializing storage...';
      });

      // Initialize Hive first (before any service that uses it)
      await Hive.initFlutter();
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth transition

      setState(() {
        _initMessage = 'Loading configuration...';
      });

      // Initialize configuration
      // Environment can be set via --dart-define=ENV=qa|prod at build time
      // In release mode, automatically use 'prod' environment
      // Defaults to 'dev' for local development
      const String envFromEnv = String.fromEnvironment('ENV', defaultValue: 'dev');

      // Automatically use production environment in release mode if not explicitly set
      final String env = (kReleaseMode && envFromEnv == 'dev') ? 'prod' : envFromEnv;

      await AppConfig.initialize(environment: env);
      await MapConfig.initialize(environment: env);
      await Future.delayed(const Duration(milliseconds: 300)); // Smooth transition

      setState(() {
        _initMessage = 'Setting up preferences...';
      });

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      setState(() {
        _initMessage = 'Starting services...';
      });

      // Initialize services
      await _initializeServices();
      await Future.delayed(const Duration(milliseconds: 500)); // Smooth transition

      setState(() {
        _initMessage = 'Almost ready...';
        _initSubMessage = 'Preparing your experience';
      });

      await Future.delayed(const Duration(milliseconds: 800)); // Final delay for smooth UX

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
      // Still show the app even if initialization fails
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          message: _initMessage,
          subMessage: _initSubMessage,
        ),
      );
    }

    return const IMUApp();
  }
}

Future<void> _initializeServices() async {
  // Initialize connectivity
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Initialize error reporter
  try {
    await ErrorReporterService().init();
  } catch (e) {
    debugPrint('ErrorReporter initialization error: $e');
    // Continue without error reporting - not critical for app
  }

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Initialize form draft service (now safe because Hive is initialized)
  try {
    await FormDraftService.initialize();
  } catch (e) {
    debugPrint('FormDraftService initialization error: $e');
    // Continue without form drafts - not critical for app
  }

  // Pre-warm geolocation (mobile only)
  if (!kIsWeb) {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final geoService = GeolocationService();
        final enabled = await geoService.isLocationServiceEnabled();
        if (enabled) {
          await geoService.requestPermission();
        }
      }
    } catch (e) {
      debugPrint('Geolocation init skipped: $e');
    }
  }

  // Initialize PowerSync if user is already authenticated
  await _initializePowerSyncIfNeeded();

  debugPrint('All services initialized (PowerSync initialized: ${PowerSyncService.isConnected})');
}

/// Initialize PowerSync connection if user has valid credentials
Future<void> _initializePowerSyncIfNeeded() async {
  try {
    // Initialize JWT auth to check for existing session
    final jwtAuth = JwtAuthService();
    await jwtAuth.initialize();

    if (jwtAuth.isAuthenticated) {
      debugPrint('User already authenticated, connecting to PowerSync...');

      // Create connector with config values
      final connector = IMUPowerSyncConnector(
        authService: jwtAuth,
        powersyncUrl: AppConfig.powerSyncUrl,
        apiUrl: AppConfig.postgresApiUrl,
      );

      // Connect to PowerSync with loading feedback
      debugPrint('Syncing for first time...');
      // Note: We can't use LoadingHelper here since we're not in a widget context
      // The loading is shown via the splash screen during initialization

      await PowerSyncService.connect(connector);
      debugPrint('PowerSync auto-connected on app start');
    } else {
      debugPrint('No existing session - checking for stored credentials...');

      // Check for stored credentials and attempt auto-login
      final hasStoredCreds = await jwtAuth.hasStoredCredentials();
      if (hasStoredCreds) {
        debugPrint('Found stored credentials, attempting auto-login...');
        final autoLoginSuccess = await jwtAuth.autoLogin();

        if (autoLoginSuccess && jwtAuth.isAuthenticated) {
          debugPrint('Auto-login successful, connecting to PowerSync...');

          // Create connector with config values
          final connector = IMUPowerSyncConnector(
            authService: jwtAuth,
            powersyncUrl: AppConfig.powerSyncUrl,
            apiUrl: AppConfig.postgresApiUrl,
          );

          await PowerSyncService.connect(connector);
          debugPrint('PowerSync connected after auto-login');
        } else {
          debugPrint('Auto-login failed - user will need to login manually');
        }
      } else {
        debugPrint('No stored credentials found - user will need to login');
      }
    }
  } catch (e) {
    debugPrint('PowerSync initialization skipped: $e');
    // Continue without PowerSync - will connect on login
  }
}
