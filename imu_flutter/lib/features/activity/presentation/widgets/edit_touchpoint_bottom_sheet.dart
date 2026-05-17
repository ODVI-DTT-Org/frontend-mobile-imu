import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/core/utils/app_notification.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/schedule_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/unified_action_bottom_sheet.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class EditTouchpointBottomSheet extends ConsumerStatefulWidget {
  final String touchpointId;
  final String clientName;

  const EditTouchpointBottomSheet({
    super.key,
    required this.touchpointId,
    required this.clientName,
  });

  @override
  ConsumerState<EditTouchpointBottomSheet> createState() =>
      _EditTouchpointBottomSheetState();
}

class _EditTouchpointBottomSheetState
    extends ConsumerState<EditTouchpointBottomSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _submitAttempted = false;
  String? _loadError;

  TouchpointReason? _reason;
  TouchpointStatus? _status;
  final _remarks = TextEditingController();

  String? _touchpointType;
  String? _visitId;
  String? _callId;
  int? _touchpointNumber;

  // Schedule fields (visits only)
  TimeOfDay? _timeIn;
  TimeOfDay? _timeOut;
  String? _odometerArrival;
  String? _odometerDeparture;
  String? _existingTimeInIso;
  String? _existingTimeOutIso;

  bool get _isVisit => _touchpointType == 'Visit';

  bool get _isFormValid {
    final baseValid = _reason != null &&
        _status != null &&
        _remarks.text.trim().isNotEmpty;
    if (!_isVisit) return baseValid;
    return baseValid &&
        _timeIn != null &&
        _timeOut != null &&
        (_odometerArrival?.isNotEmpty ?? false) &&
        (_odometerDeparture?.isNotEmpty ?? false);
  }

  @override
  void initState() {
    super.initState();
    _remarks.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  TimeOfDay? _parseTimeOfDay(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return null;
    }
  }

  // Preserves the original date; only replaces the hour/minute component.
  String _applyTimeOfDay(String? existingIso, TimeOfDay tod) {
    DateTime base;
    try {
      base = existingIso != null && existingIso.isNotEmpty
          ? DateTime.parse(existingIso).toLocal()
          : DateTime.now();
    } catch (_) {
      base = DateTime.now();
    }
    return DateTime(base.year, base.month, base.day, tod.hour, tod.minute)
        .toIso8601String();
  }

  Future<void> _loadData() async {
    try {
      final db = await PowerSyncService.database;

      final rows = await db.getAll(
        'SELECT type, status, notes, visit_id, call_id, touchpoint_number FROM touchpoints WHERE id = ?',
        [widget.touchpointId],
      );

      if (rows.isEmpty) {
        setState(() {
          _loadError = 'Touchpoint not found.';
          _isLoading = false;
        });
        return;
      }

      final row = rows.first;
      _touchpointType = row['type'] as String? ?? 'Visit';
      _visitId = row['visit_id'] as String?;
      _callId = row['call_id'] as String?;
      _touchpointNumber = row['touchpoint_number'] as int?;

      final statusStr = row['status'] as String? ?? '';
      final notesStr = row['notes'] as String? ?? '';

      String? reasonStr;
      if (_visitId != null) {
        final visitRows = await db.getAll(
          'SELECT reason, time_in, time_out, odometer_arrival, odometer_departure FROM visits WHERE id = ?',
          [_visitId!],
        );
        if (visitRows.isNotEmpty) {
          final v = visitRows.first;
          reasonStr = v['reason'] as String?;
          _existingTimeInIso = v['time_in'] as String?;
          _existingTimeOutIso = v['time_out'] as String?;
          _odometerArrival = v['odometer_arrival'] as String?;
          _odometerDeparture = v['odometer_departure'] as String?;
        }
      } else if (_callId != null) {
        final callRows = await db.getAll(
          'SELECT reason FROM calls WHERE id = ?',
          [_callId!],
        );
        if (callRows.isNotEmpty) {
          reasonStr = callRows.first['reason'] as String?;
        }
      }

      setState(() {
        _status = statusStr.isNotEmpty
            ? TouchpointStatus.fromApi(statusStr)
            : null;
        _reason = (reasonStr != null && reasonStr.isNotEmpty)
            ? TouchpointReason.fromApi(reasonStr)
            : null;
        _remarks.text = notesStr;
        _timeIn = _parseTimeOfDay(_existingTimeInIso);
        _timeOut = _parseTimeOfDay(_existingTimeOutIso);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _loadError = 'Failed to load touchpoint data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _submitAttempted = true);
    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);
    try {
      final db = await PowerSyncService.database;
      final now = DateTime.now().toIso8601String();
      final notes = _remarks.text.trim();

      await db.execute(
        'UPDATE touchpoints SET status = ?, notes = ?, updated_at = ? WHERE id = ?',
        [_status!.apiValue, notes, now, widget.touchpointId],
      );

      if (_visitId != null) {
        final timeInIso = _applyTimeOfDay(_existingTimeInIso, _timeIn!);
        final timeOutIso = _applyTimeOfDay(_existingTimeOutIso, _timeOut!);
        await db.execute(
          'UPDATE visits SET reason = ?, status = ?, notes = ?, time_in = ?, time_out = ?, odometer_arrival = ?, odometer_departure = ?, updated_at = ? WHERE id = ?',
          [
            _reason!.apiValue,
            _status!.apiValue,
            notes,
            timeInIso,
            timeOutIso,
            _odometerArrival,
            _odometerDeparture,
            now,
            _visitId!,
          ],
        );
      } else if (_callId != null) {
        await db.execute(
          'UPDATE calls SET reason = ?, status = ?, notes = ?, updated_at = ? WHERE id = ?',
          [_reason!.apiValue, _status!.apiValue, notes, now, _callId!],
        );
      }

      if (mounted) {
        AppNotification.showSuccess(context, 'Touchpoint updated successfully');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        AppNotification.showError(context, 'Failed to update: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_loadError!)),
      );
    }

    final tpLabel =
        _touchpointNumber != null ? 'Touchpoint #$_touchpointNumber' : null;

    return UnifiedActionBottomSheet(
      icon: Icons.edit_outlined,
      title: 'Edit Touchpoint',
      clientName: widget.clientName,
      pensionLabel: '',
      touchpointLabel: tpLabel,
      submitLabel: 'Save Changes',
      isFormValid: _isFormValid,
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      cards: [
        if (_isVisit) ...[
          ScheduleCard(
            timeIn: _timeIn,
            timeOut: _timeOut,
            odometerArrival: _odometerArrival,
            odometerDeparture: _odometerDeparture,
            onTimeInChanged: (t) => setState(() => _timeIn = t),
            onTimeOutChanged: (t) => setState(() => _timeOut = t),
            onOdometerArrivalChanged: (v) =>
                setState(() => _odometerArrival = v),
            onOdometerDepartureChanged: (v) =>
                setState(() => _odometerDeparture = v),
            showErrors: _submitAttempted,
          ),
          const SizedBox(height: 12),
        ],
        DetailsCard(
          locked: false,
          reason: _reason,
          status: _status,
          availableReasons: _isVisit
              ? TouchpointReason.visitReasons
              : TouchpointReason.values.toList(),
          availableStatuses: const [
            TouchpointStatus.interested,
            TouchpointStatus.undecided,
            TouchpointStatus.notInterested,
            TouchpointStatus.completed,
            TouchpointStatus.followUpNeeded,
          ],
          onReasonChanged: (r) => setState(() => _reason = r),
          onStatusChanged: (s) => setState(() => _status = s),
          showErrors: _submitAttempted,
        ),
        const SizedBox(height: 12),
        NotesCard(controller: _remarks, showError: _submitAttempted),
      ],
    );
  }
}
