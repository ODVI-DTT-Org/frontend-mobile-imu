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
    visitApiServiceProvider,
    releaseApiServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording visit only with auto-set reason/status
/// Self-contained - handles photo upload and API submission internally
class RecordVisitOnlyBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordVisitOnlyBottomSheet({
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
    final photoPath = useState<String?>(null);
    final isSubmitting = useState<bool>(false);
    final hasAttemptedSubmit = useState<bool>(false); // Track if user tried to submit

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
        final totalMinutes = newTimeIn.hour * 60 + newTimeIn.minute;
        final newTotalMinutes = totalMinutes + 5; // Add 5 minutes
        final newHour = (newTotalMinutes ~/ 60) % 24;
        final newMinute = newTotalMinutes % 60;
        timeOut.value = TimeOfDay(hour: newHour, minute: newMinute);
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
          photoPath.value != null &&
          !isSubmitting.value;
    }

    // Show validation errors if user attempted submit
    bool showValidationError() {
      return hasAttemptedSubmit.value && !canSubmit();
    }

    Future<void> handleSubmit() async {
      if (!canSubmit()) {
        hasAttemptedSubmit.value = true; // Show validation errors
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
        // Prepare photo file if provided
        File? photoFile;
        if (photoPath.value != null && photoPath.value!.isNotEmpty) {
          photoFile = File(photoPath.value!);
        }

        // Submit to API with photo file (single FormData request)
        final visitApi = ref.read(visitApiServiceProvider);
        final success = await visitApi.createVisit(
          clientId: client.id!,
          timeIn: formatTimeOfDay(timeIn.value!),
          timeOut: formatTimeOfDay(timeOut.value!),
          odometerArrival: odometerArrival.value ?? '',
          odometerDeparture: odometerDeparture.value ?? '',
          photoFile: photoFile, // Send photo file with visit data
          notes: null,
          type: 'regular_visit',
        ) != null;

        if (success && context.mounted) {
          AppNotification.showSuccess(context, 'Visit recorded successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record visit: $e');
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
                  onTimeChanged: (time) {
                    timeIn.value = time;
                    _autoCalculateTimeOut(time); // Auto-calculate Time Out
                  },
                  showError: hasAttemptedSubmit.value && timeIn.value == null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TimePickerField(
                  label: 'Time Out',
                  initialTime: timeOut.value,
                  onTimeChanged: (time) => timeOut.value = time,
                  showError: hasAttemptedSubmit.value && timeOut.value == null,
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
                  showError: hasAttemptedSubmit.value && (odometerArrival.value == null || odometerArrival.value!.isEmpty),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OdometerField(
                  label: 'Odometer Departure',
                  initialValue: odometerDeparture.value,
                  onChanged: (value) => odometerDeparture.value = value,
                  showError: hasAttemptedSubmit.value && (odometerDeparture.value == null || odometerDeparture.value!.isEmpty),
                ),
              ),
            ],
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
