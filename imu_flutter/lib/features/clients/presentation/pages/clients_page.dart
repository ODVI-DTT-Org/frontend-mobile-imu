import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/swipeable_list_tile.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/sync/sync_service.dart';
import '../../../../services/local_storage/hive_service.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../data/models/client_model.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'POTENTIAL';
  bool _showInterestedOnly = false;

  // Recently deleted for undo
  Client? _recentlyDeletedClient;
  int? _recentlyDeletedIndex;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticUtils.pullToRefresh();
    // Invalidate the clients provider to force a refresh
    ref.invalidate(clientsProvider);
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _deleteClient(Client client) async {
    final hiveService = ref.read(hiveServiceProvider);
    final syncService = ref.read(syncServiceProvider);

    // Store for undo
    final clients = ref.read(filteredClientsProvider);
    final index = clients.indexOf(client);

    setState(() {
      _recentlyDeletedClient = client;
      _recentlyDeletedIndex = index;
    });

    // Delete from local storage
    await hiveService.deleteClient(client.id);

    // Queue for sync
    await syncService.queueForSync(
      id: client.id,
      operation: 'DELETE',
      entityType: 'client',
      data: {'id': client.id},
    );

    // Refresh the list
    ref.invalidate(clientsProvider);

    HapticUtils.delete();

    // Show undo snackbar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${client.fullName} deleted'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _undoDelete(),
        ),
      ),
    );
  }

  void _undoDelete() async {
    if (_recentlyDeletedClient == null) return;

    final hiveService = ref.read(hiveServiceProvider);
    final syncService = ref.read(syncServiceProvider);

    // Restore client using saveClient
    await hiveService.saveClient(
      _recentlyDeletedClient!.id,
      _recentlyDeletedClient!.toJson(),
    );

    // Queue for sync
    await syncService.queueForSync(
      id: _recentlyDeletedClient!.id,
      operation: 'CREATE',
      entityType: 'client',
      data: _recentlyDeletedClient!.toJson(),
    );

    // Refresh
    ref.invalidate(clientsProvider);

    HapticUtils.lightImpact();

    setState(() {
      _recentlyDeletedClient = null;
      _recentlyDeletedIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Client restored')),
    );
  }

  void _archiveClient(String id) {
    HapticUtils.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Client $id archived')),
    );
  }

  void _callClient(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }

  void _navigateToClient(String? address) {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No address available')),
      );
      return;
    }
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $address...')),
    );
  }

  void _editClient(String id) {
    HapticUtils.lightImpact();
    context.push('/clients/$id/edit');
  }

  List<Client> _filterClients(List<Client> clients) {
    var filtered = clients.where((client) {
      final clientTypeStr = client.clientType.name.toUpperCase();
      final matchesTab = clientTypeStr == _activeTab;
      return matchesTab;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((client) {
        return client.fullName.toLowerCase().contains(query);
      }).toList();
    }

    if (_showInterestedOnly) {
      filtered = filtered.where((client) {
        if (client.touchpoints.isEmpty) return false;
        final lastTouchpoint = client.touchpoints.last;
        return lastTouchpoint.reason == TouchpointReason.interested;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('My Clients'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => context.push('/clients/add'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              children: [
                // Search row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search clients...',
                          prefixIcon: const Icon(LucideIcons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Filter button
                    IconButton(
                      onPressed: () => _showFilterDialog(),
                      icon: const Icon(LucideIcons.filter),
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Interested filter
                    IconButton(
                      onPressed: () {
                        HapticUtils.toggle();
                        setState(() => _showInterestedOnly = !_showInterestedOnly);
                      },
                      icon: Icon(
                        LucideIcons.star,
                        color: _showInterestedOnly ? Colors.amber : null,
                        fill: _showInterestedOnly ? 1 : 0,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: _showInterestedOnly
                            ? Colors.amber[50]
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'Potential',
                          isSelected: _activeTab == 'POTENTIAL',
                          onTap: () {
                            HapticUtils.selectionClick();
                            setState(() => _activeTab = 'POTENTIAL');
                          },
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'Existing',
                          isSelected: _activeTab == 'EXISTING',
                          onTap: () {
                            HapticUtils.selectionClick();
                            setState(() => _activeTab = 'EXISTING');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clients list with pull to refresh
          Expanded(
            child: clientsAsync.when(
              data: (clients) {
                final filteredClients = _filterClients(clients);

                if (filteredClients.isEmpty) {
                  return PullToRefresh(
                    onRefresh: _handleRefresh,
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.users, size: 48, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'No clients found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pull down to refresh or add a new client',
                                  style: TextStyle(color: Colors.grey[500]),
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
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      final primaryAddress = client.addresses.isNotEmpty
                          ? client.addresses.first.fullAddress
                          : null;
                      final primaryPhone = client.phoneNumbers.isNotEmpty
                          ? client.phoneNumbers.first.number
                          : null;

                      return SwipeableListTile(
                        leftActions: [
                          SwipeAction.call(() => _callClient(primaryPhone)),
                          SwipeAction.navigate(() => _navigateToClient(primaryAddress)),
                        ],
                        rightActions: [
                          SwipeAction.edit(() => _editClient(client.id)),
                          SwipeAction.delete(() => _deleteClient(client)),
                        ],
                        onTap: () {
                          HapticUtils.lightImpact();
                          context.push('/clients/${client.id}');
                        },
                        child: _ClientCard(client: client),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(clientsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Clear Filters'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Market Type
            const Text(
              'Market Type',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Wrap(
              spacing: 8,
              children: ['Residential', 'Commercial', 'Industrial']
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: false,
                        onSelected: (_) {
                          HapticUtils.lightImpact();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            // Product Type
            const Text(
              'Product Type',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Wrap(
              spacing: 8,
              children: ['SSS Pensioner', 'GSIS Pensioner', 'Private']
                  .map((type) => FilterChip(
                        label: Text(type),
                        selected: false,
                        onSelected: (_) {
                          HapticUtils.lightImpact();
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  final Client client;

  const _ClientCard({required this.client});

  @override
  Widget build(BuildContext context) {
    final touchpointNumber = client.completedTouchpoints;
    final touchpointType = client.nextTouchpointType;
    final lastTouchpoint = client.touchpoints.isNotEmpty
        ? client.touchpoints.last
        : null;
    final reason = lastTouchpoint?.reason;
    final lastVisitDate = lastTouchpoint?.date;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (reason != null)
                      _buildBadge(reason, touchpointNumber, touchpointType),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getProductTypeLabel(client.productType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (lastVisitDate != null)
                      Text(
                        _formatDate(lastVisitDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProductTypeLabel(ProductType type) {
    switch (type) {
      case ProductType.sssPensioner:
        return 'SSS Pensioner';
      case ProductType.gsisPensioner:
        return 'GSIS Pensioner';
      case ProductType.private:
        return 'Private';
    }
  }

  Widget _buildBadge(TouchpointReason reason, int touchpointNumber, TouchpointType? touchpointType) {
    Color bgColor;
    Color textColor;

    switch (reason) {
      case TouchpointReason.interested:
        bgColor = Colors.amber;
        textColor = Colors.white;
        break;
      case TouchpointReason.notInterested:
        bgColor = Colors.red;
        textColor = Colors.white;
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (touchpointNumber > 0 && touchpointType != null) ...[
            Icon(
              touchpointType == TouchpointType.visit
                  ? LucideIcons.mapPin
                  : LucideIcons.phone,
              size: 12,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              '${_getOrdinal(touchpointNumber)} •',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _formatReason(reason),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinal(int num) {
    const ordinals = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th'];
    return ordinals[num - 1] ?? '${num}th';
  }

  String _formatReason(TouchpointReason reason) {
    final name = reason.name;
    return name
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
