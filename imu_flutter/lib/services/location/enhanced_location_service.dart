import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../location/geolocation_service.dart';
import '../../features/psgc/data/repositories/psgc_repository.dart';
import 'mapbox_geocoding_service.dart';

/// Enhanced location service with hybrid geocoding:
/// - Online: Mapbox API (street-level precision)
/// - Offline: PSGC data (municipality-level precision)
class EnhancedLocationService {
  static final EnhancedLocationService _instance = EnhancedLocationService._internal();
  factory EnhancedLocationService() => _instance;
  EnhancedLocationService._internal();

  final _geoService = GeolocationService();
  final _mapboxService = MapboxGeocodingService();
  final _connectivity = Connectivity();

  PsgcRepository? _psgcRepository;
  String? _mapboxToken;

  /// Set PSGC repository for offline location lookup
  void setPsgcRepository(PsgcRepository repository) {
    _psgcRepository = repository;
  }

  /// Set Mapbox access token for online location lookup
  void setMapboxToken(String token) {
    _mapboxToken = token;
    _mapboxService.setAccessToken(token);
    debugPrint('EnhancedLocationService: Mapbox token configured');
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any(
        (status) => status != ConnectivityResult.none,
      );
    } catch (e) {
      debugPrint('EnhancedLocationService: Connectivity check failed: $e');
      // Assume online if connectivity check fails
      return true;
    }
  }

  /// Get comprehensive address from coordinates
  ///
  /// Strategy:
  /// 1. Try native geocoding (fast, works offline but limited data)
  /// 2. If online and native incomplete, try Mapbox API (detailed, structured)
  /// 3. If offline or Mapbox fails, fallback to PSGC data (bundled, reliable)
  Future<LocationAddress> getAddressFromCoordinates(
    double latitude,
    double longitude, {
    bool preferNative = true,
  }) async {
    debugPrint('EnhancedLocationService: Getting address for ($latitude, $longitude)...');

    // Step 1: Try native geocoding first (fastest, works offline)
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

          // If native geocoding is complete enough, use it
          if (nativeComponentCount >= 3 && nativeAddress.length >= 20) {
            return LocationAddress(
              fullAddress: nativeAddress,
              source: 'Native',
            );
          }
        }
      } catch (e) {
        debugPrint('EnhancedLocationService: Native geocoding failed: $e');
      }
    }

    // Step 2: Check connectivity and try Mapbox if online
    final isOnline = await _isOnline();
    debugPrint('EnhancedLocationService: Device is ${isOnline ? 'online' : 'offline'}');

    if (isOnline && _mapboxToken != null && _mapboxToken!.isNotEmpty) {
      debugPrint('EnhancedLocationService: Trying Mapbox API...');
      try {
        final mapboxAddress = await _mapboxService.reverseGeocode(
          latitude,
          longitude,
          includeStreetDetails: true,
        );

        if (mapboxAddress != null) {
          debugPrint('EnhancedLocationService: Mapbox API succeeded');
          return mapboxAddress;
        }
      } catch (e) {
        debugPrint('EnhancedLocationService: Mapbox API failed: $e');
      }
    } else {
      debugPrint('EnhancedLocationService: Skipping Mapbox (${isOnline ? 'no token' : 'offline'})');
    }

    // Step 3: Fallback to PSGC if available
    if (_psgcRepository != null) {
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

    // Step 4: Last resort - return native address if available
    if (nativeAddress != null) {
      debugPrint('EnhancedLocationService: Using native address as last resort');
      return LocationAddress(
        fullAddress: nativeAddress,
        source: 'Native',
      );
    }

    // Step 5: Absolute fallback - return coordinates only
    debugPrint('EnhancedLocationService: All methods failed, returning coordinates');
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
    return parts.where((p) => p.isNotEmpty).join(', ');
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
  final String source; // 'Native', 'Mapbox', 'PSGC', 'Coordinates'
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
