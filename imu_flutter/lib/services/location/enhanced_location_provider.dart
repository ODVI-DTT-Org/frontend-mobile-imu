import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/location/enhanced_location_service.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';
import '../../core/config/map_config.dart';

/// Provider for EnhancedLocationService with Mapbox + PSGC integration
final enhancedLocationServiceProvider = Provider<EnhancedLocationService>((ref) {
  final service = EnhancedLocationService();

  // Configure Mapbox token from MapConfig
  if (MapConfig.isConfigured) {
    service.setMapboxToken(MapConfig.mapboxAccessToken);
  }

  // Inject PSGC repository for offline fallback
  final psgcRepository = ref.read(psgcRepositoryProvider);
  service.setPsgcRepository(psgcRepository);

  return service;
});
