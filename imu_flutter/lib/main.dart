import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'services/local_storage/hive_service.dart';
import 'services/sync/sync_service.dart';
import 'services/location/geolocation_service.dart';
import 'services/api/pocketbase_client.dart' show initializePocketBaseClient;
import 'services/connectivity_service.dart';
import 'core/utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration (load environment)
  await AppConfig.initialize(environment: 'dev');

  // Set preferred orientations (allow landscape for tablets)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  await _initializeServices();

  // Run app
  runApp(
    const ProviderScope(
      child: IMUApp(),
    ),
  );
}

/// Initialize all required services
Future<void> _initializeServices() async {
  // Initialize Hive for local storage
  final hiveService = HiveService();
  await hiveService.init();

  // Initialize PocketBase client (singleton with token restoration)
  await initializePocketBaseClient();

  // Initialize connectivity service
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Initialize sync service
  final syncService = SyncService();
  await syncService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Pre-warm geolocation service (only on mobile platforms)
  if (!kIsWeb) {
    try {
      // Platform is only available on non-web
      if (Platform.isAndroid || Platform.isIOS) {
        final geoService = GeolocationService();
        final isLocationEnabled = await geoService.isLocationServiceEnabled();
        if (isLocationEnabled) {
          try {
            await geoService.requestPermission();
          } catch (e) {
            debugPrint('Could not request location permission: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Could not initialize geolocation service: $e');
    }
  }

  debugPrint('All services initialized');
}
