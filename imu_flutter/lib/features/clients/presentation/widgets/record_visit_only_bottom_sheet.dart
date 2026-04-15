import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay;
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording visit only with auto-set reason/status
class RecordVisitOnlyBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const RecordVisitOnlyBottomSheet({
    super.key,
    required this.client,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final photoPath = useState<String?>(null);
    final isSubmitting = useState<bool>(false);

    final imagePicker = useMemoized(() => ImagePicker());

    Future<void> pickPhoto() async {
      final picked = await imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked != null) {
        photoPath.value = picked.path;
      }
    }

    String formatTimeOfDay(TimeOfDay time) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    bool canSubmit() {
      return timeIn.value != null &&
          timeOut.value != null &&
          odometerArrival.value != null &&
          odometerDeparture.value != null &&
          !isSubmitting.value;
    }

    Future<void> handleSubmit() async {
      if (!canSubmit()) return;

      isSubmitting.value = true;

      final data = <String, dynamic>{
        'client_id': client.id,
        'time_in': formatTimeOfDay(timeIn.value!),
        'time_out': formatTimeOfDay(timeOut.value!),
        'odometer_arrival': int.parse(odometerArrival.value!),
        'odometer_departure': int.parse(odometerDeparture.value!),
        'reason': 'Client not available',
        'status': 'Incomplete',
        'photo_path': photoPath.value,
      };

      try {
        final success = await onSubmit(data);
        if (success && context.mounted) {
          Navigator.of(context).pop(true);
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return ClientActionBottomSheet(
      clientName: client.fullName,
      pensionType: client.pensionType.toString(),
      submitButtonText: 'Record Visit',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit() ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-set badges
          Row(
            children: const [
              AutoSetBadge(label: 'Reason:', value: 'Client not available'),
              SizedBox(width: 8),
              AutoSetBadge(label: 'Status:', value: 'Incomplete'),
            ],
          ),

          const SizedBox(height: 8),

          // Time In/Out - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: TimePickerField(
                  label: 'Time In',
                  initialTime: timeIn.value,
                  onTimeChanged: (time) => timeIn.value = time,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePickerField(
                  label: 'Time Out',
                  initialTime: timeOut.value,
                  onTimeChanged: (time) => timeOut.value = time,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Odometer Arrival/Departure - 2 Column Layout
          Row(
            children: [
              Expanded(
                child: OdometerField(
                  label: 'Odometer Arrival',
                  initialValue: odometerArrival.value,
                  onChanged: (value) => odometerArrival.value = value,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OdometerField(
                  label: 'Odometer Departure',
                  initialValue: odometerDeparture.value,
                  onChanged: (value) => odometerDeparture.value = value,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Photo Capture (Optional)
          InkWell(
            onTap: pickPhoto,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoPath.value != null
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(4),
                color: photoPath.value != null
                  ? Colors.green[50]
                  : Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    photoPath.value != null
                      ? LucideIcons.checkCircle
                      : LucideIcons.camera,
                    size: 20,
                    color: photoPath.value != null
                      ? Colors.green[600]
                      : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    photoPath.value != null
                      ? 'Photo captured (optional)'
                      : 'Take Photo (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      color: photoPath.value != null
                        ? Colors.green[700]
                        : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
