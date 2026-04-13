// lib/features/record_forms/presentation/widgets/record_visit_only_form.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/notes_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/info_banner_panel.dart';
import 'package:imu_flutter/features/record_forms/data/models/visit_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';
import 'package:imu_flutter/services/api/my_day_api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _formData = VisitFormData.withAutoSetValues(client: widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Visit Only'),
        leading: IconButton(
          icon: Icon(LucideIcons.x),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildClientHeader(context, widget.client),
            const SizedBox(height: 16),
            TimeOdometerPanel(
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
            const SizedBox(height: 16),
            PhotoPanel(
              photoPath: _formData.photoPath,
              onPhotoCaptured: (path) => setState(() => _formData = _formData.copyWith(photoPath: path)),
              onPhotoRemoved: () => setState(() => _formData = _formData.copyWith(clearPhoto: true)),
              error: _formData.validationErrors['photo'],
            ),
            const SizedBox(height: 16),
            NotesPanel(
              remarks: _formData.remarks,
              onRemarksChanged: (remarks) => setState(() => _formData = _formData.copyWith(remarks: remarks)),
              error: _formData.validationErrors['remarks'],
            ),
            const SizedBox(height: 16),
            InfoBannerPanel(
              messages: [
                'Auto-set: Reason = "Client Not Available"',
                'Auto-set: Status = "Incomplete"',
                'ℹ️ This visit will NOT create a touchpoint',
              ],
            ),
            const SizedBox(height: 24),
            Row(
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
          ],
        ),
      ),
    );
  }

  Widget _buildClientHeader(BuildContext context, Client client) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Client', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(client.fullName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            client.addresses?.firstOrNull?.fullAddress ?? 'No address',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formData.isValid) {
      _showErrorDialog('Please fix all errors before submitting');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Capture GPS (required)
      final gpsService = GPSCaptureService();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
