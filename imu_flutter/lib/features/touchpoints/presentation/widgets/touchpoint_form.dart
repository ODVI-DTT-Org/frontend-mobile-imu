import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/media/camera_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../providers/touchpoint_form_provider.dart';
import './time_capture_section.dart';

class TouchpointFormModal extends ConsumerStatefulWidget {
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
  ConsumerState<TouchpointFormModal> createState() => _TouchpointFormModalState();
}

class _TouchpointFormModalState extends ConsumerState<TouchpointFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _cameraService = CameraService();

  final _odometerArrivalController = TextEditingController();
  final _odometerDepartureController = TextEditingController();
  DateTime? _nextVisitDate;
  String? _selectedReason;

  // Photo capture
  File? _capturedPhoto;
  bool _isCapturingPhoto = false;

  // Reason types - synced with database touchpoint_reasons table
  static const List<Map<String, dynamic>> _reasons = [
    {'value': 'ABROAD', 'label': 'Abroad', 'color': Color(0xFF546E7A)},
    {'value': 'APPLY_MEMBERSHIP', 'label': 'Apply for PUSU Membership / LIKA Membership', 'color': Color(0xFF66BB6A)},
    {'value': 'BACKED_OUT', 'label': 'Backed Out', 'color': Color(0xFFEF5350)},
    {'value': 'CI_BI', 'label': 'CI/BI', 'color': Color(0xFF42A5F5)},
    {'value': 'DECEASED', 'label': 'Deceased', 'color': Color(0xFF424242)},
    {'value': 'DISAPPROVED', 'label': 'Disapproved', 'color': Color(0xFFE53935)},
    {'value': 'FOR_ADA_COMPLIANCE', 'label': 'For ADA Compliance', 'color': Color(0xFF26C6DA)},
    {'value': 'FOR_PROCESSING', 'label': 'For Processing / Approval / Request / Buy-Out', 'color': Color(0xFF5C6BC0)},
    {'value': 'FOR_UPDATE', 'label': 'For Update', 'color': Color(0xFFAB47BC)},
    {'value': 'FOR_VERIFICATION', 'label': 'For Verification', 'color': Color(0xFF26A69A)},
    {'value': 'INACCESSIBLE_AREA', 'label': 'Inaccessible / Critical Area', 'color': Color(0xFF78909C)},
    {'value': 'INTERESTED', 'label': 'Interested', 'color': Color(0xFF4CAF50)},
    {'value': 'LOAN_INQUIRY', 'label': 'Loan Inquiry', 'color': Color(0xFF2196F3)},
    {'value': 'MOVED_OUT', 'label': 'Moved Out', 'color': Color(0xFF9E9E9E)},
    {'value': 'NOT_AMENABLE', 'label': 'Not Amenable to Our Product Criteria', 'color': Color(0xFF8D6E63)},
    {'value': 'NOT_AROUND', 'label': 'Not Around', 'color': Color(0xFFBDBDBD)},
    {'value': 'NOT_IN_LIST', 'label': 'Not In the List', 'color': Color(0xFF9E9E9E)},
    {'value': 'NOT_INTERESTED', 'label': 'Not Interested', 'color': Color(0xFFF44336)},
    {'value': 'OVERAGE', 'label': 'Overage', 'color': Color(0xFFFFA726)},
    {'value': 'POOR_HEALTH', 'label': 'Poor Health Condition', 'color': Color(0xFFFF7043)},
    {'value': 'RETURNED_ATM', 'label': 'Returned ATM / Pick-up ATM', 'color': Color(0xFFEC407A)},
    {'value': 'UNDECIDED', 'label': 'Undecided', 'color': Color(0xFFFF9800)},
    {'value': 'UNLOCATED', 'label': 'Unlocated', 'color': Color(0xFFBDBDBD)},
    {'value': 'WITH_OTHER_LENDING', 'label': 'With Other Lending', 'color': Color(0xFF7E57C2)},
    {'value': 'INTERESTED_FAMILY_DECLINED', 'label': 'Interested, But Declined Due to Family''s Decision', 'color': Color(0xFFFFB300)},
    {'value': 'TELEMARKETING', 'label': 'Telemarketing', 'color': Color(0xFF29B6F6)},
  ];

  String get _ordinal {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[widget.touchpointNumber - 1];
  }

  @override
  void initState() {
    super.initState();
    // Initialize the provider with the touchpoint type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(touchpointFormProvider.notifier).setTouchpointType(widget.touchpointType);
    });
  }

  @override
  void dispose() {
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
                      const SizedBox(height: 16),

                      // Time In section for Visit type
                      if (widget.touchpointType == 'Visit') ...[
                        TimeCaptureSection(
                          label: 'TIME IN',
                          buttonLabel: 'CAPTURE TIME IN',
                          status: ref.watch(touchpointFormProvider).timeIn.isCapturing
                              ? TimeCaptureStatus.capturing
                              : ref.watch(touchpointFormProvider).timeIn.isCaptured
                                  ? TimeCaptureStatus.captured
                                  : TimeCaptureStatus.notCaptured,
                          capturedTime: ref.watch(touchpointFormProvider).timeIn.time,
                          gpsLat: ref.watch(touchpointFormProvider).timeIn.gpsLat,
                          gpsLng: ref.watch(touchpointFormProvider).timeIn.gpsLng,
                          gpsAddress: ref.watch(touchpointFormProvider).timeIn.gpsAddress,
                          isEnabled: true,
                          showGps: true,
                          onCapture: (time, lat, lng, address) {
                            ref.read(touchpointFormProvider.notifier).setTimeIn(time, lat, lng, address);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form fields wrapped in IgnorePointer for Visit type
                      IgnorePointer(
                        ignoring: !ref.watch(touchpointFormProvider).canFillForm,
                        child: Opacity(
                          opacity: ref.watch(touchpointFormProvider).canFillForm ? 1.0 : 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                        ),)
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
                            ],
                          ),
                        ),
                      ),

                      // Time Out section for Visit type (before submit button)
                      if (widget.touchpointType == 'Visit') ...[
                        const SizedBox(height: 16),
                        TimeCaptureSection(
                          label: 'TIME OUT',
                          buttonLabel: 'CAPTURE TIME OUT',
                          status: ref.watch(touchpointFormProvider).timeOut.isCapturing
                              ? TimeCaptureStatus.capturing
                              : ref.watch(touchpointFormProvider).timeOut.isCaptured
                                  ? TimeCaptureStatus.captured
                                  : TimeCaptureStatus.notCaptured,
                          capturedTime: ref.watch(touchpointFormProvider).timeOut.time,
                          gpsLat: ref.watch(touchpointFormProvider).timeOut.gpsLat,
                          gpsLng: ref.watch(touchpointFormProvider).timeOut.gpsLng,
                          gpsAddress: ref.watch(touchpointFormProvider).timeOut.gpsAddress,
                          isEnabled: ref.watch(touchpointFormProvider).timeIn.isCaptured,
                          showGps: true,
                          minTime: ref.watch(touchpointFormProvider).timeIn.time,
                          onCapture: (time, lat, lng, address) {
                            final timeIn = ref.read(touchpointFormProvider).timeIn.time;
                            if (timeIn != null && !time.isAfter(timeIn)) {
                              _showTimeOutValidationError(timeIn, time);
                              return;
                            }
                            ref.read(touchpointFormProvider.notifier).setTimeOut(time, lat, lng, address);
                          },
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: ref.watch(touchpointFormProvider).canSubmit
                              ? _handleSubmit
                              : null,
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

      // Get Time In/Out data from provider
      final formState = ref.read(touchpointFormProvider);
      final timeIn = formState.timeIn;
      final timeOut = formState.timeOut;

      // Return the form data
      Navigator.pop(context, {
        'reason': _selectedReason,
        // Time In/Out from provider (for Visit type)
        'timeIn': timeIn.time?.toIso8601String(),
        'timeInGpsLat': timeIn.gpsLat,
        'timeInGpsLng': timeIn.gpsLng,
        'timeInGpsAddress': timeIn.gpsAddress,
        'timeOut': timeOut.time?.toIso8601String(),
        'timeOutGpsLat': timeOut.gpsLat,
        'timeOutGpsLng': timeOut.gpsLng,
        'timeOutGpsAddress': timeOut.gpsAddress,
        // Legacy fields for backwards compatibility
        'timeArrival': timeIn.time != null ? _formatDateTime(timeIn.time!) : null,
        'timeDeparture': timeOut.time != null ? _formatDateTime(timeOut.time!) : null,
        'odometerArrival': _odometerArrivalController.text,
        'odometerDeparture': _odometerDepartureController.text,
        'nextVisitDate': _nextVisitDate?.toIso8601String(),
        'photoPath': _capturedPhoto?.path,
        // Use Time In GPS as primary location (for backwards compatibility)
        'location': timeIn.gpsLat != null && timeIn.gpsLng != null
            ? {
                'latitude': timeIn.gpsLat,
                'longitude': timeIn.gpsLng,
                'address': timeIn.gpsAddress,
                'accuracy': null,
              }
            : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Touchpoint saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Shows validation error when Time Out is not after Time In
  void _showTimeOutValidationError(DateTime timeIn, DateTime timeOut) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Invalid Time'),
          ],
        ),
        content: const Text(
          'Time Out must be after Time In.\n\n'
          'Please select a later time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
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
