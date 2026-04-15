import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable time picker field with label
class TimePickerField extends HookWidget {
  final String label;
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const TimePickerField({
    super.key,
    required this.label,
    this.initialTime,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTime = useState<TimeOfDay?>(initialTime);

    Future<void> pickTime() async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime.value ?? now,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,),
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        selectedTime.value = picked;
        onTimeChanged(picked);
      }
    }

    String formatTime(TimeOfDay? time) {
      if (time == null) return 'Select time';
      final hour = time.hourOfPeriod.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    return InkWell(
      onTap: pickTime,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            Text(
              formatTime(selectedTime.value),
              style: TextStyle(
                fontSize: 14,
                color: selectedTime.value != null
                  ? const Color(0xFF0F172A)
                  : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
