// lib/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class TimeOdometerPanel extends StatelessWidget {
  final DateTime? timeIn;
  final DateTime? timeOut;
  final String? odometerIn;
  final String? odometerOut;
  final ValueChanged<DateTime?> onTimeInChanged;
  final ValueChanged<DateTime?> onTimeOutChanged;
  final ValueChanged<String?> onOdometerInChanged;
  final ValueChanged<String?> onOdometerOutChanged;
  final Map<String, String?> errors;

  const TimeOdometerPanel({
    super.key,
    this.timeIn,
    this.timeOut,
    this.odometerIn,
    this.odometerOut,
    required this.onTimeInChanged,
    required this.onTimeOutChanged,
    required this.onOdometerInChanged,
    required this.onOdometerOutChanged,
    required this.errors,
  });

  String _formatTime(DateTime? time) {
    if (time == null) return 'Select Time';
    return DateFormat.jm().format(time);
  }

  String _formatOdometer(String? value) {
    if (value == null || value.isEmpty) return '';
    // Format with comma for thousands
    final number = int.tryParse(value);
    if (number == null) return value;
    return NumberFormat.decimalPattern().format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Row
        Row(
          children: [
            Expanded(
              child: _buildTimeField(
                context,
                label: 'Time In',
                value: timeIn,
                formattedValue: _formatTime(timeIn),
                onChanged: onTimeInChanged,
                errorKey: 'timeIn',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTimeField(
                context,
                label: 'Time Out',
                value: timeOut,
                formattedValue: _formatTime(timeOut),
                onChanged: onTimeOutChanged,
                errorKey: 'timeOut',
                subtitle: 'Auto +5min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Odometer Row
        Row(
          children: [
            Expanded(
              child: _buildOdometerField(
                context,
                label: 'Odometer In',
                value: odometerIn,
                displayValue: _formatOdometer(odometerIn),
                onChanged: onOdometerInChanged,
                errorKey: 'odometerIn',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOdometerField(
                context,
                label: 'Odometer Out',
                value: odometerOut,
                displayValue: _formatOdometer(odometerOut),
                onChanged: onOdometerOutChanged,
                errorKey: 'odometerOut',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required String formattedValue,
    required ValueChanged<DateTime?> onChanged,
    required String errorKey,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final hasError = errors[errorKey] != null;

    return InkWell(
      onTap: () => _selectTime(context, value, onChanged),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasError
                ? theme.colorScheme.error
                : theme.colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasError ? theme.colorScheme.error : null,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  LucideIcons.clock,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  formattedValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasError ? theme.colorScheme.error : null,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOdometerField(
    BuildContext context, {
    required String label,
    required String? value,
    required String displayValue,
    required ValueChanged<String?> onChanged,
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
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.gauge,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: displayValue)..selection = TextSelection.fromPosition(TextPosition(offset: displayValue.length)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (newValue) {
                    // Strip commas for the actual value
                    onChanged(newValue.replaceAll(',', ''));
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasError ? theme.colorScheme.error : null,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    DateTime? currentTime,
    ValueChanged<DateTime?> onChanged,
  ) async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime != null
          ? TimeOfDay.fromDateTime(currentTime)
          : TimeOfDay.fromDateTime(now),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final selected = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
      onChanged(selected);
    }
  }
}
