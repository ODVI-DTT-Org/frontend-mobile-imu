import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/notification_utils.dart';

/// Page to request all required permissions after login
class PermissionRequestPage extends StatefulWidget {
  const PermissionRequestPage({super.key});

  @override
  State<PermissionRequestPage> createState() => _PermissionRequestPageState();
}

class _PermissionRequestPageState extends State<PermissionRequestPage> {
  bool _isLoading = false;
  bool _isRequestingAll = false;

  // Permission states
  PermissionStatus _locationStatus = PermissionStatus.notRequested;
  PermissionStatus _cameraStatus = PermissionStatus.notRequested;
  PermissionStatus _notificationStatus = PermissionStatus.notRequested;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    // Check location permission
    final locationPermission = await Geolocator.checkPermission();
    setState(() {
      _locationStatus = _mapLocationPermission(locationPermission);
    });

    // Check camera permission
    final cameraStatus = await ph.Permission.camera.status;
    setState(() {
      _cameraStatus = _mapPermissionStatus(cameraStatus);
    });

    // Check notification permission
    final notificationService = NotificationService();
    final hasNotification = await notificationService.hasPermission();
    setState(() {
      _notificationStatus = hasNotification
          ? PermissionStatus.granted
          : PermissionStatus.notRequested;
    });
  }

  PermissionStatus _mapLocationPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return PermissionStatus.granted;
      case LocationPermission.denied:
        return PermissionStatus.denied;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.notRequested;
    }
  }

  PermissionStatus _mapPermissionStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      default:
        return PermissionStatus.notRequested;
    }
  }

  Future<void> _requestLocationPermission() async {
    HapticUtils.lightImpact();
    setState(() => _isLoading = true);

    try {
      // First try using geolocator
      var permission = await Geolocator.requestPermission();

      // If denied, try permission_handler as fallback
      if (permission == LocationPermission.denied) {
        final phStatus = await ph.Permission.locationWhenInUse.request();
        if (phStatus.isGranted) {
          permission = LocationPermission.whileInUse;
        } else if (phStatus.isPermanentlyDenied) {
          permission = LocationPermission.deniedForever;
        }
      }

      setState(() {
        _locationStatus = _mapLocationPermission(permission);
      });

      if (permission == LocationPermission.deniedForever) {
        _showOpenSettingsDialog('Location');
      }
    } catch (e) {
      setState(() => _locationStatus = PermissionStatus.denied);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestCameraPermission() async {
    HapticUtils.lightImpact();
    setState(() => _isLoading = true);

    try {
      // Use permission_handler to request camera permission without opening camera
      final status = await ph.Permission.camera.request();
      setState(() {
        _cameraStatus = _mapPermissionStatus(status);
      });

      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog('Camera');
      }
    } catch (e) {
      setState(() {
        _cameraStatus = PermissionStatus.denied;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    HapticUtils.lightImpact();
    setState(() => _isLoading = true);

    try {
      // Try permission_handler for notifications
      final status = await ph.Permission.notification.request();
      setState(() {
        _notificationStatus = _mapPermissionStatus(status);
      });

      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog('Notification');
      }
    } catch (e) {
      // Fallback to notification service
      try {
        final notificationService = NotificationService();
        final granted = await notificationService.requestPermission();
        setState(() {
          _notificationStatus = granted
              ? PermissionStatus.granted
              : PermissionStatus.denied;
        });
      } catch (e2) {
        setState(() {
          _notificationStatus = PermissionStatus.denied;
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOpenSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          '$permissionName permission is permanently denied. Please enable it in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ph.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAllPermissions() async {
    HapticUtils.lightImpact();
    setState(() => _isRequestingAll = true);

    try {
      // Request location
      await _requestLocationPermissionInternal();

      // Request camera
      await _requestCameraPermissionInternal();

      // Request notifications
      await _requestNotificationPermissionInternal();

      HapticUtils.success();
    } finally {
      setState(() => _isRequestingAll = false);
    }
  }

  Future<void> _requestLocationPermissionInternal() async {
    try {
      var permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        final phStatus = await ph.Permission.locationWhenInUse.request();
        if (phStatus.isGranted) {
          permission = LocationPermission.whileInUse;
        } else if (phStatus.isPermanentlyDenied) {
          permission = LocationPermission.deniedForever;
        }
      }

      setState(() {
        _locationStatus = _mapLocationPermission(permission);
      });
    } catch (e) {
      setState(() => _locationStatus = PermissionStatus.denied);
    }
  }

  Future<void> _requestCameraPermissionInternal() async {
    try {
      final status = await ph.Permission.camera.request();
      setState(() {
        _cameraStatus = _mapPermissionStatus(status);
      });
    } catch (e) {
      setState(() {
        _cameraStatus = PermissionStatus.denied;
      });
    }
  }

  Future<void> _requestNotificationPermissionInternal() async {
    try {
      final status = await ph.Permission.notification.request();
      setState(() {
        _notificationStatus = _mapPermissionStatus(status);
      });
    } catch (e) {
      setState(() {
        _notificationStatus = PermissionStatus.denied;
      });
    }
  }

  void _continueToApp() {
    HapticUtils.lightImpact();
    // PIN SETUP DISABLED - Skip PIN setup, go directly to sync loading
    // After permissions, go to PIN setup for first-time users
    // context.go('/pin-setup');
    context.go('/sync-loading');
  }

  bool get _hasRequiredPermissions {
    // Location is the only required permission
    return _locationStatus == PermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'App Permissions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Text(
                    'IMU needs access to your location, camera, and notifications to help you track visits and capture proof of delivery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Permission cards
              _buildPermissionCard(
                icon: LucideIcons.mapPin,
                title: 'Location',
                description: 'Required for GPS capture during time-in and visit tracking.',
                status: _locationStatus,
                isLoading: _isLoading,
                onRequest: _requestLocationPermission,
              ),
              const SizedBox(height: 12),
              _buildPermissionCard(
                icon: LucideIcons.camera,
                title: 'Camera',
                description: 'Required for capturing selfies and visit photos.',
                status: _cameraStatus,
                isLoading: _isLoading,
                onRequest: _requestCameraPermission,
              ),
              const SizedBox(height: 12),
              _buildPermissionCard(
                icon: LucideIcons.bell,
                title: 'Notifications',
                description: 'Required for visit reminders and important updates.',
                status: _notificationStatus,
                isLoading: _isLoading,
                onRequest: _requestNotificationPermission,
              ),
              const SizedBox(height: 32),

              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Location permission is required for time-in. Camera is needed for selfies. You can grant these now or later.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasRequiredPermissions ? _continueToApp : _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isRequestingAll
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _hasRequiredPermissions ? 'Continue' : 'Grant All Permissions',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required PermissionStatus status,
    required bool isLoading,
    required VoidCallback onRequest,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case PermissionStatus.granted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Granted';
        break;
      case PermissionStatus.denied:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Denied';
        break;
      case PermissionStatus.permanentlyDenied:
        statusColor = Colors.orange;
        statusIcon = Icons.block;
        statusText = 'Permanently Denied';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Not Requested';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(statusIcon, color: statusColor, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (status != PermissionStatus.granted)
            isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    onPressed: onRequest,
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    color: const Color(0xFF0F172A),
                  )
          else
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}

enum PermissionStatus {
  notRequested,
  granted,
  denied,
  permanentlyDenied,
}
