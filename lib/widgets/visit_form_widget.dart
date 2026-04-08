import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Visit form widget for recording client visits
class VisitFormWidget extends StatefulWidget {
  final Visit? initialVisit;
  final Function(Visit) onSubmit;
  final bool isLoading;

  const VisitFormWidget({
    super.key,
    this.initialVisit,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<VisitFormWidget> createState() => _VisitFormWidgetState();
}

class _VisitFormWidgetState extends State<VisitFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController();
  final _odometerArrivalController = TextEditingController();
  final _odometerDepartureController = TextEditingController();

  DateTime? _timeIn;
  DateTime? _timeOut;
  String? _type = 'regular_visit';
  String? _status;
  double? _latitude;
  double? _longitude;
  String? _photoUrl;

  final List<String> _visitTypes = ['regular_visit', 'release_loan'];
  final List<String> _statusOptions = [
    'completed',
    'pending',
    'cancelled',
    'rescheduled',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialVisit != null) {
      _initializeFromVisit(widget.initialVisit!);
    }
  }

  void _initializeFromVisit(Visit visit) {
    _notesController.text = visit.notes ?? '';
    _reasonController.text = visit.reason ?? '';
    _addressController.text = visit.address ?? '';
    _odometerArrivalController.text = visit.odometerArrival ?? '';
    _odometerDepartureController.text = visit.odometerDeparture ?? '';
    _timeIn = visit.timeIn;
    _timeOut = visit.timeOut;
    _type = visit.type;
    _status = visit.status;
    _latitude = visit.latitude;
    _longitude = visit.longitude;
    _photoUrl = visit.photoUrl;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _reasonController.dispose();
    _addressController.dispose();
    _odometerArrivalController.dispose();
    _odometerDepartureController.dispose();
    super.dispose();
  }

  Future<void> _selectTime({required bool isTimeIn}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 1)),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );

      if (time != null) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isTimeIn) {
            _timeIn = dateTime;
            // Auto-set timeOut to 5 minutes after timeIn
            if (_timeOut == null) {
              _timeOut = dateTime.add(const Duration(minutes: 5));
            }
          } else {
            _timeOut = dateTime;
          }
        });
      }
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      return;
    }

    HapticUtils.success();
    final visit = Visit(
      id: widget.initialVisit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: widget.initialVisit?.clientId ?? '',
      userId: widget.initialVisit?.userId ?? '',
      type: _type ?? 'regular_visit',
      timeIn: _timeIn,
      timeOut: _timeOut,
      odometerArrival: _odometerArrivalController.text.isEmpty ? null : _odometerArrivalController.text,
      odometerDeparture: _odometerDepartureController.text.isEmpty ? null : _odometerDepartureController.text,
      photoUrl: _photoUrl,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      status: _status,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      latitude: _latitude,
      longitude: _longitude,
      createdAt: widget.initialVisit?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSubmit(visit);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Visit Type
          _buildDropdown(
            label: 'Visit Type',
            value: _type,
            items: _visitTypes,
            onChanged: (value) => setState(() => _type = value),
            required: true,
          ),
          const SizedBox(height: 16),

          // Time In/Out Row
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  label: 'Time In',
                  time: _timeIn,
                  onTap: () => _selectTime(isTimeIn: true),
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeButton(
                  label: 'Time Out',
                  time: _timeOut,
                  onTap: () => _selectTime(isTimeIn: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Odometer Readings
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Odometer Arrival',
                  controller: _odometerArrivalController,
                  hint: 'e.g., 12345 km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  label: 'Odometer Departure',
                  controller: _odometerDepartureController,
                  hint: 'e.g., 12350 km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address (GPS)
          _buildTextField(
            label: 'Address',
            controller: _addressController,
            hint: 'GPS captured address',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Reason
          _buildTextField(
            label: 'Reason',
            controller: _reasonController,
            hint: 'Visit reason',
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Status
          _buildDropdown(
            label: 'Status',
            value: _status,
            items: _statusOptions,
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 16),

          // Notes
          _buildTextField(
            label: 'Notes',
            controller: _notesController,
            hint: 'Additional notes',
            maxLines: 3,
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Visit', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.toUpperCase()),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required DateTime? time,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 18,
                  color: time != null ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : 'Select time',
                    style: TextStyle(
                      fontSize: 14,
                      color: time != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
