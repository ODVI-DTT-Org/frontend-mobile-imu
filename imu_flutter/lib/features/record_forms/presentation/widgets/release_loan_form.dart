// lib/features/record_forms/presentation/widgets/release_loan_form.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:imu_flutter/shared/widgets/expansion_form_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/time_odometer_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/loan_details_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/photo_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/notes_panel.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/panels/info_banner_panel.dart';
import 'package:imu_flutter/features/record_forms/data/models/release_form_data.dart';
import 'package:imu_flutter/features/clients/data/models/client_model.dart';
import 'package:imu_flutter/services/gps/gps_capture_service.dart';
import 'package:imu_flutter/services/api/approvals_api_service.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/app_notification.dart';

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
  bool _timeExpanded = false;
  bool _detailsExpanded = false;

  @override
  void initState() {
    super.initState();
    _formData = ReleaseFormData.withAutoSetValues(client: widget.client);
    _timeExpanded = true; // Expand first panel by default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Release Loan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            _buildClientHeader(context, widget.client),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InfoBannerPanel(
                title: 'Auto-set Values',
                messages: [
                  'Auto-set: Reason = "New Release Loan"',
                  'Auto-set: Status = "Completed"',
                ],
              ),
            ),
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
            ExpansionFormPanel(
              title: 'Loan Details',
              icon: LucideIcons.fileText,
              isExpanded: _detailsExpanded,
              onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
              summary: _buildLoanDetailsSummary(),
              child: LoanDetailsPanel(
                udiNumber: _formData.udiNumber,
                productType: _formData.productType,
                loanType: _formData.loanType,
                onUdiNumberChanged: (value) => setState(() => _formData = _formData.copyWith(udiNumber: value)),
                onProductTypeChanged: (type) => setState(() => _formData = _formData.copyWith(productType: type)),
                onLoanTypeChanged: (type) => setState(() => _formData = _formData.copyWith(loanType: type)),
                errors: _formData.validationErrors,
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildLoanDetailsSummary() {
    final parts = <String>[];
    if (_formData.udiNumber != null && _formData.udiNumber!.isNotEmpty) {
      parts.add('₱${_formData.udiNumber}');
    }
    if (_formData.productType != null) {
      parts.add(_formData.productType!.displayName);
    }
    if (_formData.loanType != null) {
      parts.add(_formData.loanType!.displayName);
    }
    if (parts.isEmpty) {
      return const Text('Enter loan details');
    }
    return Text(parts.join(' • '));
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    return DateFormat.jm().format(time);
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

      // Validate UDI number is present
      if (_formData.udiNumber == null || _formData.udiNumber!.trim().isEmpty) {
        if (mounted) {
          _showErrorDialog('UDI number is required');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      // Prepare time strings
      final timeInStr = _formData.timeIn != null
          ? '${_formData.timeIn!.hour.toString().padLeft(2, '0')}:${_formData.timeIn!.minute.toString().padLeft(2, '0')}'
          : null;
      final timeOutStr = _formData.calculatedTimeOut != null
          ? '${_formData.calculatedTimeOut!.hour.toString().padLeft(2, '0')}:${_formData.calculatedTimeOut!.minute.toString().padLeft(2, '0')}'
          : null;

      // Submit to API using new v2 approval endpoint with all form fields
      final approvalsApiService = ApprovalsApiService();
      await approvalsApiService.submitLoanReleaseV2(
        clientId: widget.client.id!,
        udiNumber: _formData.udiNumber!.trim(),
        productType: _formData.productType?.apiValue,
        loanType: _formData.loanType?.apiValue,
        timeIn: timeInStr,
        timeOut: timeOutStr,
        odometerIn: _formData.odometerIn,
        odometerOut: _formData.odometerOut,
        latitude: _formData.gpsLatitude,
        longitude: _formData.gpsLongitude,
        address: _formData.gpsAddress,
        photoUrl: _formData.photoPath,
        remarks: _formData.remarks?.trim().isNotEmpty == true ? _formData.remarks : null,
      );

      if (mounted) {
        _showSuccessToast('Loan release submitted for admin approval');
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
    AppNotification.showSuccess(context, message);
  }
}
