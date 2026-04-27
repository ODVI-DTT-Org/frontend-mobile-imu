// lib/services/gps/gps_capture_service.dart

import 'package:geolocator/geolocator.dart';
import '../location/enhanced_location_service.dart';

class GPSData {
  final double latitude;
  final double longitude;
  final String address;
  // Structured location fields
  final String? barangay;
  final String? municipality;
  final String? province;
  final String? region;
  final String? source;

  const GPSData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.barangay,
    this.municipality,
    this.province,
    this.region,
    this.source,
  });

  /// Create GPSData from LocationAddress
  factory GPSData.fromLocationAddress(LocationAddress locationAddress) {
    return GPSData(
      latitude: 0, // Will be set by caller
      longitude: 0, // Will be set by caller
      address: locationAddress.fullAddress,
      barangay: locationAddress.barangay,
      municipality: locationAddress.municipality,
      province: locationAddress.province,
      region: locationAddress.region,
      source: locationAddress.source,
    );
  }

  @override
  String toString() => 'GPSData(lat: $latitude, lng: $longitude, address: $address, source: $source)';

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    if (barangay != null) 'barangay': barangay,
    if (municipality != null) 'municipality': municipality,
    if (province != null) 'province': province,
    if (region != null) 'region': region,
    if (source != null) 'source': source,
  };
}

class GPSRequiredException implements Exception {
  final String message;
  final dynamic originalError;

  const GPSRequiredException(this.message, [this.originalError]);

  @override
  String toString() => 'GPSRequiredException: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

class GPSCaptureService {
  final EnhancedLocationService _locationService;

  GPSCaptureService({EnhancedLocationService? locationService})
      : _locationService = locationService ?? EnhancedLocationService();

  /// Captures current GPS location with structured address
  /// Uses EnhancedLocationService with Mapbox (online) + PSGC (offline)
  /// Throws GPSRequiredException if location cannot be obtained
  Future<GPSData> captureLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const GPSRequiredException('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const GPSRequiredException('Location permissions are denied. Please grant permission in settings.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const GPSRequiredException('Location permissions are permanently denied. Please enable in app settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final locationAddress = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return GPSData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: locationAddress.fullAddress,
        barangay: locationAddress.barangay,
        municipality: locationAddress.municipality,
        province: locationAddress.province,
        region: locationAddress.region,
        source: locationAddress.source,
      );
    } catch (e) {
      throw GPSRequiredException('Failed to capture location', e);
    }
  }
}
