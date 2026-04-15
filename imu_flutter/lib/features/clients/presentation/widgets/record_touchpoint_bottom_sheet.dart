import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay;
import 'package:imu_flutter/features/clients/presentation/widgets/client_action_bottom_sheet.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/odometer_field.dart';
import 'package:imu_flutter/features/clients/presentation/widgets/form_fields/time_picker_field.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart' show
    touchpointApiServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

/// Bottom sheet for recording touchpoints with all fields
/// Self-contained - handles photo upload and API submission internally
class RecordTouchpointBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordTouchpointBottomSheet({
    super.key,
    required this.client,
  });

  /// Parse touchpoint status from string
  TouchpointStatus _parseTouchpointStatus(String status) {
    switch (status.toLowerCase()) {
      case 'interested': return TouchpointStatus.interested;
      case 'undecided': return TouchpointStatus.undecided;
      case 'not interested': return TouchpointStatus.notInterested;
      case 'completed': return TouchpointStatus.completed;
      default: return TouchpointStatus.interested;
    }
  }

  /// Parse touchpoint reason from string
  TouchpointReason _parseTouchpointReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'follow-up': return TouchpointReason.interested;
      case 'documentation': return TouchpointReason.forVerification;
      case 'payment collection': return TouchpointReason.loanInquiry;
      case 'client not available': return TouchpointReason.notAround;
      default: return TouchpointReason.interested;
    }
  }

  /// Parse ISO 8601 time string to DateTime
  DateTime? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    try {
      return DateTime.parse(timeString);
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
    final reason = useState<String>('Follow-up');
    final status = useState<String>('Interested');
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
        // Prepare photo file if provided
        File? photoFile;
        if (photoPath.value != null && photoPath.value!.isNotEmpty) {
          photoFile = File(photoPath.value!);
        }

        // Create Touchpoint object from form data
        final touchpoint = Touchpoint(
          id: '', // Will be generated by API
          clientId: client.id!,
          touchpointNumber: 1, // Will be calculated by API
          type: TouchpointType.visit, // Default to Visit for this form
          reason: _parseTouchpointReason(reason.value),
          status: _parseTouchpointStatus(status.value),
          date: DateTime.now(),
          createdAt: DateTime.now(),
          userId: '', // Will be set by API
          remarks: remarks.text.trim(),
          photoPath: null, // Photo uploaded via FormData
          audioPath: null,
          timeIn: _parseTime(formatTimeOfDay(timeIn.value!)),
          timeOut: _parseTime(formatTimeOfDay(timeOut.value!)),
          timeInGpsLat: null,
          timeInGpsLng: null,
          timeInGpsAddress: null,
          timeOutGpsLat: null,
          timeOutGpsLng: null,
          timeOutGpsAddress: null,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
        );

        // Submit to API with photo file (single FormData request)
        final touchpointApi = ref.read(touchpointApiServiceProvider);
        final success = await touchpointApi.createTouchpointWithPhoto(
          touchpoint,
          photoFile: photoFile,
        ) != null;

        if (success && context.mounted) {
          AppNotification.showSuccess(context, 'Touchpoint recorded successfully');
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record touchpoint: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return ClientActionBottomSheet(
      clientName: client.fullName,
      pensionType: client.pensionType.toString(),
      submitButtonText: 'Record Touchpoint',
      isSubmitting: isSubmitting.value,
      onSubmit: canSubmit() ? handleSubmit : () {},
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

          // Reason Dropdown
          Text(
            'Reason',
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
                value: reason.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Follow-up', child: Text('Follow-up')),
                  DropdownMenuItem(value: 'Documentation', child: Text('Documentation')),
                  DropdownMenuItem(value: 'Payment Collection', child: Text('Payment Collection')),
                  DropdownMenuItem(value: 'Client not available', child: Text('Client not available')),
                ],
                onChanged: (value) => reason.value = value ?? reason.value,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Status Dropdown
          Text(
            'Status',
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
                value: status.value,
                isExpanded: true,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                items: const [
                  DropdownMenuItem(value: 'Interested', child: Text('Interested')),
                  DropdownMenuItem(value: 'Undecided', child: Text('Undecided')),
                  DropdownMenuItem(value: 'Not Interested', child: Text('Not Interested')),
                  DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                ],
                onChanged: (value) => status.value = value ?? status.value,
              ),
            ),
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
            maxLines: 3,
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
