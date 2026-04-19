import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart'
    show SectionCard;

class LoanDetailsCard extends StatelessWidget {
  final ProductType? productType;
  final LoanType? loanType;
  final TextEditingController udiController;
  final void Function(ProductType) onProductTypeChanged;
  final void Function(LoanType) onLoanTypeChanged;
  final bool showErrors;

  const LoanDetailsCard({
    super.key,
    required this.productType,
    required this.loanType,
    required this.udiController,
    required this.onProductTypeChanged,
    required this.onLoanTypeChanged,
    required this.showErrors,
  });

  @override
  Widget build(BuildContext context) {
    final productError = showErrors && productType == null;
    final loanError = showErrors && loanType == null;
    final udiError = showErrors && udiController.text.trim().isEmpty;

    return SectionCard(
      title: 'LOAN DETAILS',
      child: Column(
        children: [
          _LabeledDropdown<ProductType>(
            label: 'Product Type',
            value: productType,
            showError: productError,
            hint: 'Select product type',
            items: ProductType.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName)))
                .toList(),
            onChanged: (v) {
              if (v != null) onProductTypeChanged(v);
            },
          ),
          const SizedBox(height: 10),
          _LabeledDropdown<LoanType>(
            label: 'Loan Type',
            value: loanType,
            showError: loanError,
            hint: 'Select loan type',
            items: LoanType.values
                .map((l) => DropdownMenuItem(value: l, child: Text(l.displayName)))
                .toList(),
            onChanged: (v) {
              if (v != null) onLoanTypeChanged(v);
            },
          ),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UDI Number',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: udiController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    hintText: udiError ? 'Required' : 'Enter UDI number',
                    hintStyle: TextStyle(
                      color: udiError
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF9CA3AF),
                    ),
                    prefixIcon:
                        const Icon(Icons.tag, size: 16, color: Color(0xFF64748B)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: udiError
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFE5E7EB),
                        width: udiError ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: udiError
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0F172A),
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                  ),
                ),
              ),
              if (udiError)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'UDI number is required',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final bool showError;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.showError,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
              width: showError ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                showError ? 'Required' : hint,
                style: TextStyle(
                  color: showError
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${label.toLowerCase()} is required',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
      ],
    );
  }
}
