import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/missed_visit_model.dart';

import '../../../../features/clients/data/models/client_model.dart';
class MissedVisitsPage extends ConsumerStatefulWidget {
  const MissedVisitsPage({super.key});

  @override
  ConsumerState<MissedVisitsPage> createState() => _MissedVisitsPageState();
}

class _MissedVisitsPageState extends ConsumerState<MissedVisitsPage> {
  @override
  Widget build(BuildContext context) {
    final missedVisits = ref.watch(filteredMissedVisitsProvider);
    final allMissedVisits = ref.watch(missedVisitsProvider);
    final selectedFilter = ref.watch(missedVisitsFilterProvider);
    final counts = ref.watch(missedVisitsCountProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Missed Visits (${allMissedVisits.length})'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: allMissedVisits.length,
                    isSelected: selectedFilter == null,
                    onTap: () {
                      HapticUtils.lightImpact();
                      ref.read(missedVisitsFilterProvider.notifier).state = null;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High',
                    count: counts[MissedVisitPriority.high] ?? 0,
                    isSelected: selectedFilter == MissedVisitPriority.high,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      HapticUtils.lightImpact();
                      ref.read(missedVisitsFilterProvider.notifier).state = MissedVisitPriority.high;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Medium',
                    count: counts[MissedVisitPriority.medium] ?? 0,
                    isSelected: selectedFilter == MissedVisitPriority.medium,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      HapticUtils.lightImpact();
                      ref.read(missedVisitsFilterProvider.notifier).state = MissedVisitPriority.medium;
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low',
                    count: counts[MissedVisitPriority.low] ?? 0,
                    isSelected: selectedFilter == MissedVisitPriority.low,
                    color: const Color(0xFF3B82F6),
                    onTap: () {
                      HapticUtils.lightImpact();
                      ref.read(missedVisitsFilterProvider.notifier).state = MissedVisitPriority.low;
                    },
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: missedVisits.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    itemCount: missedVisits.length,
                    itemBuilder: (context, index) {
                      return _MissedVisitCard(
                        missedVisit: missedVisits[index],
                        onCall: () => _handleCall(missedVisits[index]),
                        onReschedule: () => _handleReschedule(missedVisits[index]),
                        onTap: () => _handleTap(missedVisits[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleCall(MissedVisit visit) async {
    HapticUtils.lightImpact();

    if (visit.primaryPhone == null || visit.primaryPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No phone number available')),
        );
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: visit.primaryPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  void _handleReschedule(MissedVisit visit) {
    HapticUtils.lightImpact();

    showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    ).then((date) {
      if (date != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rescheduled ${visit.clientName} to ${_formatDate(date)}'),
          ),
        );
        // TODO: Save rescheduled date
      }
    });
  }

  void _handleTap(MissedVisit visit) {
    HapticUtils.lightImpact();
    context.push('/clients/${visit.clientId}');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey[700]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : chipColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : chipColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.white : chipColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkCircle, size: 64, color: Colors.green[400]),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No missed visits at this time',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _MissedVisitCard extends StatelessWidget {
  final MissedVisit missedVisit;
  final VoidCallback onCall;
  final VoidCallback onReschedule;
  final VoidCallback onTap;

  const _MissedVisitCard({
    required this.missedVisit,
    required this.onCall,
    required this.onReschedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(missedVisit.priority);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[100]!),
          ),
        ),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          missedVisit.clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              missedVisit.touchpointType == TouchpointType.visit
                                  ? LucideIcons.mapPin
                                  : LucideIcons.phone,
                              size: 12,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              missedVisit.touchpointOrdinal,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: priorityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${missedVisit.daysOverdue} days overdue',
                    style: TextStyle(
                      fontSize: 12,
                      color: priorityColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(LucideIcons.phone, color: Colors.grey[600]),
                  onPressed: onCall,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(LucideIcons.calendar, color: Colors.grey[600]),
                  onPressed: onReschedule,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(MissedVisitPriority priority) {
    switch (priority) {
      case MissedVisitPriority.high:
        return const Color(0xFFEF4444);
      case MissedVisitPriority.medium:
        return const Color(0xFFF59E0B);
      case MissedVisitPriority.low:
        return const Color(0xFF3B82F6);
    }
  }
}
