import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../providers/my_day_provider.dart';
import '../widgets/header_buttons.dart';
import '../widgets/client_card.dart';
import '../widgets/time_in_bottom_sheet.dart';
import '../widgets/multiple_time_in_sheet.dart';
import '../../data/models/my_day_client.dart';

class MyDayPage extends ConsumerStatefulWidget {
  const MyDayPage({super.key});

  @override
  ConsumerState<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends ConsumerState<MyDayPage> {
  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    await ref.read(myDayStateProvider.notifier).refresh();
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

  void _onClientTap(MyDayClient client) {
    TimeInBottomSheet.show(
      context: context,
      client: client,
      onTimeInToggle: (isTimeIn) async {
        await ref.read(myDayStateProvider.notifier).setTimeIn(client.id, isTimeIn);
      },
      onSelfieCapture: (path) async {
        if (path != null) {
          await ref.read(myDayApiServiceProvider).uploadSelfie(client.id, path);
        }
      },
      onTouchpointSelected: (number) {
        // Touchpoint selected - update state if needed
      },
      onFormSubmit: (formData) async {
        await ref.read(myDayStateProvider.notifier).submitVisitForm(client.id, formData);
      },
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
              ? const Center(child: CircularProgressIndicator())
              : state.error != null
                  ? _buildErrorState(state.error!)
                  : _buildContent(state.clients),
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
                const SizedBox(height: 16),

                // Header buttons
                HeaderButtons(
                  onMultipleTimeIn: _onMultipleTimeIn,
                  onAddNewVisit: _onAddNewVisit,
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
                    Icon(
                      LucideIcons.users,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No clients for today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap "Add new visit" to get started',
                      style: TextStyle(color: Colors.grey[500]),
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
                ),
              ),
            ),

          const SizedBox(height: 100), // Bottom nav padding
        ],
      ),
    );
  }
}
