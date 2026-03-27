import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// GPS Location tracking service with debug capabilities
class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  final List<LocationRecord> _locationHistory = [];
  LocationAccuracy _currentAccuracy = LocationAccuracy.high;

  // Debug info
  int _trackingSessionCount = 0;
  DateTime? _trackingStartTime;
  double _totalDistanceTracked = 0;
  Position? _lastPosition;

  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  List<LocationRecord> get locationHistory => List.unmodifiable(_locationHistory);
  int get locationCount => _locationHistory.length;
  int get trackingSessionCount => _trackingSessionCount;
  DateTime? get trackingStartTime => _trackingStartTime;
  double get totalDistanceTracked => _totalDistanceTracked;
  LocationAccuracy get currentAccuracy => _currentAccuracy;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('LocationService: Getting current position...');
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('LocationService: No location permission');
        return null;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location service disabled');
        return null;
      }

      debugPrint('LocationService: Fetching GPS location...');
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: _currentAccuracy,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint('LocationService: Got position - Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}');
      notifyListeners();
      return _currentPosition;
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
    int intervalSeconds = 5,
  }) async {
    if (_isTracking) {
      debugPrint('LocationService: Already tracking');
      return true;
    }

    try {
      debugPrint('LocationService: Starting location tracking...');
      final hasPermission = await _checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('LocationService: No location permission for tracking');
        return false;
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location service disabled for tracking');
        return false;
      }

      _currentAccuracy = accuracy;
      _isTracking = true;
      _trackingStartTime = DateTime.now();
      _trackingSessionCount++;
      _totalDistanceTracked = 0;
      _lastPosition = null;

      debugPrint('LocationService: Getting initial position...');
      // Get initial position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
      );

      if (_currentPosition != null) {
        _lastPosition = _currentPosition;
        _addLocationRecord(_currentPosition!, 'Initial');
        debugPrint('LocationService: Initial position - Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}');
      }

      // Start position stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      debugPrint('LocationService: Starting position stream...');
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handlePositionUpdate(position);
        },
        onError: (error) {
          debugPrint('LocationService: Position stream error: $error');
          _isTracking = false;
          notifyListeners();
        },
      );

      debugPrint('LocationService: Location tracking started');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('LocationService: Error starting tracking: $e');
      _isTracking = false;
      notifyListeners();
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;

    notifyListeners();
  }

  /// Handle position updates from stream
  void _handlePositionUpdate(Position position) {
    _currentPosition = position;

    // Calculate distance from last position
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      _totalDistanceTracked += distance;
    }

    _lastPosition = position;

    // Add to history (limit to 1000 records to prevent memory issues)
    _addLocationRecord(position, 'Update');

    notifyListeners();
  }

  /// Add location record to history
  void _addLocationRecord(Position position, String source) {
    _locationHistory.add(LocationRecord(
      timestamp: DateTime.now(),
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      heading: position.heading,
      source: source,
    ));

    // Keep only last 1000 records
    if (_locationHistory.length > 1000) {
      _locationHistory.removeAt(0);
    }
  }

  /// Check and request permission
  Future<bool> _checkAndRequestPermission() async {
    var permission = await checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Clear location history
  void clearHistory() {
    _locationHistory.clear();
    notifyListeners();
  }

  /// Get location stats for debug
  Map<String, dynamic> getDebugStats() {
    return {
      'isTracking': _isTracking,
      'trackingSessionCount': _trackingSessionCount,
      'trackingStartTime': _trackingStartTime?.toIso8601String(),
      'trackingDuration': _trackingStartTime != null
          ? DateTime.now().difference(_trackingStartTime!).inSeconds
          : 0,
      'locationCount': _locationHistory.length,
      'totalDistanceMeters': _totalDistanceTracked,
      'totalDistanceKm': _totalDistanceTracked / 1000,
      'currentPosition': _currentPosition != null
          ? {
              'latitude': _currentPosition!.latitude,
              'longitude': _currentPosition!.longitude,
              'altitude': _currentPosition!.altitude,
              'accuracy': _currentPosition!.accuracy,
              'speed': _currentPosition!.speed,
              'heading': _currentPosition!.heading,
            }
          : null,
      'accuracy': _currentAccuracy.name,
    };
  }

  /// Export location history as JSON
  List<Map<String, dynamic>> exportHistory() {
    return _locationHistory.map((record) => record.toJson()).toList();
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Location record for history tracking
class LocationRecord {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final double speedAccuracy;
  final double heading;
  final String source;

  LocationRecord({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.speedAccuracy,
    required this.heading,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
      'heading': heading,
      'source': source,
    };
  }

  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      accuracy: json['accuracy'],
      speed: json['speed'],
      speedAccuracy: json['speedAccuracy'],
      heading: json['heading'],
      source: json['source'],
    );
  }
}
