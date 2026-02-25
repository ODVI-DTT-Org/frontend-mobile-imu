import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/media/camera_service.dart';
import '../../../../services/location/geolocation_service.dart';
import '../../../../core/utils/haptic_utils.dart';

class TouchpointFormModal extends StatefulWidget {
  final int touchpointNumber;
  final String touchpointType; // 'Visit' or 'Call'
  final String clientName;
  final String? address;

  const TouchpointFormModal({
    super.key,
    required this.touchpointNumber,
    required this.touchpointType,
    required this.clientName,
    this.address,
  });

  @override
  State<TouchpointFormModal> createState() => _TouchpointFormModalState();
}

class _TouchpointFormModalState extends State<TouchpointFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _cameraService = CameraService();
  final _geoService = GeolocationService();

  TimeOfDay? _timeArrival;
  TimeOfDay? _timeDeparture;
  final _odometerArrivalController = TextEditingController();
  final _odometerDepartureController = TextEditingController();
  DateTime? _nextVisitDate;
  String? _selectedReason;

  // Photo capture
  File? _capturedPhoto;
  bool _isCapturingPhoto = false;

  // GPS capture
  LocationData? _capturedLocation;
  bool _isCapturingLocation = false;

  // Touchpoint pattern: Visit-Call-Call-Visit-Call-Call-Visit
  static const List<String> _touchpointPattern = [
    'Visit', 'Call', 'Call', 'Visit', 'Call', 'Call', 'Visit'
  ];

  // Reason types from the design
  static const List<Map<String, dynamic>> _reasons = [
    {'value': 'INTERESTED', 'label': 'Interested', 'color': Colors.green},
    {'value': 'NOT_INTERESTED', 'label': 'Not Interested', 'color': Colors.red},
    {'value': 'UNDECIDED', 'label': 'Undecided', 'color': Colors.orange},
    {'value': 'LOAN_INQUIRY', 'label': 'Loan Inquiry', 'color': Colors.blue},
    {'value': 'FOR_UPDATE', 'label': 'For Update', 'color': Colors.purple},
    {'value': 'FOR_VERIFICATION', 'label': 'For Verification', 'color': Colors.teal},
    {'value': 'FOR_PROCESSING', 'label': 'For Processing', 'color': Colors.indigo},
    {'value': 'FOR_ADA_COMPLIANCE', 'label': 'For ADA Compliance', 'color': Colors.cyan},
    {'value': 'FOR_APPLY_MEMBERSHIP', 'label': 'Apply Membership', 'color': Colors.lime},
    {'value': 'NOT_AROUND', 'label': 'Not Around', 'color': Colors.grey},
    {'value': 'NOT_AMENABLE', 'label': 'Not Amenable', 'color': Colors.brown},
    {'value': 'NOT_IN_LIST', 'label': 'Not In List', 'color': Colors.grey},
    {'value': 'UNLOCATED', 'label': 'Unlocated', 'color': Colors.grey},
    {'value': 'MOVED_OUT', 'label': 'Moved Out', 'color': Colors.grey},
    {'value': 'ABROAD', 'label': 'Abroad', 'color': Colors.blueGrey},
    {'value': 'DECEASED', 'label': 'Deceased', 'color': Colors.black54},
    {'value': 'OVERAGE', 'label': 'Overage', 'color': Colors.amber},
    {'value': 'POOR_HEALTH', 'label': 'Poor Health', 'color': Colors.deepOrange},
    {'value': 'BACKED_OUT', 'label': 'Backed Out', 'color': Colors.redAccent},
    {'value': 'DISAPPROVED', 'label': 'Disapproved', 'color': Colors.red},
    {'value': 'RETURNED_ATM', 'label': 'Returned ATM', 'color': Colors.pink},
    {'value': 'WITH_OTHER_LENDING', 'label': 'With Other Lending', 'color': Colors.deepPurple},
    {'value': 'INACCESSIBLE_AREA', 'label': 'Inaccessible Area', 'color': Colors.blueGrey},
    {'value': 'CI_BI', 'label': 'CI/BI', 'color': Colors.blue},
    {'value': 'TELEMARKETING', 'label': 'Telemarketing', 'color': Colors.lightBlue},
    {'value': 'INTERESTED_BUT_DECLINED', 'label': 'Interested but Declined', 'color': Colors.amber},
  ];

  String get _ordinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[widget.touchpointNumber - 1];
  }

  @override
  void initState() {
    super.initState();
    // Auto-capture GPS for Visit type
    if (widget.touchpointType == 'Visit') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureGps();
      });
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _odometerArrivalController.dispose();
    _odometerDepartureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.touchpointType == 'Visit' ? LucideIcons.mapPin : LucideIcons.phone,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_ordinal ${widget.touchpointType}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.clientName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date and Address
                      Text(
                        'Date: ${_formatDate(DateTime.now())}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (widget.address != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.address!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Reason dropdown
                      const Text(
                        'Reason *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedReason,
                        decoration: const InputDecoration(
                          hintText: 'Select reason',
                        ),
                        items: _reasons
                            .map((reason) => DropdownMenuItem<String>(
                                  value: reason['value'] as String,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: reason['color'],
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(reason['label']),
                                    ],
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedReason = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Visit-specific fields
                      if (widget.touchpointType == 'Visit') ...[
                        // Photo Capture Section
                        const Text(
                          'Photo Evidence',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildPhotoCapture(),
                        const SizedBox(height: 16),

                        // GPS Location Section
                        const Text(
                          'GPS Location',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        _buildGpsCapture(),
                        const SizedBox(height: 16),

                        // Time of Arrival
                        _buildTimeField(
                          label: 'Time of Arrival',
                          value: _timeArrival,
                          onTap: () => _selectTime(true),
                        ),
                        const SizedBox(height: 16),

                        // Time of Departure
                        _buildTimeField(
                          label: 'Time of Departure',
                          value: _timeDeparture,
                          onTap: () => _selectTime(false),
                        ),
                        const SizedBox(height: 16),

                        // Odometer Arrival
                        const Text(
                          'Odometer Arrival',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _odometerArrivalController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., 12,345',
                            suffixText: 'km',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Odometer Departure
                        const Text(
                          'Odometer Departure',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _odometerDepartureController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., 12,350',
                            suffixText: 'km',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Next Visit Date
                      _buildDateField(
                        label: 'Next Visit Date',
                        value: _nextVisitDate,
                        onTap: _selectNextVisitDate,
                      ),
                      const SizedBox(height: 16),

                      // Remarks
                      const Text(
                        'Remarks',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _remarksController,
                        decoration: const InputDecoration(
                          hintText: 'Enter remarks...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          child: const Text('SAVE TOUCHPOINT'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.clock),
        ),
        child: Text(
          value != null ? _formatTime(value) : 'Select time',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.calendar),
        ),
        child: Text(
          value != null ? _formatDate(value) : 'Select date',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTime(bool isArrival) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        if (isArrival) {
          _timeArrival = time;
        } else {
          _timeDeparture = time;
        }
      });
    }
  }

  Future<void> _selectNextVisitDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _nextVisitDate = date);
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      HapticUtils.success();

      // Return the form data
      Navigator.pop(context, {
        'reason': _selectedReason,
        'timeArrival': _timeArrival != null ? _formatTime(_timeArrival!) : null,
        'timeDeparture': _timeDeparture != null ? _formatTime(_timeDeparture!) : null,
        'odometerArrival': _odometerArrivalController.text,
        'odometerDeparture': _odometerDepartureController.text,
        'nextVisitDate': _nextVisitDate != null ? _nextVisitDate!.toIso8601String() : null,
        'remarks': _remarksController.text,
        'photoPath': _capturedPhoto?.path,
        'location': _capturedLocation?.toJson(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Touchpoint saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildPhotoCapture() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          image: _capturedPhoto != null
              ? DecorationImage(
                  image: FileImage(_capturedPhoto!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _isCapturingPhoto
            ? const Center(child: CircularProgressIndicator())
            : _capturedPhoto == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.camera,
                        size: 40,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to capture photo',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            HapticUtils.lightImpact();
                            setState(() => _capturedPhoto = null);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    HapticUtils.lightImpact();
    setState(() => _isCapturingPhoto = true);

    try {
      final photo = await _cameraService.capturePhoto();
      if (photo != null) {
        setState(() => _capturedPhoto = photo);
        HapticUtils.success();
      }
    } finally {
      setState(() => _isCapturingPhoto = false);
    }
  }

  Widget _buildGpsCapture() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _capturedLocation != null ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _capturedLocation != null ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _capturedLocation != null ? LucideIcons.mapPin : LucideIcons.crosshair,
            color: _capturedLocation != null ? Colors.green : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _isCapturingLocation
                ? const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Capturing GPS location...'),
                    ],
                  )
                : _capturedLocation != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Captured',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.green[800],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_capturedLocation!.latitude.toStringAsFixed(6)}, ${_capturedLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (_capturedLocation!.accuracy != null)
                            Text(
                              'Accuracy: ${_capturedLocation!.accuracy!.toStringAsFixed(0)}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      )
                    : Text(
                        'GPS will be captured automatically',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
          ),
          if (!_isCapturingLocation && _capturedLocation == null)
            TextButton(
              onPressed: _captureGps,
              child: const Text('Capture Now'),
            ),
          if (_capturedLocation != null)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: _captureGps,
              tooltip: 'Recapture GPS',
            ),
        ],
      ),
    );
  }

  Future<void> _captureGps() async {
    HapticUtils.lightImpact();
    setState(() => _isCapturingLocation = true);

    try {
      final position = await _geoService.getCurrentPosition();
      if (position != null) {
        final address = await _geoService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        setState(() {
          _capturedLocation = LocationData.fromPosition(position, address: address);
        });
        HapticUtils.success();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not capture GPS location. Please check permissions.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      setState(() => _isCapturingLocation = false);
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// Helper function to show the modal
Future<Map<String, dynamic>?> showTouchpointForm({
  required BuildContext context,
  required int touchpointNumber,
  required String touchpointType,
  required String clientName,
  String? address,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TouchpointFormModal(
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointType,
      clientName: clientName,
      address: address,
    ),
  );
}
