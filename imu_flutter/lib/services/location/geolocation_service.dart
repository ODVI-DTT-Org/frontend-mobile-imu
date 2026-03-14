import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Result enum for location operations
enum LocationResult {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

/// Location service for GPS capture and geofencing
class GeolocationService {
  static final GeolocationService _instance = GeolocationService._internal();
  factory GeolocationService() => _instance;
  GeolocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastKnownPosition;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permission
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationPermission.denied;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return LocationPermission.deniedForever;
    }

    return permission;
  }

  /// Get current position with detailed error handling
  Future<(Position?, LocationResult, String?)> getCurrentPositionWithResult({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return (null, LocationResult.serviceDisabled, 'GPS is disabled. Please enable location services in your device settings.');
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return (null, LocationResult.permissionDenied, 'Location permission denied. Please allow location access to capture your time-in location.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return (null, LocationResult.permissionDeniedForever, 'Location permission permanently denied. Please enable it in app settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
      );

      _lastKnownPosition = position;
      return (position, LocationResult.success, null);
    } on TimeoutException {
      return (null, LocationResult.timeout, 'Location request timed out. Please try again.');
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return (null, LocationResult.error, 'Failed to get location: ${e.toString()}');
    }
  }

  /// Get current position (backward compatible, returns null on any error)
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final (position, _, _) = await getCurrentPositionWithResult(
      accuracy: accuracy,
      timeout: timeout,
    );
    return position;
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
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
        return parts.join(', ');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Calculate distance in kilometers
  double calculateDistanceInKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return calculateDistance(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Check if a point is within a geofence
  bool isWithinGeofence({
    required double centerLat,
    required double centerLng,
    required double pointLat,
    required double pointLng,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(centerLat, centerLng, pointLat, pointLng);
    return distance <= radiusInMeters;
  }

  /// Start location stream for tracking
  Stream<Position> startLocationStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    Duration interval = const Duration(seconds: 5),
  }) {
    final permission = requestPermission();

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Stop location stream
  void stopLocationStream() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.heading,
    required this.timestamp,
    this.address,
  });

  factory LocationData.fromPosition(Position position, {String? address}) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
      address: address,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp.toIso8601String(),
    'address': address,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'],
    longitude: json['longitude'],
    altitude: json['altitude'],
    accuracy: json['accuracy'],
    speed: json['speed'],
    heading: json['heading'],
    timestamp: DateTime.parse(json['timestamp']),
    address: json['address'],
  );
}

/// Geofence model
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final GeofenceEvent event;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    this.event = GeofenceEvent.entry,
  });

  bool containsPoint(double lat, double lng) {
    final service = GeolocationService();
    return service.isWithinGeofence(
      centerLat: latitude,
      centerLng: longitude,
      pointLat: lat,
      pointLng: lng,
      radiusInMeters: radiusInMeters,
    );
  }
}

enum GeofenceEvent {
  entry,
  exit,
  dwell,
}
