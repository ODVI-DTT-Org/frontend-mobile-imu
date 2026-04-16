import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Reusable time picker field with label
class TimePickerField extends HookWidget {
  final String label;
  final TimeOfDay? initialTime;
  final ValueChanged<TimeOfDay?> onTimeChanged;
  final bool showError;

  const TimePickerField({
    super.key,
    required this.label,
    this.initialTime,
    required this.onTimeChanged,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTime = useState<TimeOfDay?>(initialTime);

    // Sync with external initialTime changes
    useEffect(() {
      if (initialTime != null && selectedTime.value != initialTime) {
        selectedTime.value = initialTime;
      }
    }, [initialTime]);

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
        onTimeChanged(picked); // This should trigger auto-calculation
        print('TimePickerField: Time picked - ${picked.hour}:${picked.minute}'); // Debug
      } else {
        print('TimePickerField: No time picked'); // Debug
      }
    }

    String formatTime(TimeOfDay? time) {
      if (time == null) return 'Select time';
      final hour = time.hourOfPeriod.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }

    return GestureDetector(
      onTap: pickTime,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        height: 52,
        decoration: BoxDecoration(
          border: Border.all(
            color: showError
              ? Colors.red[600]!
              : Colors.grey[300]!,
            width: showError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 18,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedTime.value != null ? formatTime(selectedTime.value) : label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: selectedTime.value != null
                    ? const Color(0xFF0F172A)
                    : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
