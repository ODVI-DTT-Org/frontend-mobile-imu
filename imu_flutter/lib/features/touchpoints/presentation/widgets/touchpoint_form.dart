import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../../../services/media/camera_service.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/config/app_config.dart';
import '../../../../services/auth/jwt_auth_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../providers/touchpoint_form_provider.dart';
import '../../../clients/data/models/client_model.dart';

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
                  ref.read(touchpointFormProvider.notifier).setStatus(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksField(BuildContext context) {
    final state = ref.watch(touchpointFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Remarks',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.all(12),
            hintText: 'Add remarks...',
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
            counterText: '${state.remarks?.length ?? 0}/500',
          ),
          onChanged: (value) {
            ref.read(touchpointFormProvider.notifier).setRemarks(value);
          },
        ),
      ],
    );
  }

  Widget _buildCameraSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Photo (Optional)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        if (_capturedPhoto != null)
          // Show thumbnail
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.file(
                    _capturedPhoto!,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                // Clear button
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _capturedPhoto = null;
                      });
                      ref.read(touchpointFormProvider.notifier).setPhotoPath(null);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          // Show camera button
          InkWell(
            onTap: () => _capturePhoto(context),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.camera,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _capturePhoto(BuildContext context) async {
    try {
      setState(() {
        _isCapturingPhoto = true;
        _hasPhotoError = false;
      });

      final photo = await _cameraService.capturePhoto();

      if (photo != null && mounted) {
        setState(() {
          _capturedPhoto = photo;
        });
        ref.read(touchpointFormProvider.notifier).setPhotoPath(photo.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPhotoError = true;
        });
        showToast('Failed to capture photo');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturingPhoto = false;
        });
      }
    }
  }

  bool _canSubmit() {
    final state = ref.watch(touchpointFormProvider);

    // Check required fields
    if (state.timeIn.time == null) return false;
    if (state.timeOut.time == null) return false;
    if (state.reason == null) return false;
    if (_selectedStatus == null) return false;
    if (_remarksController.text.trim().isEmpty) return false;

    // Check validation errors
    if (state.timeIn.error != null) return false;
    if (state.timeOut.error != null) return false;

    // Check if not currently submitting
    if (state.isSubmitting) return false;

    return true;
  }

  Future<void> _handleSubmit() async {
    if (!_canSubmit()) return;

    final state = ref.read(touchpointFormProvider);

    try {
      // Set submitting state
      ref.read(touchpointFormProvider.notifier).setIsSubmitting(true);

      // Prepare payload
      final payload = {
        'client_id': widget.clientId,
        'touchpoint_number': widget.touchpointNumber,
        'type': widget.touchpointType.toLowerCase(),
        'reason': state.reason!,
        'status': _selectedStatus!,
        'remarks': _remarksController.text.trim(),
        'time_arrival': state.timeIn.time!.toIso8601String(),
        'time_departure': state.timeOut.time!.toIso8601String(),
        if (_capturedPhoto != null) {
          'photo': _capturedPhoto!.path,
        },
      };

      // Submit to API
      final dio = Dio();
      final response = await dio.post(
        '${AppConfig.postgresApiUrl}/api/my-day/visits',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (JwtAuthService.instance.accessToken != null)
              'Authorization': 'Bearer ${JwtAuthService.instance.accessToken}',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        if (mounted) {
          showToast('Touchpoint recorded successfully');
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to submit touchpoint');
      }
    } catch (e) {
      if (mounted) {
        showToast('Failed to submit touchpoint: ${e.toString()}');
      }
    } finally {
      ref.read(touchpointFormProvider.notifier).setIsSubmitting(false);
    }
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
