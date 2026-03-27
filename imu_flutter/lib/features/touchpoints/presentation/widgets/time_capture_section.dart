import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/location/geolocation_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/utils/loading_helper.dart';

/// Status enum for time capture operations
enum TimeCaptureStatus {
  notCaptured,
  capturing,
  captured,
  error,
  timeout,
  permissionDenied,
}

/// A widget for capturing Time In/Out with optional GPS location
class TimeCaptureSection extends ConsumerStatefulWidget {
  /// Label displayed above the section (e.g., "TIME IN", "TIME OUT")
  final String label;

  /// Text displayed on the capture button (e.g., "CAPTURE TIME IN")
  final String buttonLabel;

  /// Current status of the time capture
  final TimeCaptureStatus status;

  /// The captured time, if any
  final DateTime? capturedTime;

  /// Captured GPS latitude
  final double? gpsLat;

  /// Captured GPS longitude
  final double? gpsLng;

  /// Captured GPS address (reverse geocoded)
  final String? gpsAddress;

  /// Whether the capture button is enabled
  final bool isEnabled;

  /// Whether to show GPS capture functionality
  final bool showGps;

  /// Minimum time for the time picker (used for Time Out to default to Time In + 15 mins)
  final DateTime? minTime;

  /// Callback when time is captured with optional GPS data
  final void Function(DateTime time, double? lat, double? lng, String? address) onCapture;

  /// Callback when user skips GPS capture (captures time only)
  final VoidCallback? onSkip;

  /// Callback when user wants to retry after an error
  final VoidCallback? onRetry;

  const TimeCaptureSection({
    super.key,
    required this.label,
    required this.buttonLabel,
    required this.status,
    this.capturedTime,
    this.gpsLat,
    this.gpsLng,
    this.gpsAddress,
    this.isEnabled = true,
    this.showGps = true,
    this.minTime,
    required this.onCapture,
    this.onSkip,
    this.onRetry,
  });

  @override
  ConsumerState<TimeCaptureSection> createState() => _TimeCaptureSectionState();
}

class _TimeCaptureSectionState extends ConsumerState<TimeCaptureSection> {
  final _geoService = GeolocationService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),

        // Content based on status
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    switch (widget.status) {
      case TimeCaptureStatus.notCaptured:
      case TimeCaptureStatus.error:
      case TimeCaptureStatus.timeout:
      case TimeCaptureStatus.permissionDenied:
        return _buildNotCapturedState();

      case TimeCaptureStatus.capturing:
        return _buildCapturingState();

      case TimeCaptureStatus.captured:
        return _buildCapturedState();
    }
  }

  /// Not captured state - shows capture button
  Widget _buildNotCapturedState() {
    // Show error message if there was an error
    String? errorMessage;
    if (widget.status == TimeCaptureStatus.error) {
      errorMessage = 'Failed to capture. Please try again.';
    } else if (widget.status == TimeCaptureStatus.timeout) {
      errorMessage = 'GPS timeout. Please try again.';
    } else if (widget.status == TimeCaptureStatus.permissionDenied) {
      errorMessage = 'Location permission denied.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Capture button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: widget.isEnabled ? _showTimePicker : null,
            icon: const Icon(LucideIcons.clock),
            label: Text(widget.buttonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Capturing state - shows loading indicator
  Widget _buildCapturingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capturing...',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.showGps ? 'Getting time and GPS location' : 'Getting current time',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Captured state - shows captured time and GPS with edit option
  Widget _buildCapturedState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time row
          Row(
            children: [
              Icon(LucideIcons.checkCircle, color: Colors.green[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatTime(widget.capturedTime!),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[800],
                  ),
                ),
              ),
              // Edit button
              if (widget.isEnabled)
                TextButton.icon(
                  onPressed: _showTimePicker,
                  icon: const Icon(LucideIcons.pencil, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
            ],
          ),

          // GPS info if available and shown
          if (widget.showGps && widget.gpsLat != null && widget.gpsLng != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.mapPin, color: Colors.green[600], size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Location',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.gpsLat!.toStringAsFixed(6)}, ${widget.gpsLng!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (widget.gpsAddress != null && widget.gpsAddress!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.gpsAddress!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],

          // Show if GPS was skipped
          if (widget.showGps && widget.gpsLat == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.mapPinOff, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Text(
                  'GPS skipped - time only',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Shows the time picker dialog
  Future<void> _showTimePicker() async {
    HapticUtils.lightImpact();

    // Calculate initial time
    TimeOfDay initialTime;
    if (widget.capturedTime != null) {
      // Use existing captured time if editing
      initialTime = TimeOfDay.fromDateTime(widget.capturedTime!);
    } else if (widget.minTime != null) {
      // For Time Out, default to minTime (Time In + 15 mins)
      initialTime = TimeOfDay.fromDateTime(widget.minTime!);
    } else {
      // Default to current time
      initialTime = TimeOfDay.now();
    }

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: widget.label,
      confirmText: widget.showGps ? 'CAPTURE WITH GPS' : 'CAPTURE TIME',
      cancelText: 'CANCEL',
    );

    if (selectedTime == null) return;

    // Create DateTime from selected time
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    // If GPS is enabled, automatically capture GPS
    if (widget.showGps) {
      _captureWithGps(selectedDateTime);
    } else {
      // Capture time only
      widget.onCapture(selectedDateTime, null, null, null);
    }
  }

  /// Captures time with GPS location
  Future<void> _captureWithGps(DateTime selectedTime) async {
    HapticUtils.lightImpact();

    // First capture the time immediately
    widget.onCapture(selectedTime, null, null, null);

    try {
      // Get GPS position with detailed result using LoadingHelper
      final (position, result, errorMessage) = await LoadingHelper.withLoadingTimeout(
        ref: ref,
        operation: () => _geoService.getCurrentPositionWithResult(
          accuracy: LocationAccuracy.high,
          timeout: const Duration(seconds: 30),
        ),
        message: 'Capturing location...',
        timeout: const Duration(seconds: 35),
        timeoutMessage: 'GPS capture timed out. Please try again.',
      ) ?? (null, LocationResult.timeout, 'Operation timed out');

      if (!mounted) return;

      if (result == LocationResult.success && position != null) {
        // Show loading for address lookup
        final address = await LoadingHelper.withLoading(
          ref: ref,
          message: 'Getting address...',
          operation: () => _geoService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          ),
        );

        if (!mounted) return;

        HapticUtils.success();

        // Call onCapture with full GPS data
        widget.onCapture(selectedTime, position.latitude, position.longitude, address);
      } else {
        // Handle specific error cases
        switch (result) {
          case LocationResult.permissionDenied:
          case LocationResult.permissionDeniedForever:
            _showGpsErrorDialog(
              title: 'Permission Denied',
              message: 'Location permission is required to capture GPS. '
                  'Please grant location permission in your device settings.',
              showSettingsButton: true,
            );
            break;

          case LocationResult.timeout:
            _showGpsErrorDialog(
              title: 'GPS Timeout',
              message: 'Could not get your location in time. '
                  'This may happen indoors or with poor GPS signal.',
              showSettingsButton: false,
            );
            break;

          case LocationResult.serviceDisabled:
            _showGpsErrorDialog(
              title: 'GPS Disabled',
              message: 'Location services are disabled. '
                  'Please enable location services in your device settings.',
              showSettingsButton: true,
            );
            break;

          default:
            _showGpsErrorDialog(
              title: 'GPS Error',
              message: errorMessage ?? 'An error occurred while capturing GPS location.',
              showSettingsButton: false,
            );
        }
      }
    } catch (e) {
      if (!mounted) return;

      _showGpsErrorDialog(
        title: 'GPS Error',
        message: 'An unexpected error occurred: ${e.toString()}',
        showSettingsButton: false,
      );
    }
  }

  /// Captures time without GPS
  void _captureWithoutGps(DateTime selectedTime) {
    HapticUtils.lightImpact();
    widget.onCapture(selectedTime, null, null, null);

    if (widget.onSkip != null) {
      widget.onSkip!();
    }
  }

  /// Shows an error dialog for GPS issues
  Future<void> _showGpsErrorDialog({
    required String title,
    required String message,
    required bool showSettingsButton,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.orange[700], size: 24),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (showSettingsButton)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openAppSettings();
              },
              icon: const Icon(LucideIcons.settings, size: 18),
              label: const Text('OPEN SETTINGS'),
            ),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable time string
  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
