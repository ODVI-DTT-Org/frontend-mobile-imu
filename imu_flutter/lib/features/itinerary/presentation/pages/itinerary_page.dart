import 'dart:io';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../app.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/widgets/offline_banner.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../shared/widgets/skeletons/itinerary_skeleton.dart';
import '../../../../shared/widgets/action_bottom_sheet.dart';
import '../../../../shared/widgets/client_selector_modal.dart';
import '../../../../shared/widgets/client/client_list_card.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../services/api/itinerary_api_service.dart' show ItineraryItem;
import '../../../../services/api/approvals_api_service.dart';
import '../../../../features/itineraries/data/repositories/itinerary_repository.dart' show itineraryByDateProvider, itineraryRepositoryProvider;
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../shared/providers/app_providers.dart' show
    authNotifierProvider,
    hiveServiceProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
import '../../../../shared/utils/permission_helpers.dart';
import '../../../../shared/widgets/touchpoint_history_dialog.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/widgets/touchpoint_validation_dialog.dart';
import '../../../../features/clients/data/models/client_model.dart';
import '../../../../features/clients/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import '../../../../features/clients/presentation/widgets/record_visit_only_bottom_sheet.dart';
import '../../../../features/clients/presentation/widgets/record_loan_release_bottom_sheet.dart';
import '../../../../features/touchpoints/presentation/widgets/touchpoint_form.dart';
import '../../../../shared/widgets/previous_touchpoint_badge.dart';
import '../../../../services/maps/map_service.dart';

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

  // Helper methods for touchpoint creation
  TouchpointStatus _parseTouchpointStatus(String status) {
    switch (status.toLowerCase()) {
      case 'interested': return TouchpointStatus.interested;
      case 'undecided': return TouchpointStatus.undecided;
      case 'not interested': return TouchpointStatus.notInterested;
      case 'completed': return TouchpointStatus.completed;
      default: return TouchpointStatus.interested;
    }
  }

  TouchpointReason _parseTouchpointReason(String reason) {
    switch (reason.toLowerCase()) {
      case 'follow-up': return TouchpointReason.interested;
      case 'documentation': return TouchpointReason.forVerification;
      case 'payment collection': return TouchpointReason.loanInquiry;
      case 'client not available': return TouchpointReason.notAround;
      case 'new loan release': return TouchpointReason.loanInquiry;
      default: return TouchpointReason.interested;
    }
  }

  DateTime? _parseTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    try {
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, hour, minute);
    } catch (e) {
      return null;
    }
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

  Future<void> _onBulkRemove() async {
    if (_selectedVisitIds.isEmpty) {
      showToast('No visits selected');
      return;
    }

    HapticUtils.lightImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Visits'),
        content: Text('Remove ${_selectedVisitIds.length} visit${_selectedVisitIds.length == 1 ? '' : 's'} from itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(itineraryRepositoryProvider);
    for (final id in _selectedVisitIds.toList()) {
      await repo.deleteItinerary(id);
    }
    _exitMultiSelectMode();
    if (mounted) showToast('Visits removed');
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
            icon: LucideIcons.user,
            title: 'View Details',
            description: 'Go to client profile',
            value: 'details',
          ),
          ActionOption(
            icon: LucideIcons.edit,
            title: 'Edit Client',
            description: 'View and update client information',
            value: 'edit',
          ),
          ActionOption(
            icon: LucideIcons.listChecks,
            title: 'Record Touchpoint',
            description: 'Create touchpoint + visit',
            value: 'touchpoint',
          ),
          ActionOption(
            icon: LucideIcons.mapPin,
            title: 'Record Visit Only',
            description: 'Create visit without touchpoint',
            value: 'visit_only',
          ),
          ActionOption(
            icon: LucideIcons.dollarSign,
            title: 'Release Loan',
            description: 'Record loan release',
            value: 'release_loan',
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
        case 'touchpoint':
          await _handleRecordTouchpoint(visit);
          break;
        case 'visit_only':
          await _handleRecordVisitOnly(visit);
          break;
        case 'release_loan':
          await _handleReleaseLoan(visit);
          break;
        case 'edit':
          await _editClient(visit);
          break;
        case 'details':
          await _viewDetails(visit);
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

    // RBAC: Check if user can create this touchpoint number based on their role
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role;

    // BUG FIX: Check BOTH touchpoint number AND type
    if (userRole == null ||
        !isValidTouchpointNumberForRole(touchpointNumber, userRole) ||
        (touchpointType != null && !isValidTouchpointTypeForRole(touchpointType, userRole))) {
      // User's role doesn't allow this touchpoint number or type
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => TouchpointValidationDialog(
            attemptedNumber: touchpointNumber,
            attemptedType: touchpointType,
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
      return;
    }

    // Open the TouchpointForm which handles submission internally
    await showTouchpointForm(
      context: context,
      clientId: visit.clientId,
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointTypeStr,
      clientName: visit.clientName,
      address: visit.address,
    );
    // Note: The form submits directly to the API and handles success/error internally
  }

  Future<void> _handleRecordTouchpoint(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);

    // Show as bottom sheet instead of full screen
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordTouchpointBottomSheet(
        client: fullClient,
      ),
    );

  }

  Future<void> _handleRecordVisitOnly(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);

    // Show as bottom sheet instead of full screen
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordVisitOnlyBottomSheet(
        client: fullClient,
      ),
    );

  }

  Future<void> _handleReleaseLoan(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(visit.clientId);
    if (clientData == null) {
      if (mounted) {
        AppNotification.showError(context, 'Client not found');
      }
      return;
    }
    final fullClient = Client.fromJson(clientData);

    // Show as bottom sheet instead of full screen
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordLoanReleaseBottomSheet(
        client: fullClient,
      ),
    );

  }

  Future<void> _releaseLoan(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // Navigate to unified Release Loan form
    final result = await context.push<bool>('/release-loan/${visit.clientId}');

    // If form was submitted successfully, refresh itinerary data
    if (result == true && mounted) {
      HapticUtils.success();
    }
  }

  Future<void> _editClient(ItineraryItem visit) async {
    HapticUtils.lightImpact();
    context.push('/clients/${visit.clientId}/edit');
  }

  Future<void> _viewDetails(ItineraryItem visit) async {
    HapticUtils.lightImpact();
    if (mounted && visit.clientId != null) {
      context.push('/clients/${visit.clientId}');
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
    final targetDate = _selectedCalendarDate ?? _selectedDate;
    final itineraryAsync = ref.read(itineraryByDateProvider(targetDate));

    itineraryAsync.when(
      data: (items) {
        final visit = items.where((v) => v.id == visitId && v.status != 'completed').firstOrNull;
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
      final targetDate = _selectedCalendarDate ?? _selectedDate;
      final currentItems = ref.read(itineraryByDateProvider(targetDate)).valueOrNull ?? [];
      final index = currentItems.indexWhere((v) => v.id == visitId && v.status != 'completed');
      if (index != -1) {
        setState(() {
          _recentlyDeletedVisit = currentItems[index];
          _recentlyDeletedIndex = index;
        });
      }

      final repo = ref.read(itineraryRepositoryProvider);
      await repo.deleteItinerary(visitId);

      if (mounted) {
        HapticUtils.delete();
        showToast('Visit deleted');
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
      },
      title: 'Add to Itinerary',
      showAssignedFilter: true,
    );
  }

  Future<void> _navigateToVisit(ItineraryItem visit) async {
    HapticUtils.lightImpact();

    // If coordinates are available, use them for navigation
    if (visit.latitude != null && visit.longitude != null) {
      final mapService = MapService();
      final success = await mapService.openGoogleMapsNavigation(
        latitude: visit.latitude!,
        longitude: visit.longitude!,
        label: visit.clientName,
      );

      if (!success && mounted) {
        showToast('Unable to open navigation. Please install Google Maps.');
      }
    } else if (visit.address != null && visit.address!.isNotEmpty) {
      // Fallback to showing address if no coordinates
      showToast('Address: ${visit.address}');
    } else {
      showToast('No address or coordinates available for this client.');
    }
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
    final targetDate = _selectedCalendarDate ?? _selectedDate;
    final itineraryAsync = ref.watch(itineraryByDateProvider(targetDate));

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
            const OfflineBanner(),
            // Header - centered title (per Figma)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

            const SizedBox(height: 16),

            // Tab filter (Tomorrow / Today / Yesterday) with calendar button (per Figma)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9), // gray-100
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabPill('Tomorrow', 'Tomorrow'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTabPill('Today', 'Today'),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTabPill('Yesterday', 'Yesterday'),
                  ),
                  const SizedBox(width: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCalendarDate = null;
                          _selectedTab = 'Today';
                        });
                      },
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Multi-select header buttons (shown only in multi-select mode)
            if (_isMultiSelectMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _MultiSelectHeaderButtons(
                  selectedCount: _selectedVisitIds.length,
                  onRemove: _onBulkRemove,
                  onCancel: _exitMultiSelectMode,
                ),
              ),

            // Visits list
            Expanded(
              child: itineraryAsync.when(
                data: (items) {
                  final filteredItems = items.where((item) => item.status != 'completed').toList();

                  if (filteredItems.isEmpty) {
                    return PullToRefresh(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                  const SizedBox(height: 24),
                                  Text(
                                    'No visits scheduled for ${_getSelectedTabLabel()}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tap the + button to schedule a visit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final visit = filteredItems[index];

                        // In multi-select mode, don't use SwipeableListTile
                        if (_isMultiSelectMode) {
                          return GestureDetector(
                            onLongPress: () => _onVisitLongPress(visit),
                            onTap: () => _onVisitTap(visit),
                            child: ClientListCard.fromItineraryItem(
                              itineraryItem: visit,
                              onTap: () => _onVisitTap(visit),
                              onLongPress: () => _onVisitLongPress(visit),
                              isSelected: _isVisitSelected(visit.id),
                              isMultiSelectMode: true,
                            ),
                          );
                        }

                        return SwipeableListTile(
                          leftActions: [
                            SwipeAction.call(() => _callClient('+63 912 345 6789')),
                            SwipeAction.navigate(() => _navigateToVisit(visit)),
                          ],
                          rightActions: [
                            SwipeAction.edit(() => _editVisit(visit.id)),
                            SwipeAction.delete(() => _deleteVisit(visit.id)),
                          ],
                          onTap: () async {
                            await _onVisitTap(visit);
                          },
                          onLongPress: () => _onVisitLongPress(visit),
                          child: ClientListCard.fromItineraryItem(
                            itineraryItem: visit,
                            onTap: () => _onVisitTap(visit),
                            onLongPress: () => _onVisitLongPress(visit),
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
                // Touchpoint info badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // Next touchpoint badge (from ItineraryItem)
                    if (visit.touchpointNumber != null && visit.touchpointType != null)
                      _buildNextTouchpointBadge(
                        visit.touchpointNumber!,
                        visit.touchpointType!,
                      ),
                    // Previous touchpoint badge (from ItineraryItem)
                    if (visit.previousTouchpointNumber != null)
                      PreviousTouchpointBadge(
                        touchpointNumber: visit.previousTouchpointNumber,
                        touchpointType: visit.previousTouchpointType,
                        touchpointReason: visit.previousTouchpointReason,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Previous touchpoint date
                if (visit.previousTouchpointDate != null)
                  Row(
                    children: [
                      Text(
                        'Last activity: ',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d').format(visit.previousTouchpointDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
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

  Widget _buildNextTouchpointBadge(int touchpointNumber, String touchpointType) {
    final isVisit = touchpointType.toLowerCase() == 'visit';
    final badgeColor = isVisit ? const Color(0xFF3B82F6) : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVisit ? LucideIcons.mapPin : LucideIcons.phone,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$touchpointNumber/7 • ${isVisit ? 'Visit' : 'Call'}',
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
  String _productType = 'BFP ACTIVE';
  String _reason = 'INTERESTED';
  int _touchpoint = 1;

  final List<String> _productTypes = [
    'BFP ACTIVE',
    'BFP PENSION',
    'PNP PENSION',
    'NAPOLCOM',
    'BFP STP',
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
            'date': '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
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

/// Multi-select header buttons: Remove, Cancel
class _MultiSelectHeaderButtons extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onRemove;
  final VoidCallback onCancel;

  const _MultiSelectHeaderButtons({
    required this.selectedCount,
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
