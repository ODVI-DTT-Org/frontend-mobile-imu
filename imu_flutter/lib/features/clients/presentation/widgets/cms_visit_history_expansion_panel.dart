import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../../services/api/visit_api_service.dart';

final _cmsVisitsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, clientId) => ref.read(visitApiServiceProvider).getVisitsByClientId(clientId),
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
                    children: visits.map((v) => _buildVisitTile(v)).toList(),
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

  Widget _buildVisitTile(Map<String, dynamic> visit) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: Colors.blue[400]!, width: 3)),
      ),
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
    );
  }
}
