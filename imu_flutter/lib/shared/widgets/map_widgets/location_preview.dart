import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/maps/map_service.dart';

/// Compact location preview widget with navigation button
class LocationPreviewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String? label;
  final double height;
  final bool showNavigation;

  const LocationPreviewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
    this.label,
    this.height = 200,
    this.showNavigation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          // Static map placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.mapPin,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Location Preview',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
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

          // Coordinates display
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),

          // Navigation button
          if (showNavigation)
            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: () => _showNavigationOptions(context),
                icon: const Icon(LucideIcons.navigation, size: 18),
                label: const Text('Navigate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNavigationOptions(BuildContext context) {
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

/// Small location display widget for lists
class LocationChip extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback? onTap;

  const LocationChip({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distance display widget
class DistanceDisplay extends StatelessWidget {
  final double distanceKm;
  final String? label;

  const DistanceDisplay({
    super.key,
    required this.distanceKm,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    String distanceText;
    if (distanceKm < 1.0) {
      distanceText = '${(distanceKm * 1000).toInt()} m';
    } else {
      distanceText = '${distanceKm.toStringAsFixed(1)} km';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          LucideIcons.navigation,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label != null ? '$label: $distanceText' : distanceText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
