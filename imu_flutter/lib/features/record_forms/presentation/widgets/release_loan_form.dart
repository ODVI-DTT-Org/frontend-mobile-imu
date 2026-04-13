// lib/features/record_forms/presentation/widgets/release_loan_form.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/loan_details_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/notes_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/info_banner_panel.dart';
import 'package:imu_flutter/features/record_forms/data/models/release_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';
import 'package:imu_flutter/services/api/my_day_api_service.dart';

class ReleaseLoanForm extends StatefulWidget {
  final Client client;

  const ReleaseLoanForm({
    super.key,
    required this.client,
  });

  @override
  State<ReleaseLoanForm> createState() => _ReleaseLoanFormState();
}

class _ReleaseLoanFormState extends State<ReleaseLoanForm> {
  late ReleaseFormData _formData;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _formData = ReleaseFormData.withAutoSetValues(client: widget.client);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Loan'),
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
            InfoBannerPanel(
              title: 'Auto-set Values',
              messages: [
                'Auto-set: Reason = "New Release Loan"',
                'Auto-set: Status = "Completed"',
              ],
            ),
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
            LoanDetailsPanel(
              udiNumber: _formData.udiNumber,
              productType: _formData.productType,
              loanType: _formData.loanType,
              onUdiNumberChanged: (value) => setState(() => _formData = _formData.copyWith(udiNumber: value)),
              onProductTypeChanged: (type) => setState(() => _formData = _formData.copyWith(productType: type)),
              onLoanTypeChanged: (type) => setState(() => _formData = _formData.copyWith(loanType: type)),
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
      setState(() {}); // Trigger rebuild to show validation errors
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
      ) as ReleaseFormData;

      // Prepare time strings
      final timeArrival = _formData.timeIn != null
          ? '${_formData.timeIn!.hour.toString().padLeft(2, '0')}:${_formData.timeIn!.minute.toString().padLeft(2, '0')}'
          : null;
      final timeDeparture = _formData.calculatedTimeOut != null
          ? '${_formData.calculatedTimeOut!.hour.toString().padLeft(2, '0')}:${_formData.calculatedTimeOut!.minute.toString().padLeft(2, '0')}'
          : null;

      // Submit to API using completeVisit endpoint with release loan data
      final myDayApiService = MyDayApiService();
      final result = await myDayApiService.completeVisit(
        clientId: widget.client.id!,
        touchpointNumber: 0, // Release loan doesn't create a touchpoint
        type: 'Visit',
        reason: _formData.reason?.apiValue ?? 'NEW_RELEASE_LOAN',
        status: _formData.status?.apiValue ?? 'COMPLETED',
        address: _formData.gpsAddress,
        timeArrival: timeArrival,
        timeDeparture: timeDeparture,
        odometerArrival: _formData.odometerIn,
        odometerDeparture: _formData.odometerOut,
        notes: '${_formData.remarks ?? ''}\n\nUDI: ${_formData.udiNumber ?? ''}\nProduct: ${_formData.productType?.apiValue ?? ''}\nLoan: ${_formData.loanType?.apiValue ?? ''}',
        latitude: _formData.gpsLatitude,
        longitude: _formData.gpsLongitude,
        photoPath: _formData.photoPath,
      );

      if (mounted) {
        _showSuccessToast('Release loan submitted');
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
        title: const Text('Submission Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
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
