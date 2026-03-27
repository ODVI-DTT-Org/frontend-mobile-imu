import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/location/geolocation_service.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/my_day_client.dart';

/// Bottom sheet for bulk time-in of multiple clients
class MultipleTimeInSheet extends ConsumerStatefulWidget {
  final List<MyDayClient> clients;
  final Function(List<String> clientIds, String? address, String timestamp) onBulkTimeIn;

  const MultipleTimeInSheet({
    super.key,
    required this.clients,
    required this.onBulkTimeIn,
  });

  static Future<void> show({
    required BuildContext context,
    required List<MyDayClient> clients,
    required Function(List<String> clientIds, String? address, String timestamp) onBulkTimeIn,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => MultipleTimeInSheet(
          clients: clients,
          onBulkTimeIn: onBulkTimeIn,
        ),
      ),
    );
  }

  @override
  ConsumerState<MultipleTimeInSheet> createState() => _MultipleTimeInSheetState();
}

class _MultipleTimeInSheetState extends ConsumerState<MultipleTimeInSheet> {
  final GeolocationService _geoService = GeolocationService();
  final Set<String> _selectedClientIds = {};
  bool _isLoading = false;
  String? _capturedAddress;
  String? _capturedTimestamp;
  bool _locationCaptured = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    // Automatically capture GPS when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureLocation();
    });
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Multiple Time In',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 50), // Balance the cancel button
              ],
            ),
          ),

          // Location status
          _buildLocationStatus(),

          const Divider(height: 1),

          // Select all / deselect all
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_selectedClientIds.length} selected',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _selectAll,
                  child: const Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _deselectAll,
                  child: const Text(
                    'Deselect All',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Client list
          Expanded(
            child: ListView.builder(
              itemCount: widget.clients.length,
              itemBuilder: (context, index) {
                final client = widget.clients[index];
                final isSelected = _selectedClientIds.contains(client.id);

                return _buildClientItem(client, isSelected);
              },
            ),
          ),

          // Bulk time-in button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _canSubmit ? _handleBulkTimeIn : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('TIME IN ${_selectedClientIds.length} CLIENTS'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    // Show loading state on initial load
    if (_isLoading && !_locationCaptured && _locationError == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3B82F6)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Capturing location automatically...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show error state if location capture failed
    if (_locationError != null && !_locationCaptured) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.alertCircle,
              size: 18,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _locationError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            GestureDetector(
              onTap: _captureLocation,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_locationCaptured) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF22C55E)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 18,
              color: Color(0xFF22C55E),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location captured at $_capturedTimestamp',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  if (_capturedAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _capturedAddress!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: _captureLocation,
              child: const Text(
                'Update',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _captureLocation,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.mapPin, size: 18),
            label: Text(_isLoading ? 'Capturing...' : 'Capture Location First'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0F172A),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Location is required before time-in',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientItem(MyDayClient client, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleClient(client.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.05) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Touchpoint badge
            if (client.touchpointNumber > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  client.touchpointOrdinal,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.fullName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (client.location != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      client.location!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Time-in status
            if (client.isTimeIn) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Timed In',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _canSubmit => _selectedClientIds.isNotEmpty && _locationCaptured;

  void _toggleClient(String clientId) {
    HapticUtils.lightImpact();
    setState(() {
      if (_selectedClientIds.contains(clientId)) {
        _selectedClientIds.remove(clientId);
      } else {
        _selectedClientIds.add(clientId);
      }
    });
  }

  void _selectAll() {
    HapticUtils.lightImpact();
    setState(() {
      _selectedClientIds.clear();
      _selectedClientIds.addAll(widget.clients.map((c) => c.id));
    });
  }

  void _deselectAll() {
    HapticUtils.lightImpact();
    setState(() {
      _selectedClientIds.clear();
    });
  }

  Future<void> _captureLocation() async {
    HapticUtils.lightImpact();
    setState(() {
      _isLoading = true;
      _locationError = null;
    });

    try {
      final (position, result, errorMessage) = await LoadingHelper.withLoading(
        ref: ref,
        message: 'Capturing location...',
        operation: () => _geoService.getCurrentPositionWithResult(),
      ) ?? (null, LocationResult.error, 'Failed to capture location');

      if (position == null) {
        setState(() {
          _isLoading = false;
          _locationError = errorMessage ?? 'Unable to get location';
        });

        // Show action for permission issues
        if (mounted && (result == LocationResult.permissionDeniedForever ||
            result == LocationResult.serviceDisabled)) {
          _showLocationActionDialog(result);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage ?? 'Unable to get location'),
              backgroundColor: const Color(0xFFEF4444),
              action: result == LocationResult.permissionDenied
                  ? SnackBarAction(
                      label: 'Settings',
                      textColor: Colors.white,
                      onPressed: () => _geoService.openAppSettings(),
                    )
                  : null,
            ),
          );
        }
        return;
      }

      final address = await LoadingHelper.withLoading(
        ref: ref,
        message: 'Getting address...',
        operation: () => _geoService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        ),
      );

      final timestamp = DateTime.now();
      final formattedTime = DateFormat('h:mm a').format(timestamp);

      HapticUtils.success();
      setState(() {
        _isLoading = false;
        _locationCaptured = true;
        _locationError = null;
        _capturedAddress = address ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _capturedTimestamp = formattedTime;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationError = 'Error capturing location: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing location: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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

  void _handleBulkTimeIn() {
    HapticUtils.success();
    widget.onBulkTimeIn(
      _selectedClientIds.toList(),
      _capturedAddress,
      _capturedTimestamp ?? DateTime.now().toIso8601String(),
    );
    Navigator.pop(context);
  }
}
