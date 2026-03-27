import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/client_api_service.dart';
import '../../../../services/api/approvals_api_service.dart';
import '../../../../services/touchpoint/touchpoint_validation_service.dart';
import '../../../../features/clients/data/models/client_model.dart';
import '../../../../features/clients/presentation/pages/edit_client_page.dart';
import '../providers/my_day_provider.dart';
import '../widgets/header_buttons.dart';
import '../widgets/client_card.dart';
import '../widgets/multiple_time_in_sheet.dart';
import '../../data/models/my_day_client.dart';
import '../../../touchpoints/presentation/widgets/touchpoint_form.dart';

class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Refreshing...',
      operation: () => ref.read(myDayStateProvider.notifier).refresh(),
    );
  }

  void _onMultipleTimeIn() {
    HapticUtils.lightImpact();
    final state = ref.read(myDayStateProvider);

    if (state.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clients available for time-in'),
          backgroundColor: Color(0xFF64748B),
        ),
      );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time-in recorded for ${clientIds.length} clients'),
              backgroundColor: const Color(0xFF22C55E),
            ),
          );
        }
      },
    );
  }

  void _onAddNewVisit() {
    HapticUtils.lightImpact();
    // Navigate to client selection or add visit flow
    context.push('/clients');
  }

  void _showRecordVisitOptions(BuildContext context) {
    HapticUtils.lightImpact();
    final state = ref.read(myDayStateProvider);

    if (state.clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No clients available for recording'),
          backgroundColor: Color(0xFF64748B),
        ),
      );
      return;
    }

    // Show bottom sheet with client list
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Record Visit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select a client to record a visit:',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ...state.clients.map((client) => ListTile(
                  leading: const Icon(LucideIcons.user, color: Color(0xFF0F172A)),
                  title: Text(client.fullName),
                  subtitle: client.location != null
                      ? Text(client.location!)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    _onClientTap(client);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          await myDayApiService.removeFromMyDay(client.id);
          if (mounted) {
            HapticUtils.success();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${client.fullName} removed from My Day'),
                backgroundColor: const Color(0xFF22C55E),
              ),
            );
            await ref.read(myDayStateProvider.notifier).refresh();
          }
        },
      );
    }
  }

  void _onClientTap(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Show action dialog with options
    if (mounted) {
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(client.fullName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (client.location != null && client.location!.isNotEmpty) ...[
                Text(
                  client.location!,
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
          await _recordVisit(client);
          break;
        case 'release':
          await _releaseLoan(client);
          break;
        case 'edit':
          await _editClient(client);
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

    // Open the TouchpointForm which handles Time In/Out internally
    final result = await showTouchpointForm(
      context: context,
      clientId: client.id,
      touchpointNumber: touchpointNumber,
      touchpointType: touchpointType == TouchpointType.visit ? 'Visit' : 'Call',
      clientName: client.fullName,
      address: client.location,
    );

    // Handle form submission result
    if (result != null && mounted) {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Saving touchpoint...',
        operation: () async {
          await ref.read(myDayStateProvider.notifier).submitVisitForm(client.id, result);

          // Upload selfie if photo was captured
          if (result['photoPath'] != null) {
            await ref.read(myDayApiServiceProvider).uploadSelfie(client.id, result['photoPath']);
          }
        },
      );

      // Check if this was the 7th touchpoint
      if (touchpointNumber == 7) {
        _showTouchpointCompletionDialog(client.fullName);
      }
    }
  }

  Future<void> _releaseLoan(MyDayClient client) async {
    HapticUtils.lightImpact();

    // Show UDI input dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ReleaseLoanDialog(clientName: client.fullName),
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
          clientId: client.id,
          udiNumber: udiNumber.trim(),
          notes: 'Loan release requested via mobile app',
        );
        // Refresh My Day to show updated status
        await ref.read(myDayStateProvider.notifier).refresh();
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

  Future<void> _editClient(MyDayClient client) async {
    HapticUtils.lightImpact();
    context.push('/clients/${client.id}/edit');
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PullToRefresh(
          onRefresh: _handleRefresh,
          child: state.isLoading
              ? const MyDaySkeleton()
              : state.error != null
                  ? _buildErrorState(state.error!)
                  : _buildContent(state.clients),
        ),
      ),
      floatingActionButton: state.clients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showRecordVisitOptions(context),
              icon: const Icon(LucideIcons.mapPin),
              label: const Text('Record Visit'),
              backgroundColor: const Color(0xFF0F172A),
            )
          : null,
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

                // Header buttons
                HeaderButtons(
                  onMultipleTimeIn: _onMultipleTimeIn,
                  onAddClient: _onAddNewVisit,
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
                child: ClientCard(
                  client: client,
                  onTap: () => _onClientTap(client),
                  onRemove: () => _confirmRemoveClient(client),
                ),
              ),
            ),

          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
    );
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
