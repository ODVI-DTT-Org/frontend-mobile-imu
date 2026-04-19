import 'package:flutter/material.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart'
    show SectionCard;

class DetailsCard extends StatelessWidget {
  final bool locked;
  final TouchpointReason? reason;
  final TouchpointStatus? status;
  final List<TouchpointReason> availableReasons;
  final List<TouchpointStatus> availableStatuses;
  final void Function(TouchpointReason)? onReasonChanged;
  final void Function(TouchpointStatus)? onStatusChanged;
  final bool showErrors;
  final String? lockedReasonLabel;
  final String? lockedStatusLabel;

  const DetailsCard({
    super.key,
    required this.locked,
    required this.reason,
    required this.status,
    required this.availableReasons,
    required this.availableStatuses,
    required this.onReasonChanged,
    required this.onStatusChanged,
    required this.showErrors,
    this.lockedReasonLabel,
    this.lockedStatusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'DETAILS',
      child: Column(
        children: [
          _DropdownField<TouchpointReason>(
            label: 'Reason',
            value: reason,
            locked: locked,
            lockedLabel: lockedReasonLabel,
            showError: showErrors && !locked && reason == null,
            hint: 'Select reason',
            items: availableReasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                .toList(),
            onChanged: (v) {
              if (v != null) onReasonChanged?.call(v);
            },
          ),
          const SizedBox(height: 10),
          _DropdownField<TouchpointStatus>(
            label: 'Status',
            value: status,
            locked: locked,
            lockedLabel: lockedStatusLabel,
            showError: showErrors && !locked && status == null,
            hint: 'Select status',
            items: availableStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                .toList(),
            onChanged: (v) {
              if (v != null) onStatusChanged?.call(v);
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final bool locked;
  final String? lockedLabel;
  final bool showError;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.locked,
    required this.showError,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.lockedLabel,
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
            color: locked ? const Color(0xFFF9FAFB) : Colors.white,
          ),
          child: locked
              ? Row(children: [
                  Expanded(
                    child: Text(
                      lockedLabel ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
                ])
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      showError ? hint : hint,
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
