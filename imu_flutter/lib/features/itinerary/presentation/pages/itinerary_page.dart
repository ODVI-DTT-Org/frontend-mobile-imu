import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../shared/widgets/skeletons/itinerary_skeleton.dart';
import '../../../../shared/widgets/action_bottom_sheet.dart';
import '../../../../shared/widgets/client_selector_modal.dart';
import '../../../../shared/widgets/previous_touchpoint_badge.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../services/api/itinerary_api_service.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../shared/widgets/touchpoint_history_dialog.dart';
import '../../../../features/clients/data/models/client_model.dart';
import '../../../../features/touchpoints/presentation/widgets/touchpoint_form.dart';

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

  // Multi-select state
  final Set<String> _selectedVisitIds = {};
  bool _isMultiSelectMode = false;

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

  // Multi-select helper methods
  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedVisitIds.clear();
    });
    HapticUtils.lightImpact();
  }

  void _toggleVisitSelection(String visitId) {
    setState(() {
      if (_selectedVisitIds.contains(visitId)) {
        _selectedVisitIds.remove(visitId);
        if (_selectedVisitIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedVisitIds.add(visitId);
        if (!_isMultiSelectMode) {
          _isMultiSelectMode = true;
        }
      }
    });
    HapticUtils.lightImpact();
  }

  bool _isVisitSelected(String visitId) {
    return _selectedVisitIds.contains(visitId);
  }

  void _onVisitLongPress(ItineraryItem visit) {
    // Enter multi-select mode and select this visit
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
      });
    }
    _toggleVisitSelection(visit.id);
  }

  Future<void> _onBulkSubmitVisit() async {
    if (_selectedVisitIds.isEmpty) return;

    final state = ref.watch(todayItineraryProvider);
    final selectedVisits = state.valueOrNull ?? [];
    final filteredVisits = selectedVisits.where((v) => _selectedVisitIds.contains(v.id)).toList();

    if (filteredVisits.isEmpty) {
      showToast('No visits selected');
      return;
    }

    HapticUtils.lightImpact();

    // Process each selected visit
    for (final visit in filteredVisits) {
      await _recordVisit(visit);
    }

    // Exit multi-select mode after processing
    _exitMultiSelectMode();
  }

  Future<void> _onBulkRemove() async {
    if (_selectedVisitIds.isEmpty) return;

    final state = ref.watch(todayItineraryProvider);
    final selectedVisits = state.valueOrNull ?? [];
    final filteredVisits = selectedVisits.where((v) => _selectedVisitIds.contains(v.id)).toList();

    if (filteredVisits.isEmpty) return;

    HapticUtils.lightImpact();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Selected Visits'),
        content: Text('Remove ${filteredVisits.length} visit(s) from itinerary?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticUtils.lightImpact();
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticUtils.mediumImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete each visit using the API
      for (final visit in filteredVisits) {
        await _deleteVisit(visit.id);
      }
      // Exit multi-select mode after processing
      _exitMultiSelectMode();
    } else {
      _exitMultiSelectMode();
    }
  }

  Future<void> _onVisitTap(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // In multi-select mode, toggle selection instead of showing bottom sheet
    if (_isMultiSelectMode) {
      _toggleVisitSelection(visit.id);
      return;
    }

    // Show action bottom sheet with options
    if (mounted) {
      final action = await ActionBottomSheet.show(
        context,
        title: visit.clientName,
        subtitle: visit.address,
        options: [
          ActionOption(
            icon: LucideIcons.history,
            title: 'View History',
            description: 'See all touchpoints',
            value: 'history',
          ),
          ActionOption(
            icon: LucideIcons.edit,
            title: 'Edit Client',
            description: 'View and update client information',
            value: 'edit',
          ),
          ActionOption(
            icon: LucideIcons.dollarSign,
            title: 'Release Loan',
            description: 'Mark loan as released',
            value: 'release',
          ),
          ActionOption(
            icon: LucideIcons.mapPin,
            title: 'Record Visit',
            description: 'Create a new touchpoint',
            value: 'visit',
          ),
          ActionOption(
            icon: LucideIcons.x,
            title: 'Cancel',
            value: 'cancel',
            isDestructive: true,
          ),
        ],
      );

      if (action == null || action == 'cancel') return;

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
        case 'history':
          await _viewHistory(visit);
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
    final notes = result['notes'] as String?;

    if (udiNumber == null || udiNumber.trim().isEmpty) {
      if (mounted) {
        showToast('UDI number is required');
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
          notes: (notes?.trim().isNotEmpty ?? false) ? notes!.trim() : 'Loan release requested via mobile app',
        );
        // Refresh itinerary to show updated status
        ref.invalidate(todayItineraryProvider);
      },
    );

    if (mounted) {
      HapticUtils.success();
      showToast('Loan release submitted for approval (UDI: ${udiNumber.trim()})');
    }
  }

  Future<void> _editClient(ItineraryItem visit) async {
    HapticUtils.lightImpact();
    context.push('/clients/${visit.clientId}/edit');
  }

  Future<void> _viewHistory(ItineraryItem visit) async {
    HapticUtils.lightImpact();
    if (mounted) {
      await TouchpointHistoryDialog.show(
        context,
        clientId: visit.clientId,
        clientName: visit.clientName,
      );
    }
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

  Future<void> _deleteVisit(String visitId) async {
    try {
      final itineraryApi = ref.read(itineraryApiServiceProvider);

      // Call API to delete from database
      await itineraryApi.deleteItinerary(visitId);

      if (mounted) {
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
              showToast('Visit deleted');
            }
          },
          loading: () {},
          error: (_, __) {},
        );

        // Invalidate provider to refresh the list
        ref.invalidate(todayItineraryProvider);
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        showToast('Failed to delete visit: $e');
      }
    }
  }

  void _undoDelete() {
    if (_recentlyDeletedVisit != null && _recentlyDeletedIndex != null) {
      setState(() {
        _recentlyDeletedVisit = null;
        _recentlyDeletedIndex = null;
      });

      HapticUtils.lightImpact();
      showToast('Visit restored');
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
    ClientSelectorModal.show(
      context,
      selectedDate: _selectedDate,
      onClientAdded: () {
        HapticUtils.success();
        ref.invalidate(todayItineraryProvider);
      },
      title: 'Add to Itinerary',
      showAssignedFilter: true,
    );
  }

  void _navigateToVisit(String address) {
    HapticUtils.lightImpact();
    showToast('Navigating to $address...');
    // In production, open maps for navigation
  }

  void _callClient(String phone) {
    HapticUtils.lightImpact();
    showToast('Calling $phone...');
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

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (_isMultiSelectMode && !didPop) {
          _exitMultiSelectMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton(
          onPressed: _addVisit,
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
        body: GestureDetector(
          // Handle tap outside to exit multi-select mode
          onTap: () {
            if (_isMultiSelectMode) {
              _exitMultiSelectMode();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
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

            // Multi-select header buttons (shown only in multi-select mode)
            if (_isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 8),
                child: _MultiSelectHeaderButtons(
                  selectedCount: _selectedVisitIds.length,
                  onSubmitVisit: _onBulkSubmitVisit,
                  onRemove: _onBulkRemove,
                  onCancel: _exitMultiSelectMode,
                ),
              ),

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

                        // In multi-select mode, don't use SwipeableListTile
                        if (_isMultiSelectMode) {
                          return GestureDetector(
                            onLongPress: () => _onVisitLongPress(visit),
                            onTap: () => _onVisitTap(visit),
                            child: _VisitCard(
                              visit: visit,
                              isSelected: _isVisitSelected(visit.id),
                              isMultiSelectMode: true,
                            ),
                          );
                        }

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
                          onLongPress: () => _onVisitLongPress(visit),
                          child: _VisitCard(
                            visit: visit,
                            isSelected: _isVisitSelected(visit.id),
                            isMultiSelectMode: false,
                          ),
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
  final bool isSelected;
  final bool isMultiSelectMode;

  const _VisitCard({
    required this.visit,
    this.isSelected = false,
    this.isMultiSelectMode = false,
  });

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

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return const Color(0xFFEF4444); // Red
      case 'normal':
        return const Color(0xFF3B82F6); // Blue
      case 'low':
        return const Color(0xFF64748B); // Slate
      default:
        return Colors.grey;
    }
  }

  String _formatPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'HIGH';
      case 'normal':
        return 'NORMAL';
      case 'low':
        return 'LOW';
      default:
        return 'NORMAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 17, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection checkmark indicator (shown in multi-select mode)
          if (isMultiSelectMode)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.check,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
          // Left side: Touchpoint + Client info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Previous touchpoint badge and date row
                Row(
                  children: [
                    PreviousTouchpointBadge(
                      touchpointNumber: visit.previousTouchpointNumber,
                      touchpointType: visit.previousTouchpointType,
                      touchpointReason: visit.previousTouchpointReason,
                    ),
                    const Spacer(),
                    if (visit.previousTouchpointDate != null)
                      Text(
                        DateFormat('MMM d').format(visit.previousTouchpointDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Client name
                Text(
                  visit.clientName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                // Previous reason
                if (visit.previousTouchpointReason != null && visit.previousTouchpointReason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    visit.previousTouchpointReason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Notes
                if (visit.notes != null && visit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.stickyNote,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                // Location (optional, below notes)
                if (visit.address != null && visit.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          visit.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Priority and Status badges (optional, can be removed)
          if (visit.priority != 'normal' || visit.status != 'pending')
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (visit.priority != 'normal') ...[
                    // Priority badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(visit.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getPriorityColor(visit.priority).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _formatPriority(visit.priority),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getPriorityColor(visit.priority),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (visit.status != 'pending')
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getTouchpointIcon(String? touchpointType) {
    if (touchpointType?.toLowerCase() == 'call') {
      return LucideIcons.phone;
    }
    return LucideIcons.mapPin;
  }

  Color _getTouchpointIconColor(String? touchpointType) {
    if (touchpointType?.toLowerCase() == 'call') {
      return const Color(0xFF22C55E); // Green for calls
    }
    return const Color(0xFF3B82F6); // Blue for visits
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
            showToast('Failed to save visit: $e');
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

/// Dialog for Release Loan with UDI number input
class _ReleaseLoanDialog extends StatefulWidget {
  final String clientName;

  const _ReleaseLoanDialog({required this.clientName});

  @override
  State<_ReleaseLoanDialog> createState() => _ReleaseLoanDialogState();
}

class _ReleaseLoanDialogState extends State<_ReleaseLoanDialog> {
  final _udiController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _udiController.dispose();
    _notesController.dispose();
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
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Enter notes (optional)...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
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
              showToast('UDI number is required');
              return;
            }
            if (udiNumber.length > 50) {
              showToast('UDI number must be 50 characters or less');
              return;
            }
            Navigator.pop(context, {
              'confirmed': true,
              'udi_number': udiNumber,
              'notes': _notesController.text.trim(),
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

/// Multi-select header buttons: Submit Visit, Remove, Cancel
class _MultiSelectHeaderButtons extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSubmitVisit;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  const _MultiSelectHeaderButtons({
    required this.selectedCount,
    required this.onSubmitVisit,
    required this.onRemove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selection count text
        Text(
          '$selectedCount visit${selectedCount == 1 ? '' : 's'} selected',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 12),
        // Action buttons
        Row(
          children: [
            // Submit Visit button
            Expanded(
              child: _PillButton(
                icon: const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF0F172A)),
                label: 'Submit Visit',
                onTap: onSubmitVisit,
              ),
            ),
            const SizedBox(width: 12),
            // Remove button
            Expanded(
              child: _PillButton(
                icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                label: 'Remove',
                onTap: onRemove,
                isDestructive: true,
              ),
            ),
            const SizedBox(width: 12),
            // Cancel button
            GestureDetector(
              onTap: () {
                HapticUtils.lightImpact();
                onCancel();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFEF2F2)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFEF4444).withOpacity(0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDestructive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
