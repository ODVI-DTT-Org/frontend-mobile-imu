// Simplified Clients page with My Clients / All Clients filters and pagination
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../app.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/client_api_service.dart' show ClientsResponse;
import '../../../../shared/providers/app_providers.dart' show
    currentUserIdProvider,
    clientsProvider,
    onlineClientsProvider,
    onlineClientSearchQueryProvider,
    onlineClientPageProvider,
    isOnlineProvider;
import '../../../../shared/providers/filter_providers.dart';
import '../../../../shared/utils/loading_helper.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';

// Provider to check if client is in My Day
final _isInMyDayProvider = FutureProvider.family<bool, String>((ref, clientId) async {
  final myDayApiService = ref.watch(myDayApiServiceProvider);
  return await myDayApiService.isInMyDay(clientId);
});

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showMyClientsOnly = true; // true = My Clients (PowerSync), false = All Clients (Online)

  // Pagination
  final int _itemsPerPage = 20;
  int _currentPage = 1;
  List<Client> _allClients = [];
  List<Client> _filteredClients = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1; // Reset to first page on search
    });

    // Update the appropriate search query provider based on mode
    if (_showMyClientsOnly) {
      // My Clients: filter locally (PowerSync already has territory-filtered data)
    } else {
      // All Clients: update online search query provider
      ref.read(onlineClientSearchQueryProvider.notifier).state = _searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _getPaginatedClients() {
    if (_filteredClients.isEmpty) return [];

    // For online mode, the server already paginated, so return all items
    // For offline mode (My Clients), paginate locally
    if (!_showMyClientsOnly) {
      return _filteredClients;
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredClients.length) return [];
    if (endIndex > _filteredClients.length) {
      return _filteredClients.sublist(startIndex);
    }
    return _filteredClients.sublist(startIndex, endIndex);
  }

  int _totalPages([ClientsResponse? onlineMeta]) {
    // For online mode, use server's total pages
    if (!_showMyClientsOnly && onlineMeta != null) {
      return onlineMeta.totalPages;
    }
    // For offline mode, calculate locally
    return (_filteredClients.length / _itemsPerPage).ceil();
  }

  int _totalItems([ClientsResponse? onlineMeta]) {
    // For online mode, use server's total items
    if (!_showMyClientsOnly && onlineMeta != null) {
      return onlineMeta.totalItems;
    }
    // For offline mode, use filtered count
    return _filteredClients.length;
  }

  void _goToPage(int page) {
    HapticUtils.lightImpact();
    setState(() {
      _currentPage = page;
    });

    // For online mode, update the provider's page state and invalidate to trigger refetch
    if (!_showMyClientsOnly) {
      ref.read(onlineClientPageProvider.notifier).state = page;
      ref.invalidate(onlineClientsProvider);
    }
  }

  void _handleRefresh() async {
    HapticUtils.lightImpact();
    // Refresh the appropriate provider based on current mode
    if (_showMyClientsOnly) {
      ref.invalidate(clientsProvider);
    } else {
      ref.invalidate(onlineClientsProvider);
    }
  }

  void _showAddClientModal() {
    context.push('/clients/add');
  }

  Future<void> _addToMyDay(Client client) async {
    if (client.id == null) {
      if (mounted) {
        showToast('Client ID is missing');
      }
      return;
    }

    HapticUtils.lightImpact();
    final myDayApiService = ref.read(myDayApiServiceProvider);

    try {
      final success = await myDayApiService.addToMyDay(client.id!);
      if (success && mounted) {
        HapticUtils.success();
        showToast('${client.fullName} added to My Day');
        ref.invalidate(_isInMyDayProvider(client.id!));
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        showToast('Failed to add to My Day: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignedMunicipalities = ref.watch(assignedMunicipalitiesProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Choose provider based on mode
    // My Clients = PowerSync (offline, territory-filtered)
    // All Clients = Online API (search all clients in database)
    final clientsAsync = _showMyClientsOnly
        ? ref.watch(clientsProvider)
        : ref.watch(onlineClientsProvider);

    return clientsAsync.when(
      data: (data) {
        // Handle different return types: List<Client> vs ClientsResponse
        final clients = _showMyClientsOnly ? data as List<Client> : (data as ClientsResponse).items;

        // For online mode, get pagination metadata from response
        final onlineMeta = _showMyClientsOnly ? null : (data as ClientsResponse);

        // Filter clients based on selected mode
        _allClients = clients;
        final query = _searchQuery.toLowerCase();

        // My Clients: filter by territory and search locally
        // All Clients: already filtered by search query in provider, just paginate
        _filteredClients = clients.where((client) {
          if (_showMyClientsOnly) {
            // My Clients: filter by assigned municipalities
            // Construct municipality ID from client's province and municipality
            final clientMunicipalityId = client.province != null && client.municipality != null
                ? '${client.province}-${client.municipality}'
                : null;
            final matchesViewMode = clientMunicipalityId != null &&
                assignedMunicipalities.contains(clientMunicipalityId);

            // Filter by search (local)
            final matchesSearch = query.isEmpty ||
                client.fullName.toLowerCase().contains(query) ||
                (client.addresses.isNotEmpty &&
                 client.addresses.first.city.toLowerCase().contains(query));

            return matchesViewMode && matchesSearch;
          } else {
            // All Clients: already searched on server, just return as-is
            return true;
          }
        }).toList();

        final paginatedClients = _getPaginatedClients();
        final totalPages = _totalPages(onlineMeta);
        final totalItems = _totalItems(onlineMeta);

        return Scaffold(
          backgroundColor: Colors.white,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              HapticUtils.lightImpact();
              _showAddClientModal();
            },
            backgroundColor: const Color(0xFF0F172A),
            child: const Icon(LucideIcons.plus, color: Colors.white),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 17,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Back button
                          GestureDetector(
                            onTap: () {
                              HapticUtils.lightImpact();
                              context.go('/home');
                            },
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.chevronLeft,
                                  size: 20,
                                  color: const Color(0xFF0F172A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Home',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Title
                          Text(
                            _showMyClientsOnly ? 'My Clients' : 'All Clients',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 50),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Toggle between My Clients and All Clients
                      Row(
                        children: [
                          _buildFilterToggle('My Clients', _showMyClientsOnly, () {
                            HapticUtils.lightImpact();
                            setState(() {
                              _showMyClientsOnly = true;
                              _currentPage = 1;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            // Invalidate online provider when switching back to My Clients
                            ref.invalidate(onlineClientsProvider);
                          }),
                          const SizedBox(width: 8),
                          _buildFilterToggle('All Clients', !_showMyClientsOnly, () {
                            HapticUtils.lightImpact();
                            // Check if online before switching to All Clients
                            final isOnlineNow = ref.read(isOnlineProvider);
                            if (!isOnlineNow) {
                              showToast('Cannot search all clients while offline');
                              return;
                            }
                            setState(() {
                              _showMyClientsOnly = false;
                              _currentPage = 1;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            // Reset online search and page to first page when switching
                            ref.read(onlineClientSearchQueryProvider.notifier).state = '';
                            ref.read(onlineClientPageProvider.notifier).state = 1;
                          }),
                        ],
                      ),
                      // Show online indicator when in All Clients mode
                      if (!_showMyClientsOnly)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.globe,
                                size: 12,
                                color: Colors.green.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Searching all clients in database',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Search Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search clients...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade400, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(LucideIcons.x, color: Colors.grey.shade400, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Top Pagination Info
                if (_filteredClients.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                    child: _buildTopPagination(totalItems, totalPages),
                  ),

                const SizedBox(height: 8),

                // Client list
                Expanded(
                  child: paginatedClients.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () async => _handleRefresh(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                            itemCount: paginatedClients.length,
                            itemBuilder: (context, index) {
                              final client = paginatedClients[index];
                              return _buildClientCard(client);
                            },
                          ),
                        ),
                ),

                // Bottom Pagination
                if (_filteredClients.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17, vertical: 16),
                    child: _buildBottomPagination(totalPages),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header skeleton
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 80,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search bar skeleton
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
              // Filter chips skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // List skeleton
              const Expanded(
                child: ClientListSkeleton(itemCount: 7),
              ),
            ],
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _showMyClientsOnly
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showMyClientsOnly
                      ? LucideIcons.alertCircle
                      : LucideIcons.wifiOff,
                  size: 40,
                  color: _showMyClientsOnly
                      ? Colors.red.shade400
                      : Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _showMyClientsOnly
                    ? 'Failed to load clients'
                    : 'Cannot search all clients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_showMyClientsOnly) {
                    ref.invalidate(clientsProvider);
                  } else {
                    ref.invalidate(onlineClientsProvider);
                  }
                },
                child: Text(_showMyClientsOnly ? 'Retry' : 'Check Connection'),
              ),
              if (!_showMyClientsOnly) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showMyClientsOnly = true;
                      _currentPage = 1;
                    });
                  },
                  child: const Text('Switch to My Clients (Offline)'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F172A)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTopPagination(int totalItems, int totalPages) {
    // For online mode, show actual counts from server
    // For offline mode, calculate local pagination
    final startIndex = _showMyClientsOnly
        ? (_currentPage - 1) * _itemsPerPage + 1
        : (_currentPage - 1) * 50 + 1; // Server uses perPage=50
    final endIndex = _showMyClientsOnly
        ? (_currentPage * _itemsPerPage).clamp(1, _filteredClients.length)
        : (_currentPage * 50).clamp(1, totalItems);

    return Row(
      children: [
        Text(
          'Showing $startIndex-$endIndex of $totalItems clients',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (totalPages > 1)
          Text(
            'Page $_currentPage of $totalPages',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildPageButton(
            icon: LucideIcons.chevronLeft,
            enabled: _currentPage > 1,
            onTap: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          const SizedBox(width: 8),

          // Page numbers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _buildPageNumbers(totalPages),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Next button
          _buildPageButton(
            icon: LucideIcons.chevronRight,
            enabled: _currentPage < totalPages,
            onTap: _currentPage < totalPages ? () => _goToPage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    // Show max 5 page numbers
    final startPage = (_currentPage - 2).clamp(1, totalPages);
    final endPage = (_currentPage + 2).clamp(1, totalPages);

    final pages = List.generate(endPage - startPage + 1, (index) => startPage + index);

    return pages.map((page) {
      final isCurrentPage = page == _currentPage;
      return GestureDetector(
        onTap: () => _goToPage(page),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage
                ? const Color(0xFF0F172A)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCurrentPage
                  ? const Color(0xFF0F172A)
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrentPage ? FontWeight.w600 : FontWeight.w500,
              color: isCurrentPage ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0F172A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? Colors.white : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
              _showMyClientsOnly ? LucideIcons.users : LucideIcons.search,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? (_showMyClientsOnly ? 'No assigned clients' : 'No clients found')
                : 'No clients found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? (_showMyClientsOnly
                    ? 'Add your first client to get started'
                    : 'Try searching for clients by name')
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_searchQuery.isEmpty && _showMyClientsOnly) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddClientModal,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Add Client'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final latestTouchpoint = client.touchpoints.isNotEmpty
        ? client.touchpoints.last
        : null;
    final isFirstTime = client.touchpoints.isEmpty;

    final myDayApiService = ref.watch(myDayApiServiceProvider);
    final isInMyDayValue = client.id != null
        ? ref.watch(_isInMyDayProvider(client.id!))
        : const AsyncValue.data(false);

    final primaryPhone = client.phoneNumbers.isNotEmpty
        ? client.phoneNumbers.first.number
        : null;
    final primaryAddress = client.addresses.isNotEmpty
        ? client.addresses.first.fullAddress
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticUtils.lightImpact();
          if (client.id != null) {
            context.push('/clients/${client.id}');
          } else {
            showToast('Client ID is missing');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: badge + name + status
              Row(
                children: [
                  // Touchpoint badge or NEW badge
                  if (isFirstTime) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else if (latestTouchpoint != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        latestTouchpoint.ordinal,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  // Client name with "In My Day" badge
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            client.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((isInMyDayValue.value ?? false) == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 10,
                                  color: const Color(0xFF22C55E),
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'In My Day',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Chevron
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Address row
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      client.addresses.isNotEmpty
                          ? client.addresses.first.street
                          : 'No address',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Touchpoint summary (if not first time)
              if (!isFirstTime && latestTouchpoint != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      latestTouchpoint.type == TouchpointType.visit
                          ? LucideIcons.mapPin
                          : LucideIcons.phone,
                      size: 12,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getTouchpointSummary(latestTouchpoint),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              // Touchpoint reason (if available)
              if (!isFirstTime && latestTouchpoint != null && latestTouchpoint.reason != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.messageCircle,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        latestTouchpoint.reason!.apiValue,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              // Quick actions and Add button row
              Row(
                children: [
                  // Quick actions: Call and Navigate
                  if (primaryPhone != null)
                    _QuickActionButton(
                      icon: LucideIcons.phone,
                      label: 'Call',
                      onTap: () => _callClient(primaryPhone),
                    ),
                  if (primaryPhone != null && primaryAddress != null)
                    const SizedBox(width: 8),
                  if (primaryAddress != null)
                    _QuickActionButton(
                      icon: LucideIcons.navigation,
                      label: 'Navigate',
                      onTap: () => _navigateToAddress(primaryAddress),
                    ),
                  if ((primaryPhone != null || primaryAddress != null))
                    const SizedBox(width: 8),
                  // Spacer to push button to the right
                  const Spacer(),
                  // "Add to My Day" button
                  if ((isInMyDayValue.value ?? false) == true)
                    Icon(
                      LucideIcons.checkCircle,
                      size: 20,
                      color: const Color(0xFF22C55E),
                    )
                  else
                    GestureDetector(
                      onTap: () => _addToMyDay(client),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTouchpointSummary(Touchpoint touchpoint) {
    final ordinal = touchpoint.ordinal;
    final type = touchpoint.type == TouchpointType.visit ? 'Visit' : 'Call';
    final timeAgo = _getTimeAgo(touchpoint.date);
    return '$ordinal $type - $timeAgo';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        final minutes = difference.inMinutes;
        return minutes <= 1 ? 'just now' : '${minutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? 'last week' : '${weeks}w ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? 'last month' : '${months}mo ago';
    }
  }

  void _callClient(String? phone) {
    if (phone == null || phone.isEmpty) {
      showToast('No phone number available');
      return;
    }
    HapticUtils.lightImpact();
    showToast('Calling $phone...');
  }

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      showToast('No address available');
      return;
    }
    HapticUtils.lightImpact();
    showToast('Navigating to $address...');
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: const Color(0xFF0F172A),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
