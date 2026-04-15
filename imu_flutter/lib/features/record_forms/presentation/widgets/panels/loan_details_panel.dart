// lib/features/record_forms/presentation/widgets/panels/loan_details_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';

class LoanDetailsPanel extends StatelessWidget {
  final String? udiNumber;
  final ProductType? productType;
  final LoanType? loanType;
  final ValueChanged<String?> onUdiNumberChanged;
  final ValueChanged<ProductType?> onProductTypeChanged;
  final ValueChanged<LoanType?> onLoanTypeChanged;
  final Map<String, String?> errors;

  const LoanDetailsPanel({
    super.key,
    this.udiNumber,
    this.productType,
    this.loanType,
    required this.onUdiNumberChanged,
    required this.onProductTypeChanged,
    required this.onLoanTypeChanged,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // UDI Number
        _buildTextInput(
          context: context,
          label: 'UDI Number (Release Amount)',
          value: udiNumber,
          hint: 'Enter amount',
          onChanged: onUdiNumberChanged,
          errorKey: 'udiNumber',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),

        // Product Type
        _buildDropdown<ProductType>(
          context: context,
          label: 'Product Type',
          value: productType,
          items: ProductType.values,
          displayName: (type) => type.displayName,
          onChanged: onProductTypeChanged,
          errorKey: 'productType',
        ),
        const SizedBox(height: 12),

        // Loan Type
        _buildDropdown<LoanType>(
          context: context,
          label: 'Loan Type',
          value: loanType,
          items: LoanType.values,
          displayName: (type) => type.displayName,
          onChanged: onLoanTypeChanged,
          errorKey: 'loanType',
        ),
      ],
    );
  }

  Widget _buildTextInput({
    required BuildContext context,
    required String label,
    required String? value,
    required String hint,
    required ValueChanged<String?> onChanged,
    required String errorKey,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    final hasError = errors[errorKey] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: hasError ? theme.colorScheme.error : null,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value?.length ?? 0)),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            errorText: errors[errorKey],
            errorStyle: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) displayName,
    required ValueChanged<T?> onChanged,
    required String errorKey,
  }) {
    final theme = Theme.of(context);
    final hasError = errors[errorKey] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: hasError ? theme.colorScheme.error : null,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
              icon: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayName(item),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasError ? theme.colorScheme.error : null,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 12,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  errors[errorKey]!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
