// Simplified Clients page with My Clients / All Clients filters and pagination
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../shared/providers/app_providers.dart' show currentUserIdProvider;
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
  bool _showMyClientsOnly = true; // true = My Clients, false = All Clients

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Client> _getPaginatedClients() {
    if (_filteredClients.isEmpty) return [];

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredClients.length) return [];
    if (endIndex > _filteredClients.length) {
      return _filteredClients.sublist(startIndex);
    }
    return _filteredClients.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredClients.length / _itemsPerPage).ceil();

  void _goToPage(int page) {
    HapticUtils.lightImpact();
    setState(() {
      _currentPage = page;
    });
  }

  void _handleRefresh() async {
    HapticUtils.lightImpact();
    // Refresh clients
    ref.invalidate(clientsProvider);
  }

  void _showAddClientModal() {
    context.push('/clients/add');
  }

  Future<void> _addToMyDay(Client client) async {
    if (client.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client ID is missing'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    HapticUtils.lightImpact();
    final myDayApiService = ref.read(myDayApiServiceProvider);

    try {
      final success = await myDayApiService.addToMyDay(client.id!);
      if (success && mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${client.fullName} added to My Day'),
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 2),
          ),
        );
        ref.invalidate(_isInMyDayProvider(client.id!));
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to My Day: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final assignedMunicipalities = ref.watch(assignedMunicipalitiesProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return clientsAsync.when(
      data: (clients) {
        // Filter clients based on selected mode
        _allClients = clients;
        final query = _searchQuery.toLowerCase();

        _filteredClients = clients.where((client) {
          // Filter by view mode
          final matchesViewMode = !_showMyClientsOnly ||
              (client.municipality != null && assignedMunicipalities.contains(client.municipality));

          // Filter by search
          final matchesSearch = query.isEmpty ||
              client.fullName.toLowerCase().contains(query) ||
              (client.addresses.isNotEmpty &&
               client.addresses.first.city.toLowerCase().contains(query));

          return matchesViewMode && matchesSearch;
        }).toList();

        final paginatedClients = _getPaginatedClients();

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
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildFilterToggle('All Clients', !_showMyClientsOnly, () {
                            HapticUtils.lightImpact();
                            setState(() {
                              _showMyClientsOnly = false;
                              _currentPage = 1;
                            });
                          }),
                        ],
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
                    child: _buildTopPagination(),
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
                    child: _buildBottomPagination(),
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
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.alertCircle,
                  size: 40,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load clients',
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
                onPressed: () => ref.invalidate(clientsProvider),
                child: const Text('Retry'),
              ),
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

  Widget _buildTopPagination() {
    final startIndex = (_currentPage - 1) * _itemsPerPage + 1;
    final endIndex = (_currentPage * _itemsPerPage).clamp(1, _filteredClients.length);

    return Row(
      children: [
        Text(
          'Showing $startIndex-$endIndex of ${_filteredClients.length} clients',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (_totalPages > 1)
          Text(
            'Page $_currentPage of $_totalPages',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  Widget _buildBottomPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

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
                children: _buildPageNumbers(),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Next button
          _buildPageButton(
            icon: LucideIcons.chevronRight,
            enabled: _currentPage < _totalPages,
            onTap: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    // Show max 5 page numbers
    final startPage = (_currentPage - 2).clamp(1, _totalPages);
    final endPage = (_currentPage + 2).clamp(1, _totalPages);

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
              LucideIcons.users,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? (_showMyClientsOnly ? 'No assigned clients' : 'No clients yet')
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
                ? 'Add your first client to get started'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          if (_searchQuery.isEmpty) ...[
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Client ID is missing'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
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
                  // Touchpoint badge
                  if (latestTouchpoint != null) ...[
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

  void _callClient(String? phone) {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          backgroundColor: Color(0xFF64748B),
        ),
      );
      return;
    }
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone...')),
    );
  }

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No address available'),
          backgroundColor: Color(0xFF64748B),
        ),
      );
      return;
    }
    HapticUtils.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to $address...')),
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
