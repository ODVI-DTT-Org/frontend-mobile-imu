// lib/services/gps/gps_capture_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class GPSData {
  final double latitude;
  final double longitude;
  final String address;

  const GPSData({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  String toString() => 'GPSData(lat: $latitude, lng: $longitude, address: $address)';
}

class GPSRequiredException implements Exception {
  final String message;
  final dynamic originalError;

  const GPSRequiredException(this.message, [this.originalError]);

  @override
  String toString() => 'GPSRequiredException: $message${originalError != null ? ' (caused by: $originalError)' : ''}';
}

class GPSCaptureService {
  /// Captures current GPS location with address
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

      // Reverse geocode to get address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final address = _formatAddress(placemarks.first);

      return GPSData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
    } catch (e) {
      throw GPSRequiredException('Failed to capture location', e);
    }
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];

    if (placemark.street != null && placemark.street!.isNotEmpty) {
      parts.add(placemark.street!);
    }
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      parts.add(placemark.subLocality!);
    }
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      parts.add(placemark.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }
}
