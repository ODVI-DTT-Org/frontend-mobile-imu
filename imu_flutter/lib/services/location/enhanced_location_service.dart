import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../location/geolocation_service.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';

/// Enhanced location service with PSGC fallback for Philippine locations
class EnhancedLocationService {
  static final EnhancedLocationService _instance = EnhancedLocationService._internal();
  factory EnhancedLocationService() => _instance;
  EnhancedLocationService._internal();

  final _geoService = GeolocationService();
  PsgcRepository? _psgcRepository;

  /// Set PSGC repository for fallback location lookup
  void setPsgcRepository(PsgcRepository repository) {
    _psgcRepository = repository;
  }

  /// Get comprehensive address from coordinates
  /// Uses native geocoding first, then falls back to PSGC data
  Future<LocationAddress> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    bool preferNative = true,
  }) async {
    debugPrint('EnhancedLocationService: Getting address for ($latitude, $longitude)...');

    // Try native geocoding first (more accurate for street-level)
    String? nativeAddress;
    int nativeComponentCount = 0;

    if (preferNative) {
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[
            if (place.street != null && place.street!.isNotEmpty) place.street!,
            if (place.subLocality != null && place.subLocality!.isNotEmpty)
              place.subLocality!,
            if (place.locality != null && place.locality!.isNotEmpty)
              place.locality!,
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty)
              place.administrativeArea!,
            if (place.country != null && place.country!.isNotEmpty) place.country!,
          ];
          nativeAddress = parts.join(', ');
          nativeComponentCount = parts.where((p) => p.isNotEmpty).length;
          debugPrint('EnhancedLocationService: Native geocoding returned "$nativeAddress" ($nativeComponentCount components)');
        }
      } catch (e) {
        debugPrint('EnhancedLocationService: Native geocoding failed: $e');
      }
    }

    // Fallback to PSGC if native geocoding returns incomplete data (< 3 components)
    if (_psgcRepository != null &&
        (nativeAddress == null ||
            nativeComponentCount < 3 ||
            nativeAddress.length < 15)) {
      debugPrint('EnhancedLocationService: Using PSGC fallback...');
      try {
        final nearestMunicipality =
            await _psgcRepository!.findNearestMunicipality(latitude, longitude);

        if (nearestMunicipality != null) {
          final psgcAddress = _formatPsgcAddress(nearestMunicipality);
          debugPrint('EnhancedLocationService: PSGC returned "$psgcAddress"');

          return LocationAddress(
            fullAddress: psgcAddress,
            street: null,
            barangay: nearestMunicipality.barangay,
            municipality: nearestMunicipality.municipality,
            province: nearestMunicipality.province,
            region: nearestMunicipality.region,
            country: 'Philippines',
            source: 'PSGC',
            municipalityKind: nearestMunicipality.municipalityKind,
          );
        }
      } catch (e) {
        debugPrint('EnhancedLocationService: PSGC fallback failed: $e');
      }
    }

    // Return native address if available, even if incomplete
    if (nativeAddress != null) {
      return LocationAddress(
        fullAddress: nativeAddress,
        source: 'Native',
      );
    }

    // Last resort: return GPS coordinates only
    return LocationAddress(
      fullAddress: '$latitude, $longitude',
      source: 'Coordinates',
    );
  }

  /// Format PSGC barangay data into a readable address
  String _formatPsgcAddress(dynamic barangay) {
    final parts = <String>[
      barangay.barangay,
      barangay.municipality,
      barangay.province,
      barangay.region,
      'Philippines',
    ];
    return parts.where((p) => p != null && p.isNotEmpty).join(', ');
  }

  /// Get current position with comprehensive error handling (delegates to GeolocationService)
  Future<(Position?, LocationResult, String?)> getCurrentPositionWithResult({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _geoService.getCurrentPositionWithResult(
      accuracy: accuracy,
      timeout: timeout,
    );
  }

  /// Get current position (backward compatible, delegates to GeolocationService)
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return _geoService.getCurrentPosition(
      accuracy: accuracy,
      timeout: timeout,
    );
  }

  /// Calculate distance between two points in meters (delegates to GeolocationService)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return _geoService.calculateDistance(startLat, startLng, endLat, endLng);
  }

  /// Calculate distance in kilometers (delegates to GeolocationService)
  double calculateDistanceInKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return _geoService.calculateDistanceInKm(startLat, startLng, endLat, endLng);
  }
}

/// Comprehensive location address model
class LocationAddress {
  final String fullAddress;
  final String? street;
  final String? barangay;
  final String? municipality;
  final String? province;
  final String? region;
  final String? country;
  final String source; // 'Native', 'PSGC', 'Coordinates'
  final String? municipalityKind;

  LocationAddress({
    required this.fullAddress,
    this.street,
    this.barangay,
    this.municipality,
    this.province,
    this.region,
    this.country,
    required this.source,
    this.municipalityKind,
  });

  /// Get a formatted short address (municipality, province)
  String get shortAddress {
    final parts = [municipality, province].whereType<String>();
    if (parts.isEmpty) return fullAddress;
    return parts.join(', ');
  }

  /// Get a formatted medium address (barangay, municipality, province)
  String get mediumAddress {
    final parts = [barangay, municipality, province].whereType<String>();
    if (parts.isEmpty) return fullAddress;
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
    'fullAddress': fullAddress,
    'street': street,
    'barangay': barangay,
    'municipality': municipality,
    'province': province,
    'region': region,
    'country': country,
    'source': source,
    'municipalityKind': municipalityKind,
  };

  @override
  String toString() => fullAddress;
}
