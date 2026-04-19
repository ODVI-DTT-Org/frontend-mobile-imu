import 'package:flutter/material.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

class GpsStatusIndicator extends StatelessWidget {
  final bool isLoading;
  final GPSData? gpsData;
  final String? error;

  const GpsStatusIndicator({
    super.key,
    required this.isLoading,
    required this.gpsData,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildTile(
        context,
        icon: const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: 'Getting GPS location...',
        color: Colors.orange,
        bgColor: Colors.orange.shade50,
      );
    }

    if (gpsData != null) {
      return _buildTile(
        context,
        icon: Icon(LucideIcons.mapPin, size: 14, color: Colors.green[700]),
        label: 'GPS acquired',
        color: Colors.green,
        bgColor: Colors.green.shade50,
      );
    }

    return _buildTile(
      context,
      icon: Icon(LucideIcons.alertCircle, size: 14, color: Colors.red[700]),
      label: error ?? 'GPS unavailable — cannot submit',
      color: Colors.red,
      bgColor: Colors.red.shade50,
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required Widget icon,
    required String label,
    required MaterialColor color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color.shade800),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
