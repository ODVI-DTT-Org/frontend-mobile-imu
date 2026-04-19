import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/location/geolocation_service.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../services/api/touchpoint_api_service.dart';
import '../../data/models/my_day_client.dart';
import '../../../../features/clients/data/models/client_model.dart' hide TimeOfDay;

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
  bool _isSubmitting = false;
  String? _capturedAddress;
  String? _capturedTimestamp;
  bool _locationCaptured = false;
  String? _locationError;
  Position? _capturedPosition;

  // Touchpoint form fields
  final _reasonController = TextEditingController();
  final _remarksController = TextEditingController();
  TouchpointStatus _selectedStatus = TouchpointStatus.interested;
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    // Automatically capture GPS when sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureLocation();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _remarksController.dispose();
    super.dispose();
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
            child: widget.clients.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No clients available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add clients to your My Day list first',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(LucideIcons.x, size: 16),
                            label: const Text('Close'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.clients.length,
                    itemBuilder: (context, index) {
                      final client = widget.clients[index];
                      final isSelected = _selectedClientIds.contains(client.id);

                      return _buildClientItem(client, isSelected);
                    },
                  ),
          ),

          // Touchpoint details section
          if (_locationCaptured) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Touchpoint Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reason dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedReason,
                    decoration: const InputDecoration(
                      labelText: 'Reason *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    items: _getAvailableReasons(widget.clients).map((reason) {
                      return DropdownMenuItem<String>(
                        value: reason,
                        child: Text(reason),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Status selection
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TouchpointStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      return FilterChip(
                        label: Text(_getStatusLabel(status)),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          HapticUtils.lightImpact();
                        },
                        selectedColor: _getStatusColor(status).withOpacity(0.2),
                        checkmarkColor: _getStatusColor(status),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  // Remarks field
                  TextField(
                    controller: _remarksController,
                    decoration: const InputDecoration(
                      labelText: 'Remarks',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ],

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
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
                      onPressed: _canSubmit && !_isSubmitting ? _handleBulkTouchpointSubmit : null,
                      child: _isLoading || _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('SUBMIT ${_selectedClientIds.length} TOUCHPOINT${_selectedClientIds.length > 1 ? 'S' : ''}'),
                    ),
                  ),
                  // Show requirement hints when submit is disabled
                  if (!_canSubmit && widget.clients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildRequirementHints(),
                  ],
                ],
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

  bool get _canSubmit => _selectedClientIds.isNotEmpty && _locationCaptured && _selectedReason != null;

  Widget _buildRequirementHints() {
    final hints = <String>[];

    if (_selectedClientIds.isEmpty) {
      hints.add('• Select at least one client');
    }
    if (!_locationCaptured) {
      hints.add('• Capture GPS location');
    }
    if (_selectedReason == null) {
      hints.add('• Select a reason');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.alertCircle,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 8),
              Text(
                'Required to submit:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...hints.map((hint) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 4),
                child: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                  ),
                ),
              )),
        ],
      ),
    );
  }

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
          if (result == LocationResult.permissionDenied) {
            AppNotification.showErrorWithAction(
              context,
              message: errorMessage ?? 'Unable to get location',
              actionLabel: 'Settings',
              onAction: () => _geoService.openAppSettings(),
            );
          } else {
            AppNotification.showError(context, errorMessage ?? 'Unable to get location');
          }
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
        _capturedPosition = position;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationError = 'Error capturing location: $e';
      });
      if (mounted) {
        AppNotification.showError(context, 'Error capturing location: $e');
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

  Future<void> _handleBulkTouchpointSubmit() async {
    if (_selectedReason == null || _capturedPosition == null) {
      AppNotification.showError(context, 'Please select a reason and ensure location is captured');
      return;
    }

    HapticUtils.mediumImpact();
    setState(() {
      _isSubmitting = true;
    });

    try {
      final touchpointApi = ref.read(touchpointApiServiceProvider);

      // Get today's date in YYYY-MM-DD format
      final now = DateTime.now();
      final todayDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Build touchpoints array from selected clients
      final touchpoints = widget.clients
          .where((client) => _selectedClientIds.contains(client.id))
          .map((client) {
            final nextTouchpointNumber = client.touchpointNumber;
            final touchpointType = TouchpointPattern.getType(nextTouchpointNumber);

            return {
              'client_id': client.id,
              'touchpoint_number': nextTouchpointNumber,
              'type': touchpointType.apiValue,
              'reason': TouchpointReason.values
                  .firstWhere((r) => r.name == _selectedReason,
                      orElse: () => TouchpointReason.interested)
                  .apiValue,
              'status': _selectedStatus.apiValue,
              if (_remarksController.text.trim().isNotEmpty)
                'remarks': _remarksController.text.trim(),
              'date': todayDate,
              // GPS fields will be added as shared GPS in the bulk API call
            };
          }).toList();

      // Call bulk API
      final result = await touchpointApi.createBulkTouchpoints(
        touchpoints: touchpoints,
        sharedGpsLat: _capturedPosition!.latitude,
        sharedGpsLng: _capturedPosition!.longitude,
        sharedGpsAddress: _capturedAddress,
      );

      final successCount = result['successCount'] as int? ?? 0;
      final errorCount = result['errorCount'] as int? ?? 0;
      final errors = result['errors'] as List<dynamic>? ?? [];

      if (mounted) {
        HapticUtils.success();

        if (successCount > 0) {
          // Call the callback with the submitted client IDs
          widget.onBulkTimeIn(
            _selectedClientIds.toList(),
            _capturedAddress,
            _capturedTimestamp ?? DateTime.now().toIso8601String(),
          );

          Navigator.pop(context);

          // Show success message
          AppNotification.showSuccess(
            context,
            'Successfully submitted $successCount touchpoint${successCount > 1 ? 's' : ''}',
            duration: const Duration(seconds: 2),
          );
        }

        // Show errors if any
        if (errorCount > 0) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              AppNotification.showErrorWithAction(
                context,
                message: '$errorCount touchpoint${errorCount > 1 ? 's' : ''} failed to submit',
                actionLabel: 'View',
                onAction: () {
                  // Show error details dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Submission Errors'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: errors.length,
                          itemBuilder: (context, index) {
                            final error = errors[index] as Map<String, dynamic>;
                            final clientId = error['clientId'] as String?;
                            final errorMessage = error['error'] as String?;
                            final client = widget.clients.firstWhere(
                              (c) => c.id == clientId,
                              orElse: () => widget.clients.first,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text('• ${client.fullName}: $errorMessage'),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        AppNotification.showError(context, 'Failed to submit touchpoints: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Get available touchpoint reasons based on the clients
  List<String> _getAvailableReasons(List<MyDayClient> clients) {
    return TouchpointReason.values.map((r) => r.apiValue).toList();
  }

  /// Get display label for touchpoint status
  String _getStatusLabel(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.interested:
        return 'Interested';
      case TouchpointStatus.undecided:
        return 'Undecided';
      case TouchpointStatus.notInterested:
        return 'Not Interested';
      case TouchpointStatus.completed:
        return 'Completed';
      case TouchpointStatus.followUpNeeded:
        return 'Follow Up Needed';
      case TouchpointStatus.incomplete:
        return 'Incomplete';
    }
  }

  /// Get color for touchpoint status
  Color _getStatusColor(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.interested:
        return const Color(0xFF22C55E); // Green
      case TouchpointStatus.undecided:
        return const Color(0xFFF59E0B); // Orange
      case TouchpointStatus.notInterested:
        return const Color(0xFFEF4444); // Red
      case TouchpointStatus.completed:
        return const Color(0xFF3B82F6); // Blue
      case TouchpointStatus.followUpNeeded:
        return const Color(0xFF8B5CF6); // Purple
      case TouchpointStatus.incomplete:
        return const Color(0xFF6B7280); // Grey
    }
  }
}
