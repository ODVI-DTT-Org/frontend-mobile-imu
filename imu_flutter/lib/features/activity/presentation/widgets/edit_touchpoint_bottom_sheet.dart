import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imu_flutter/core/utils/app_notification.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/details_card.dart';
import 'package:imu_flutter/features/record_forms/presentation/widgets/shared/notes_card.dart';
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

  bool get _isFormValid =>
      _reason != null &&
      _status != null &&
      _remarks.text.trim().isNotEmpty;

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
          'SELECT reason FROM visits WHERE id = ?',
          [_visitId!],
        );
        if (visitRows.isNotEmpty) {
          reasonStr = visitRows.first['reason'] as String?;
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
        await db.execute(
          'UPDATE visits SET reason = ?, status = ?, notes = ?, updated_at = ? WHERE id = ?',
          [_reason!.apiValue, _status!.apiValue, notes, now, _visitId!],
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

    final isVisit = _touchpointType == 'Visit';
    final tpLabel = _touchpointNumber != null ? 'Touchpoint #$_touchpointNumber' : null;

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
        DetailsCard(
          locked: false,
          reason: _reason,
          status: _status,
          availableReasons: isVisit
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
