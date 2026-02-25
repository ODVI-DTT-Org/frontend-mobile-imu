import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/local_storage/hive_service.dart';
import 'services/sync/sync_service.dart';
import 'services/location/geolocation_service.dart';
import 'core/utils/notification_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize sync service
  final syncService = SyncService();
  await syncService.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Pre-warm geolocation service
  final geoService = GeolocationService();
  final isLocationEnabled = await geoService.isLocationServiceEnabled();
  if (isLocationEnabled) {
    await geoService.requestPermission();
  }

  debugPrint('All services initialized');
}
