import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../../../shared/widgets/skeletons/itinerary_skeleton.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../services/api/itinerary_api_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../features/clients/data/models/client_model.dart';
import '../../../../shared/providers/app_providers.dart' show clientsProvider;
import '../../../../features/touchpoints/presentation/widgets/touchpoint_form.dart';
import '../../../clients/presentation/pages/edit_client_page.dart';

class ItineraryPage extends ConsumerStatefulWidget {
  const ItineraryPage({super.key});

  @override
  ConsumerState<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends ConsumerState<ItineraryPage> {
  String _selectedTab = 'Today'; // 'Tomorrow', 'Today', 'Yesterday'
  DateTime? _selectedCalendarDate;
  ItineraryItem? _recentlyDeletedVisit;
  int? _recentlyDeletedIndex;

  @override
  void initState() {
    super.initState();
  }

  DateTime get _selectedDate {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 'Tomorrow':
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        return DateTime(yesterday.year, yesterday.month, yesterday.day);
      default: // Today
        return DateTime(now.year, now.month, now.day);
    }
  }

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    ref.invalidate(todayItineraryProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _onVisitTap(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Show action dialog with options
    if (mounted) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(visit.clientName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visit.address != null) ...[
                Text(
                  visit.address!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'edit'),
              child: const Text('Edit Client'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'release'),
              child: const Text('Release Loan'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'visit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Record Visit'),
            ),
          ],
        ),
      );

      if (action == null) return;

      switch (action) {
        case 'visit':
          await _recordVisit(visit);
          break;
        case 'release':
          await _releaseLoan(visit);
          break;
        case 'edit':
          await _editClient(visit);
          break;
      }
    }
  }

  Future<void> _recordVisit(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Get touchpoint number from visit
    final touchpointNumber = visit.touchpointNumber ?? 1;

    // Calculate expected touchpoint type based on touchpoint number (1=Visit, 2=Call, 3=Call, 4=Visit, 5=Call, 6=Call, 7=Visit)
    final touchpointType = TouchpointValidationService.getExpectedTouchpointType(touchpointNumber);
    final touchpointTypeStr = touchpointType == TouchpointType.visit ? 'Visit' : 'Call';

    // Check if touchpoint number is valid (1-7)
    if (touchpointNumber > 7) {
      if (mounted) {
        _showTouchpointCompletionDialog(visit.clientName);
      }
      return;
    }

    // Validate the sequence
    final validation = TouchpointValidationService.validateTouchpointSequence(
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointType,
    );

    if (!validation.isValid) {
      if (mounted) {
        _showValidationError(validation, visit.clientName);
      }
      return;
    }

    // Open the TouchpointForm which handles Time In/Out internally
    final result = await showTouchpointForm(
      context: context,
      clientId: visit.clientId,
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointTypeStr,
      clientName: visit.clientName,
      address: visit.address,
    );

    // Handle form submission result
    if (result != null && mounted) {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Saving touchpoint...',
        operation: () async {
          final myDayApiService = ref.read(myDayApiServiceProvider);
          await myDayApiService.submitVisitForm(visit.clientId, result);

          // Upload selfie if photo was captured
          if (result['photoPath'] != null) {
            await myDayApiService.uploadSelfie(visit.clientId, result['photoPath']);
          }

          // Refresh itinerary to show updated status
          ref.invalidate(todayItineraryProvider);
        },
      );

      // Check if this was the 7th touchpoint
      if (touchpointNumber == 7) {
        _showTouchpointCompletionDialog(visit.clientName);
      }
    }
  }

  Future<void> _releaseLoan(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Show UDI input dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReleaseLoanDialog(clientName: visit.clientName),
    );

    if (result == null || !result['confirmed']) return;

    final udiNumber = result['udi_number'] as String?;

    if (udiNumber == null || udiNumber.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UDI number is required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Submitting loan release...',
      operation: () async {
        final approvalsApi = ref.read(approvalsApiServiceProvider);
        await approvalsApi.submitLoanRelease(
          clientId: visit.clientId,
          udiNumber: udiNumber.trim(),
          notes: 'Loan release requested via mobile app',
        );
        // Refresh itinerary to show updated status
        ref.invalidate(todayItineraryProvider);
      },
    );

    if (mounted) {
      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loan release submitted for approval (UDI: ${udiNumber.trim()})'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _editClient(ItineraryItem visit) async {
    HapticUtils.lightImpact();
    context.push('/clients/${visit.clientId}/edit');
  }

  /// Show dialog when all 7 touchpoints are completed
  void _showTouchpointCompletionDialog(String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          LucideIcons.checkCircle,
          color: Colors.green[600],
          size: 48,
        ),
        title: const Text('All Touchpoints Completed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$clientName has completed all 7 touchpoints.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Touchpoint Sequence Completed:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...TouchpointValidationService.getSequenceDisplay().map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.check,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show validation error dialog
  void _showValidationError(dynamic validation, String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          LucideIcons.alertTriangle,
          color: Colors.orange[600],
          size: 48,
        ),
        title: const Text('Touchpoint Sequence Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cannot record touchpoint for $clientName:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              validation.errorMessage ?? 'Invalid touchpoint sequence',
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
            if (validation.expectedType != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expected: ${validation.expectedType}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addVisit() {
    HapticUtils.lightImpact();
    _showClientSelector();
  }

  void _editVisit(String visitId) {
    HapticUtils.lightImpact();
    final itineraryAsync = ref.read(todayItineraryProvider);
    final targetDate = _selectedCalendarDate ?? _selectedDate;

    itineraryAsync.when(
      data: (items) {
        final filteredItems = items.where((item) {
          final itemDate = item.scheduledDate;
          return itemDate.year == targetDate.year &&
                 itemDate.month == targetDate.month &&
                 itemDate.day == targetDate.day;
        }).toList();

        final visit = filteredItems.firstWhere((v) => v.id == visitId, orElse: null);
        if (visit != null) {
          _showVisitForm(existingVisit: visit);
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _deleteVisit(String visitId) {
    final itineraryAsync = ref.read(todayItineraryProvider);
    final targetDate = _selectedCalendarDate ?? _selectedDate;

    itineraryAsync.when(
      data: (items) {
        final filteredItems = items.where((item) {
          final itemDate = item.scheduledDate;
          return itemDate.year == targetDate.year &&
                 itemDate.month == targetDate.month &&
                 itemDate.day == targetDate.day;
        }).toList();

        final index = filteredItems.indexWhere((v) => v.id == visitId);
        if (index != -1) {
          setState(() {
            _recentlyDeletedVisit = filteredItems[index];
            _recentlyDeletedIndex = index;
          });

          HapticUtils.delete();

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Visit deleted'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: _undoDelete,
              ),
            ),
          );
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _undoDelete() {
    if (_recentlyDeletedVisit != null && _recentlyDeletedIndex != null) {
      setState(() {
        _recentlyDeletedVisit = null;
        _recentlyDeletedIndex = null;
      });

      HapticUtils.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit restored')),
      );
      ref.invalidate(todayItineraryProvider);
    }
  }

  void _showVisitForm({ItineraryItem? existingVisit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VisitFormModal(
        existingVisit: existingVisit?.toJson(),
        selectedDate: _selectedDate,
        ref: ref,
        onSave: (visitData) {
          HapticUtils.success();
          ref.invalidate(todayItineraryProvider);
        },
      ),
    );
  }

  void _showClientSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClientSelectorModal(
        selectedDate: _selectedDate,
        ref: ref,
        onClientAdded: () {
          HapticUtils.success();
          ref.invalidate(todayItineraryProvider);
        },
      ),
    );
  }

  void _navigateToVisit(String address) {
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $address...')),
    );
    // In production, open maps for navigation
  }

  void _callClient(String phone) {
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
    // In production, use url_launcher
  }

  void _showCalendarPicker() {
    HapticUtils.lightImpact();
    showDatePicker(
      context: context,
      initialDate: _selectedCalendarDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    ).then((date) {
      if (date != null) {
        setState(() {
          _selectedCalendarDate = date;
          _selectedTab = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final itineraryAsync = ref.watch(todayItineraryProvider);
    final targetDate = _selectedCalendarDate ?? _selectedDate;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _addVisit,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        child: const Icon(LucideIcons.plus),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header - centered title (per Figma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
              child: Row(
                children: [
                  const Spacer(),
                  const Text(
                    'Itinerary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Tab filter (Tomorrow / Today / Yesterday) with calendar button (per Figma)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 17),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // gray-100
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabPill('Tomorrow', 'Tomorrow'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabPill('Today', 'Today'),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildTabPill('Yesterday', 'Yesterday'),
                  ),
                  const SizedBox(width: 8),
                  // Calendar button
                  GestureDetector(
                    onTap: _showCalendarPicker,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedCalendarDate != null
                            ? const Color(0xFF0F172A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.calendar,
                        size: 20,
                        color: _selectedCalendarDate != null
                            ? Colors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected date indicator (when using calendar)
            if (_selectedCalendarDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_selectedCalendarDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCalendarDate = null;
                          _selectedTab = 'Today';
                        });
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Visits list
            Expanded(
              child: itineraryAsync.when(
                data: (items) {
                  // Debug logging for filtering
                  debugPrint('[ItineraryPage] Filtering items for ${_getSelectedTabLabel()}:');
                  debugPrint('[ItineraryPage] targetDate: $targetDate (local: ${DateTime(targetDate.year, targetDate.month, targetDate.day)})');
                  for (var item in items) {
                    final itemDate = item.scheduledDate;
                    final matches = itemDate.year == targetDate.year &&
                           itemDate.month == targetDate.month &&
                           itemDate.day == targetDate.day;
                    debugPrint('[ItineraryPage] item: ${item.clientName} - scheduledDate: $itemDate (${itemDate.year}-${itemDate.month}-${itemDate.day}) -> matches: $matches');
                  }

                  // Filter items for the selected date
                  final filteredItems = items.where((item) {
                    final itemDate = item.scheduledDate;
                    return itemDate.year == targetDate.year &&
                           itemDate.month == targetDate.month &&
                           itemDate.day == targetDate.day;
                  }).toList();

                  debugPrint('[ItineraryPage] Filtered ${filteredItems.length} items for ${_getSelectedTabLabel()}');

                  if (filteredItems.isEmpty) {
                    return PullToRefresh(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.calendar,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No visits scheduled for ${_getSelectedTabLabel()}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to schedule a visit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'or select a different date',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return PullToRefresh(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final visit = filteredItems[index];
                        return SwipeableListTile(
                          leftActions: [
                            SwipeAction.call(() => _callClient('+63 912 345 6789')),
                            SwipeAction.navigate(() => _navigateToVisit(visit.address ?? '')),
                          ],
                          rightActions: [
                            SwipeAction.edit(() => _editVisit(visit.id)),
                            SwipeAction.delete(() => _deleteVisit(visit.id)),
                          ],
                          onTap: () async {
                            await _onVisitTap(visit);
                          },
                          child: _VisitCard(visit: visit),
                        );
                      },
                    ),
                  );
                },
                loading: () => const ItineraryListSkeleton(itemCount: 7),
                error: (_, __) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 48,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load itinerary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _handleRefresh,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(String tabValue, String label) {
    final isSelected = _selectedTab == tabValue && _selectedCalendarDate == null;
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          _selectedTab = tabValue;
          _selectedCalendarDate = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _getSelectedTabLabel() {
    if (_selectedCalendarDate != null) {
      return DateFormat('MMM d').format(_selectedCalendarDate!);
    }
    return _selectedTab.toLowerCase();
  }
}

class _VisitCard extends StatelessWidget {
  final ItineraryItem visit;

  const _VisitCard({required this.visit});

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'INTERESTED':
        return const Color(0xFF10B981); // Green
      case 'NOT INTERESTED':
        return const Color(0xFFEF4444); // Red
      case 'UNDECIDED':
        return const Color(0xFFF59E0B); // Yellow/Orange
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Touchpoint + Client info
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Touchpoint icon and number
                SizedBox(
                  width: 30,
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 20,
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getOrdinal(visit.touchpointNumber ?? 0),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Client name and agency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.clientName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        visit.address ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Status and notes
          SizedBox(
            width: 133,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(visit.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatStatus(visit.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(visit.status),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    visit.notes!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Visit form modal for adding/editing visits
class _VisitFormModal extends StatefulWidget {
  final Map<String, dynamic>? existingVisit;
  final DateTime? selectedDate;
  final Function(Map<String, dynamic>) onSave;
  final WidgetRef ref;

  const _VisitFormModal({
    this.existingVisit,
    this.selectedDate,
    required this.onSave,
    required this.ref,
  });

  @override
  State<_VisitFormModal> createState() => _VisitFormModalState();
}

class _VisitFormModalState extends State<_VisitFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _timeArrival = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _timeDeparture = const TimeOfDay(hour: 9, minute: 30);
  String _productType = 'SSS Pensioner';
  String _reason = 'INTERESTED';
  int _touchpoint = 1;

  final List<String> _productTypes = [
    'SSS Pensioner',
    'GSIS Pensioner',
    'Private',
  ];

  final List<String> _reasons = [
    'INTERESTED',
    'NOT INTERESTED',
    'UNDECIDED',
    'LOAN INQUIRY',
    'FOR UPDATE',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }
    if (widget.existingVisit != null) {
      _clientNameController.text = widget.existingVisit!['clientName'] ?? '';
      _addressController.text = widget.existingVisit!['address'] ?? '';
      _notesController.text = widget.existingVisit!['notes'] ?? '';
      _productType = widget.existingVisit!['productType'] ?? _productType;
      _reason = widget.existingVisit!['reason'] ?? _reason;
      _touchpoint = widget.existingVisit!['touchpoint'] ?? _touchpoint;

      if (widget.existingVisit!['date'] != null) {
        _selectedDate = DateTime.parse(widget.existingVisit!['date']);
      }
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existingVisit != null ? 'Edit Visit' : 'Add Visit',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Client Name
                      const Text(
                        'Client Name *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter client name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      const Text(
                        'Address *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Enter address',
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date
                      const Text(
                        'Visit Date *',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            suffixIcon: Icon(LucideIcons.calendar),
                          ),
                          child: Text(_formatDate(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time Arrival',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectTime(true),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(LucideIcons.clock, size: 18),
                                    ),
                                    child: Text(_formatTime(_timeArrival)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time Departure',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectTime(false),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      suffixIcon: Icon(LucideIcons.clock, size: 18),
                                    ),
                                    child: Text(_formatTime(_timeDeparture)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Product Type
                      const Text(
                        'Product Type',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _productType,
                        items: _productTypes
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _productType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Touchpoint
                      const Text(
                        'Touchpoint Number',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(7, (index) {
                          final num = index + 1;
                          final isSelected = _touchpoint == num;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticUtils.lightImpact();
                                setState(() => _touchpoint = num);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0F172A) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$num',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Reason
                      const Text(
                        'Reason',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _reason,
                        items: _reasons
                            .map((reason) => DropdownMenuItem(
                                  value: reason,
                                  child: Text(_formatReason(reason)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _reason = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      const Text(
                        'Notes',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText: 'Enter notes (optional)',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _handleSave,
                          child: Text(
                            widget.existingVisit != null
                                ? 'UPDATE VISIT'
                                : 'ADD VISIT',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    HapticUtils.lightImpact();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime(bool isArrival) async {
    HapticUtils.lightImpact();
    final initialTime = isArrival ? _timeArrival : _timeDeparture;
    final time = await showTimePicker(
      context: context,
      initialTime: flutter.TimeOfDay(hour: initialTime.hour, minute: initialTime.minute),
    );
    if (time != null) {
      setState(() {
        final customTime = TimeOfDay(hour: time.hour, minute: time.minute);
        if (isArrival) {
          _timeArrival = customTime;
        } else {
          _timeDeparture = customTime;
        }
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      HapticUtils.success();

      LoadingHelper.withLoading(
        ref: widget.ref,
        message: widget.existingVisit != null ? 'Updating visit...' : 'Adding visit...',
        operation: () async {
          await Future.delayed(const Duration(milliseconds: 500)); // Simulate save

          widget.onSave({
            'clientName': _clientNameController.text,
            'address': _addressController.text,
            'notes': _notesController.text,
            'date': _selectedDate.toIso8601String().split('T')[0],
            'timeArrival': _formatTime(_timeArrival),
            'timeDeparture': _formatTime(_timeDeparture),
            'productType': _productType,
            'pensionType': _productType.contains('SSS') ? 'SSS' : 'GSIS',
            'touchpoint': _touchpoint,
            'reason': _reason,
          });

          if (mounted) {
            Navigator.pop(context);
          }
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save visit: $e')),
            );
          }
        },
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatReason(String reason) {
    return reason
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}

/// Client selector modal for adding clients to itinerary
class _ClientSelectorModal extends StatefulWidget {
  final DateTime selectedDate;
  final Function() onClientAdded;
  final WidgetRef ref;

  const _ClientSelectorModal({
    required this.selectedDate,
    required this.onClientAdded,
    required this.ref,
  });

  @override
  State<_ClientSelectorModal> createState() => _ClientSelectorModalState();
}

class _ClientSelectorModalState extends State<_ClientSelectorModal> {
  final _searchController = TextEditingController();
  List<Client> _allClients = [];
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Set<String> _addingClientIds = {};
  bool _isLoading = true;
  String? _error;
  String _clientFilter = 'assigned'; // 'assigned' or 'all'

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Wait for clients to be loaded
      List<Client> clients = [];
      int retries = 0;

      while (clients.isEmpty && retries < 10) {
        // Use ref.read to get current state
        final clientsAsync = widget.ref.read(clientsProvider);

        clientsAsync.when(
          data: (data) {
            clients = data;
          },
          loading: () {
            // Still loading, wait a bit
          },
          error: (error, _) {
            if (mounted) {
              setState(() {
                _error = error.toString();
                _isLoading = false;
              });
            }
            return;
          },
        );

        if (clients.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries++;
        } else {
          break;
        }
      }

      // Get today's itinerary to filter out already added clients
      final itineraryAsync = widget.ref.read(todayItineraryProvider);
      final today = DateTime.now();

      Set<String> existingClientIds = {};
      itineraryAsync.when(
        data: (items) {
          existingClientIds = items
              .where((item) => item.scheduledDate.year == today.year &&
                             item.scheduledDate.month == today.month &&
                             item.scheduledDate.day == today.day)
              .map((item) => item.clientId)
              .toSet();
        },
        loading: () {},
        error: (_, __) {},
      );

      // Filter out clients already in today's itinerary
      _allClients = clients.where((client) => !existingClientIds.contains(client.id)).toList();

      // Apply filter (assigned vs all)
      _applyClientFilter();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyClientFilter() {
    if (_clientFilter == 'all') {
      _clients = _allClients;
    } else {
      // For 'assigned', show all clients (no municipality filtering in this context)
      // The user can select any client to add to their itinerary
      _clients = _allClients;
    }
    _filterClients(); // Apply search filter
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final fullName = '${client.firstName} ${client.lastName} ${client.middleName ?? ''}'.toLowerCase();
          final email = (client.email ?? '').toLowerCase();
          return fullName.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _addClientToItinerary(Client client, {DateTime? customDate}) async {
    if (client.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid client: missing ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(client.id!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid client ID format: ${client.id}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _addingClientIds.add(client.id!);
    });

    try {
      final itineraryApi = ItineraryApiService();
      final targetDate = customDate ?? widget.selectedDate;

      // Always use createItinerary to add to the itinerary system
      await itineraryApi.createItinerary(
        clientId: client.id!,
        scheduledDate: targetDate,
        status: 'pending',
        priority: 'normal',
      );

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customDate == null
                ? '${client.firstName} ${client.lastName} added to Today'
                : '${client.firstName} ${client.lastName} added to ${_formatDateShort(customDate)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Remove client from list
        setState(() {
          _clients.remove(client);
          _filterClients();
        });

        // Close modal immediately
        if (mounted) Navigator.pop(context);

        // Trigger parent refresh after modal closes
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onClientAdded();
        });
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        debugPrint('Error adding client to itinerary: $e');

        // Check if it's the specific "already in itinerary" error
        String errorMessage = e.toString();
        if (errorMessage.contains('Client already in today\'s itinerary') ||
            errorMessage.contains('already in today\'s itinerary') ||
            errorMessage.contains('already has an itinerary for this date') ||
            errorMessage.contains('already in My Day')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${client.firstName} ${client.lastName} is already in the itinerary for this date'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add client: ${errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } finally {
      setState(() {
        _addingClientIds.remove(client.id!);
      });
    }
  }

  String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _clientFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _clientFilter = value;
        });
        _applyClientFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Itinerary',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(widget.selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  prefixIcon: const Icon(LucideIcons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _filterClients();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            // Filter toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('Assigned', 'assigned'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All Clients', 'all'),
                ],
              ),
            ),
            // Client list
            Expanded(
              child: _buildClientList(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(ScrollController? scrollController) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Failed to load clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClients,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No clients available' : 'No clients found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'All clients have been added to today\'s itinerary'
                  : 'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        final isAdding = _addingClientIds.contains(client.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client info row
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: client.clientType == ClientType.existing
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Text(
                        '${client.firstName[0]}${client.lastName.isNotEmpty ? client.lastName[0] : ''}',
                        style: TextStyle(
                          color: client.clientType == ClientType.existing ? Colors.green.shade700 : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${client.firstName} ${client.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          if (client.email != null && client.email!.isNotEmpty)
                            Text(
                              client.email!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          if (client.phone != null && client.phone!.isNotEmpty)
                            Text(
                              client.phone!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    if (client.clientType != null)
                      Chip(
                        label: Text(
                          client.clientType!.name.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: client.clientType == ClientType.existing
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: LucideIcons.calendar,
                        label: 'Add to Today',
                        isPrimary: true,
                        isLoading: isAdding,
                        onTap: () => _addClientToItinerary(client),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: LucideIcons.calendarClock,
                        label: 'Add with Date',
                        isPrimary: false,
                        isLoading: isAdding,
                        onTap: () => _showDatePicker(client),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.shade200
              : isPrimary
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? const Color(0xFF0F172A) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              )
            else
              Icon(
                icon,
                size: 14,
                color: isPrimary ? Colors.white : const Color(0xFF0F172A),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLoading
                    ? Colors.grey.shade500
                    : isPrimary
                        ? Colors.white
                        : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDatePicker(Client client) async {
    HapticUtils.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      // Normalize the picked date to midnight to avoid timezone issues
      final normalizedDate = DateTime(picked.year, picked.month, picked.day);
      await _addClientToItinerary(client, customDate: normalizedDate);
    }
  }
}

/// Dialog for Release Loan with UDI number input
class _ReleaseLoanDialog extends StatefulWidget {
  final String clientName;

  const _ReleaseLoanDialog({required this.clientName});

  @override
  State<_ReleaseLoanDialog> createState() => _ReleaseLoanDialogState();
}

class _ReleaseLoanDialogState extends State<_ReleaseLoanDialog> {
  final _udiController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _udiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        LucideIcons.dollarSign,
        color: Colors.green[600],
        size: 48,
      ),
      title: const Text('Release Loan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit loan release request for ${widget.clientName}?',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _udiController,
            decoration: const InputDecoration(
              labelText: 'UDI Number *',
              hintText: 'Enter UDI number...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          Text(
            'This will submit a request for approval. The loan will be marked as released and all touchpoints will be completed.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '⚠️ This action requires approval and cannot be undone.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final udiNumber = _udiController.text.trim();
            if (udiNumber.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UDI number is required'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            if (udiNumber.length > 50) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('UDI number must be 50 characters or less'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'confirmed': true,
              'udi_number': udiNumber,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
