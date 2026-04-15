import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../../../shared/widgets/action_bottom_sheet.dart';
import '../../../../shared/widgets/bulk_delete_bottom_sheet.dart';
import '../../../../shared/widgets/client_selector_modal.dart';
import '../../../../shared/widgets/touchpoint_history_dialog.dart';
import '../../../../shared/widgets/touchpoint_validation_dialog.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../shared/providers/app_providers.dart' show
    bulkDeleteApiServiceProvider,
    authNotifierProvider,
    hiveServiceProvider,
    touchpointApiServiceProvider,
    releaseApiServiceProvider,
    uploadApiServiceProvider;
import '../../../../shared/utils/permission_helpers.dart';
import '../../../../features/clients/data/models/client_model.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../providers/my_day_provider.dart';
import '../widgets/header_buttons.dart';
import '../../../../shared/widgets/client/client_list_card.dart';
import '../widgets/multiple_time_in_sheet.dart';
import '../../data/models/my_day_client.dart';
import '../../../clients/presentation/widgets/record_touchpoint_bottom_sheet.dart';
import '../../../clients/presentation/widgets/record_visit_only_bottom_sheet.dart';
import '../../../clients/presentation/widgets/record_loan_release_bottom_sheet.dart';
import '../../../touchpoints/presentation/widgets/touchpoint_form.dart';

class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  // Multi-select state
  final Set<String> _selectedClientIds = {};
  bool _isMultiSelectMode = false;

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Refreshing...',
      operation: () => ref.read(myDayStateProvider.notifier).refresh(),
    );
  }

  // Multi-select helper methods
  void _toggleMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = !_isMultiSelectMode;
      if (!_isMultiSelectMode) {
        _selectedClientIds.clear();
      }
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedClientIds.clear();
    });
    HapticUtils.lightImpact();
  }

  void _toggleClientSelection(String clientId) {
    setState(() {
      if (_selectedClientIds.contains(clientId)) {
        _selectedClientIds.remove(clientId);
        if (_selectedClientIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedClientIds.add(clientId);
        if (!_isMultiSelectMode) {
          _isMultiSelectMode = true;
        }
      }
    });
    HapticUtils.lightImpact();
  }

  bool _isClientSelected(String clientId) {
    return _selectedClientIds.contains(clientId);
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

  Future<void> _onBulkSubmitVisit() async {
    if (_selectedClientIds.isEmpty) return;

    final selectedClients = ref.read(myDayStateProvider).clients.where((c) => _selectedClientIds.contains(c.id)).toList();

    if (selectedClients.isEmpty) {
      showToast('No clients selected');
      return;
    }

    HapticUtils.lightImpact();

    // Process each selected client
    for (final client in selectedClients) {
      await _recordVisit(client);
    }

    // Exit multi-select mode after processing
    _exitMultiSelectMode();
  }

  Future<void> _onBulkRemove() async {
    if (_selectedClientIds.isEmpty) {
      showToast('No clients selected');
      return;
    }

    final selectedClients = ref.read(myDayStateProvider).clients.where((c) => _selectedClientIds.contains(c.id)).toList();

    if (selectedClients.isEmpty) {
      showToast('No clients selected');
      return;
    }

    HapticUtils.lightImpact();

    // Show bulk delete bottom sheet
    await BulkDeleteBottomSheet.show(
      context: context,
      itemIds: _selectedClientIds.toList(),
      itemType: 'clients',
      onDelete: (ids) {
        final bulkDeleteApi = ref.read(bulkDeleteApiServiceProvider);
        return bulkDeleteApi.bulkRemoveFromMyDay(ids);
      },
      onComplete: () {
        _exitMultiSelectMode();
        ref.read(myDayStateProvider.notifier).refresh();
      },
    );
  }

  void _onMultipleTimeIn() {
    HapticUtils.lightImpact();
    final state = ref.read(myDayStateProvider);

    if (state.clients.isEmpty) {
      showToast('No clients available for time-in');
      return;
    }

    MultipleTimeInSheet.show(
      context: context,
      clients: state.clients,
      onBulkTimeIn: (clientIds, address, timestamp) async {
        // Set time-in for all selected clients
        for (final clientId in clientIds) {
          await ref.read(myDayStateProvider.notifier).setTimeIn(clientId, true);
        }

        if (mounted) {
          showToast('Time-in recorded for ${clientIds.length} clients');
        }
      },
    );
  }

  void _onAddNewVisit() {
    HapticUtils.lightImpact();
    // Navigate to add prospect client page
    context.push('/clients/add');
  }

  void _showRecordVisitOptions(BuildContext context) {
    HapticUtils.lightImpact();

    // Show client selector modal to add clients to today's itinerary
    ClientSelectorModal.show(
      context,
      selectedDate: DateTime.now(),
      onClientAdded: () async {
        // Refresh My Day after client is added
        await ref.read(myDayStateProvider.notifier).refresh();
      },
      title: 'Add to My Day',
      showAssignedFilter: true,
    );
  }

  Future<void> _confirmRemoveClient(MyDayClient client) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from My Day'),
        content: Text('Remove ${client.fullName} from today\'s list?'),
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

    if (confirmed == true && mounted) {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Removing ${client.fullName}...',
        operation: () async {
          final myDayApiService = ref.read(myDayApiServiceProvider);
          await myDayApiService.removeFromMyDay(client.clientId);
          if (mounted) {
            HapticUtils.success();
            showToast('${client.fullName} removed from My Day');
            await ref.read(myDayStateProvider.notifier).refresh();
          }
        },
      );
    }
  }

  void _onClientTap(MyDayClient client) async {
    HapticUtils.lightImpact();

    // In multi-select mode, toggle selection instead of showing bottom sheet
    if (_isMultiSelectMode) {
      _toggleClientSelection(client.id);
      return;
    }

    // Show action bottom sheet with options
    if (mounted) {
      final action = await ActionBottomSheet.show(
        context,
        title: client.fullName,
        subtitle: client.location,
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
            icon: LucideIcons.navigation,
            title: 'Navigate',
            description: 'Open navigation to client address',
            value: 'navigate',
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
          await _handleRecordTouchpoint(client);
          break;
        case 'visit_only':
          await _handleRecordVisitOnly(client);
          break;
        case 'release_loan':
          await _handleReleaseLoan(client);
          break;
        case 'edit':
          await _editClient(client);
          break;
        case 'history':
          await _viewHistory(client);
          break;
        case 'navigate':
          await _navigateToClient(client);
          break;
      }
    }
  }

  Future<void> _recordVisit(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Validate the touchpoint sequence
    final touchpointNumber = client.touchpointNumber > 0 ? client.touchpointNumber : 1;

    // Calculate expected touchpoint type based on touchpoint number (enforce sequence)
    final touchpointType = TouchpointValidationService.getExpectedTouchpointType(touchpointNumber);

    // Check if touchpoint number is valid (1-7)
    if (touchpointNumber > 7) {
      if (mounted) {
        _showTouchpointCompletionDialog(client.fullName);
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
        _showValidationError(validation, client.fullName);
      }
      return;
    }

    // RBAC: Check if user can create this touchpoint number based on their role
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.user?.role;

    if (userRole == null || !isValidTouchpointNumberForRole(touchpointNumber, userRole)) {
      // User's role doesn't allow this touchpoint number
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
      clientId: client.clientId,
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointType == TouchpointType.visit ? 'Visit' : 'Call',
      clientName: client.fullName,
      address: client.location,
    );
    // Note: The form submits directly to the API and handles success/error internally
  }

  Future<void> _handleRecordTouchpoint(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordTouchpointBottomSheet(
        client: fullClient,
        onSubmit: (data) async {
          try {
            // Upload photo first if provided
            String? photoUrl;
            if (data['photo_path'] != null && data['photo_path'].toString().isNotEmpty) {
              final file = File(data['photo_path']);
              final uploadApiService = ref.read(uploadApiServiceProvider);
              final uploadResult = await uploadApiService.uploadPhoto(file);
              if (uploadResult != null) {
                photoUrl = uploadResult.url;
                debugPrint('Photo uploaded: $photoUrl');
              }
            }

            // Create Touchpoint object from form data
            final touchpoint = Touchpoint(
              id: '', // Will be generated by API
              clientId: fullClient.id!,
              touchpointNumber: 1, // Will be calculated by API
              type: data['type'] ?? 'Visit',
              reason: data['reason'] ?? 'Follow-up',
              status: _parseTouchpointStatus(data['status'] ?? 'Interested'),
              date: DateTime.now(),
              createdAt: DateTime.now(),
              userId: '', // Will be set by API
              remarks: data['remarks'],
              photoPath: photoUrl, // Use uploaded photo URL
              audioPath: null,
              timeIn: _parseTime(data['time_in']),
              timeOut: _parseTime(data['time_out']),
              timeInGpsLat: null,
              timeInGpsLng: null,
              timeInGpsAddress: null,
              timeOutGpsLat: null,
              timeOutGpsLng: null,
              timeOutGpsAddress: null,
            );

            // Submit to API
            final touchpointApi = ref.read(touchpointApiServiceProvider);
            final success = await touchpointApi.createTouchpoint(touchpoint) != null;

            if (success && mounted) {
              showToast('Touchpoint recorded successfully');
              await ref.read(myDayStateProvider.notifier).refresh();
            }
            return success;
          } catch (e) {
            if (mounted) {
              showToast('Failed to record touchpoint: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      // Refresh data
      await ref.read(myDayStateProvider.notifier).refresh();
    }
  }

  Future<void> _handleRecordVisitOnly(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordVisitOnlyBottomSheet(
        client: fullClient,
        onSubmit: (data) async {
          try {
            // Upload photo first if provided
            String? photoUrl;
            if (data['photo_path'] != null && data['photo_path'].toString().isNotEmpty) {
              final file = File(data['photo_path']);
              final uploadApiService = ref.read(uploadApiServiceProvider);
              final uploadResult = await uploadApiService.uploadPhoto(file);
              if (uploadResult != null) {
                photoUrl = uploadResult.url;
                debugPrint('Photo uploaded: $photoUrl');
              }
            }

            // Create Touchpoint object from form data
            final touchpoint = Touchpoint(
              id: '', // Will be generated by API
              clientId: fullClient.id!,
              touchpointNumber: 1, // Will be calculated by API
              type: TouchpointType.visit,
              reason: TouchpointReason.notAround,
              status: TouchpointStatus.notInterested,
              date: DateTime.now(),
              createdAt: DateTime.now(),
              userId: '', // Will be set by API
              remarks: null,
              photoPath: photoUrl, // Use uploaded photo URL
              audioPath: null,
              timeIn: _parseTime(data['time_in']),
              timeOut: _parseTime(data['time_out']),
              timeInGpsLat: null,
              timeInGpsLng: null,
              timeInGpsAddress: null,
              timeOutGpsLat: null,
              timeOutGpsLng: null,
              timeOutGpsAddress: null,
            );

            // Submit to API
            final touchpointApi = ref.read(touchpointApiServiceProvider);
            final success = await touchpointApi.createTouchpoint(touchpoint) != null;

            if (success && mounted) {
              showToast('Visit recorded successfully');
              await ref.read(myDayStateProvider.notifier).refresh();
            }
            return success;
          } catch (e) {
            if (mounted) {
              showToast('Failed to record visit: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      await ref.read(myDayStateProvider.notifier).refresh();
    }
  }

  Future<void> _handleReleaseLoan(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Fetch full client by ID
    final hiveService = ref.read(hiveServiceProvider);
    final clientData = hiveService.getClient(client.clientId);
    if (clientData == null) {
      if (mounted) showToast('Client not found');
      return;
    }
    final fullClient = Client.fromJson(clientData);

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => RecordLoanReleaseBottomSheet(
        client: fullClient,
        onSubmit: (data) async {
          try {
            // Submit to API using enhanced release service
            final releaseApiService = ref.read(releaseApiServiceProvider);
            final success = await releaseApiService.createCompleteLoanRelease(
              clientId: fullClient.id!,
              timeIn: data['time_in'],
              timeOut: data['time_out'],
              odometerArrival: data['odometer_arrival'],
              odometerDeparture: data['odometer_departure'],
              productType: data['product_type'],
              loanType: data['loan_type'],
              udiNumber: data['udi_number'],
              remarks: data['remarks'],
              photoPath: data['photo_path'],
            ) != null;

            if (success && context.mounted) {
              showToast('Loan released successfully');
              await ref.read(myDayStateProvider.notifier).refresh();
            }
            return success;
          } catch (e) {
            if (context.mounted) {
              showToast('Failed to release loan: $e');
            }
            return false;
          }
        },
      ),
    );

    if (result == true && mounted) {
      await ref.read(myDayStateProvider.notifier).refresh();
    }
  }

  Future<void> _releaseLoan(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Navigate to unified Release Loan form
    final result = await context.push<bool>('/release-loan/${client.clientId}');

    // If form was submitted successfully, refresh My Day data
    if (result == true) {
      await ref.read(myDayStateProvider.notifier).refresh();
      if (mounted) {
        HapticUtils.success();
      }
    }
  }

  Future<void> _editClient(MyDayClient client) async {
    HapticUtils.lightImpact();
    context.push('/clients/${client.clientId}/edit');
  }

  Future<void> _viewHistory(MyDayClient client) async {
    HapticUtils.lightImpact();
    if (mounted) {
      await TouchpointHistoryDialog.show(
        context,
        clientId: client.clientId,
        clientName: client.fullName,
      );
    }
  }

  Future<void> _navigateToClient(MyDayClient client) async {
    HapticUtils.lightImpact();

    final address = client.location;
    if (address == null || address.isEmpty) {
      if (mounted) {
        showToast('No address available for this client');
      }
      return;
    }

    try {
      // Open Google Maps with the address
      final Uri mapUri = Uri(
        scheme: 'https',
        host: 'www.google.com',
        path: '/maps/search/',
        queryParameters: {
          'api': '1',
          'query': address,
        },
      );

      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          showToast('Could not open maps application');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast('Failed to open navigation: $e');
      }
    }
  }

  void _onClientLongPress(MyDayClient client) {
    // Enter multi-select mode and select this client
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
      });
    }
    _toggleClientSelection(client.id);
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
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show validation error dialog
  void _showValidationError(validation, String clientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          LucideIcons.alertCircle,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Invalid Touchpoint Sequence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(validation.error ?? 'Invalid touchpoint sequence'),
            const SizedBox(height: 16),
            const Text(
              'Expected Sequence:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...TouchpointValidationService.getSequenceDisplay().map((item) {
              return Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Text('• $item'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myDayStateProvider);

    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, result) {
        if (_isMultiSelectMode && !didPop) {
          _exitMultiSelectMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          // Handle tap outside to exit multi-select mode
          onTap: () {
            if (_isMultiSelectMode) {
              _exitMultiSelectMode();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: SafeArea(
            child: PullToRefresh(
              onRefresh: _handleRefresh,
              child: state.isLoading
                  ? const MyDaySkeleton()
                  : state.error != null
                      ? _buildErrorState(state.error!)
                      : _buildContent(state.clients),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showRecordVisitOptions(context),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(myDayStateProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(List<MyDayClient> clients) {
    // Count completed visits (those with timeIn)
    final total = clients.length;
    final completed = clients.where((c) => c.isTimeIn).length;
    final progress = total > 0 ? completed / total : 0.0;
    final progressPercent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Circular progress icon
          Stack(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                  ),
                  strokeWidth: 3,
                ),
              ),
              if (total > 0)
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: progress >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Progress text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$completed of $total clients visited',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (total == 0)
                  Text(
                    'Add clients to get started',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  )
                else if (completed < total)
                  Text(
                    '${total - completed} remaining',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  )
                else if (completed == total && total > 0)
                  Text(
                    'All done! Great work!',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<MyDayClient> clients) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Day',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress indicator
                _buildProgressIndicator(clients),

                const SizedBox(height: 16),

                // Header buttons - change based on multi-select mode
                if (!_isMultiSelectMode)
                  HeaderButtons(
                    onMultipleTimeIn: _onMultipleTimeIn,
                    onAddClient: _onAddNewVisit,
                  )
                else
                  _MultiSelectHeaderButtons(
                    selectedCount: _selectedClientIds.length,
                    onSubmitVisit: _onBulkSubmitVisit,
                    onRemove: _onBulkRemove,
                    onCancel: _exitMultiSelectMode,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Client list
          if (clients.isEmpty)
            SizedBox(
              height: 400,
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
                      'No clients planned for today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Add clients from My Clients to plan your visits for today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/clients'),
                      icon: const Icon(LucideIcons.userPlus, size: 18),
                      label: const Text('Go to My Clients'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...clients.map(
              (client) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 4),
                child: ClientListCard.fromMyDayClient(
                  myDayClient: client,
                  clientId: client.clientId,
                  fullName: client.fullName,
                  location: client.location,
                  touchpointNumber: client.touchpointNumber,
                  touchpointType: client.touchpointType,
                  previousTouchpointNumber: client.previousTouchpointNumber,
                  previousTouchpointReason: client.previousTouchpointReason,
                  previousTouchpointType: client.previousTouchpointType,
                  previousTouchpointDate: client.previousTouchpointDate,
                  onTap: () => _onClientTap(client),
                  onRemove: () => _confirmRemoveClient(client),
                  onLongPress: () => _onClientLongPress(client),
                  isSelected: _isClientSelected(client.id),
                  isMultiSelectMode: _isMultiSelectMode,
                  enableSwipeToDismiss: true,
                  showInMyDayBadge: true,
                ),
              ),
            ),

          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
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
          '$selectedCount client${selectedCount == 1 ? '' : 's'} selected',
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
