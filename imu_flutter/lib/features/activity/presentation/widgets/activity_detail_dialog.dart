import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/core/config/app_config.dart';
import 'package:imu_flutter/features/activity/data/models/activity_item.dart';
import 'package:imu_flutter/features/activity/providers/activity_feed_provider.dart';
import 'package:imu_flutter/services/api/approvals_api_service.dart';
import 'package:imu_flutter/services/auth/auth_service.dart' show jwtAuthProvider;
import 'package:imu_flutter/shared/providers/app_providers.dart' show currentUserRoleProvider;
import 'package:imu_flutter/core/models/user_role.dart';

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

  @override
  void initState() {
    super.initState();
    // For loan releases, detail IS the UDI number; for touchpoints, extract from format
    final initialReason = widget.item.subtype == ActivitySubtype.loanRelease
        ? (widget.item.detail ?? '')
        : _extractReason(widget.item.detail);
    _reasonCtrl = TextEditingController(text: initialReason);
    _remarksCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _remarksCtrl.dispose();
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
    if (_isLoanRelease() && item.status == ActivityStatus.pending) {
      if (isManager) return true;
      final hoursSinceCreation = DateTime.now().difference(item.createdAt).inHours;
      return hoursSinceCreation <= 24;
    }

    return false;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (_isLoanRelease()) {
        await ref.read(approvalsApiServiceProvider).ownerEditLoanRelease(
          approvalId: widget.item.id,
          udiNumber: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : null,
          remarks: _remarksCtrl.text.trim().isNotEmpty ? _remarksCtrl.text.trim() : null,
        );
      } else {
        final jwtAuth = ref.read(jwtAuthProvider);
        final token = jwtAuth.accessToken;
        final dio = Dio(BaseOptions(baseUrl: AppConfig.postgresApiUrl));
        await dio.patch(
          '/visits',
          queryParameters: {'touchpoint_id': widget.item.id},
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
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
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
                    onPressed: () => setState(() => _isEditMode = true),
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
            ] else if (item.detail != null && item.detail!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _DetailRow(icon: LucideIcons.alignLeft, label: 'Details', value: item.detail!),
            ],

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
    );
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
