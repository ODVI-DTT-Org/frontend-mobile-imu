import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../../features/visits/data/repositories/visit_repository.dart';

final _cmsVisitsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, clientId) async {
    final repo = ref.read(visitRepositoryProvider);
    final visits = await repo.getByClientId(clientId);
    return visits.map((v) => v.toMap()).toList();
  },
);

/// CMS Visit History Expansion Panel
/// Displays physical visits recorded for a client from the visits table.
class CmsVisitHistoryExpansionPanel extends ConsumerWidget {
  final String clientId;

  const CmsVisitHistoryExpansionPanel({
    super.key,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(_cmsVisitsProvider(clientId));

    return ExpansionTile(
      title: Text(
        'CMS VISIT HISTORY',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      subtitle: Text(
        'Read Only',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      initiallyExpanded: false,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: visitsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildEmptyState('Failed to load visit history'),
            data: (visits) => visits.isEmpty
                ? _buildEmptyState('No CMS visit history recorded')
                : Column(
                    children: visits.map((v) => _buildVisitTile(context, v)).toList(),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.history, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTile(BuildContext context, Map<String, dynamic> visit) {
    final type = visit['type'] == 'release_loan' ? 'Loan Release' : 'Regular Visit';
    final source = visit['source'] as String?;
    final timeIn = visit['time_in'] != null
        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(visit['time_in']).toLocal())
        : null;
    final agentFirst = visit['agent_first_name'] as String?;
    final agentLast = visit['agent_last_name'] as String?;
    final agentName = (agentFirst != null || agentLast != null)
        ? '${agentFirst ?? ''} ${agentLast ?? ''}'.trim()
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.blue[400]!, width: 3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showVisitDetailDialog(context, visit),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                      ),
                    ),
                    if (source != null) ...[
                      const SizedBox(width: 6),
                      Text('via $source', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                    const Spacer(),
                    if (timeIn != null)
                      Text(timeIn, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                  ],
                ),
                if (visit['reason'] != null) ...[
                  const SizedBox(height: 6),
                  Text('Reason: ${visit['reason']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
                if (visit['status'] != null) ...[
                  const SizedBox(height: 2),
                  Text('Status: ${visit['status']}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
                if (visit['notes'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit['notes'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (agentName != null) ...[
                  const SizedBox(height: 4),
                  Text('Agent: $agentName', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVisitDetailDialog(BuildContext context, Map<String, dynamic> visit) {
    final type = visit['type'] == 'release_loan' ? 'Loan Release' : 'Regular Visit';
    final source = visit['source'] as String?;
    final timeIn = visit['time_in'] != null
        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(visit['time_in']).toLocal())
        : null;
    final timeOut = visit['time_out'] != null
        ? DateFormat('MMM d, y h:mm a').format(DateTime.parse(visit['time_out']).toLocal())
        : null;
    final agentFirst = visit['agent_first_name'] as String?;
    final agentLast = visit['agent_last_name'] as String?;
    final agentName = (agentFirst != null || agentLast != null)
        ? '${agentFirst ?? ''} ${agentLast ?? ''}'.trim()
        : null;

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
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clipboardList, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Visit Details',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[800]),
                          ),
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[800]),
                                ),
                              ),
                              if (source != null) ...[
                                const SizedBox(width: 6),
                                Text('via $source', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
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
                      _detailRow(LucideIcons.logIn, 'Time In', timeIn ?? '—'),
                      if (timeOut != null) _detailRow(LucideIcons.logOut, 'Time Out', timeOut),
                      if (visit['reason'] != null)
                        _detailRow(LucideIcons.messageCircle, 'Reason', visit['reason'] as String),
                      if (visit['status'] != null)
                        _detailRow(LucideIcons.tag, 'Status', visit['status'] as String),
                      if (agentName != null)
                        _detailRow(LucideIcons.user, 'Agent', agentName),
                      if (visit['address'] != null)
                        _detailRow(LucideIcons.mapPin, 'Address', visit['address'] as String),
                      if (visit['odometer_arrival'] != null)
                        _detailRow(LucideIcons.gauge, 'Odometer (Arrival)', visit['odometer_arrival'] as String),
                      if (visit['odometer_departure'] != null)
                        _detailRow(LucideIcons.gauge, 'Odometer (Departure)', visit['odometer_departure'] as String),
                      if (visit['notes'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
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
                            visit['notes'] as String,
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

  Widget _detailRow(IconData icon, String label, String value) {
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
}
