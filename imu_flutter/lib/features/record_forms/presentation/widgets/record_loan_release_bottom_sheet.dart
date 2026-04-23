import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart' hide TimeOfDay, ProductType, LoanType;
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/location_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/loan_details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/photo_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/shared/providers/app_providers.dart'
    show releaseCreationServiceProvider, assignedClientsProvider;
import 'package:imu_flutter/core/utils/app_notification.dart';

class RecordLoanReleaseBottomSheet extends HookConsumerWidget {
  final Client client;

  const RecordLoanReleaseBottomSheet({super.key, required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeIn = useState<TimeOfDay?>(null);
    final timeOut = useState<TimeOfDay?>(null);
    final odometerArrival = useState<String?>(null);
    final odometerDeparture = useState<String?>(null);
    final gpsData = useState<LocationData?>(null);
    final gpsFailed = useState(false);
    final productType = useState<ProductType?>(null);
    final loanType = useState<LoanType?>(null);
    final udiController = useTextEditingController();
    final remarks = useTextEditingController();
    final photoPath = useState<String?>(null);
    final submitAttempted = useState(false);
    final isSubmitting = useState(false);

    useListenable(remarks);
    useListenable(udiController);

    final isFormValid = timeIn.value != null &&
        timeOut.value != null &&
        (odometerArrival.value?.isNotEmpty ?? false) &&
        (odometerDeparture.value?.isNotEmpty ?? false) &&
        gpsData.value != null &&
        !gpsFailed.value &&
        productType.value != null &&
        loanType.value != null &&
        udiController.text.trim().isNotEmpty &&
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
        final service = ref.read(releaseCreationServiceProvider);
        await service.createCompleteLoanRelease(
          clientId: client.id!,
          timeIn: timeInDt.toUtc().toIso8601String(),
          timeOut: timeOutDt.toUtc().toIso8601String(),
          odometerArrival: odometerArrival.value!,
          odometerDeparture: odometerDeparture.value!,
          productType: productType.value!.apiValue,
          loanType: loanType.value!.apiValue,
          udiNumber: udiController.text.trim(),
          remarks: remarks.text.trim(),
          photoPath: photoPath.value,
          latitude: gps.lat,
          longitude: gps.lng,
          address: gps.address,
        );

        if (context.mounted) {
          AppNotification.showSuccess(context, 'Loan release recorded successfully');
          // Invalidate cache to refresh loan released status in clients list
          ref.invalidate(assignedClientsProvider);
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          AppNotification.showError(context, 'Failed to record loan release: $e');
        }
      } finally {
        isSubmitting.value = false;
      }
    }

    return UnifiedActionBottomSheet(
      icon: Icons.monetization_on_outlined,
      title: 'Record Loan Release',
      clientName: client.fullName,
      pensionLabel: client.pensionType.toString(),
      touchpointLabel: 'Touchpoint 7 of 7',
      submitLabel: 'Record Loan Release',
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
        LoanDetailsCard(
          productType: productType.value,
          loanType: loanType.value,
          udiController: udiController,
          onProductTypeChanged: (p) => productType.value = p,
          onLoanTypeChanged: (l) => loanType.value = l,
          showErrors: submitAttempted.value,
        ),
        DetailsCard(
          locked: true,
          reason: null,
          status: null,
          availableReasons: const [],
          availableStatuses: const [],
          onReasonChanged: null,
          onStatusChanged: null,
          showErrors: false,
          lockedReasonLabel: 'New Loan Release',
          lockedStatusLabel: 'Completed',
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
