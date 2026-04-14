import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/call_model.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Call form widget for recording client calls
class CallFormWidget extends StatefulWidget {
  final Call? initialCall;
  final Function(Call) onSubmit;
  final bool isLoading;

  const CallFormWidget({
    super.key,
    this.initialCall,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<CallFormWidget> createState() => _CallFormWidgetState();
}

class _CallFormWidgetState extends State<CallFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _dialTime;
  int? _duration;
  String? _status;

  final List<String> _statusOptions = [
    'completed',
    'no_answer',
    'busy',
    'wrong_number',
    'rescheduled',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCall != null) {
      _initializeFromCall(widget.initialCall!);
    }
  }

  void _initializeFromCall(Call call) {
    _phoneNumberController.text = call.phoneNumber;
    _notesController.text = call.notes ?? '';
    _reasonController.text = call.reason ?? '';
    _dialTime = call.dialTime;
    _duration = call.duration;
    _status = call.status;
    if (call.duration != null) {
      _durationController.text = call.duration.toString();
    }
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDialTime() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dialTime ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 1)),
    );

    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dialTime ?? now),
      );

      if (time != null) {
        setState(() {
          _dialTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      return;
    }

    // Parse duration from controller
    final durationText = _durationController.text;
    int? parsedDuration;
    if (durationText.isNotEmpty) {
      parsedDuration = int.tryParse(durationText);
    }

    HapticUtils.success();
    final call = Call(
      id: widget.initialCall?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: widget.initialCall?.clientId ?? '',
      userId: widget.initialCall?.userId ?? '',
      phoneNumber: _phoneNumberController.text,
      dialTime: _dialTime,
      duration: parsedDuration ?? _duration,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      reason: _reasonController.text.isEmpty ? null : _reasonController.text,
      status: _status,
      createdAt: widget.initialCall?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSubmit(call);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone Number
          _buildTextField(
            label: 'Phone Number',
            controller: _phoneNumberController,
            hint: 'e.g., 09123456789',
            required: true,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Dial Time
          _buildDateTimeButton(
            label: 'Dial Time',
            dateTime: _dialTime,
            onTap: _selectDialTime,
          ),
          const SizedBox(height: 16),

          // Duration
          _buildTextField(
            label: 'Duration (seconds)',
            controller: _durationController,
            hint: 'e.g., 300',
            keyboardType: TextInputType.number,
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

          // Reason
          _buildTextField(
            label: 'Reason',
            controller: _reasonController,
            hint: 'Call reason',
            maxLines: 2,
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
                  : const Text('Save Call', style: TextStyle(fontSize: 16)),
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
    bool required = false,
    TextInputType? keyboardType,
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
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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

  Widget _buildDateTimeButton({
    required String label,
    required DateTime? dateTime,
    required VoidCallback onTap,
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
                  LucideIcons.calendar,
                  size: 18,
                  color: dateTime != null ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateTime != null
                        ? '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                        : 'Select date and time',
                    style: TextStyle(
                      fontSize: 14,
                      color: dateTime != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
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
