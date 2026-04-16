// Simplified Clients page with Assigned Clients / All Clients filters and pagination
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../app.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/debounce_utils.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/client_api_service.dart' show ClientsResponse;
import '../../../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    assignedClientSearchQueryProvider,
    assignedClientPageProvider,
    onlineClientsProvider,
    onlineClientSearchQueryProvider,
    onlineClientPageProvider,
    isOnlineProvider,
    assignedMunicipalitiesProvider,
    currentUserRoleProvider,
    locationFilterProvider,
    clientAttributeFilterProvider;
import '../../../../shared/widgets/client/touchpoint_progress_badge.dart';
import '../../../../shared/widgets/client/touchpoint_status_badge.dart';
import '../../../../shared/widgets/client/client_status_badge.dart';
import '../../../../shared/widgets/location_filter_icon.dart';
import '../../../../shared/widgets/location_filter_chips.dart';
import '../../../../shared/widgets/location_filter_bottom_sheet.dart';
import '../../../../shared/widgets/filters/client_attribute_filter_bottom_sheet_dropdown.dart';
import '../../../../shared/widgets/filters/attribute_filter_chip.dart';
import '../../../../shared/widgets/filters/client_attribute_filter_helpers.dart';
import '../widgets/client_filter_icon_button.dart';
import '../../../../models/client_status.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../data/models/client_model.dart';
import '../../../../shared/models/client_attribute_filter.dart';
import '../../../../services/api/itinerary_api_service.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});

  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debounce(milliseconds: 300);
  String _searchQuery = '';
  bool _showAssignedClientsOnly = true; // true = Assigned Clients (API with municipality filter, cached), false = All Clients (API, no filter)

  // Pagination - server-side
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce.run(() {
      if (!mounted) return;

      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 1; // Reset to first page on search
      });

      // Defer provider updates until after build cycle
      Future.microtask(() {
        if (!mounted) return;

        // Update the appropriate search query provider based on mode
        if (_showAssignedClientsOnly) {
          // Assigned Clients: update assigned search query provider
          ref.read(assignedClientSearchQueryProvider.notifier).state = _searchQuery;
        } else {
          // All Clients: update online search query provider
          ref.read(onlineClientSearchQueryProvider.notifier).state = _searchQuery;
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  int _totalPages(ClientsResponse meta) {
    return meta.totalPages;
  }

  int _totalItems(ClientsResponse meta) {
    return meta.totalItems;
  }

  void _goToPage(int page) {
    HapticUtils.lightImpact();
    setState(() {
      _currentPage = page;
    });

    // Defer provider updates until after build cycle
    Future.microtask(() {
      if (!mounted) return;

      // Update the appropriate provider's page state and invalidate to trigger refetch
      if (_showAssignedClientsOnly) {
        ref.read(assignedClientPageProvider.notifier).state = page;
        ref.invalidate(assignedClientsProvider);
      } else {
        ref.read(onlineClientPageProvider.notifier).state = page;
        ref.invalidate(onlineClientsProvider);
      }
    });
  }

  void _handleRefresh() async {
    HapticUtils.lightImpact();
    // Refresh the appropriate provider based on current mode
    if (_showAssignedClientsOnly) {
      ref.invalidate(assignedClientsProvider);
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
        ref.invalidate(todayItineraryProvider);
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        showToast('Failed to add to My Day: $e');
      }
    }
  }

  void _showLocationFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationFilterBottomSheet(
        onApply: (filter) {
          ref.read(locationFilterProvider.notifier).updateFilter(filter);
          // Invalidate the appropriate provider based on mode
          if (_showAssignedClientsOnly) {
            ref.invalidate(assignedClientsProvider);
          } else {
            ref.invalidate(onlineClientsProvider);
          }
        },
        showAllPsgcAreas: !_showAssignedClientsOnly, // All Clients mode = show all PSGC areas
      ),
    );
  }

  void _showAttributeFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientAttributeFilterDropdownBottomSheet(
        onApply: (filter) {
          final notifier = ref.read(clientAttributeFilterProvider.notifier);
          notifier.updateFilter(filter);
          // Invalidate the appropriate provider based on mode
          if (_showAssignedClientsOnly) {
            ref.invalidate(assignedClientsProvider);
          } else {
            ref.invalidate(onlineClientsProvider);
          }
        },
        onClearAll: () {
          final notifier = ref.read(clientAttributeFilterProvider.notifier);
          notifier.clear();
          // Invalidate the appropriate provider based on mode
          if (_showAssignedClientsOnly) {
            ref.invalidate(assignedClientsProvider);
          } else {
            ref.invalidate(onlineClientsProvider);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedMunicipalitiesAsync = ref.watch(assignedMunicipalitiesProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final attributeFilter = ref.watch(clientAttributeFilterProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Choose provider based on mode
    // Assigned Clients = API with municipality filter (cached for offline)
    // All Clients = Online API (search all clients in database)
    final clientsAsync = _showAssignedClientsOnly
        ? ref.watch(assignedClientsProvider)
        : ref.watch(onlineClientsProvider);

    return clientsAsync.when(
      data: (data) {
        // Both providers now return ClientsResponse
        final clients = data.items;
        final meta = data;

        // Server handles filtering and pagination, just display the results
        final paginatedClients = clients;
        final totalPages = _totalPages(meta);
        final totalItems = _totalItems(meta);

        return Scaffold(
          backgroundColor: Colors.white,
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
                            _showAssignedClientsOnly ? 'Assigned Clients' : 'All Clients',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add Client icon button
                          InkWell(
                            onTap: _showAddClientModal,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Toggle between Assigned Clients and All Clients
                      Row(
                        children: [
                          _buildFilterToggle('Assigned Clients', _showAssignedClientsOnly, () {
                            HapticUtils.lightImpact();
                            setState(() {
                              _showAssignedClientsOnly = true;
                              _currentPage = 1;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            // Defer provider updates until after build cycle
                            Future.microtask(() {
                              if (!mounted) return;
                              // Invalidate online provider when switching back to Assigned Clients
                              ref.invalidate(onlineClientsProvider);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildFilterToggle('All Clients', !_showAssignedClientsOnly, () {
                            HapticUtils.lightImpact();
                            // Check if online before switching to All Clients
                            final isOnlineNow = ref.read(isOnlineProvider);
                            if (!isOnlineNow) {
                              showToast('Cannot search all clients while offline');
                              return;
                            }
                            setState(() {
                              _showAssignedClientsOnly = false;
                              _currentPage = 1;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                            // Defer provider updates until after build cycle
                            Future.microtask(() {
                              if (!mounted) return;
                              // Reset online search and page to first page when switching
                              ref.read(onlineClientSearchQueryProvider.notifier).state = '';
                              ref.read(onlineClientPageProvider.notifier).state = 1;
                            });
                          }),
                        ],
                      ),
                      // Show online indicator when in All Clients mode
                      if (!_showAssignedClientsOnly)
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
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: Icon(LucideIcons.x, color: Colors.grey.shade400, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                          ClientFilterIconButton(
                            showAttributeOnly: true,
                            onPressed: () => _showAttributeFilterBottomSheet(context),
                          ),
                          LocationFilterIcon(
                            onTap: () => _showLocationFilterBottomSheet(context),
                          ),
                        ],
                      ),
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

                // Active filter chips
                const LocationFilterChips(),

                // Client attribute filter chips
                if (attributeFilter.hasFilter)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                    child: _buildAttributeFilterChips(attributeFilter),
                  ),

                const SizedBox(height: 12),

                // Top Pagination Info
                if (totalItems > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                    child: _buildTopPagination(totalItems, totalPages),
                  ),

                const SizedBox(height: 8),

                // Client list
                Expanded(
                  child: paginatedClients.isEmpty
                      ? _buildEmptyState()
                      : Column(
                          children: [
                            // Client list
                            Expanded(
                              child: RefreshIndicator(
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
                          ],
                        ),
                ),

                // Bottom Pagination
                if (totalItems > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17, vertical: 16),
                    child: _buildBottomPagination(totalPages),
                  ),
              ],
            ),
          ),
        );
      },
      loading: () {
        final attributeFilter = ref.watch(clientAttributeFilterProvider);
        return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header (always visible)
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
                          _showAssignedClientsOnly ? 'Assigned Clients' : 'All Clients',
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
                    // Toggle between Assigned Clients and All Clients
                    Row(
                      children: [
                        _buildFilterToggle('Assigned Clients', _showAssignedClientsOnly, () {
                          HapticUtils.lightImpact();
                          setState(() {
                            _showAssignedClientsOnly = true;
                            _currentPage = 1;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          // Defer provider updates until after build cycle
                          Future.microtask(() {
                            if (!mounted) return;
                            // Invalidate online provider when switching back to Assigned Clients
                            ref.invalidate(onlineClientsProvider);
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterToggle('All Clients', !_showAssignedClientsOnly, () {
                          HapticUtils.lightImpact();
                          // Check if online before switching to All Clients
                          final isOnlineNow = ref.read(isOnlineProvider);
                          if (!isOnlineNow) {
                            showToast('Cannot search all clients while offline');
                            return;
                          }
                          setState(() {
                            _showAssignedClientsOnly = false;
                            _currentPage = 1;
                            _searchQuery = '';
                            _searchController.clear();
                          });
                          // Defer provider updates until after build cycle
                          Future.microtask(() {
                            if (!mounted) return;
                            // Reset online search and page to first page when switching
                            ref.read(onlineClientSearchQueryProvider.notifier).state = '';
                            ref.read(onlineClientPageProvider.notifier).state = 1;
                          });
                        }),
                      ],
                    ),
                    // Show online indicator when in All Clients mode
                    if (!_showAssignedClientsOnly)
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

              // Search Bar (always visible)
              Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(LucideIcons.search, color: Colors.grey.shade400, size: 20),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(LucideIcons.x, color: Colors.grey.shade400, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        ClientFilterIconButton(
                          showAttributeOnly: true,
                          onPressed: () => _showAttributeFilterBottomSheet(context),
                        ),
                        LocationFilterIcon(
                          onTap: () => _showLocationFilterBottomSheet(context),
                        ),
                      ],
                    ),
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

              // Active filter chips (loading state)
              if (attributeFilter.hasFilter)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                  child: _buildAttributeFilterChips(attributeFilter),
                ),

              const SizedBox(height: 12),

              // Client list skeleton (only the list shows skeleton)
              const Expanded(
                child: ClientListSkeleton(itemCount: 7),
              ),
            ],
          ),
        ),
      );},
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
                  color: _showAssignedClientsOnly
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showAssignedClientsOnly
                      ? LucideIcons.alertCircle
                      : LucideIcons.wifiOff,
                  size: 40,
                  color: _showAssignedClientsOnly
                      ? Colors.red.shade400
                      : Colors.orange.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _showAssignedClientsOnly
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
                  if (_showAssignedClientsOnly) {
                    ref.invalidate(assignedClientsProvider);
                  } else {
                    ref.invalidate(onlineClientsProvider);
                  }
                },
                child: Text(_showAssignedClientsOnly ? 'Retry' : 'Check Connection'),
              ),
              if (!_showAssignedClientsOnly) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAssignedClientsOnly = true;
                      _currentPage = 1;
                    });
                  },
                  child: const Text('Switch to Assigned Clients (Offline)'),
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
    final startIndex = _showAssignedClientsOnly
        ? (_currentPage - 1) * _itemsPerPage + 1
        : (_currentPage - 1) * 10 + 1; // Server uses perPage=10
    final endIndex = _showAssignedClientsOnly
        ? (_currentPage * _itemsPerPage).clamp(1, totalItems)
        : (_currentPage * 10).clamp(1, totalItems);

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
              _showAssignedClientsOnly ? LucideIcons.users : LucideIcons.search,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? (_showAssignedClientsOnly ? 'No assigned clients' : 'No clients found')
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
                ? (_showAssignedClientsOnly
                    ? 'Add your first client to get started'
                    : 'Try searching for clients by name')
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    final latestTouchpoint = client.touchpointSummary.isNotEmpty
        ? client.touchpointSummary.last
        : null;
    final isFirstTime = client.touchpointSummary.isEmpty;

    // Check if client is in today's itinerary using local data
    final todayItineraryAsync = ref.watch(todayItineraryProvider);
    final today = DateTime.now();

    bool isInMyDay = false;
    todayItineraryAsync.when(
      data: (items) {
        isInMyDay = items.any((item) =>
          item.clientId == client.id &&
          item.scheduledDate.year == today.year &&
          item.scheduledDate.month == today.month &&
          item.scheduledDate.day == today.day
        );
      },
      loading: () => isInMyDay = false,
      error: (_, __) => isInMyDay = false,
    );

    final primaryAddress = client.fullAddress;

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
                        if (isInMyDay)
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
              // Touchpoint progress and status badges (replicated from ClientSelectorModal)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  TouchpointProgressBadge(client: client),
                  TouchpointStatusBadge(client: client),
                ],
              ),
              const SizedBox(height: 4),
              // Overall status badge (Loan Released, Visited today, Already added, Call Touchpoint)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: [
                  ClientStatusBadge(
                    client: client,
                    status: ClientStatus(
                      inItinerary: isInMyDay,
                      loanReleased: client.loanReleased,
                    ),
                    currentUserRole: ref.watch(currentUserRoleProvider),
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
                      client.fullAddress ?? 'No address',
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
                  // Quick action: Navigate (only in Assigned Clients tab)
                  if (_showAssignedClientsOnly && primaryAddress != null)
                    _QuickActionButton(
                      icon: LucideIcons.navigation,
                      label: 'Navigate',
                      onTap: () => _navigateToAddress(primaryAddress),
                    ),
                  // Spacer to push button to the right
                  const Spacer(),
                  // "Add to My Day" button
                  if (isInMyDay)
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

  void _navigateToAddress(String? address) {
    if (address == null || address.isEmpty) {
      showToast('No address available');
      return;
    }
    HapticUtils.lightImpact();
    showToast('Navigating to $address...');
  }

  Widget _buildAttributeFilterChips(ClientAttributeFilter filter) {
    final chips = <Widget>[];

    // Add Client Type chip if active
    if (filter.clientType != null) {
      chips.add(
        AttributeFilterChip(
          label: formatClientType(filter.clientType),
          icon: getClientTypeIcon(filter.clientType),
          onRemoved: () => _removeFilter('clientType'),
        ),
      );
    }

    // Add Market Type chip if active
    if (filter.marketType != null) {
      chips.add(
        AttributeFilterChip(
          label: formatMarketType(filter.marketType),
          icon: getMarketTypeIcon(filter.marketType),
          onRemoved: () => _removeFilter('marketType'),
        ),
      );
    }

    // Add Pension Type chip if active
    if (filter.pensionType != null) {
      chips.add(
        AttributeFilterChip(
          label: formatPensionType(filter.pensionType),
          icon: getPensionTypeIcon(filter.pensionType),
          onRemoved: () => _removeFilter('pensionType'),
        ),
      );
    }

    // Add Product Type chip if active
    if (filter.productType != null) {
      chips.add(
        AttributeFilterChip(
          label: formatProductType(filter.productType),
          icon: getProductTypeIcon(filter.productType),
          onRemoved: () => _removeFilter('productType'),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: chips,
    );
  }

  void _removeFilter(String filterType) {
    HapticUtils.lightImpact();
    final currentFilter = ref.read(clientAttributeFilterProvider);
    ClientAttributeFilter newFilter;

    switch (filterType) {
      case 'clientType':
        newFilter = currentFilter.copyWith(clientType: null);
        break;
      case 'marketType':
        newFilter = currentFilter.copyWith(marketType: null);
        break;
      case 'pensionType':
        newFilter = currentFilter.copyWith(pensionType: null);
        break;
      case 'productType':
        newFilter = currentFilter.copyWith(productType: null);
        break;
      default:
        return;
    }

    ref.read(clientAttributeFilterProvider.notifier).updateFilter(newFilter);

    // Invalidate the appropriate provider based on mode
    if (_showAssignedClientsOnly) {
      ref.invalidate(assignedClientsProvider);
    } else {
      ref.invalidate(onlineClientsProvider);
    }
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
