import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';

/// Visit form with Transaction, Status, Remarks fields
class VisitForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final bool isTimeInCompleted;
  final String? validationError;

  const VisitForm({
    super.key,
    required this.onSubmit,
    this.isTimeInCompleted = false,
    this.validationError,
  });

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  String? _selectedTransaction;
  String? _selectedStatus;
  String? _selectedRemarks;
  final _releaseController = TextEditingController();
  final _otherRemarksController = TextEditingController();

  // Validation error states
  String? _transactionError;
  String? _statusError;
  String? _remarksError;

  final List<String> _transactions = [
    'New Loan Application',
    'Loan Renewal',
    'Document Submission',
    'Payment Collection',
    'Follow-up',
    'Other',
  ];

  final List<String> _statuses = [
    'Interested',
    'For Processing',
    'For Verification',
    'Not Interested',
    'Not Around',
    'Follow-up Needed',
  ];

  final List<String> _remarks = [
    'Approved',
    'Pending Requirements',
    'Incomplete Documents',
    'Rescheduled',
    'Declined',
    'Other',
  ];

  @override
  void dispose() {
    _releaseController.dispose();
    _otherRemarksController.dispose();
    super.dispose();
  }

  /// Validate all required fields
  bool _validateForm() {
    setState(() {
      _transactionError = _selectedTransaction == null ? 'Please select a transaction' : null;
      _statusError = _selectedStatus == null ? 'Please select a status' : null;
      _remarksError = _selectedRemarks == null ? 'Please select remarks' : null;
    });

    return _transactionError == null &&
           _statusError == null &&
           _remarksError == null;
  }

  void _handleSubmit() {
    if (!widget.isTimeInCompleted) {
      // Parent will show error
      return;
    }

    if (!_validateForm()) {
      HapticUtils.error();
      return;
    }

    HapticUtils.success();
    widget.onSubmit({
      'transaction': _selectedTransaction,
      'status': _selectedStatus,
      'remarks': _selectedRemarks,
      'releaseAmount': _releaseController.text,
      'otherRemarks': _otherRemarksController.text,
    });
  }

  bool get _canSubmit => widget.isTimeInCompleted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time In required warning
        if (!widget.isTimeInCompleted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.alertCircle,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please tap "Time In" before submitting the form',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Transaction dropdown
        _buildDropdown(
          label: 'Transaction',
          value: _selectedTransaction,
          hint: 'Select Transaction',
          items: _transactions,
          onChanged: (value) => setState(() {
            _selectedTransaction = value;
            _transactionError = null;
          }),
          errorText: _transactionError,
        ),
        const SizedBox(height: 16),

        // Status dropdown
        _buildDropdown(
          label: 'Status',
          value: _selectedStatus,
          hint: 'Select Status',
          items: _statuses,
          onChanged: (value) => setState(() {
            _selectedStatus = value;
            _statusError = null;
          }),
          errorText: _statusError,
        ),
        const SizedBox(height: 16),

        // Remarks dropdown
        _buildDropdown(
          label: 'Remarks',
          value: _selectedRemarks,
          hint: 'Select Remarks',
          items: _remarks,
          onChanged: (value) => setState(() {
            _selectedRemarks = value;
            _remarksError = null;
          }),
          errorText: _remarksError,
        ),
        const SizedBox(height: 16),

        // Add New Release field
        const Text(
          'Add New Release',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _releaseController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Php',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Other Remarks field
        const Text(
          'Other Remarks',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _otherRemarksController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter remarks...',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _canSubmit ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _canSubmit ? _handleSubmit : null,
            child: const Text('SUBMIT'),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ],
    );
  }
}
