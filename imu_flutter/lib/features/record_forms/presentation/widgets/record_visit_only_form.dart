// lib/features/record_forms/presentation/widgets/record_visit_only_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:imu_flutter/shared/widgets/expansion_form_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/notes_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/info_banner_panel.dart';
import 'package:imu_flutter/features/record_forms/data/models/visit_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/features/record_forms/presentation/providers/record_form_providers.dart';
import 'package:imu_flutter/services/api/my_day_api_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_notification.dart';

class RecordVisitOnlyForm extends ConsumerStatefulWidget {
  final Client client;

  const RecordVisitOnlyForm({
    super.key,
    required this.client,
  });

  @override
  ConsumerState<RecordVisitOnlyForm> createState() => _RecordVisitOnlyFormState();
}

class _RecordVisitOnlyFormState extends ConsumerState<RecordVisitOnlyForm> {
  late VisitFormData _formData;
  bool _isSubmitting = false;
  bool _timeExpanded = false;

  @override
  void initState() {
    super.initState();
    _formData = VisitFormData.withAutoSetValues(client: widget.client);
    _timeExpanded = true; // Expand first panel by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Visit Only'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildClientHeader(context, widget.client),
            const SizedBox(height: 16),
            ExpansionFormPanel(
              title: 'Time & Odometer',
              icon: LucideIcons.clock,
              isExpanded: _timeExpanded,
              onTap: () => setState(() => _timeExpanded = !_timeExpanded),
              summary: _buildTimeSummary(),
              child: TimeOdometerPanel(
                timeIn: _formData.timeIn,
                timeOut: _formData.timeOut,
                odometerIn: _formData.odometerIn,
                odometerOut: _formData.odometerOut,
                onTimeInChanged: (time) => setState(() => _formData = _formData.copyWith(timeIn: time)),
                onTimeOutChanged: (time) => setState(() => _formData = _formData.copyWith(timeOut: time)),
                onOdometerInChanged: (value) => setState(() => _formData = _formData.copyWith(odometerIn: value)),
                onOdometerOutChanged: (value) => setState(() => _formData = _formData.copyWith(odometerOut: value)),
                errors: _formData.validationErrors,
              ),
            ),
            // Photo Panel (single field - no expansion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PhotoPanel(
                photoPath: _formData.photoPath,
                onPhotoCaptured: (path) => setState(() => _formData = _formData.copyWith(photoPath: path)),
                onPhotoRemoved: () => setState(() => _formData = _formData.copyWith(clearPhoto: true)),
                error: _formData.validationErrors['photo'],
              ),
            ),

            const SizedBox(height: 16),

            // Notes Panel (single field - no expansion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NotesPanel(
                remarks: _formData.remarks,
                onRemarksChanged: (remarks) => setState(() => _formData = _formData.copyWith(remarks: remarks)),
                error: _formData.validationErrors['remarks'],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoBannerPanel(
                messages: [
                  'Auto-set: Reason = "Client Not Available"',
                  'Auto-set: Status = "Incomplete"',
                  'ℹ️ This visit will NOT create a touchpoint',
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      child: _isSubmitting
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

  Widget _buildClientHeader(BuildContext context, Client client) {
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
          Text('Client', style: theme.textTheme.labelSmall?.copyWith(fontSize: 11)),
          const SizedBox(height: 3),
          Text(client.fullName, style: theme.textTheme.titleMedium?.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            client.addresses?.firstOrNull?.fullAddress ?? 'No address',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSummary() {
    if (_formData.timeIn != null && _formData.calculatedTimeOut != null) {
      return Text('Time In: ${_formatTime(_formData.timeIn)} • Time Out: ${_formatTime(_formData.calculatedTimeOut)}');
    }
    return const Text('Select time and odometer');
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat.jm().format(time);
  }

  void _handleSubmit() async {
    if (!_formData.isValid) {
      _showErrorDialog('Please fix all errors before submitting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Capture GPS (required)
      final gpsService = ref.read(gpsCaptureServiceProvider);
      final gps = await gpsService.captureLocation();

      // Update form data with GPS
      _formData = _formData.copyWith(
        gpsLatitude: gps.latitude,
        gpsLongitude: gps.longitude,
        gpsAddress: gps.address,
      ) as VisitFormData;

      // Prepare time strings
      final timeArrival = _formData.timeIn != null
          ? '${_formData.timeIn!.hour.toString().padLeft(2, '0')}:${_formData.timeIn!.minute.toString().padLeft(2, '0')}'
          : null;
      final timeDeparture = _formData.calculatedTimeOut != null
          ? '${_formData.calculatedTimeOut!.hour.toString().padLeft(2, '0')}:${_formData.calculatedTimeOut!.minute.toString().padLeft(2, '0')}'
          : null;

      // Submit to API using completeVisit endpoint (visit only, no touchpoint)
      final myDayApiService = MyDayApiService();
      final result = await myDayApiService.completeVisit(
        clientId: widget.client.id!,
        touchpointNumber: 0, // Visit only doesn't create a touchpoint
        type: 'Visit',
        reason: _formData.reason?.apiValue ?? 'CLIENT_NOT_AVAILABLE',
        status: _formData.status?.apiValue ?? 'INCOMPLETE',
        address: _formData.gpsAddress,
        timeArrival: timeArrival,
        timeDeparture: timeDeparture,
        odometerArrival: _formData.odometerIn,
        odometerDeparture: _formData.odometerOut,
        notes: _formData.remarks,
        latitude: _formData.gpsLatitude,
        longitude: _formData.gpsLongitude,
        photoPath: _formData.photoPath,
      );

      if (mounted) {
        _showSuccessToast('Visit recorded successfully');
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
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

  void _showSuccessToast(String message) {
    AppNotification.showSuccess(context, message);
  }
}
