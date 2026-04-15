// lib/features/record_forms/presentation/widgets/record_touchpoint_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:imu_flutter/shared/widgets/expansion_form_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/touchpoint_details_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/notes_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/providers/record_form_providers.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_notification.dart';

class RecordTouchpointForm extends ConsumerStatefulWidget {
  final Client client;

  const RecordTouchpointForm({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<RecordTouchpointForm> createState() => _RecordTouchpointFormState();
}

class _RecordTouchpointFormState extends ConsumerState<RecordTouchpointForm> {
  bool _timeExpanded = false;
  bool _detailsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Expand first panel by default
    _timeExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(touchpointFormProvider(widget.client));
    final formNotifier = ref.read(touchpointFormProvider(widget.client).notifier);

    // Show success/error messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (formState.submissionError != null) {
        _showErrorDialog(context, formState.submissionError!);
      } else if (formState.successMessage != null) {
        _showSuccessToast(context, formState.successMessage!);
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Touchpoint'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // Client info header
            _buildClientHeader(context, widget.client, formState.touchpointNumber),

            const SizedBox(height: 16),

            // Time & Odometer Panel
            ExpansionFormPanel(
              title: 'Time & Odometer',
              icon: LucideIcons.clock,
              isExpanded: _timeExpanded,
              onTap: () => setState(() => _timeExpanded = !_timeExpanded),
              summary: _buildTimeSummary(formState.data),
              child: TimeOdometerPanel(
                timeIn: formState.data.timeIn,
                timeOut: formState.data.timeOut,
                odometerIn: formState.data.odometerIn,
                odometerOut: formState.data.odometerOut,
                onTimeInChanged: (time) => formNotifier.updateTimeIn(time),
                onTimeOutChanged: (time) => formNotifier.updateTimeOut(time),
                onOdometerInChanged: (value) => formNotifier.updateOdometerIn(value),
                onOdometerOutChanged: (value) => formNotifier.updateOdometerOut(value),
                errors: formState.data.validationErrors,
              ),
            ),

            // Touchpoint Details Panel
            ExpansionFormPanel(
              title: 'Touchpoint Details',
              icon: LucideIcons.listChecks,
              isExpanded: _detailsExpanded,
              onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
              summary: _buildDetailsSummary(formState.data),
              child: TouchpointDetailsPanel(
                reason: formState.data.reason,
                status: formState.data.status,
                onReasonChanged: (reason) => formNotifier.updateReason(reason),
                onStatusChanged: (status) => formNotifier.updateStatus(status),
                errors: formState.data.validationErrors,
              ),
            ),

            // Photo Panel (single field - no expansion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PhotoPanel(
                photoPath: formState.data.photoPath,
                onPhotoCaptured: (path) => formNotifier.updatePhoto(path),
                onPhotoRemoved: () => formNotifier.updatePhoto(null),
                error: formState.data.validationErrors['photo'],
              ),
            ),

            const SizedBox(height: 16),

            // Notes Panel (single field - no expansion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NotesPanel(
                remarks: formState.data.remarks,
                onRemarksChanged: (remarks) => formNotifier.updateRemarks(remarks),
                error: formState.data.validationErrors['remarks'],
              ),
            ),

            // Submit buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: formState.isSubmitting ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: formState.isSubmitting ? null : () => _handleSubmit(formNotifier),
                      child: formState.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context, Client client, int? touchpointNumber) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            client.fullName,
            style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            client.addresses?.firstOrNull?.fullAddress ?? 'No address',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
          if (touchpointNumber != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Touchpoint #$touchpointNumber of 7',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSummary(TouchpointFormData data) {
    if (data.timeIn != null && data.calculatedTimeOut != null) {
      return Text('Time In: ${_formatTime(data.timeIn)} • Time Out: ${_formatTime(data.calculatedTimeOut)}');
    }
    return const Text('Select time and odometer');
  }

  Widget _buildDetailsSummary(TouchpointFormData data) {
    if (data.reason != null && data.status != null) {
      return Text('${data.reason!.displayName} • ${data.status!.displayName}');
    }
    return const Text('Select reason and status');
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat.jm().format(time);
  }

  void _handleSubmit(TouchpointFormNotifier notifier) async {
    final success = await notifier.submit();
    if (!success && mounted) {
      // Error will be shown via state
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessToast(BuildContext context, String message) {
    AppNotification.showSuccess(context, message);
  }
}
