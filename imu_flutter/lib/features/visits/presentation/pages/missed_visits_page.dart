import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/missed_visit_model.dart';
import '../../../../features/clients/data/models/client_model.dart' show TouchpointType;
import '../../../../services/sync/powersync_service.dart';
import '../../../../services/api/missed_visits_api_service.dart';
import '../../../../shared/providers/app_providers.dart';

class MissedVisitsPage extends ConsumerStatefulWidget {
  const MissedVisitsPage({super.key});

  @override
  ConsumerState<MissedVisitsPage> createState() => _MissedVisitsPageState();
}

class _MissedVisitsPageState extends ConsumerState<MissedVisitsPage> {
  final _scrollController = ScrollController();

  List<MissedVisit> _items = [];
  Map<MissedVisitPriority, int> _counts = {};
  MissedVisitPriority? _selectedFilter;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  int _total = 0;

  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _hasMore &&
        !_isLoading) {
      _fetchPage();
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final nextPage = reset ? 1 : _page + 1;
    try {
      final api = ref.read(missedVisitsApiServiceProvider);
      final response = await api.fetchMissedVisits(
        page: nextPage,
        limit: _limit,
        priority: _selectedFilter,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _items = response.items;
          } else {
            _items = [..._items, ...response.items];
          }
          _page = response.page;
          _hasMore = response.hasMore;
          _total = response.total;
          _counts = response.counts;
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
        AppNotification.showError(context, 'Failed to load missed visits');
      }
    }
  }

  void _setFilter(MissedVisitPriority? filter) {
    if (_selectedFilter == filter) return;
    HapticUtils.lightImpact();
    setState(() {
      _selectedFilter = filter;
      _items = [];
      _page = 1;
      _hasMore = true;
      _isInitialLoad = true;
    });
    _fetchPage(reset: true);
  }

  int get _allCount =>
      (_counts[MissedVisitPriority.high] ?? 0) +
      (_counts[MissedVisitPriority.medium] ?? 0) +
      (_counts[MissedVisitPriority.low] ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: Text('Missed Visits ($_total)'),
      ),
      body: Column(
        children: [
          // Filter chips
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
                    count: _allCount,
                    isSelected: _selectedFilter == null,
                    onTap: () => _setFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'High',
                    count: _counts[MissedVisitPriority.high] ?? 0,
                    isSelected: _selectedFilter == MissedVisitPriority.high,
                    color: const Color(0xFFEF4444),
                    onTap: () => _setFilter(MissedVisitPriority.high),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Medium',
                    count: _counts[MissedVisitPriority.medium] ?? 0,
                    isSelected: _selectedFilter == MissedVisitPriority.medium,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _setFilter(MissedVisitPriority.medium),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low',
                    count: _counts[MissedVisitPriority.low] ?? 0,
                    isSelected: _selectedFilter == MissedVisitPriority.low,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _setFilter(MissedVisitPriority.low),
                  ),
                ],
              ),
            ),
          ),

          // List
          Expanded(
            child: _isInitialLoad
                ? _buildSkeleton()
                : _items.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _fetchPage(reset: true),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _items.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _MissedVisitCard(
                              missedVisit: _items[index],
                              onCall: () => _handleCall(_items[index]),
                              onReschedule: () => _handleReschedule(_items[index]),
                              onTap: () => _handleTap(_items[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 160, color: Colors.grey[200]),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.grey[200]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCall(MissedVisit visit) async {
    HapticUtils.lightImpact();

    if (visit.primaryPhone == null || visit.primaryPhone!.isEmpty) {
      if (mounted) {
        AppNotification.showError(context, 'No phone number available');
      }
      return;
    }

    final uri = Uri(scheme: 'tel', path: visit.primaryPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppNotification.showError(context, 'Could not launch phone app');
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
    ).then((date) async {
      if (date != null && mounted) {
        await LoadingHelper.withLoading(
          ref: ref,
          message: 'Rescheduling visit...',
          operation: () async {
            final db = await PowerSyncService.database;
            final userId = ref.read(jwtAuthProvider).currentUser?.id ?? '';
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            final now = DateTime.now().toIso8601String();
            final newId = const Uuid().v4();

            if (visit.source == MissedVisitSource.missedItinerary &&
                visit.itineraryId != null) {
              await db.writeTransaction((tx) async {
                await tx.execute(
                  'UPDATE itineraries SET status = ?, updated_at = ? WHERE id = ?',
                  ['cancelled', now, visit.itineraryId],
                );
                await tx.execute(
                  'INSERT INTO itineraries (id, user_id, client_id, scheduled_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                  [newId, userId, visit.clientId, dateStr, 'pending', now, now],
                );
              });
            } else {
              await db.execute(
                'INSERT INTO itineraries (id, user_id, client_id, scheduled_date, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
                [newId, userId, visit.clientId, dateStr, 'pending', now, now],
              );
            }
          },
          onError: (e) {
            if (mounted) {
              AppNotification.showError(context, 'Failed to reschedule: $e');
            }
          },
        );

        if (mounted) {
          AppNotification.showSuccess(
            context,
            'Rescheduled ${visit.clientName} to ${_formatDate(date)}',
          );
          // Refresh the list to reflect the rescheduled item being removed
          _fetchPage(reset: true);
        }
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

String _formatShortDate(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[date.month - 1]} ${date.day}';
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
                    missedVisit.source == MissedVisitSource.missedItinerary
                        ? 'Scheduled ${_formatShortDate(missedVisit.scheduledDate)}'
                        : 'Last touched ${missedVisit.daysOverdue} days ago',
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
