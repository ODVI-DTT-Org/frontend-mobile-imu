import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/location/enhanced_location_service.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';
import '../../features/psgc/data/services/psgc_asset_service.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';

/// Provider for EnhancedLocationService with PSGC integration
final enhancedLocationServiceProvider = Provider<EnhancedLocationService>((ref) {
  final service = EnhancedLocationService();

  // Inject PSGC repository for fallback location lookup
  final psgcRepository = ref.read(psgcRepositoryProvider);
  service.setPsgcRepository(psgcRepository);

  return service;
});
