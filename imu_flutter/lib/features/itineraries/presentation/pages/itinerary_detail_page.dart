import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../services/api/itinerary_api_service.dart';
import '../../../../services/connectivity_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../data/models/itinerary_model.dart';

/// Itinerary detail provider
final itineraryDetailProvider = FutureProvider.family<ItineraryItem?, String>((ref, itineraryId) async {
  final itineraryApi = ref.watch(itineraryApiServiceProvider);
  final isOnline = ref.watch(isOnlineProvider);

  if (isOnline) {
    try {
      return await itineraryApi.fetchItineraryById(itineraryId);
    } catch (e) {
      // Fall back to local cache
      final hiveService = HiveService();
      if (!hiveService.isInitialized) await hiveService.init();
      final localItinerary = await hiveService.getItinerary(itineraryId);
      if (localItinerary != null) {
        return ItineraryItem.fromJson(localItinerary);
      }
      return null;
    }
  } else {
    // Offline - use local cache
    final hiveService = HiveService();
    if (!hiveService.isInitialized) await hiveService.init();
    final localItinerary = await hiveService.getItinerary(itineraryId);
    if (localItinerary != null) {
      return ItineraryItem.fromJson(localItinerary);
    }
    return null;
  }
});

class ItineraryDetailPage extends ConsumerStatefulWidget {
  final String itineraryId;

  const ItineraryDetailPage({
    super.key,
    required this.itineraryId,
  });

  @override
  ConsumerState<ItineraryDetailPage> createState() => _ItineraryDetailPageState();
}

class _ItineraryDetailPageState extends ConsumerState<ItineraryDetailPage> {
  final _hiveService = HiveService();

  ItineraryItem? _itinerary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItinerary();
  }

  Future<void> _loadItinerary() async {
    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Loading visit details...',
      operation: () async {
        if (!_hiveService.isInitialized) {
          await _hiveService.init();
        }

        final itineraryData = await _hiveService.getItinerary(widget.itineraryId);
        if (itineraryData != null && mounted) {
          setState(() {
            _itinerary = ItineraryItem.fromJson(itineraryData);
            _isLoading = false;
          });
        } else {
          // Try API
          final itineraryApi = ref.read(itineraryApiServiceProvider);
          try {
            final itinerary = await itineraryApi.fetchItineraryById(widget.itineraryId);
            if (itinerary != null && mounted) {
              setState(() {
                _itinerary = itinerary;
                _isLoading = false;
              });
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          }
        }
      },
    );
  }

  Future<void> _handleDelete() async {
    if (_itinerary == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Itinerary'),
        content: const Text('Are you sure you want to delete this scheduled visit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticUtils.delete();

      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Deleting visit...',
        operation: () async {
          await _hiveService.deleteItinerary(widget.itineraryId);
          ref.invalidate(todayItineraryProvider);
        },
        onError: (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete visit: $e')),
            );
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Itinerary deleted')),
        );
        context.pop();
      }
    }
  }

  void _editItinerary() {
    HapticUtils.lightImpact();
    _showEditItineraryDialog();
  }

  void _showEditItineraryDialog() {
    final notesController = TextEditingController(text: _itinerary?.notes ?? '');
    String selectedStatus = _itinerary?.status ?? 'pending';
    String selectedPriority = _itinerary?.priority ?? 'normal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Itinerary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value ?? 'pending';
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedPriority = value ?? 'normal';
                  });
                },
              ),
              const SizedBox(height: 16),
              const Text('Notes', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedItinerary = _itinerary!.copyWith(
                  status: selectedStatus,
                  priority: selectedPriority,
                  notes: notesController.text.isEmpty ? null : notesController.text,
                );

                await LoadingHelper.withLoading(
                  ref: ref,
                  message: 'Updating visit...',
                  operation: () async {
                    await _hiveService.updateItinerary(updatedItinerary.toJson());
                    ref.invalidate(todayItineraryProvider);
                  },
                  onError: (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update visit: $e')),
                      );
                    }
                  },
                );

                if (mounted) {
                  Navigator.pop(context);
                  _loadItinerary();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Itinerary updated')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    if (_itinerary == null) return;

    HapticUtils.success();

    final updatedItinerary = _itinerary!.copyWith(
      status: 'completed',
    );

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Marking visit as completed...',
      operation: () async {
        await _hiveService.updateItinerary(updatedItinerary.toJson());
        ref.invalidate(todayItineraryProvider);
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to mark as completed: $e')),
          );
        }
      },
    );

    if (mounted) {
      _loadItinerary();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit marked as completed')),
      );
    }
  }

  Future<void> _markAsInProgress() async {
    if (_itinerary == null) return;

    HapticUtils.lightImpact();

    final updatedItinerary = _itinerary!.copyWith(
      status: 'in_progress',
    );

    await LoadingHelper.withLoading(
      ref: ref,
      message: 'Starting visit...',
      operation: () async {
        await _hiveService.updateItinerary(updatedItinerary.toJson());
        ref.invalidate(todayItineraryProvider);
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start visit: $e')),
          );
        }
      },
    );

    if (mounted) {
      _loadItinerary();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit marked as in progress')),
      );
    }
  }

  void _navigateToClient() {
    if (_itinerary == null) return;
    HapticUtils.lightImpact();
    context.push('/clients/${_itinerary!.clientId}');
  }

  void _navigateToAddress() {
    if (_itinerary?.address == null || _itinerary!.address!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No address available')),
      );
      return;
    }
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to ${_itinerary!.address}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_itinerary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visit Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.calendar, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Scheduled visit not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.pencil),
            onPressed: _editItinerary,
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visit header with status badge
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
                          _itinerary!.clientName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_itinerary!.scheduledDate),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_itinerary!.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatStatus(_itinerary!.status),
                      style: TextStyle(
                        color: _getStatusColor(_itinerary!.status),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_itinerary!.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _markAsCompleted,
                        icon: const Icon(LucideIcons.check, size: 18),
                        label: const Text('Mark as Completed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (_itinerary!.status == 'pending') ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _markAsInProgress,
                        icon: const Icon(LucideIcons.play, size: 18),
                        label: const Text('Start Visit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: LucideIcons.user,
                          label: 'View Client',
                          onTap: _navigateToClient,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: LucideIcons.mapPin,
                          label: 'Navigate',
                          onTap: _navigateToAddress,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Visit Information Section
            const _Section(title: 'Visit Information'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.user,
                    label: 'Client',
                    value: _itinerary!.clientName,
                  ),
                  if (_itinerary!.address != null)
                    _InfoRow(
                      icon: LucideIcons.mapPin,
                      label: 'Address',
                      value: _itinerary!.address!,
                    ),
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Scheduled Date',
                    value: _formatDate(_itinerary!.scheduledDate),
                  ),
                  if (_itinerary!.scheduledTime != null)
                    _InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Scheduled Time',
                      value: _itinerary!.scheduledTime!,
                    ),
                  _InfoRow(
                    icon: LucideIcons.activity,
                    label: 'Status',
                    value: _formatStatus(_itinerary!.status),
                    valueColor: _getStatusColor(_itinerary!.status),
                  ),
                  _InfoRow(
                    icon: LucideIcons.flag,
                    label: 'Priority',
                    value: _formatPriority(_itinerary!.priority),
                    valueColor: _getPriorityColor(_itinerary!.priority),
                  ),
                  if (_itinerary!.touchpointNumber != null)
                    _InfoRow(
                      icon: LucideIcons.list,
                      label: 'Touchpoint',
                      value: '${_getOrdinal(_itinerary!.touchpointNumber!)} touchpoint',
                    ),
                ],
              ),
            ),

            // Notes Section
            if (_itinerary!.notes != null && _itinerary!.notes!.isNotEmpty) ...[
              const _Section(title: 'Notes'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.stickyNote, size: 18, color: Colors.amber[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _itinerary!.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Actions Section
            if (_itinerary!.status != 'completed') ...[
              const _Section(title: 'Quick Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ActionTile(
                      icon: LucideIcons.phone,
                      title: 'Call Client',
                      subtitle: 'Contact the client',
                      onTap: () {
                        HapticUtils.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Call feature - Coming soon')),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: LucideIcons.messageCircle,
                      title: 'Send Message',
                      subtitle: 'Send a text message',
                      onTap: () {
                        HapticUtils.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Message feature - Coming soon')),
                        );
                      },
                    ),
                    _ActionTile(
                      icon: LucideIcons.navigation,
                      title: 'Get Directions',
                      subtitle: 'Open in maps app',
                      onTap: _navigateToAddress,
                    ),
                  ],
                ),
              ),
            ],

            // Metadata Section
            const _Section(title: 'Details'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoRow(
                    icon: LucideIcons.calendar,
                    label: 'Created',
                    value: _formatDate(_itinerary!.createdAt),
                  ),
                  if (_itinerary!.updatedAt != null)
                    _InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Last Updated',
                      value: _formatDate(_itinerary!.updatedAt!),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Bottom padding
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatPriority(String priority) {
    return priority[0].toUpperCase() + priority.substring(1).toLowerCase();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }
}

class _Section extends StatelessWidget {
  final String title;

  const _Section({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
