import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay;
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording loan release with product/loan type selection
class RecordLoanReleaseBottomSheet extends HookWidget {
  final Client client;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const RecordLoanReleaseBottomSheet({
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
    final productType = useState<String>('PUSU');
    final loanType = useState<String>('NEW');
    final udiNumber = useTextEditingController();
    final remarks = useTextEditingController();
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
          udiNumber.text.trim().isNotEmpty &&
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
        'product_type': productType.value,
        'loan_type': loanType.value,
        'udi_number': udiNumber.text.trim(),
        'remarks': remarks.text.trim(),
        'photo_path': photoPath.value,
        'reason': 'New Loan Release',
        'status': 'Completed',
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
      submitButtonText: 'Release Loan',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit() ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-set badges
          Row(
            children: const [
              AutoSetBadge(label: 'Reason:', value: 'New Loan Release'),
              SizedBox(width: 8),
              AutoSetBadge(label: 'Status:', value: 'Completed'),
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

          // Product Type Dropdown
          Text(
            'Product Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: productType.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'PUSU', child: Text('PUSU')),
                  DropdownMenuItem(value: 'LIKA', child: Text('LIKA')),
                  DropdownMenuItem(value: 'SUB2K', child: Text('SUB2K')),
                ],
                onChanged: (value) => productType.value = value ?? productType.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Loan Type Dropdown
          Text(
            'Loan Type',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[50],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: loanType.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                  DropdownMenuItem(value: 'ADDITIONAL', child: Text('ADDITIONAL')),
                  DropdownMenuItem(value: 'RENEWAL', child: Text('RENEWAL')),
                  DropdownMenuItem(value: 'PRETERM', child: Text('PRETERM')),
                ],
                onChanged: (value) => loanType.value = value ?? loanType.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // UDI Number
          Text(
            'UDI Number *',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: udiNumber,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(12),
              hintText: 'Enter UDI number',
            ),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // Remarks
          Text(
            'Remarks',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: remarks,
            maxLines: 2,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 8),

          // Photo Capture
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
                      ? 'Photo captured'
                      : 'Take Photo',
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
