// NEW VERSION of the Clients page
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../data/models/client_model.dart';
import '../providers/clients_provider.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTouchpoint = 'all'; // 'all', 1-7, or null for archive
  bool _showInterestedOnly = false;
  String? _selectedMarketType;
  String? _selectedProductType;
  String? _selectedPensionType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Filter clients based on current filters
  List<Client> get _filteredClients {
    final clientsAsync = ref.watch(clientsProvider);
    final query = _searchQuery.toLowerCase();

    return clientsAsync.when(
      data: (clients) => clients.where((client) {
        final matchesSearch = query.isEmpty ||
            client.fullName.toLowerCase().contains(query) ||
            (client.addresses.isNotEmpty && client.addresses.first.city.toLowerCase().contains(query));

        // Filter by Interested status
        final matchesInterested = !_showInterestedOnly || client.isStarred;

        // Filter by touchpoint
        final matchesTouchpoint = _selectedTouchpoint == 'all' ||
            (_getLatestTouchpointNumber(client) ?? 0) == int.parse(_selectedTouchpoint);

        // Filter by market/product/pension type
        final matchesMarketType = _selectedMarketType == null ||
            client.marketType?.name.toUpperCase() == _selectedMarketType;
        final matchesProductType = _selectedProductType == null ||
            client.productType.name.toUpperCase() == _selectedProductType;
        final matchesPensionType = _selectedPensionType == null ||
            client.pensionType.name.toUpperCase() == _selectedPensionType;

        return matchesSearch && matchesInterested &&
               matchesTouchpoint && matchesMarketType &&
               matchesProductType && matchesPensionType;
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  int _getLatestTouchpointNumber(Client client) {
    if (client.touchpoints.isEmpty) return 0;
    return client.touchpoints.last.touchpointNumber;
  }

  void _handleRefresh() async {
    HapticUtils.lightImpact();
    ref.invalidate(clientsProvider);
    await _loadClients();
  }

  void _showAddClientModal() {
    context.push('/clients/add');
  }

  void _clearFilters() {
    setState(() {
      _selectedTouchpoint = 'all';
      _selectedMarketType = null;
      _selectedProductType = null;
      _selectedPensionType = null;
      _showInterestedOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clients = _filteredClients;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
              child: Row(
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
                  const Text(
                    'My Clients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 50),
                ],
              ),
            ),

            // Interested Tab
            Container(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
              child: Row(
                children: [
                  _buildInterestedChip(),
                ],
              ),
            ),
            const SizedBox(height: 12),

          // Touchpoint Selector (horizontal scroll)
          Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTouchpointChip('all', 'All'),
                _buildTouchpointChip('1st', '1st'),
                _buildTouchpointChip('2nd', '2nd'),
                _buildTouchpointChip('3rd', '3rd'),
                _buildTouchpointChip('4th', '4th'),
                _buildTouchpointChip('5th', '5th'),
                _buildTouchpointChip('6th', '6th'),
                _buildTouchpointChip('7th', '7th'),
                _buildArchiveChip(),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar with Filter
          Container(
            margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                // Filter button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.slidersHorizontal),
                    color: const Color(0xFF0F172A),
                    onPressed: _showFilterModal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Client list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : clients.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async => _handleRefresh(),
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return _buildClientCard(client);
                          },
                        ),
                      ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildInterestedChip() {
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          _showInterestedOnly = !_showInterestedOnly;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showInterestedOnly
              ? const Color(0xFF22C55E)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.star,
              size: 14,
              color: _showInterestedOnly
                  ? Colors.white
                  : const Color(0xFF0F172A),
            ),
            const SizedBox(width: 4),
            Text(
              'Interested',
              style: TextStyle(
                color: _showInterestedOnly
                  ? Colors.white
                  : const Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchpointChip(String value, String label) {
    final isSelected = _selectedTouchpoint == value;
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          _selectedTouchpoint = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveChip() {
    final isSelected = _selectedTouchpoint == 'archive';
    return GestureDetector(
      onTap: () {
        HapticUtils.lightImpact();
        setState(() {
          _selectedTouchpoint = 'archive';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0F172A)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          LucideIcons.archive,
          size: 16,
          color: isSelected ? Colors.white : const Color(0xFF64748B),
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
            _searchQuery.isEmpty ? 'No clients yet' : 'No clients found',
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
          context.push('/clients/${client.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                    latestTouchpoint!.ordinal,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
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
                              : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Clients',
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
                const Text('Market Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  children: MarketType.values.map((type) => _buildFilterChip(
                    type.name.toUpperCase(),
                    _selectedMarketType == type.name.toUpperCase(),
                    () => setState(() {
                      _selectedMarketType = _selectedMarketType == type.name.toUpperCase()
                          ? null
                          : type.name.toUpperCase();
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Product Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  children: ProductType.values.map((type) => _buildFilterChip(
                    type.name.toUpperCase(),
                    _selectedProductType == type.name.toUpperCase(),
                    () => setState(() {
                      _selectedProductType = _selectedProductType == type.name.toUpperCase()
                          ? null
                          : type.name.toUpperCase();
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Pension Type', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  children: PensionType.values.map((type) => _buildFilterChip(
                    type.name.toUpperCase(),
                    _selectedPensionType == type.name.toUpperCase(),
                    () => setState(() {
                      _selectedPensionType = _selectedPensionType == type.name.toUpperCase()
                          ? null
                          : type.name.toUpperCase();
                    }),
                  )).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearFilters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    child: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
