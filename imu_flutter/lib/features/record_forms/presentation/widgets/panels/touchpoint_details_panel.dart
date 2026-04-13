// lib/features/record_forms/presentation/widgets/panels/touchpoint_details_panel.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';

class TouchpointDetailsPanel extends StatelessWidget {
  final TouchpointReason? reason;
  final TouchpointStatus? status;
  final ValueChanged<TouchpointReason?> onReasonChanged;
  final ValueChanged<TouchpointStatus?> onStatusChanged;
  final Map<String, String?> errors;

  const TouchpointDetailsPanel({
    super.key,
    this.reason,
    this.status,
    required this.onReasonChanged,
    required this.onStatusChanged,
    required this.errors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reason dropdown
        _buildDropdown(
          context,
          label: 'Reason',
          value: reason,
          items: TouchpointReason.values,
          displayName: (reason) => reason.displayName,
          onChanged: onReasonChanged,
          errorKey: 'reason',
        ),
        const SizedBox(height: 16),

        // Status dropdown
        _buildDropdown(
          context,
          label: 'Client Status',
          value: status,
          items: TouchpointStatus.values,
          displayName: (status) => status.displayName,
          onChanged: onStatusChanged,
          errorKey: 'status',
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
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              hint: Text(
                'Select $label',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              icon: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    displayName(item),
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: hasError ? theme.colorScheme.error : null,
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
                size: 14,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errors[errorKey]!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
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
