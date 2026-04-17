import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay;
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/auto_set_badge.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show
    releaseApiServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording loan release with product/loan type selection
/// Self-contained - handles photo upload and API submission internally
class RecordLoanReleaseBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordLoanReleaseBottomSheet({
    super.key,
    required this.client,
  });

  /// Parse time string to DateTime
  DateTime? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final productType = useState<String>('BFP_ACTIVE');
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
      // Create DateTime with today's date and the TimeOfDay time
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      // Return ISO 8601 format string (backend expects this format)
      return dateTime.toIso8601String();
    }

    /// Auto-calculate Time Out as Time In + 5 minutes
    void _autoCalculateTimeOut(TimeOfDay? newTimeIn) {
      if (newTimeIn != null) {
        // Convert to total minutes, add 5, then convert back to TimeOfDay
        final totalMinutes = newTimeIn.hour * 60 + newTimeIn.minute;
        final newTotalMinutes = totalMinutes + 5; // Add 5 minutes
        final newHour = (newTotalMinutes ~/ 60) % 24;
        final newMinute = newTotalMinutes % 60;

        // Create new TimeOfDay with the calculated hour and minute
        final calculatedTimeOut = TimeOfDay(hour: newHour, minute: newMinute);

        // Update the timeOut state
        timeOut.value = calculatedTimeOut;

        // Debug print to verify calculation
        print('Auto-calc Time Out: ${newTimeIn.hour}:${newTimeIn.minute} -> ${calculatedTimeOut.hour}:${calculatedTimeOut.minute}');
      }
    }

    /// Auto-calculate Odometer Departure as Arrival + 5km
    void _autoCalculateOdometerDeparture(String? arrivalValue) {
      if (arrivalValue != null && arrivalValue.isNotEmpty) {
        try {
          final arrivalKm = double.tryParse(arrivalValue);
          if (arrivalKm != null) {
            odometerDeparture.value = (arrivalKm + 5).toString();
          }
        } catch (e) {
          // If parsing fails, don't auto-calculate
        }
      }
    }

    bool canSubmit() {
      return timeIn.value != null &&
          timeOut.value != null &&
          odometerArrival.value != null &&
          odometerDeparture.value != null &&
          udiNumber.text.trim().isNotEmpty &&
          photoPath.value != null &&
          !isSubmitting.value;
    }

    Future<void> handleSubmit() async {
      if (!canSubmit()) {
        if (photoPath.value == null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              AppNotification.showError(context, 'Please capture a photo before submitting');
            }
          });
        }
        return;
      }

      isSubmitting.value = true;

      try {
        // Submit to API using the complete loan release method
        // The API service will handle photo upload internally with FormData
        final releaseApi = ref.read(releaseApiServiceProvider);
        final success = await releaseApi.createCompleteLoanRelease(
          clientId: client.id!,
          timeIn: formatTimeOfDay(timeIn.value!),
          timeOut: formatTimeOfDay(timeOut.value!),
          odometerArrival: odometerArrival.value ?? '',
          odometerDeparture: odometerDeparture.value ?? '',
          productType: productType.value,
          loanType: loanType.value,
          udiNumber: int.tryParse(udiNumber.text.trim()),
          remarks: remarks.text.trim(),
          photoPath: photoPath.value, // API service will handle File creation and upload
        ) != null;

        if (success && context.mounted) {
          AppNotification.showSuccess(context, 'Loan released successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to release loan: $e');
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
                  onTimeChanged: (time) {
                    timeIn.value = time;
                    _autoCalculateTimeOut(time); // Auto-calculate Time Out
                  },
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
                  onChanged: (value) {
                    odometerArrival.value = value;
                    _autoCalculateOdometerDeparture(value); // Auto-calculate Departure
                  },
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
                  DropdownMenuItem(value: 'BFP_ACTIVE', child: Text('BFP Active')),
                  DropdownMenuItem(value: 'BFP_PENSION', child: Text('BFP Pension')),
                  DropdownMenuItem(value: 'PNP_PENSION', child: Text('PNP Pension')),
                  DropdownMenuItem(value: 'NAPOLCOM', child: Text('NAPOLCOM')),
                  DropdownMenuItem(value: 'BFP_STP', child: Text('BFP STP')),
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
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: udiNumber,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Enter UDI number',
              hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400]),
            ),
            style: const TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 8),

          // Remarks
          Text(
            'Remarks',
            style: TextStyle(
              fontSize: 13,
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
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: const TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 8),

          // Photo Capture (Required)
          Text(
            'Photo *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: pickPhoto,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(
                  color: photoPath.value != null
                    ? Colors.green[600]!
                    : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
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
                      fontSize: 15,
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
