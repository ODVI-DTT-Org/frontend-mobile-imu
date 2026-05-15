import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart'
    show SectionCard;

class ScheduleCard extends StatelessWidget {
  final TimeOfDay? timeIn;
  final TimeOfDay? timeOut;
  final String? odometerArrival;
  final String? odometerDeparture;
  final void Function(TimeOfDay) onTimeInChanged;
  final void Function(TimeOfDay) onTimeOutChanged;
  final void Function(String) onOdometerArrivalChanged;
  final void Function(String) onOdometerDepartureChanged;
  final bool showErrors;

  const ScheduleCard({
    super.key,
    required this.timeIn,
    required this.timeOut,
    required this.odometerArrival,
    required this.odometerDeparture,
    required this.onTimeInChanged,
    required this.onTimeOutChanged,
    required this.onOdometerArrivalChanged,
    required this.onOdometerDepartureChanged,
    required this.showErrors,
  });

  String _formatTime(TimeOfDay t) {
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'SCHEDULE',
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: _TimeField(
                label: 'Time In',
                value: timeIn,
                showError: showErrors && timeIn == null,
                onChanged: onTimeInChanged,
                formatTime: _formatTime,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeField(
                label: 'Time Out',
                value: timeOut,
                showError: showErrors && timeOut == null,
                onChanged: onTimeOutChanged,
                formatTime: _formatTime,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _OdometerField(
                label: 'Odo Arrival',
                value: odometerArrival,
                showError:
                    showErrors && (odometerArrival == null || odometerArrival!.isEmpty),
                onChanged: onOdometerArrivalChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _OdometerField(
                label: 'Odo Departure',
                value: odometerDeparture,
                showError:
                    showErrors && (odometerDeparture == null || odometerDeparture!.isEmpty),
                onChanged: onOdometerDepartureChanged,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final bool showError;
  final void Function(TimeOfDay) onChanged;
  final String Function(TimeOfDay) formatTime;

  const _TimeField({
    required this.label,
    required this.value,
    required this.showError,
    required this.onChanged,
    required this.formatTime,
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
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: value ?? TimeOfDay.now(),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                width: showError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF9FAFB),
            ),
            child: Row(children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                value != null
                    ? formatTime(value!)
                    : (showError ? 'Required' : '--:--'),
                style: TextStyle(
                  fontSize: 14,
                  color: showError && value == null
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0F172A),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _OdometerField extends StatelessWidget {
  final String label;
  final String? value;
  final bool showError;
  final void Function(String) onChanged;

  const _OdometerField({
    required this.label,
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
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
        SizedBox(
          height: 48,
          child: TextFormField(
            initialValue: value ?? '',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              suffixText: hasValue ? 'km' : null,
              hintText: showError ? 'Required' : '0',
              hintStyle: TextStyle(
                color: showError ? const Color(0xFFEF4444) : const Color(0xFF9CA3AF),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: showError ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
                  width: showError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: showError ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
