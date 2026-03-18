import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/config/app_config.dart';
import 'services/location/geolocation_service.dart';
import 'services/connectivity_service.dart';
import 'services/dev_data_seeder.dart';
import 'core/utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  await AppConfig.initialize(environment: 'dev');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize services
  await _initializeServices();

  // Seed development data if needed
  await DevDataSeeder.seedIfNeeded();

  // Run app
  runApp(const ProviderScope(child: IMUApp()));
}

Future<void> _initializeServices() async {
  // Initialize connectivity
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.init();

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

  debugPrint('All services initialized (PowerSync pending)');
}
