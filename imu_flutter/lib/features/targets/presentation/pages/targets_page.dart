import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/target_model.dart';

class TargetsPage extends ConsumerStatefulWidget {
  const TargetsPage({super.key});

  @override
  ConsumerState<TargetsPage> createState() => _TargetsPageState();
}

class _TargetsPageState extends ConsumerState<TargetsPage> {
  @override
  Widget build(BuildContext context) {
    final targetAsync = ref.watch(targetsProvider);
    final selectedPeriod = ref.watch(targetPeriodProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('My Targets'),
      ),
      body: Column(
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: TargetPeriod.values.map((period) {
                  final isSelected = selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticUtils.selectionClick();
                        ref.read(targetPeriodProvider.notifier).state = period;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          _getPeriodLabel(period),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: targetAsync.when(
              data: (targets) {
                final target = targets.where((t) => t.period == selectedPeriod).firstOrNull;
                if (target == null) {
                  return const Center(
                    child: Text('No targets found for this period'),
                  );
                }
                return _TargetsContent(target: target);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(TargetPeriod period) {
    switch (period) {
      case TargetPeriod.daily:
        return 'Daily';
      case TargetPeriod.weekly:
        return 'Weekly';
      case TargetPeriod.monthly:
        return 'Monthly';
    }
  }
}

class _TargetsContent extends StatelessWidget {
  final Target target;

  const _TargetsContent({required this.target});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Progress Card
          _OverallProgressCard(target: target),
          const SizedBox(height: 32),

          // Individual Metrics
          const Text(
            'Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _MetricProgressBar(
            label: 'Client Visits',
            completed: target.clientVisitsCompleted,
            total: target.clientVisitsTarget,
            icon: LucideIcons.users,
            color: _getStatusColor(target.status),
          ),
          const SizedBox(height: 16),

          _MetricProgressBar(
            label: 'Touchpoints',
            completed: target.touchpointsCompleted,
            total: target.touchpointsTarget,
            icon: LucideIcons.messageCircle,
            color: _getStatusColor(target.status),
          ),
          const SizedBox(height: 16),

          _MetricProgressBar(
            label: 'New Clients',
            completed: target.newClientsAdded,
            total: target.newClientsTarget,
            icon: LucideIcons.userPlus,
            color: _getStatusColor(target.status),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TargetStatus status) {
    switch (status) {
      case TargetStatus.onTrack:
        return const Color(0xFF22C55E);
      case TargetStatus.atRisk:
        return const Color(0xFFF59E0B);
      case TargetStatus.behind:
        return const Color(0xFFEF4444);
    }
  }
}

class _OverallProgressCard extends StatelessWidget {
  final Target target;

  const _OverallProgressCard({required this.target});

  @override
  Widget build(BuildContext context) {
    final progress = target.overallProgress;
    final status = target.status;
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(status),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TargetStatus status) {
    switch (status) {
      case TargetStatus.onTrack:
        return const Color(0xFF22C55E);
      case TargetStatus.atRisk:
        return const Color(0xFFF59E0B);
      case TargetStatus.behind:
        return const Color(0xFFEF4444);
    }
  }

  String _getStatusText(TargetStatus status) {
    switch (status) {
      case TargetStatus.onTrack:
        return 'On Track';
      case TargetStatus.atRisk:
        return 'At Risk';
      case TargetStatus.behind:
        return 'Behind';
    }
  }
}

class _MetricProgressBar extends StatelessWidget {
  final String label;
  final int completed;
  final int total;
  final IconData icon;
  final Color color;

  const _MetricProgressBar({
    required this.label,
    required this.completed,
    required this.total,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
