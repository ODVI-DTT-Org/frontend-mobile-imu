import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/providers/activity_feed_provider.dart';
import 'package:imu_flutter/features/record_forms/data/models/touchpoint_form_data.dart' show ProductType, LoanType;
import 'package:imu_flutter/services/api/approvals_api_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/shared/providers/app_providers.dart' show currentUserRoleProvider;
import 'package:imu_flutter/core/models/user_role.dart';
import 'package:imu_flutter/services/release/pending_release_service.dart';
import 'package:imu_flutter/services/sync/powersync_service.dart';

class ActivityDetailDialog extends ConsumerStatefulWidget {
  final ActivityItem item;
  final VoidCallback? onEdit;

  const ActivityDetailDialog({super.key, required this.item, this.onEdit});

  static Future<void> show(BuildContext context, {required ActivityItem item, VoidCallback? onEdit}) {
    return showDialog(
      context: context,
      builder: (context) => ActivityDetailDialog(item: item, onEdit: onEdit),
    );
  }

  @override
  ConsumerState<ActivityDetailDialog> createState() => _ActivityDetailDialogState();
}

class _ActivityDetailDialogState extends ConsumerState<ActivityDetailDialog> {
  bool _isEditMode = false;
  bool _isSaving = false;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _remarksCtrl;
  late final TextEditingController _timeInCtrl;
  late final TextEditingController _timeOutCtrl;
  late final TextEditingController _odometerArrivalCtrl;
  late final TextEditingController _odometerDepartureCtrl;
  ProductType? _selectedProductType;
  LoanType? _selectedLoanType;

  @override
  void initState() {
    super.initState();
    // For loan releases, detail IS the UDI number; for touchpoints, extract from format
    final initialReason = widget.item.subtype == ActivitySubtype.loanRelease
        ? (widget.item.detail ?? '')
        : _extractReason(widget.item.detail);
    _reasonCtrl = TextEditingController(text: initialReason);
    _remarksCtrl = TextEditingController(
      text: (widget.item.metadata['remarks'] as String?) ??
          (widget.item.metadata['approvalNotes'] as String?) ??
          (widget.item.metadata['notes'] as String?) ??
          '',
    );
    _timeInCtrl = TextEditingController(
      text: widget.item.metadata['timeIn'] as String? ?? '',
    );
    _timeOutCtrl = TextEditingController(
      text: widget.item.metadata['timeOut'] as String? ?? '',
    );
    _odometerArrivalCtrl = TextEditingController(
      text: widget.item.metadata['odometerArrival'] as String? ?? '',
    );
    _odometerDepartureCtrl = TextEditingController(
      text: widget.item.metadata['odometerDeparture'] as String? ?? '',
    );
    // Initialize product/loan type from metadata for loan release edits
    final rawProductType = widget.item.metadata['productType'] as String?;
    final rawLoanType = widget.item.metadata['loanType'] as String?;
    if (rawProductType != null && rawProductType.isNotEmpty) {
      _selectedProductType = ProductType.values.where(
        (t) => t.apiValue == rawProductType,
      ).firstOrNull;
    }
    if (rawLoanType != null && rawLoanType.isNotEmpty) {
      _selectedLoanType = LoanType.values.where(
        (t) => t.apiValue == rawLoanType,
      ).firstOrNull;
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _remarksCtrl.dispose();
    _timeInCtrl.dispose();
    _timeOutCtrl.dispose();
    _odometerArrivalCtrl.dispose();
    _odometerDepartureCtrl.dispose();
    super.dispose();
  }

  String _extractReason(String? detail) {
    if (detail == null) return '';
    // detail format: "Touchpoint #N • Visit — REASON"
    final idx = detail.indexOf(' — ');
    return idx >= 0 ? detail.substring(idx + 3) : '';
  }

  bool _isLoanRelease() => widget.item.subtype == ActivitySubtype.loanRelease;

  bool _canEdit() {
    final item = widget.item;
    final role = ref.read(currentUserRoleProvider);
    final isManager = role == UserRole.admin ||
        role == UserRole.areaManager ||
        role == UserRole.assistantAreaManager;

    if (item.type == ActivityType.touchpoint) {
      if (isManager) return true;
      // Caravan/Tele: only same-day edits
      final now = DateTime.now();
      final created = item.createdAt;
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }

    // Loan release: editable while pending and within 1 day
    if (_isLoanRelease()) {
      final hoursSinceCreation = DateTime.now().difference(item.createdAt).inHours;
      final isPending = item.status == ActivityStatus.pending;
      final withinWindow = hoursSinceCreation <= 48;
      debugPrint('[ACTIVITY][canEdit] loanRelease: status=${item.status}($isPending) source=${item.source} createdAt=${item.createdAt} hours=$hoursSinceCreation withinWindow=$withinWindow');
      return isPending && withinWindow;
    }

    debugPrint('[ACTIVITY][canEdit] not editable: type=${item.type} subtype=${item.subtype} status=${item.status}');
    return false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (_isLoanRelease()) {
        final udiNumber = _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null;
        final remarks = _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null;
        final timeIn = _timeInCtrl.text.trim().isNotEmpty ? _timeInCtrl.text.trim() : null;
        final timeOut = _timeOutCtrl.text.trim().isNotEmpty ? _timeOutCtrl.text.trim() : null;
        final odometerArrival = _odometerArrivalCtrl.text.trim().isNotEmpty ? _odometerArrivalCtrl.text.trim() : null;
        final odometerDeparture = _odometerDepartureCtrl.text.trim().isNotEmpty ? _odometerDepartureCtrl.text.trim() : null;

        if (widget.item.source == ActivitySource.pendingReleaseQueue) {
          await ref.read(pendingReleaseServiceProvider).update(
            id: widget.item.id,
            udiNumber: udiNumber,
            remarks: remarks,
            productType: _selectedProductType?.apiValue,
            loanType: _selectedLoanType?.apiValue,
            timeIn: timeIn,
            timeOut: timeOut,
            odometerArrival: odometerArrival,
            odometerDeparture: odometerDeparture,
          );
        } else {
          await ref.read(approvalsApiServiceProvider).ownerEditLoanRelease(
            approvalId: widget.item.id,
            udiNumber: udiNumber,
            remarks: remarks,
            productType: _selectedProductType?.apiValue,
            loanType: _selectedLoanType?.apiValue,
            timeIn: timeIn,
            timeOut: timeOut,
            odometerArrival: odometerArrival,
            odometerDeparture: odometerDeparture,
          );
        }
      } else {
        // For touchpoints: get visit_id from the touchpoint record, then update via visits endpoint
        final db = await PowerSyncService.database;
        final rows = await db.getAll(
          'SELECT visit_id FROM touchpoints WHERE id = ?',
          [widget.item.id],
        );

        if (rows.isEmpty) {
          throw Exception('Touchpoint not found');
        }

        final visitId = rows.first['visit_id'] as String?;
        if (visitId == null) {
          throw Exception('Visit ID not found for this touchpoint');
        }

        final jwtAuth = ref.read(jwtAuthProvider);
        final token = jwtAuth.accessToken;
        final dio = Dio(BaseOptions(baseUrl: AppConfig.postgresApiUrl));
        await dio.patch(
          '/visits/$visitId',
          data: {
            if (_reasonCtrl.text.isNotEmpty) 'reason': _reasonCtrl.text.trim(),
            if (_remarksCtrl.text.isNotEmpty) 'remarks': _remarksCtrl.text.trim(),
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
      ref.read(activityFeedProvider.notifier).refresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('[ACTIVITY][edit] save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save changes')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 640),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 24, color: item.statusColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (!_isEditMode && _canEdit())
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    tooltip: 'Edit',
                    onPressed: () {
                      if (widget.onEdit != null) {
                        Navigator.pop(context);
                        widget.onEdit!();
                        return;
                      }
                      setState(() => _isEditMode = true);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(height: 24),

            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: item.statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatusIcon(item.status), size: 14, color: item.statusColor),
                      const SizedBox(width: 6),
                      Text(
                        item.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (item.clientName != null) ...[
              const SizedBox(height: 16),
              _DetailRow(icon: LucideIcons.user, label: 'Client', value: item.clientName!),
            ],

            // Edit form or read-only detail
            if (_isEditMode) ...[
              const SizedBox(height: 16),
              Text(
                _isLoanRelease() ? 'UDI Number' : 'Reason',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              if (_isLoanRelease()) ...[
                const SizedBox(height: 12),
                const Text('Product Type', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                DropdownButtonFormField<ProductType>(
                  value: _selectedProductType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Select product type'),
                  items: ProductType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedProductType = v),
                ),
                const SizedBox(height: 12),
                const Text('Loan Type', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                DropdownButtonFormField<LoanType>(
                  value: _selectedLoanType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Select loan type'),
                  items: LoanType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLoanType = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time In', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _timeInCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'e.g. 09:00 AM',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Time Out', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _timeOutCtrl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              hintText: 'e.g. 11:00 AM',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Odometer In', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _odometerArrivalCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Odometer Out', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _odometerDepartureCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Text('Remarks', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 4),
              TextField(
                controller: _remarksCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  hintText: 'Optional notes...',
                ),
              ),
            ] else
              ..._buildReadOnlyDetails(item),

            const SizedBox(height: 16),
            _DetailRow(icon: LucideIcons.tag, label: 'Type', value: _getTypeLabel(item.type)),

            const SizedBox(height: 24),

            if (_isEditMode)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => setState(() => _isEditMode = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReadOnlyDetails(ActivityItem item) {
    final rows = <Widget>[];
    void add({
      required IconData icon,
      required String label,
      String? value,
    }) {
      final text = value?.trim();
      if (text == null || text.isEmpty) return;
      rows
        ..add(const SizedBox(height: 16))
        ..add(_DetailRow(icon: icon, label: label, value: text));
    }

    if (item.subtype == ActivitySubtype.loanRelease) {
      add(icon: LucideIcons.hash, label: 'UDI Number', value: _metaText('udiNumber') ?? item.detail);
      add(icon: LucideIcons.hash, label: 'Updated UDI', value: _metaText('updatedUdi'));
      add(icon: Icons.inventory_2_outlined, label: 'Product Type', value: _metaText('productType'));
      add(icon: LucideIcons.fileText, label: 'Loan Type', value: _metaText('loanType'));
      add(icon: LucideIcons.alignLeft, label: 'Reason', value: _metaText('reason'));
      add(icon: LucideIcons.alignLeft, label: 'Remarks', value: _metaText('remarks'));
      add(icon: LucideIcons.alignLeft, label: 'Notes', value: _metaText('notes'));
      add(icon: LucideIcons.alignLeft, label: 'Approval Notes', value: _metaText('approvalNotes'));
      add(icon: LucideIcons.clock, label: 'Time In', value: _metaText('timeIn'));
      add(icon: LucideIcons.clock, label: 'Time Out', value: _metaText('timeOut'));
      add(icon: Icons.speed, label: 'Odometer Arrival', value: _metaText('odometerArrival'));
      add(icon: Icons.speed, label: 'Odometer Departure', value: _metaText('odometerDeparture'));
      add(icon: LucideIcons.mapPin, label: 'Location', value: _locationText());
      add(icon: LucideIcons.image, label: 'Photo', value: _photoText());
      add(icon: Icons.event_available_outlined, label: 'Approved At', value: _metaText('approvedAt'));
      if (rows.isEmpty) add(icon: LucideIcons.alignLeft, label: 'Details', value: item.detail);
      return rows;
    }

    if (item.type == ActivityType.touchpoint) {
      add(icon: LucideIcons.hash, label: 'Touchpoint', value: _touchpointNumberText());
      add(icon: Icons.format_list_bulleted, label: 'Touchpoint Type', value: _metaText('touchpointType'));
      add(icon: LucideIcons.calendar, label: 'Date', value: _metaText('date'));
      add(icon: LucideIcons.alignLeft, label: 'Reason', value: _metaText('reason'));
      add(icon: LucideIcons.alignLeft, label: 'Remarks', value: _metaText('notes'));
      add(icon: LucideIcons.activity, label: 'Status', value: _metaText('status'));
      add(icon: LucideIcons.clock, label: 'Time In', value: _metaText('timeIn'));
      add(icon: LucideIcons.clock, label: 'Time Out', value: _metaText('timeOut'));
      add(icon: Icons.speed, label: 'Odometer Arrival', value: _metaText('odometerArrival'));
      add(icon: Icons.speed, label: 'Odometer Departure', value: _metaText('odometerDeparture'));
      add(icon: LucideIcons.phone, label: 'Phone Number', value: _metaText('phoneNumber'));
      add(icon: LucideIcons.phoneCall, label: 'Dial Time', value: _metaText('dialTime'));
      add(icon: Icons.timer_outlined, label: 'Duration', value: _durationText());
      add(icon: LucideIcons.mapPin, label: 'Location', value: _locationText());
      add(icon: LucideIcons.image, label: 'Photo', value: _photoText());
      if (rows.isEmpty) add(icon: LucideIcons.alignLeft, label: 'Details', value: item.detail);
      return rows;
    }

    add(icon: LucideIcons.alignLeft, label: 'Details', value: item.detail);
    return rows;
  }

  String? _metaText(String key) {
    final value = widget.item.metadata[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _touchpointNumberText() {
    final number = _metaText('touchpointNumber');
    return number == null ? null : '#$number';
  }

  String? _durationText() {
    final duration = widget.item.metadata['duration'];
    if (duration == null) return null;
    final seconds = int.tryParse(duration.toString());
    if (seconds == null) return duration.toString();
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return remainder == 0 ? '${minutes}m' : '${minutes}m ${remainder}s';
  }

  String? _locationText() {
    final address = _metaText('address');
    final latitude = _metaText('latitude');
    final longitude = _metaText('longitude');
    if (address != null && latitude != null && longitude != null) {
      return '$address ($latitude, $longitude)';
    }
    if (address != null) return address;
    if (latitude != null && longitude != null) return '$latitude, $longitude';
    return null;
  }

  String? _photoText() {
    final value = _metaText('photoUrl') ?? _metaText('photoPath');
    if (value == null) return null;
    return value;
  }

  String _formatDateTime(DateTime dt) => DateFormat('MMM d, yyyy • h:mm a').format(dt);

  IconData _getStatusIcon(ActivityStatus status) {
    switch (status) {
      case ActivityStatus.pending:   return LucideIcons.clock;
      case ActivityStatus.syncing:   return LucideIcons.refreshCw;
      case ActivityStatus.completed:
      case ActivityStatus.approved:  return LucideIcons.checkCircle;
      case ActivityStatus.rejected:
      case ActivityStatus.failed:    return LucideIcons.xCircle;
    }
  }

  String _getTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.approval:   return 'Approval';
      case ActivityType.touchpoint: return 'Touchpoint';
      case ActivityType.visit:      return 'Visit';
      case ActivityType.call:       return 'Call';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
        ),
      ],
    );
  }
}
