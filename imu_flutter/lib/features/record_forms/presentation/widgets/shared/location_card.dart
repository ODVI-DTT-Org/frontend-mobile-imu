import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:imu_flutter/services/location/enhanced_location_provider.dart';

class LocationData {
  final double lat;
  final double lng;
  final String address;

  const LocationData({
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  bool operator ==(Object other) =>
      other is LocationData && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);
}

typedef LocationFetcher = Future<LocationData?> Function();

enum _GpsStatus { acquiring, acquired, failed }

Future<LocationData?> _enhancedFetch(WidgetRef ref) async {
  try {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final service = ref.read(enhancedLocationServiceProvider);
    final addr = await service.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );
    return LocationData(
      lat: position.latitude,
      lng: position.longitude,
      address: addr.fullAddress,
    );
  } catch (_) {
    return null;
  }
}

class LocationCard extends HookConsumerWidget {
  final void Function(LocationData) onAcquired;
  final VoidCallback onFailed;
  final bool showError;
  final LocationFetcher? locationFetcher;

  const LocationCard({
    super.key,
    required this.onAcquired,
    required this.onFailed,
    this.showError = false,
    this.locationFetcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = useState(_GpsStatus.acquiring);
    final location = useState<LocationData?>(null);

    useEffect(() {
      final fetch = locationFetcher ?? () => _enhancedFetch(ref);
      bool mounted = true;

      fetch().then((data) {
        if (!mounted) return; // Check if widget is still mounted

        if (data != null) {
          location.value = data;
          status.value = _GpsStatus.acquired;
          onAcquired(data);
        } else {
          status.value = _GpsStatus.failed;
          onFailed();
        }
      });

      return () {
        mounted = false; // Cleanup: mark as unmounted
      };
    }, const [],);

    return SectionCard(
      title: 'LOCATION',
      child: _buildContent(status.value, location.value),
    );
  }

  Widget _buildContent(_GpsStatus gpsStatus, LocationData? data) {
    switch (gpsStatus) {
      case _GpsStatus.acquiring:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'Acquiring location...',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],),
        );
      case _GpsStatus.acquired:
        final loc = data!;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 18, color: Color(0xFF22C55E)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.lat.toStringAsFixed(4)}°N, ${loc.lng.toStringAsFixed(4)}°E',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      loc.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _GpsStatus.failed:
        return Container(
          decoration: BoxDecoration(
            color: showError
                ? const Color(0xFFFEE2E2)
                : const Color(0xFFFFF7F7),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(children: [
                Icon(Icons.location_off, size: 18, color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                Text(
                  'GPS Unavailable',
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],),
              const SizedBox(height: 4),
              const Text(
                'Location access is required',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: openAppSettings,
                child: const Text(
                  'Enable Location Settings',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

/// Shared card wrapper used by all section card widgets.
class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
