import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/location/geolocation_service.dart';
import '../../../../services/media/camera_service.dart';
import '../../data/models/my_day_client.dart';
import 'touchpoint_selector.dart';
import 'visit_form.dart';

/// Bottom sheet for Time In, Selfie, Touchpoint selection, and Visit form
class TimeInBottomSheet extends StatefulWidget {
  final MyDayClient client;
  final Function(bool) onTimeInToggle;
  final Function(String?) onSelfieCapture;
  final Function(int) onTouchpointSelected;
  final Function(Map<String, dynamic>) onFormSubmit;

  const TimeInBottomSheet({
    super.key,
    required this.client,
    required this.onTimeInToggle,
    required this.onSelfieCapture,
    required this.onTouchpointSelected,
    required this.onFormSubmit,
  });

  static Future<void> show({
    required BuildContext context,
    required MyDayClient client,
    required Function(bool) onTimeInToggle,
    required Function(String?) onSelfieCapture,
    required Function(int) onTouchpointSelected,
    required Function(Map<String, dynamic>) onFormSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => TimeInBottomSheet(
          client: client,
          onTimeInToggle: onTimeInToggle,
          onSelfieCapture: onSelfieCapture,
          onTouchpointSelected: onTouchpointSelected,
          onFormSubmit: onFormSubmit,
        ),
      ),
    );
  }

  @override
  State<TimeInBottomSheet> createState() => _TimeInBottomSheetState();
}

class _TimeInBottomSheetState extends State<TimeInBottomSheet> {
  final GeolocationService _geoService = GeolocationService();
  final CameraService _cameraService = CameraService();

  int _selectedTouchpoint = 1;
  bool _isTimeIn = false;
  bool _isLoadingTimeIn = false;
  String? _timeInAddress;
  String? _timeInTimestamp;
  String? _selfiePath;
  String? _timeInError;

  @override
  void initState() {
    super.initState();
    _selectedTouchpoint = widget.client.touchpointNumber > 0
        ? widget.client.touchpointNumber
        : 1;
    _isTimeIn = widget.client.isTimeIn;
  }

  Future<void> _handleTimeIn() async {
    HapticUtils.lightImpact();
    setState(() {
      _isLoadingTimeIn = true;
      _timeInError = null;
    });

    try {
      // Get current position with detailed error handling
      final (position, result, errorMessage) = await _geoService.getCurrentPositionWithResult();

      if (position == null) {
        setState(() {
          _isLoadingTimeIn = false;
          _timeInError = errorMessage ?? 'Unable to get location';
        });
        HapticUtils.error();

        // Show action dialog for permission/service issues
        if (result == LocationResult.permissionDeniedForever ||
            result == LocationResult.serviceDisabled) {
          _showLocationActionDialog(result);
        }
        return;
      }

      // Get address from coordinates
      final address = await _geoService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final timestamp = DateTime.now();
      final formattedTime = DateFormat('h:mm a').format(timestamp);

      HapticUtils.success();
      setState(() {
        _isTimeIn = true;
        _isLoadingTimeIn = false;
        _timeInAddress = address ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _timeInTimestamp = formattedTime;
      });

      widget.onTimeInToggle(true);
    } catch (e) {
      setState(() {
        _isLoadingTimeIn = false;
        _timeInError = 'Error capturing location: $e';
      });
      HapticUtils.error();
    }
  }

  void _showLocationActionDialog(LocationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Required'),
        content: Text(
          result == LocationResult.serviceDisabled
              ? 'GPS is disabled. Please enable location services to capture your time-in location.'
              : 'Location permission is required. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (result == LocationResult.serviceDisabled) {
                _geoService.openLocationSettings();
              } else {
                _geoService.openAppSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelfie() async {
    HapticUtils.lightImpact();

    try {
      // Capture photo using front camera
      final photo = await _cameraService.capturePhoto(
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        HapticUtils.success();
        setState(() => _selfiePath = photo.path);
        widget.onSelfieCapture(_selfiePath);
      }
    } catch (e) {
      HapticUtils.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture selfie: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _handleFormSubmit(Map<String, dynamic> formData) {
    widget.onFormSubmit(formData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with client info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    '< Back',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const Spacer(),
                // Client info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.client.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.client.location != null)
                      Text(
                        widget.client.location!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Time In and Selfie buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.mapPin,
                    label: 'Time In',
                    onTap: _isTimeIn ? null : _handleTimeIn,
                    isCompleted: _isTimeIn,
                    isLoading: _isLoadingTimeIn,
                    subText: _isTimeIn ? _timeInTimestamp : null,
                    detailText: _isTimeIn ? _timeInAddress : null,
                    errorText: _timeInError,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.camera,
                    label: 'Selfie',
                    onTap: _handleSelfie,
                    isCompleted: _selfiePath != null,
                    selfiePath: _selfiePath,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Touchpoint selector
          TouchpointSelector(
            selectedTouchpoint: _selectedTouchpoint,
            onTouchpointSelected: (number) {
              setState(() => _selectedTouchpoint = number);
              widget.onTouchpointSelected(number);
            },
            onArchiveTap: () {
              // TODO: Handle archive
              HapticUtils.lightImpact();
            },
          ),

          const Divider(height: 1),

          // Visit form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: VisitForm(
                onSubmit: _handleFormSubmit,
                isTimeInCompleted: _isTimeIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isCompleted,
    bool isLoading = false,
    String? subText,
    String? detailText,
    String? errorText,
    String? selfiePath,
  }) {
    final hasError = errorText != null;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: hasError
              ? const Color(0xFFFEE2E2)
              : isCompleted
                  ? const Color(0xFF22C55E).withOpacity(0.1)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasError
                ? const Color(0xFFEF4444)
                : isCompleted
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            // Show selfie thumbnail if captured
            if (selfiePath != null && isCompleted) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.file(
                  File(selfiePath),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    LucideIcons.check,
                    size: 24,
                    color: const Color(0xFF22C55E),
                  ),
                ),
              ),
            ] else if (isLoading) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
              ),
            ] else ...[
              Icon(
                hasError
                    ? LucideIcons.alertCircle
                    : isCompleted
                        ? LucideIcons.check
                        : icon,
                size: 24,
                color: hasError
                    ? const Color(0xFFEF4444)
                    : isCompleted
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF64748B),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasError
                    ? const Color(0xFFEF4444)
                    : isCompleted
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF64748B),
              ),
            ),
            if (subText != null) ...[
              const SizedBox(height: 4),
              Text(
                subText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
            if (detailText != null) ...[
              const SizedBox(height: 2),
              Text(
                detailText,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (hasError) ...[
              const SizedBox(height: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFFEF4444),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
