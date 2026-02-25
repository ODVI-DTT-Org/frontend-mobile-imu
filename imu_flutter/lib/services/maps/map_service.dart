import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Map service for navigation and external map apps
class MapService {
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  /// Open Google Maps for navigation
  Future<bool> openGoogleMapsNavigation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = label != null
        ? '$latitude,$longitude($label)'
        : '$latitude,$longitude';

    final uri = Uri.parse(
      'google.navigation:q=$query&mode=d',
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fallback to web URL
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    if (await canLaunchUrl(webUri)) {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Open Apple Maps (iOS only)
  Future<bool> openAppleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    if (!Platform.isIOS) {
      return openGoogleMapsNavigation(
        latitude: latitude,
        longitude: longitude,
        label: label,
      );
    }

    final query = label != null
        ? '$latitude,$longitude($label)'
        : '$latitude,$longitude';

    final uri = Uri.parse(
      'maps://?daddr=$query&dirflg=d',
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Open Waze for navigation
  Future<bool> openWazeNavigation({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'waze://?ll=$latitude,$longitude&navigate=yes',
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fallback to web
    final webUri = Uri.parse(
      'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes',
    );

    if (await canLaunchUrl(webUri)) {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Open maps with a pin at location
  Future<bool> openMapsWithPin({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final query = label != null
        ? Uri.encodeComponent('$label@$latitude,$longitude')
        : '$latitude,$longitude';

    final uri = Uri.parse('geo:$query');

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Show route preview
  Future<bool> showRoutePreview({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng',
    );

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return false;
  }

  /// Get static map URL (for Mapbox)
  String getMapboxStaticMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 15,
    int width = 400,
    int height = 300,
    String? accessToken,
  }) {
    const style = 'mapbox/streets-v12';
    final token = accessToken ?? 'YOUR_MAPBOX_TOKEN';

    return 'https://api.mapbox.com/styles/v1/$style/static/'
        'pin-l+000($longitude,$latitude)/$longitude,$latitude,$zoom/'
        '${width}x$height@2x?access_token=$token';
  }
}

/// Map preview widget with navigation button
class MapPreviewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String? label;
  final double height;

  const MapPreviewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.label,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Map placeholder (would use Mapbox in production)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Map Preview',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                if (address != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      address!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Navigation button
          Positioned(
            right: 12,
            bottom: 12,
            child: ElevatedButton.icon(
              onPressed: () => _navigate(context),
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Navigate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose Navigation App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(context);
                MapService().openGoogleMapsNavigation(
                  latitude: latitude,
                  longitude: longitude,
                  label: label,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () {
                Navigator.pop(context);
                MapService().openWazeNavigation(
                  latitude: latitude,
                  longitude: longitude,
                );
              },
            ),
            if (Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Apple Maps'),
                onTap: () {
                  Navigator.pop(context);
                  MapService().openAppleMaps(
                    latitude: latitude,
                    longitude: longitude,
                    label: label,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
