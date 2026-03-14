import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Location tracking service
class LocationTrackingService extends ChangeNotifier {
  LocationData? _currentLocation;
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  LocationData? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;

  /// Check location permission
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );

      notifyListeners();
      return _currentLocation;
    } catch (e) {
      debugPrint('LocationTrackingService: Error getting location: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) {
      throw Exception('Location permission not granted');
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentLocation = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      _isTracking = true;
      notifyListeners();
    });

    _isTracking = true;
    notifyListeners();
    debugPrint('LocationTrackingService: Started tracking');
  }

  /// Stop location tracking
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    notifyListeners();
    debugPrint('LocationTrackingService: Stopped tracking');
  }

  /// Calculate distance between two points in meters
  double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Check if within range of target location
  bool isWithinRange(LocationData location, double targetLat, double targetLng, {double maxDistanceMeters = 100}) {
    final distance = calculateDistance(
      location.latitude,
      location.longitude,
      targetLat,
      targetLng,
    );
    return distance <= maxDistanceMeters;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Provider for LocationTrackingService
final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  return LocationTrackingService();
});

/// Provider for current location
final currentLocationProvider = Provider<LocationData?>((ref) {
  final locationService = ref.watch(locationTrackingServiceProvider);
  return locationService.currentLocation;
});
