// Simplified Clients page with Assigned Clients / All Clients filters and pagination
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../app.dart';
import '../../../../core/utils/haptic_utils.dart';
import '../../../../core/utils/debounce_utils.dart';
import '../../../../core/utils/app_notification.dart';
import '../../../../services/api/my_day_api_service.dart';
import '../../../../services/api/client_api_service.dart' show ClientsResponse;
import '../../../../services/api/itinerary_api_service.dart' show todayItineraryProvider;
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
    clientAttributeFilterProvider,
    touchpointFilterProvider,
    myDayApiServiceProvider,
    assignedClientsFetchProvider,
    AssignedClientsFetchState;
import '../../../../core/utils/app_notification.dart';
import '../../../../shared/widgets/client/touchpoint_progress_badge.dart';
import '../../../../shared/widgets/client/touchpoint_status_badge.dart';
import '../../../../shared/widgets/client/client_status_badge.dart';
import '../../../../shared/widgets/client/client_list_tile.dart';
import '../../../../shared/widgets/filters/touchpoint_filter_chips.dart';
import '../../../../shared/widgets/filters/filter_drawer.dart';
import '../../../../shared/widgets/filters/active_filter_chips_row.dart';
import '../../../../shared/providers/client_attribute_filter_provider.dart' show activeFilterCountProvider;
import '../../../../models/client_status.dart';
import '../../../my_day/presentation/providers/my_day_provider.dart' show myDayStateProvider;
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../data/models/client_model.dart';
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

  // Optimistic set of client IDs scheduled today — prevents button re-enabling during provider reload
  final Set<String> _scheduledTodayIds = {};

  // Pagination - server-side
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Listen for assigned clients fetch status changes
    ref.listen<AssignedClientsFetchState>(
      assignedClientsFetchProvider,
      (previous, next) {
        if (!mounted) return;

        // Show notification when fetch starts
        if (next.isFetching && (previous == null || !previous.isFetching)) {
          AppNotification.showWarning(
            context,
            'Loading assigned clients...',
            duration: const Duration(seconds: 30), // Longer duration for large fetches
          );
        }

        // Show success notification when fetch completes
        if (!next.isFetching && next.fetchCount > 0 && (previous == null || previous.isFetching)) {
          AppNotification.showSuccess(
            context,
            '${next.fetchCount} assigned clients loaded',
            duration: const Duration(seconds: 3),
          );
        }

        // Dismiss any in-progress notification if fetch failed
        if (!next.isFetching && next.fetchCount == 0 && (previous == null || previous.isFetching)) {
          AppNotification.dismiss();
        }
      },
    );
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

  Future<void> _handleRefresh() async {
    HapticUtils.lightImpact();

    // Show orange notification that refresh is in progress
    if (mounted) {
      AppNotification.showWarning(
        context,
        _showAssignedClientsOnly
          ? 'Refreshing assigned clients...'
          : 'Refreshing all clients...',
        duration: const Duration(seconds: 10), // Longer duration for refresh
      );
    }

    if (_showAssignedClientsOnly) {
      ref.invalidate(assignedClientsProvider);
    } else {
      ref.invalidate(onlineClientsProvider);
    }

    // Show success notification when refresh completes
    if (mounted) {
      AppNotification.showSuccess(
        context,
        _showAssignedClientsOnly
          ? 'Assigned clients refreshed'
          : 'All clients refreshed',
      );
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
        ref.read(myDayStateProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        showToast('Failed to add to My Day: $e');
      }
    }
  }

  void _showFilterDrawer(BuildContext context) {
    showFilterDrawer(context, showAllPsgc: !_showAssignedClientsOnly);
  }

  @override
  Widget build(BuildContext context) {
    final assignedMunicipalitiesAsync = ref.watch(assignedMunicipalitiesProvider);
    final isOnline = ref.watch(isOnlineProvider);
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
                            Future.microtask(() {
                              if (!mounted) return;
                              // Reset all state to prevent contamination from All Clients mode
                              ref.read(assignedClientSearchQueryProvider.notifier).state = '';
                              ref.read(assignedClientPageProvider.notifier).state = 1;
                              ref.read(touchpointFilterProvider.notifier).clear();
                              ref.read(locationFilterProvider.notifier).clear();
                              ref.read(clientAttributeFilterProvider.notifier).clear();
                              ref.invalidate(onlineClientsProvider);
                              ref.invalidate(assignedClientsProvider);
                            });
                          }),
                          const SizedBox(width: 8),
                          _buildFilterToggle('All Clients', !_showAssignedClientsOnly, () {
                            HapticUtils.lightImpact();
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
                            Future.microtask(() {
                              if (!mounted) return;
                              ref.read(onlineClientSearchQueryProvider.notifier).state = '';
                              ref.read(onlineClientPageProvider.notifier).state = 1;
                              ref.read(touchpointFilterProvider.notifier).clear();
                              ref.read(locationFilterProvider.notifier).clear();
                              ref.read(clientAttributeFilterProvider.notifier).clear();
                              ref.invalidate(onlineClientsProvider);
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
                          Consumer(
                            builder: (context, ref, _) {
                              final count = ref.watch(activeFilterCountProvider);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.tune),
                                    onPressed: () => _showFilterDrawer(context),
                                  ),
                                  if (count > 0)
                                    Positioned(
                                      right: 4,
                                      top: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$count',
                                          style: const TextStyle(color: Colors.white, fontSize: 9),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
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

                const SizedBox(height: 8),
                const TouchpointFilterChips(),

                // Active filter chips row
                const ActiveFilterChipsRow(),

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
                                    return _buildClientTile(client);
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
                          Future.microtask(() {
                            if (!mounted) return;
                            ref.read(assignedClientSearchQueryProvider.notifier).state = '';
                            ref.read(assignedClientPageProvider.notifier).state = 1;
                            ref.read(touchpointFilterProvider.notifier).clear();
                            ref.read(locationFilterProvider.notifier).clear();
                            ref.read(clientAttributeFilterProvider.notifier).clear();
                            ref.invalidate(onlineClientsProvider);
                            ref.invalidate(assignedClientsProvider);
                          });
                        }),
                        const SizedBox(width: 8),
                        _buildFilterToggle('All Clients', !_showAssignedClientsOnly, () {
                          HapticUtils.lightImpact();
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
                          Future.microtask(() {
                            if (!mounted) return;
                            ref.read(onlineClientSearchQueryProvider.notifier).state = '';
                            ref.read(onlineClientPageProvider.notifier).state = 1;
                            ref.read(touchpointFilterProvider.notifier).clear();
                            ref.read(locationFilterProvider.notifier).clear();
                            ref.read(clientAttributeFilterProvider.notifier).clear();
                            ref.invalidate(onlineClientsProvider);
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
                        Consumer(
                          builder: (context, ref, _) {
                            final count = ref.watch(activeFilterCountProvider);
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.tune),
                                  onPressed: () => _showFilterDrawer(context),
                                ),
                                if (count > 0)
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(color: Colors.white, fontSize: 9),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
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

              const SizedBox(height: 8),
              const TouchpointFilterChips(),

              const SizedBox(height: 12),

              const ActiveFilterChipsRow(),

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
              // Use consistent icon for both tabs - search icon indicates "no results"
              _searchQuery.isEmpty ? LucideIcons.users : LucideIcons.search,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No clients found'
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
                    ? 'No clients assigned to your territory yet'
                    : 'No clients in the database')
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildClientTile(Client client) {
    // Check if client is in today's itinerary using local data
    final todayItineraryAsync = ref.watch(todayItineraryProvider);
    final today = DateTime.now();

    // Optimistic: already scheduled in this session
    bool isInMyDay = _scheduledTodayIds.contains(client.id);
    if (!isInMyDay) {
      todayItineraryAsync.when(
        data: (items) {
          isInMyDay = items.any((item) =>
            item.clientId == client.id &&
            item.scheduledDate.year == today.year &&
            item.scheduledDate.month == today.month &&
            item.scheduledDate.day == today.day
          );
        },
        loading: () {},  // keep optimistic value, don't flip to false while reloading
        error: (_, __) => isInMyDay = false,
      );
    }

    // Build action buttons
    final actionButtons = [
      _buildActionButton(
        icon: LucideIcons.calendar,
        label: isInMyDay ? 'Scheduled' : 'Add Today',
        isPrimary: true,
        onTap: isInMyDay ? null : () => _addClientToToday(client),
      ),
      _buildActionButton(
        icon: LucideIcons.calendarClock,
        label: 'Schedule',
        isPrimary: false,
        onTap: () => _showDatePickerForClient(client),
      ),
    ];

    return ClientListTile(
      client: client,
      onTap: () {
        HapticUtils.lightImpact();
        if (client.id != null) {
          context.push('/clients/${client.id}');
        } else {
          showToast('Client ID is missing');
        }
      },
      actions: actionButtons,
    );
  }

  // Action button helper
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    final fontSize = isDisabled && label.length > 20 ? 10.0 : 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isDisabled && label.length > 20 ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.shade300
              : isPrimary
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isDisabled || label.length <= 20)
              Icon(
                icon,
                size: 14,
                color: isDisabled
                    ? Colors.grey.shade500
                    : isPrimary
                        ? Colors.white
                        : const Color(0xFF0F172A),
              ),
            if (!isDisabled || label.length <= 20)
              const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isDisabled
                    ? Colors.grey.shade500
                    : isPrimary
                        ? Colors.white
                        : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Unified handler for adding client to itinerary
  // If useDatePicker is true, shows date picker first
  // Otherwise, adds directly to today's itinerary
  Future<void> _addClientToItinerary(Client client, {bool useDatePicker = false}) async {
    DateTime? scheduledDate;

    // Show date picker if requested
    if (useDatePicker) {
      final DateTime now = DateTime.now();
      scheduledDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 30)),
      );

      if (scheduledDate == null) return; // User canceled
    }

    try {
      HapticUtils.lightImpact();
      final myDayApiService = ref.read(myDayApiServiceProvider);

      final success = await myDayApiService.addToMyDay(
        client.id!,
        scheduledDate: scheduledDate,
      );

      if (mounted) {
        if (success) {
          if (scheduledDate == null) {
            setState(() { _scheduledTodayIds.add(client.id!); });
            showToast('Added to today\'s itinerary');
            ref.read(myDayStateProvider.notifier).refresh();
          } else {
            showToast('Added to itinerary for ${DateFormat('MMM dd').format(scheduledDate)}');
          }
          // Refresh today's itinerary
          ref.invalidate(todayItineraryProvider);
        } else {
          showToast('Failed to add client');
        }
      }
    } catch (e) {
      if (mounted) {
        showToast('Failed to add client: $e');
      }
    }
  }

  // Add client to today's itinerary (wrapper for unified handler)
  Future<void> _addClientToToday(Client client) async {
    await _addClientToItinerary(client, useDatePicker: false);
  }

  // Show date picker for adding client with custom date (wrapper for unified handler)
  Future<void> _showDatePickerForClient(Client client) async {
    await _addClientToItinerary(client, useDatePicker: true);
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
