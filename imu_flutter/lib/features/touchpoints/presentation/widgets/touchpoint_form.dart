import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../services/media/camera_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../providers/touchpoint_form_provider.dart';
import '../../../clients/data/models/client_model.dart';
import './time_capture_section.dart';

class TouchpointFormModal extends ConsumerStatefulWidget {
  final String clientId;
  final int touchpointNumber;
  final String touchpointType; // 'Visit' or 'Call'
  final String clientName;
  final String? address;

  const TouchpointFormModal({
    super.key,
    required this.clientId,
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

  final _remarksController = TextEditingController(); // NEW: remarks field
  String? _selectedReason;
  String? _selectedStatus; // Changed from TouchpointStatus? to String? for simplified form

  // Status options for touchpoints
  static const List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Interested', 'label': 'Interested', 'color': Color(0xFF4CAF50)},
    {'value': 'Undecided', 'label': 'Undecided', 'color': Color(0xFFFF9800)},
    {'value': 'Not Interested', 'label': 'Not Interested', 'color': Color(0xFFF44336)},
    {'value': 'Completed', 'label': 'Completed', 'color': Color(0xFF2196F3)},
    {'value': 'Follow-up Needed', 'label': 'Follow-up Needed', 'color': Color(0xFF9C27B0)}, // NEW
  ];

  // Photo capture
  File? _capturedPhoto;
  bool _isCapturingPhoto = false;
  bool _hasPhotoError = false;

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
      // Validate the touchpoint sequence
      final validation = TouchpointValidationService.validateTouchpointSequence(
        touchpointNumber: widget.touchpointNumber,
        touchpointType: widget.touchpointType == 'Visit'
            ? TouchpointType.visit
            : TouchpointType.call,
      );

      if (!validation.isValid) {
        // Show validation error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showSequenceValidationError(validation);
        });
        return;
      }

      ref.read(touchpointFormProvider.notifier).setTouchpointType(widget.touchpointType);
    });
  }

  @override
  void dispose() {
    _remarksController.dispose(); // NEW
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Time In / Time Out (two columns)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimeInField(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimeOutField(context),
                            ),
                          ],
                        ),
                      ),

                      // Row 2: Reason / Status (two columns)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildReasonDropdown(context),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusDropdown(context),
                            ),
                          ],
                        ),
                      ),

                      // Row 3: Remarks (full width)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildRemarksField(context),
                      ),

                      // Row 4: Camera (full width)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _buildCameraSection(context),
                      ),

                      // Fixed bottom submit buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: const Text('CANCEL'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _canSubmit() ? _handleSubmit : null,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: ref.watch(touchpointFormProvider).isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('SUBMIT'),
                              ),
                            ),
                          ],
                        ),
                      ),
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
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, isOptional: isOptional),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select date',
              suffixIcon: const Icon(LucideIcons.calendar),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2),
              ),
            ),
            child: Text(
              value != null ? _formatDate(value) : 'Select date',
              style: TextStyle(
                color: value != null ? Colors.black : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Helper widget for form field labels
  Widget _buildFieldLabel(String label, {bool isRequired = false, bool isOptional = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        if (isOptional)
          Text(
            ' (Optional)',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
      ],
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

  Widget _buildTimeInField(BuildContext context) {
    final state = ref.watch(touchpointFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Time In',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectTimeIn(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.timeIn.time != null
                      ? '${state.timeIn.time.hour}:${state.timeIn.time.minute.toString().padLeft(2, '0')}'
                      : 'Select time',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.timeIn.time != null ? Colors.black : Colors.grey[600],
                  ),
                ),
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (state.timeIn.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.timeIn.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeOutField(BuildContext context) {
    final state = ref.watch(touchpointFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Time Out',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectTimeOut(context),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.timeOut.time != null
                      ? '${state.timeOut.time.hour}:${state.timeOut.time.minute.toString().padLeft(2, '0')}'
                      : 'Select time',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.timeOut.time != null ? Colors.black : Colors.grey[600],
                  ),
                ),
                Icon(
                  LucideIcons.clock,
                  size: 16,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        if (state.timeOut.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              state.timeOut.error!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectTimeIn(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
    );

    if (picked != null) {
      final timeIn = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      ref.read(touchpointFormProvider.notifier).setTimeIn(timeIn, null, null, null);

      // Auto-calculate Time Out = Time In + 5 minutes
      if (ref.read(touchpointFormProvider).timeOut.time == null) {
        final timeOut = timeIn.add(const Duration(minutes: 5));
        ref.read(touchpointFormProvider.notifier).setTimeOut(timeOut, null, null, null);
      }
    }
  }

  Future<void> _selectTimeOut(BuildContext context) async {
    final state = ref.watch(touchpointFormProvider);
    final now = DateTime.now();
    final initialTime = state.timeOut.time ?? now;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialTime.hour, minute: initialTime.minute),
    );

    if (picked != null) {
      final timeOut = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      // Validate time out is after time in
      final timeInValue = state.timeIn.time;
      if (timeInValue != null && timeOut.isBefore(timeInValue)) {
        ref.read(touchpointFormProvider.notifier).setTimeOutError(
          'Time out must be after time in',
        );
        return;
      }

      ref.read(touchpointFormProvider.notifier).setTimeOut(timeOut, null, null, null);
      ref.read(touchpointFormProvider.notifier).clearTimeOutError();
    }
  }

  Widget _buildReasonDropdown(BuildContext context) {
    final state = ref.watch(touchpointFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Reason',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.reason,
              hint: Text(
                'Select reason',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey[600],
              ),
              items: _reasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason['value'],
                  child: Text(
                    reason['label'],
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(touchpointFormProvider.notifier).setReason(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              hint: Text(
                'Select status',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey[600],
              ),
              items: _statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status['value'],
                  child: Text(
                    status['label'],
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  // Note: Will add to state provider in Task 8
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksField(BuildContext context) {
    return const Center(child: Text('Remarks Field - TODO'));
  }

  Widget _buildCameraSection(BuildContext context) {
    return const Center(child: Text('Camera Section - TODO'));
  }

  bool _canSubmit() {
    // Placeholder validation logic
    // Will be implemented in Task 7
    return false;
  }

  void _handleSubmit() {
    // Validate photo evidence for Visit type
    if (widget.touchpointType == 'Visit' && _capturedPhoto == null) {
      setState(() => _hasPhotoError = true);
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a photo evidence'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      HapticUtils.success();

      // Get Time In/Out data from provider
      final formState = ref.read(touchpointFormProvider);
      final timeIn = formState.timeIn;
      final timeOut = formState.timeOut;

      // Return the form data
      Navigator.pop(context, {
        // Required fields for API
        'client_id': widget.clientId,
        'touchpoint_number': widget.touchpointNumber,
        'type': widget.touchpointType,
        // Form fields
        'reason': _selectedReason,
        'status': _selectedStatus?.apiValue ?? 'Interested', // NEW: status field
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
        'odometerArrival': _odometerArrivalController.text.isEmpty ? null : _odometerArrivalController.text,
        'odometerDeparture': _odometerDepartureController.text.isEmpty ? null : _odometerDepartureController.text,
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
        setState(() {
          _capturedPhoto = photo;
          _hasPhotoError = false; // Reset error when photo is captured
        });
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

  /// Build the touchpoint sequence information card
  Widget _buildSequenceInfoCard() {
    final sequence = TouchpointValidationService.getSequenceDisplay();
    final currentIndex = widget.touchpointNumber - 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 16,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Touchpoint Sequence',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(sequence.length, (index) {
              final isCurrent = index == currentIndex;
              final isPast = index < currentIndex;
              final isFuture = index > currentIndex;

              Color bgColor;
              Color textColor;
              Border? border;

              if (isCurrent) {
                bgColor = Colors.blue[600]!;
                textColor = Colors.white;
                border = Border.all(color: Colors.blue[800]!, width: 2);
              } else if (isPast) {
                bgColor = Colors.green[200]!;
                textColor = Colors.green[900]!;
              } else {
                bgColor = Colors.grey[200]!;
                textColor = Colors.grey[600]!;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                  border: border,
                ),
                child: Text(
                  sequence[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: textColor,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            'Creating: $_ordinal ${widget.touchpointType}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Show sequence validation error dialog
  void _showSequenceValidationError(validation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Invalid Touchpoint Type'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.error ?? 'Invalid touchpoint sequence'),
            const SizedBox(height: 16),
            const Text(
              'Expected Sequence:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...TouchpointValidationService.getSequenceDisplay().map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('• $item'),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) {
      // Close the form modal as well
      Navigator.pop(context);
    });
  }
}

// Helper function to show the modal
Future<Map<String, dynamic>?> showTouchpointForm({
  required BuildContext context,
  required String clientId,
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
      clientId: clientId,
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointType,
      clientName: clientName,
      address: address,
    ),
  );
}
