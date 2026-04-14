import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:imu_flutter/models/touchpoint_model_v2.dart';
import 'package:imu_flutter/models/visit_model.dart';
import 'package:imu_flutter/models/call_model.dart';

/// Touchpoint list widget that displays normalized touchpoints with visit/call details
class TouchpointListWidget extends StatelessWidget {
  final List<TouchpointV2> touchpoints;
  final Map<String, Visit> visits;
  final Map<String, Call> calls;
  final Function(TouchpointV2) onTap;
  final Function(TouchpointV2)? onDelete;

  const TouchpointListWidget({
    super.key,
    required this.touchpoints,
    required this.visits,
    required this.calls,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (touchpoints.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      itemCount: touchpoints.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final touchpoint = touchpoints[index];
        return _buildTouchpointTile(context, touchpoint);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 64,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 16),
          Text(
            'No Touchpoints',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first touchpoint to get started',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchpointTile(BuildContext context, TouchpointV2 touchpoint) {
    final visit = touchpoint.visitId != null ? visits[touchpoint.visitId] : null;
    final call = touchpoint.callId != null ? calls[touchpoint.callId] : null;
    final isVisit = touchpoint.type == 'Visit';

    return InkWell(
      onTap: () => onTap(touchpoint),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Touchpoint Number Badge
            _buildTouchpointNumberBadge(touchpoint.touchpointNumber),
            const SizedBox(width: 12),

            // Icon (Visit/Call)
            _buildTypeIcon(isVisit),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Text(
                        'Touchpoint #${touchpoint.touchpointNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTypeBadge(isVisit),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date
                  Text(
                    _formatDate(touchpoint.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Details based on type
                  if (visit != null) _buildVisitDetails(visit),
                  if (call != null) _buildCallDetails(call),

                  // Rejection Reason (if any)
                  if (touchpoint.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            size: 14,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              touchpoint.rejectionReason!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Delete Button (if provided)
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(LucideIcons.trash2, size: 18),
                color: const Color(0xFFEF4444),
                onPressed: () => onDelete!(touchpoint),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTouchpointNumberBadge(int number) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '#$number',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon(bool isVisit) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isVisit ? const Color(0xFFDBEAFE) : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isVisit ? LucideIcons.mapPin : LucideIcons.phone,
        size: 20,
        color: isVisit ? const Color(0xFF2563EB) : const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildTypeBadge(bool isVisit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isVisit ? const Color(0xFFDBEAFE) : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVisit ? 'VISIT' : 'CALL',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isVisit ? const Color(0xFF1E40AF) : const Color(0xFF4338CA),
        ),
      ),
    );
  }

  Widget _buildVisitDetails(Visit visit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visit.timeIn != null) ...[
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                _formatTime(visit.timeIn!),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              if (visit.timeOut != null) ...[
                const Text(' - ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                Text(_formatTime(visit.timeOut!), style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ],
          ),
        ],
        if (visit.address != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  visit.address!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (visit.status != null) ...[
          const SizedBox(height: 4),
          _buildStatusBadge(visit.status!),
        ],
      ],
    );
  }

  Widget _buildCallDetails(Call call) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.phone, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(
              call.phoneNumber,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        if (call.dialTime != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(call.dialTime!),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
        if (call.duration != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(LucideIcons.timer, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                _formatDuration(call.duration!),
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
        if (call.status != null) ...[
          const SizedBox(height: 4),
          _buildStatusBadge(call.status!),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final (label, color) = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  (String, Color) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return ('COMPLETED', const Color(0xFF10B981));
      case 'pending':
        return ('PENDING', const Color(0xFFF59E0B));
      case 'cancelled':
        return ('CANCELLED', const Color(0xFFEF4444));
      case 'rescheduled':
        return ('RESCHEDULED', const Color(0xFF8B5CF6));
      case 'no_answer':
        return ('NO ANSWER', const Color(0xFFF59E0B));
      case 'busy':
        return ('BUSY', const Color(0xFFEF4444));
      default:
        return (status.toUpperCase(), const Color(0xFF6B7280));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${_formatTime(dateTime)}';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}
