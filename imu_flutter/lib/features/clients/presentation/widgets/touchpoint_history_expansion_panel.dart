import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../clients/data/models/client_model.dart';

/// Touchpoint History Expansion Panel
/// Displays the touchpoint history with status indicators
class TouchpointHistoryExpansionPanel extends StatelessWidget {
  final Client client;
  final List<Touchpoint> touchpoints;

  const TouchpointHistoryExpansionPanel({
    super.key,
    required this.client,
    required this.touchpoints,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        'TOUCHPOINT HISTORY',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        '${touchpoints.length} step${touchpoints.length == 1 ? '' : 's'}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7-STEP TOUCHPOINT SEQUENCE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(7, (index) => _buildTouchpointTile(context, index + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTouchpointTile(BuildContext context, int touchpointNumber) {
    final touchpoint = touchpoints.cast<Touchpoint?>().firstWhere(
          (tp) => tp?.touchpointNumber == touchpointNumber,
          orElse: () => null,
        );

    final type = _getExpectedType(touchpointNumber);
    final status = _getTouchpointStatus(touchpoint);
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    final tileContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    'TP$touchpointNumber: ${type.name}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
            if (touchpoint != null) ...[
              const Spacer(),
              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
            ],
          ],
        ),
        if (touchpoint != null) ...[
          const SizedBox(height: 8),
          Text(
            'Date: ${_formatDate(touchpoint!.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          if (touchpoint.userId != null)
            Text(
              'Agent: ${touchpoint.userId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          if (touchpoint.status != null)
            Text(
              'Status: ${touchpoint.status?.name ?? '—'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
        ] else if (status == 'Pending') ...[
          const SizedBox(height: 4),
          Text(
            'Scheduled: ${_getScheduledDate(touchpointNumber)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: touchpoint != null
          ? Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showTouchpointDetailDialog(context, touchpoint),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: tileContent,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12),
              child: tileContent,
            ),
    );
  }

  void _showTouchpointDetailDialog(BuildContext context, Touchpoint tp) {
    final isVisit = tp.type == TouchpointType.visit;
    final statusColor = _getStatusColor('Completed');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isVisit ? Colors.blue[50] : Colors.green[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    bottom: BorderSide(color: isVisit ? Colors.blue[100]! : Colors.green[100]!),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isVisit ? Colors.blue[100] : Colors.green[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVisit ? LucideIcons.mapPin : LucideIcons.phone,
                        size: 18,
                        color: isVisit ? Colors.blue[700] : Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Touchpoint ${tp.touchpointNumber} Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isVisit ? Colors.blue[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isVisit ? 'Visit' : 'Call',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isVisit ? Colors.blue[800] : Colors.green[800],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tp.status.name,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, size: 18, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tpDetailRow(LucideIcons.calendar, 'Date', DateFormat('MMM d, yyyy').format(tp.date)),
                      if (tp.timeIn != null)
                        _tpDetailRow(LucideIcons.logIn, 'Time In', DateFormat('MMM d, y h:mm a').format(tp.timeIn!.toLocal())),
                      if (tp.timeOut != null)
                        _tpDetailRow(LucideIcons.logOut, 'Time Out', DateFormat('MMM d, y h:mm a').format(tp.timeOut!.toLocal())),
                      if (tp.timeInGpsAddress != null)
                        _tpDetailRow(LucideIcons.mapPin, 'Arrival Location', tp.timeInGpsAddress!),
                      if (tp.timeOutGpsAddress != null)
                        _tpDetailRow(LucideIcons.mapPin, 'Departure Location', tp.timeOutGpsAddress!),
                      if (tp.address != null)
                        _tpDetailRow(LucideIcons.home, 'Address', tp.address!),
                      _tpDetailRow(LucideIcons.messageCircle, 'Reason', tp.reason.apiValue),
                      if (tp.userId != null)
                        _tpDetailRow(LucideIcons.user, 'Agent', tp.userId!),
                      if (tp.odometerArrival != null)
                        _tpDetailRow(LucideIcons.gauge, 'Odometer (Arrival)', tp.odometerArrival!),
                      if (tp.odometerDeparture != null)
                        _tpDetailRow(LucideIcons.gauge, 'Odometer (Departure)', tp.odometerDeparture!),
                      if (tp.nextVisitDate != null)
                        _tpDetailRow(LucideIcons.calendarPlus, 'Next Visit Date', DateFormat('MMM d, yyyy').format(tp.nextVisitDate!)),
                      if (tp.rejectionReason != null)
                        _tpDetailRow(LucideIcons.alertCircle, 'Rejection Reason', tp.rejectionReason!),
                      if (tp.remarks != null) ...[
                        const SizedBox(height: 4),
                        Text('Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            tp.remarks!,
                            style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tpDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TouchpointType _getExpectedType(int number) {
    // Touchpoint sequence pattern: Visit → Call → Call → Visit → Call → Call → Visit
    switch (number) {
      case 1:
      case 4:
      case 7:
        return TouchpointType.visit;
      case 2:
      case 3:
      case 5:
      case 6:
        return TouchpointType.call;
      default:
        return TouchpointType.visit;
    }
  }

  String _getTouchpointStatus(Touchpoint? touchpoint) {
    if (touchpoint == null) {
      // Check if this is the next pending touchpoint
      if (client.nextTouchpointNumber != null &&
          touchpoints.length < client.nextTouchpointNumber!) {
        return 'Pending';
      }
      return 'Not Started';
    }
    return 'Completed';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return LucideIcons.checkCircle;
      case 'Pending':
        return LucideIcons.clock;
      default:
        return LucideIcons.circle;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.month}/${date.day}/${date.year}';
  }

  String _getScheduledDate(int touchpointNumber) {
    // Calculate expected date based on previous touchpoint dates
    // This is a simplified calculation - you may want to enhance this
    final lastTouchpoint = touchpoints.isNotEmpty ? touchpoints.last : null;
    if (lastTouchpoint != null) {
      final scheduledDate = lastTouchpoint.date.add(const Duration(days: 7));
      return '${scheduledDate.month}/${scheduledDate.day}/${scheduledDate.year}';
    }
    return 'TBD';
  }
}
