import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/release_model.dart';
import 'package:imu_flutter/core/utils/haptic_utils.dart';

/// Release form widget for loan release applications
class ReleaseFormWidget extends StatefulWidget {
  final Release? initialRelease;
  final Function(Release) onSubmit;
  final bool isLoading;

  const ReleaseFormWidget({
    super.key,
    this.initialRelease,
    required this.onSubmit,
    this.isLoading = false,
  });

  @override
  State<ReleaseFormWidget> createState() => _ReleaseFormWidgetState();
}

class _ReleaseFormWidgetState extends State<ReleaseFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _approvalNotesController = TextEditingController();

  String? _productType;
  String? _loanType;
  String? _visitId; // This would normally come from a visit selector

  final List<String> _productTypes = ['PUSU', 'LIKA', 'SUB2K'];
  final List<String> _loanTypes = ['NEW', 'ADDITIONAL', 'RENEWAL', 'PRETERM'];

  @override
  void initState() {
    super.initState();
    if (widget.initialRelease != null) {
      _initializeFromRelease(widget.initialRelease!);
    }
  }

  void _initializeFromRelease(Release release) {
    _amountController.text = release.amount.toString();
    _approvalNotesController.text = release.approvalNotes ?? '';
    _productType = release.productType;
    _loanType = release.loanType;
    _visitId = release.visitId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _approvalNotesController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      HapticUtils.error();
      return;
    }

    final amountText = _amountController.text;
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      HapticUtils.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    HapticUtils.success();
    final release = Release(
      id: widget.initialRelease?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      clientId: widget.initialRelease?.clientId ?? '',
      userId: widget.initialRelease?.userId ?? '',
      visitId: _visitId ?? '',
      productType: _productType ?? 'PUSU',
      loanType: _loanType ?? 'NEW',
      amount: amount,
      approvalNotes: _approvalNotesController.text.isEmpty ? null : _approvalNotesController.text,
      status: widget.initialRelease?.status ?? 'pending',
      createdAt: widget.initialRelease?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSubmit(release);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Type
          _buildDropdown(
            label: 'Product Type',
            value: _productType,
            items: _productTypes,
            onChanged: (value) => setState(() => _productType = value),
            required: true,
          ),
          const SizedBox(height: 16),

          // Loan Type
          _buildDropdown(
            label: 'Loan Type',
            value: _loanType,
            items: _loanTypes,
            onChanged: (value) => setState(() => _loanType = value),
            required: true,
          ),
          const SizedBox(height: 16),

          // Amount
          _buildTextField(
            label: 'Amount',
            controller: _amountController,
            hint: 'e.g., 50000.00',
            required: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
          ),
          const SizedBox(height: 16),

          // Approval Notes (optional)
          _buildTextField(
            label: 'Approval Notes',
            controller: _approvalNotesController,
            hint: 'Notes for approval',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Status Display (read-only for existing releases)
          if (widget.initialRelease != null) ...[
            _buildStatusDisplay(),
            const SizedBox(height: 16),
          ],

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
                  : Text(
                      widget.initialRelease == null ? 'Submit for Approval' : 'Update Release',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),

          // Info note
          if (widget.initialRelease == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.info,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Loan releases require manager approval before disbursement',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
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
                    child: Text(item),
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

  Widget _buildStatusDisplay() {
    final status = widget.initialRelease?.status ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 18, color: statusColor),
          const SizedBox(width: 8),
          Text(
            'Status: ${status.toUpperCase()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'disbursed':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return LucideIcons.checkCircle;
      case 'rejected':
        return LucideIcons.xCircle;
      case 'disbursed':
        return LucideIcons.dollarSign;
      default:
        return LucideIcons.clock;
    }
  }
}
