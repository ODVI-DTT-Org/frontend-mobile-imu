import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/debounce_utils.dart';
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart' show Client;
import '../../features/itineraries/data/repositories/itinerary_repository.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/client_api_service.dart' show ClientsResponse;
import '../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    onlineClientsProvider,
    assignedClientSearchQueryProvider,
    assignedClientPageProvider,
    onlineClientSearchQueryProvider,
    onlineClientPageProvider,
    currentUserRoleProvider,
    currentUserIdProvider,
    assignedMunicipalitiesProvider,
    clientTouchpointCountsProvider,
    locationFilterProvider,
    clientAttributeFilterProvider,
    touchpointFilterProvider;
import '../providers/client_attribute_filter_provider.dart' show activeFilterCountProvider;
import '../../features/clients/data/providers/client_favorites_provider.dart';
import 'filters/touchpoint_filter_chips.dart';
import 'filters/filter_drawer.dart';
import 'filters/active_filter_chips_row.dart';
import './client/client_list_tile.dart';
import './client/touchpoint_progress_badge.dart';
import './client/touchpoint_status_badge.dart';
import './client/client_status_badge.dart';

/// Reusable client selector modal for adding clients to itinerary
/// Used by both ItineraryPage and MyDayPage
class ClientSelectorModal extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final Function() onClientAdded;
  final String title;
  final bool showAssignedFilter;

  const ClientSelectorModal({
    super.key,
    required this.selectedDate,
    required this.onClientAdded,
    this.title = 'Add to Itinerary',
    this.showAssignedFilter = true,
  });

  @override
  ConsumerState<ClientSelectorModal> createState() => _ClientSelectorModalState();

  /// Show the modal as a bottom sheet
  static Future<void> show(
    BuildContext context, {
    required DateTime selectedDate,
    required Function() onClientAdded,
    String title = 'Add to Itinerary',
    bool showAssignedFilter = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ClientSelectorModal(
        selectedDate: selectedDate,
        onClientAdded: onClientAdded,
        title: title,
        showAssignedFilter: showAssignedFilter,
      ),
    );
  }
}

class _ClientSelectorModalState extends ConsumerState<ClientSelectorModal> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debounce(milliseconds: 300);
  String _searchQuery = '';
  String _clientFilter = 'assigned'; // 'assigned' or 'all'
  Set<String> _addingClientIds = {};
  Set<String> _addedClientIds = {};

  // Pagination state
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce.run(() {
      if (!mounted) return;

      // Store search query WITHOUT calling setState to prevent keyboard from closing
      _searchQuery = _searchController.text;
      _currentPage = 1; // Reset to first page on search

      // Update the appropriate search query provider based on mode
      if (_clientFilter == 'starred') {
        // Starred uses local SQLite — no server call needed
        // Trigger rebuild for starred filter
        setState(() {});
      } else if (_clientFilter == 'assigned') {
        ref.read(assignedClientSearchQueryProvider.notifier).state = _searchQuery;
        ref.read(assignedClientPageProvider.notifier).state = _currentPage;
        ref.invalidate(assignedClientsProvider);
      } else {
        // All Clients: update online search query provider
        ref.read(onlineClientSearchQueryProvider.notifier).state = _searchQuery;
        ref.read(onlineClientPageProvider.notifier).state = _currentPage;
        ref.invalidate(onlineClientsProvider);
      }
    });
  }

  void _applyClientFilter() {
    // Reset pagination and update provider
    setState(() {
      _currentPage = 1;
      _searchQuery = '';
      _searchController.clear();
    });

    // Defer provider updates until after build cycle
    Future.microtask(() {
      if (!mounted) return;

      // Reset shared filters to prevent contamination between Assigned/All modes
      ref.read(touchpointFilterProvider.notifier).clear();
      ref.read(locationFilterProvider.notifier).clear();
      ref.read(clientAttributeFilterProvider.notifier).clear();

      if (_clientFilter == 'starred') {
        // Starred uses local SQLite — no server call needed
      } else if (_clientFilter == 'assigned') {
        ref.read(assignedClientPageProvider.notifier).state = _currentPage;
        ref.read(assignedClientSearchQueryProvider.notifier).state = '';
        // Force fresh re-read from Hive to avoid stale/contaminated state
        ref.invalidate(assignedClientsProvider);
      } else {
        // For 'all' mode, use online pagination providers
        ref.read(onlineClientPageProvider.notifier).state = _currentPage;
        ref.read(onlineClientSearchQueryProvider.notifier).state = '';
        ref.invalidate(onlineClientsProvider);
      }
    });
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
      if (_clientFilter == 'starred') {
        // no-op: starred uses local SQLite stream
      } else if (_clientFilter == 'assigned') {
        ref.read(assignedClientPageProvider.notifier).state = page;
        ref.invalidate(assignedClientsProvider);
      } else {
        ref.read(onlineClientPageProvider.notifier).state = page;
        ref.invalidate(onlineClientsProvider);
      }
    });
  }

  void _filterClients() {
    // Clear search and reload clients
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _applyClientFilter();
  }

  int _totalPages(ClientsResponse meta) {
    return meta.totalPages;
  }

  int _totalItems(ClientsResponse meta) {
    return meta.totalItems;
  }

  List<Client> _getDisplayableClients(List<Client> clients) {
    return clients;
  }

  Future<void> _showDatePicker(Client client) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: widget.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (selectedDate != null && mounted) {
      await _addClientToItinerary(client, customDate: selectedDate);
    }
  }

  Future<void> _addClientToItinerary(Client client, {DateTime? customDate}) async {
    if (client.id == null) {
      if (mounted) {
        showToast('Invalid client: missing ID');
      }
      return;
    }

    // Validate UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(client.id!)) {
      if (mounted) {
        showToast('Invalid client ID format: ${client.id}');
      }
      return;
    }

    setState(() {
      _addingClientIds.add(client.id!);
    });

    try {
      final targetDate = customDate ?? widget.selectedDate;

      final repo = ref.read(itineraryRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.createItinerary(Itinerary(
        id: '',
        caravanId: userId,
        clientId: client.id!,
        scheduledDate: targetDate,
        status: 'pending',
        priority: 'normal',
      ));

      if (mounted) {
        HapticUtils.success();
        showToast('${client.fullName} added to ${_formatDateShort(targetDate)}');

        // Mark client as added (disable button, show "Added" status)
        setState(() {
          if (client.id != null) {
            _addedClientIds.add(client.id!);
          }
        });

        // Trigger parent refresh immediately
        widget.onClientAdded();

        // Invalidate clientTouchpointCountsProvider to refresh touchpoint counts
        ref.invalidate(clientTouchpointCountsProvider);
      }
    } catch (e) {
      if (mounted) {
        HapticUtils.error();
        debugPrint('Error adding client to itinerary: $e');

        // Extract error message from exception
        String errorMessage = 'Failed to add client';
        if (e is ApiException) {
          errorMessage = e.message;
        } else if (e.toString().contains('Client already')) {
          errorMessage = e.toString();
        }

        showToast(errorMessage);
      }
    } finally {
      setState(() {
        _addingClientIds.remove(client.id!);
      });
    }
  }

  String _formatDateShort(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _clientFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _clientFilter = value;
        });
        _applyClientFilter();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showFilterDrawer() {
    showFilterDrawer(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch touchpoint counts for badges
    final touchpointCountsAsync = ref.watch(clientTouchpointCountsProvider);

    // Watch keyboard height changes to trigger rebuilds when keyboard appears/disappears
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Starred filter uses local PowerSync SQLite — no server pagination
    if (_clientFilter == 'starred') {
      final starredAsync = ref.watch(favoritedClientListProvider);
      return starredAsync.when(
        data: (clients) {
          final displayableClients = _getDisplayableClients(clients.clients);
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Compact header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(DateFormat('EEE, MMM d').format(widget.selectedDate),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 20),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            ),
                          ],
                        ),
                      ),
                      // Compact search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            prefixIcon: const Icon(LucideIcons.search, size: 18),
                            hintStyle: const TextStyle(fontSize: 14),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                      // Compact filter chips
                      if (widget.showAssignedFilter)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              _buildFilterChip('★ Favorites', 'starred'),
                              const SizedBox(width: 6),
                              _buildFilterChip('Assigned', 'assigned'),
                              const SizedBox(width: 6),
                              _buildFilterChip('All Clients', 'all'),
                            ],
                          ),
                        ),
                      if (displayableClients.isEmpty)
                        const Expanded(
                          child: Center(child: Text('No favorites yet', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        Expanded(
                          child: _buildClientList(displayableClients, displayableClients.length, touchpointCountsAsync, scrollController),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, __) => const Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, __) => Center(child: Text('Error: $e')),
        ),
      );
    }

    // Choose provider based on mode (Assigned Clients vs All Clients)
    final clientsAsync = _clientFilter == 'assigned'
        ? ref.watch(assignedClientsProvider)
        : ref.watch(onlineClientsProvider);

    return clientsAsync.when(
      data: (data) {
        // Both providers return ClientsResponse
        final clients = data.items;
        final meta = data;
        final totalPages = _totalPages(meta);
        final totalItems = _totalItems(meta);

        final displayableClients = _getDisplayableClients(clients);

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            // Get keyboard height for safe area padding
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: keyboardHeight),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Compact header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEE, MMM d').format(widget.selectedDate),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                    // Compact search bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          hintStyle: const TextStyle(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ),
                    // Compact filter chips
                    if (widget.showAssignedFilter)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            _buildFilterChip('★ Favorites', 'starred'),
                            const SizedBox(width: 6),
                            _buildFilterChip('Assigned', 'assigned'),
                            const SizedBox(width: 6),
                            _buildFilterChip('All Clients', 'all'),
                          ],
                        ),
                      ),
                    // Compact client count and pagination
                    if (totalItems > 0 || totalPages > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Client count
                            if (totalItems > 0)
                              Text(
                                '${displayableClients.length} of $totalItems',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            // Pagination controls
                            if (totalPages > 1)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(LucideIcons.chevronLeft, size: 16),
                                    onPressed: _currentPage > 1
                                        ? () => _goToPage(_currentPage - 1)
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_currentPage/$totalPages',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.chevronRight, size: 16),
                                    onPressed: _currentPage < totalPages
                                        ? () => _goToPage(_currentPage + 1)
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    // Client list
                    Expanded(
                      child: _buildClientList(displayableClients, totalItems, touchpointCountsAsync, scrollController),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Compact header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEE, MMM d').format(widget.selectedDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                  ),
                  // Compact search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        hintStyle: const TextStyle(fontSize: 14),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ),
                  ),
                  // Filter toggle
                  if (widget.showAssignedFilter)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          _buildFilterChip('★ Favorites', 'starred'),
                          const SizedBox(width: 6),
                          _buildFilterChip('Assigned', 'assigned'),
                          const SizedBox(width: 6),
                          _buildFilterChip('All Clients', 'all'),
                        ],
                      ),
                    ),
                  // Client list skeleton (only the list shows skeleton)
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: 7, // Show 7 skeleton cards
                      itemBuilder: (context, index) => _buildClientSkeleton(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      error: (error, _) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text('Failed to load clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(error.toString(), style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_clientFilter == 'assigned') {
                          ref.invalidate(assignedClientsProvider);
                        } else if (_clientFilter != 'starred') {
                          ref.invalidate(onlineClientsProvider);
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClientList(
    List<Client> displayableClients,
    int totalItems,
    AsyncValue<Map<String, int>> touchpointCountsAsync,
    ScrollController scrollController,
  ) {
    if (displayableClients.isEmpty) {
      // Check if user has no assigned municipalities
      final UserRole userRole = ref.read(currentUserRoleProvider);
      final shouldFilterByArea = switch (userRole) {
        UserRole.admin || UserRole.assistantAreaManager => false,
        UserRole.areaManager || UserRole.caravan || UserRole.tele => true,
        _ => false, // Fallback for any other roles
      };

      final assignedMunicipalitiesAsync = ref.watch(assignedMunicipalitiesProvider);
      final hasNoAssignedLocations = shouldFilterByArea &&
          assignedMunicipalitiesAsync.valueOrNull?.isEmpty == true &&
          _clientFilter == 'assigned';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasNoAssignedLocations
                  ? LucideIcons.mapPinOff
                  : LucideIcons.users,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasNoAssignedLocations
                  ? 'No Assigned Locations'
                  : (_searchQuery.isEmpty ? 'No clients available' : 'No clients found'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              hasNoAssignedLocations
                  ? 'You have no assigned locations. Please contact your administrator to assign areas to you.'
                  : (_searchQuery.isEmpty
                      ? 'No clients match the current filters'
                      : 'Try a different search term'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (hasNoAssignedLocations) ...[
              const SizedBox(height: 16),
              Text(
                'Switch to "All Clients" to see all available clients',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayableClients.length,
      itemBuilder: (context, index) {
        final client = displayableClients[index];
        final isAdding = _addingClientIds.contains(client.id);
        final isAdded = client.id != null && _addedClientIds.contains(client.id);

        final actionButtons = [
          _buildActionButton(
            icon: isAdded ? LucideIcons.checkCircle : LucideIcons.calendar,
            label: isAdded ? 'Added' : 'Add Today',
            isPrimary: true,
            isLoading: isAdding,
            onTap: isAdded || isAdding ? null : () => _addClientToItinerary(client),
          ),
          _buildActionButton(
            icon: LucideIcons.calendarClock,
            label: 'Schedule',
            isPrimary: false,
            isLoading: false,
            onTap: isAdding ? null : () => _showDatePicker(client),
          ),
        ];

        return ClientListTile(
          client: client,
          useCardStyle: true,
          actions: actionButtons,
        );
      },
    );
  }

  Widget _buildClientSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSkeletonCircle(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonLine(width: 100),
                      const SizedBox(height: 3),
                      _buildSkeletonLine(width: 150),
                      const SizedBox(height: 3),
                      _buildSkeletonLine(width: 80),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildSkeletonButton()),
                const SizedBox(width: 6),
                Expanded(child: _buildSkeletonButton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCircle() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSkeletonLine({required double width}) {
    return Container(
      height: 10,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null && !isLoading;
    // Use smaller font for disabled buttons with longer text
    final fontSize = isDisabled && label.length > 20 ? 10.0 : 12.0;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isDisabled && label.length > 20 ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.shade200
              : isDisabled
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
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPrimary ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              )
            else if (!isDisabled || label.length <= 20)
              Icon(
                icon,
                size: 14,
                color: isDisabled
                    ? Colors.grey.shade500
                    : (isPrimary ? Colors.white : const Color(0xFF0F172A)),
              ),
            if (!isDisabled || label.length <= 20) const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isLoading
                    ? Colors.grey.shade500
                    : isDisabled
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
}
