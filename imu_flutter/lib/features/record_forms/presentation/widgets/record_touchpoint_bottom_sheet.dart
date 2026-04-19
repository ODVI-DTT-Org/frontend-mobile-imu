import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay, TouchpointReason, TouchpointStatus;
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart'
    show touchpointCreationServiceProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';

class RecordTouchpointBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordTouchpointBottomSheet({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final gpsData = useState<LocationData?>(null);
    final gpsFailed = useState(false);
    final reason = useState<TouchpointReason?>(null);
    final status = useState<TouchpointStatus?>(null);
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final submitAttempted = useState(false);
    final isSubmitting = useState(false);

    // Rebuild when remarks text changes
    useListenable(remarks);

    final isFormValid = timeIn.value != null &&
        timeOut.value != null &&
        (odometerArrival.value?.isNotEmpty ?? false) &&
        (odometerDeparture.value?.isNotEmpty ?? false) &&
        gpsData.value != null &&
        !gpsFailed.value &&
        reason.value != null &&
        status.value != null &&
        remarks.text.trim().isNotEmpty &&
        photoPath.value != null;

    Future<void> handleSubmit() async {
      submitAttempted.value = true;
      if (!isFormValid) return;

      isSubmitting.value = true;
      try {
        final now = DateTime.now();
        final timeInDt = DateTime(
            now.year, now.month, now.day, timeIn.value!.hour, timeIn.value!.minute);
        final timeOutDt = DateTime(
            now.year, now.month, now.day, timeOut.value!.hour, timeOut.value!.minute);
        final gps = gpsData.value!;

        final touchpoint = Touchpoint(
          id: '',
          clientId: client.id!,
          touchpointNumber: client.nextTouchpointNumber ?? client.touchpointNumber,
          type: TouchpointType.visit,
          reason: reason.value!,
          status: status.value!,
          date: now,
          createdAt: now,
          userId: '',
          remarks: remarks.text.trim(),
          photoPath: null,
          audioPath: null,
          timeIn: timeInDt,
          timeOut: timeOutDt,
          timeInGpsLat: gps.lat,
          timeInGpsLng: gps.lng,
          timeInGpsAddress: gps.address,
          timeOutGpsLat: gps.lat,
          timeOutGpsLng: gps.lng,
          timeOutGpsAddress: gps.address,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
          nextVisitDate: null,
        );

        final service = ref.read(touchpointCreationServiceProvider);
        await service.createTouchpoint(
          client.id!,
          touchpoint,
          photo: photoPath.value != null ? File(photoPath.value!) : null,
          latitude: gps.lat,
          longitude: gps.lng,
          address: gps.address,
        );

        if (context.mounted) {
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

    final touchpointNum = client.nextTouchpointNumber ?? client.touchpointNumber;

    return UnifiedActionBottomSheet(
      icon: Icons.assignment_outlined,
      title: 'Record Touchpoint',
      clientName: client.fullName,
      pensionLabel: client.pensionType.toString(),
      touchpointLabel: 'Touchpoint $touchpointNum of 7',
      submitLabel: 'Record Touchpoint',
      isFormValid: isFormValid,
      isSubmitting: isSubmitting.value,
      onSubmit: handleSubmit,
      cards: [
        ScheduleCard(
          timeIn: timeIn.value,
          timeOut: timeOut.value,
          odometerArrival: odometerArrival.value,
          odometerDeparture: odometerDeparture.value,
          showErrors: submitAttempted.value,
          onTimeInChanged: (t) {
            timeIn.value = t;
            final totalMin = t.hour * 60 + t.minute + 5;
            timeOut.value =
                TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
          },
          onTimeOutChanged: (t) => timeOut.value = t,
          onOdometerArrivalChanged: (v) {
            odometerArrival.value = v;
            final arrival = double.tryParse(v);
            if (arrival != null) {
              odometerDeparture.value = (arrival + 5).toStringAsFixed(0);
            }
          },
          onOdometerDepartureChanged: (v) => odometerDeparture.value = v,
        ),
        LocationCard(
          showError: submitAttempted.value && gpsData.value == null,
          onAcquired: (data) => gpsData.value = data,
          onFailed: () => gpsFailed.value = true,
        ),
        DetailsCard(
          locked: false,
          reason: reason.value,
          status: status.value,
          availableReasons: TouchpointReason.values
              .where((r) => r != TouchpointReason.newReleaseLoan)
              .toList(),
          availableStatuses: [
            TouchpointStatus.interested,
            TouchpointStatus.undecided,
            TouchpointStatus.notInterested,
            TouchpointStatus.completed,
            TouchpointStatus.followUpNeeded,
          ],
          onReasonChanged: (r) => reason.value = r,
          onStatusChanged: (s) => status.value = s,
          showErrors: submitAttempted.value,
        ),
        NotesCard(controller: remarks, showError: submitAttempted.value),
        PhotoCard(
          photoPath: photoPath.value,
          onPhotoTaken: (path) => photoPath.value = path,
          showError: submitAttempted.value,
        ),
      ],
    );
  }
}
