import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/map_config.dart';

/// Map marker widget for individual clients
class ClientMapMarkerWidget extends StatelessWidget {
  final String clientId;
  final String clientName;
  final LatLng position;
  final TouchpointStatus status;
  final int completedTouchpoints;
  final VoidCallback? onTap;
  final bool isSelected;

  const ClientMapMarkerWidget({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.position,
    required this.status,
    required this.completedTouchpoints,
    this.onTap,
    this.isSelected = false,
  });

  /// Create a Google Maps Marker from this widget's data
  Marker toGoogleMapsMarker() {
    return Marker(
      markerId: MarkerId(clientId),
      position: position,
      infoWindow: InfoWindow(
        title: clientName,
        snippet: '$completedTouchpoints/7 Touchpoints',
        onTap: onTap,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        _getMarkerHue(status),
      ),
      onTap: onTap,
    );
  }

  /// Get marker color based on touchpoint status
  double _getMarkerHue(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.completed:
        return BitmapDescriptor.hueGreen;
      case TouchpointStatus.inProgress:
        return BitmapDescriptor.hueOrange;
      case TouchpointStatus.none:
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is for custom marker rendering if needed
    return Container(
      decoration: BoxDecoration(
        color: Color(status.color),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.white,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForStatus(status),
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
              '$completedTouchpoints/7',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForStatus(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.completed:
        return Icons.check_circle;
      case TouchpointStatus.inProgress:
        return Icons.pending;
      case TouchpointStatus.none:
        return Icons.radio_button_unchecked;
    }
  }
}

/// Cluster marker for grouped clients
class ClusterMarkerWidget extends StatelessWidget {
  final int count;
  final LatLng position;
  final VoidCallback? onTap;

  const ClusterMarkerWidget({
    super.key,
    required this.count,
    required this.position,
    this.onTap,
  });

  /// Create a Google Maps Marker for this cluster
  Marker toGoogleMapsMarker() {
    return Marker(
      markerId: MarkerId('cluster_${position.latitude}_${position.longitude}'),
      position: position,
      infoWindow: InfoWindow(
        title: '$count Clients',
        snippet: 'Tap to view',
        onTap: onTap,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
