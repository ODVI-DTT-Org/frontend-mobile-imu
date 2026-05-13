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
    final sorted = [...touchpoints]..sort((a, b) => b.touchpointNumber.compareTo(a.touchpointNumber));

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
        sorted.isEmpty
            ? 'No touchpoints yet'
            : '${sorted.length} touchpoint${sorted.length == 1 ? '' : 's'}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: sorted.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No touchpoints recorded yet',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sorted.map((tp) => _buildTouchpointTile(context, tp)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTouchpointTile(BuildContext context, Touchpoint touchpoint) {
    final isVisit = touchpoint.type == TouchpointType.visit;
    final typeColor = isVisit ? Colors.purple : Colors.orange;
    final statusLabel = _statusLabel(touchpoint);
    final statusColor = _statusColor(touchpoint);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: typeColor,
            width: 3,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showTouchpointDetailDialog(context, touchpoint),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: number + type + status + date
                Row(
                  children: [
                    Text(
                      '#${touchpoint.touchpointNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      isVisit ? 'Visit' : 'Call',
                      typeColor.withOpacity(0.15),
                      typeColor,
                    ),
                    const SizedBox(width: 6),
                    _chip(statusLabel, statusColor.withOpacity(0.15), statusColor),
                    if (touchpoint.source != null && touchpoint.source!.isNotEmpty)
                      _chip(touchpoint.source!, Colors.grey[200]!, Colors.grey[600]!),
                    const Spacer(),
                    Text(
                      _formatDate(touchpoint.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
                // Reason row
                if (touchpoint.reasonRaw != null && touchpoint.reasonRaw!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(LucideIcons.messageCircle, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formatReason(touchpoint.reasonRaw),
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // Time in/out row
                if (touchpoint.timeIn != null || touchpoint.timeOut != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRange(touchpoint.timeIn, touchpoint.timeOut),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  void _showTouchpointDetailDialog(BuildContext context, Touchpoint tp) {
    final isVisit = tp.type == TouchpointType.visit;
    final statusColor = _statusColor(tp);
    final statusLabel = _statusLabel(tp);

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
                            'Touchpoint #${tp.touchpointNumber}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _chip(
                                isVisit ? 'Visit' : 'Call',
                                isVisit ? Colors.blue[100]! : Colors.green[100]!,
                                isVisit ? Colors.blue[800]! : Colors.green[800]!,
                              ),
                              const SizedBox(width: 6),
                              _chip(
                                statusLabel,
                                statusColor.withOpacity(0.15),
                                statusColor,
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
                      if (tp.source != null && tp.source!.isNotEmpty)
                        _tpDetailRow(LucideIcons.tag, 'Source', tp.source!),
                      if (tp.reasonRaw != null && tp.reasonRaw!.isNotEmpty)
                        _tpDetailRow(LucideIcons.messageCircle, 'Reason', _formatReason(tp.reasonRaw)),
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
                      if (tp.odometerArrival != null)
                        _tpDetailRow(LucideIcons.gauge, 'Odometer (Arrival)', tp.odometerArrival!),
                      if (tp.odometerDeparture != null)
                        _tpDetailRow(LucideIcons.gauge, 'Odometer (Departure)', tp.odometerDeparture!),
                      if (tp.nextVisitDate != null)
                        _tpDetailRow(LucideIcons.calendarPlus, 'Next Visit Date', DateFormat('MMM d, yyyy').format(tp.nextVisitDate!)),
                      if (tp.rejectionReason != null)
                        _tpDetailRow(LucideIcons.alertCircle, 'Rejection Reason', tp.rejectionReason!),
                      if (tp.remarks != null && tp.remarks!.isNotEmpty) ...[
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

  String _statusLabel(Touchpoint tp) {
    // Use the raw string from backend if available (already human-readable)
    if (tp.statusRaw != null && tp.statusRaw!.isNotEmpty) return tp.statusRaw!;
    switch (tp.status) {
      case TouchpointStatus.interested: return 'Interested';
      case TouchpointStatus.undecided: return 'Undecided';
      case TouchpointStatus.notInterested: return 'Not Interested';
      case TouchpointStatus.completed: return 'Completed';
      case TouchpointStatus.followUpNeeded: return 'Follow Up Needed';
      case TouchpointStatus.incomplete: return 'Incomplete';
    }
  }

  Color _statusColor(Touchpoint tp) {
    final label = _statusLabel(tp).toLowerCase();
    if (label.contains('interested') && !label.contains('not')) return Colors.green;
    if (label.contains('not interested')) return Colors.red;
    if (label.contains('undecided')) return Colors.amber[700]!;
    if (label.contains('completed')) return Colors.blue;
    if (label.contains('follow up')) return Colors.orange;
    if (label.contains('incomplete')) return Colors.grey[600]!;
    return Colors.grey[600]!;
  }

  String _formatReason(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    return raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(' ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTimeRange(DateTime? timeIn, DateTime? timeOut) {
    final fmt = DateFormat('h:mm a');
    if (timeIn != null && timeOut != null) {
      return '${fmt.format(timeIn.toLocal())} – ${fmt.format(timeOut.toLocal())}';
    }
    if (timeIn != null) return 'In: ${fmt.format(timeIn.toLocal())}';
    if (timeOut != null) return 'Out: ${fmt.format(timeOut.toLocal())}';
    return '—';
  }
}
