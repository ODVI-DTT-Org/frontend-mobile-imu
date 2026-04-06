import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/debounce_utils.dart';
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart' show Client, ClientType, TouchpointPattern, TouchpointType;
import '../../models/client_status.dart';
import '../../services/api/my_day_api_service.dart';
import '../../services/api/itinerary_api_service.dart' show todayItineraryProvider;
import '../../services/api/api_exception.dart';
import '../../services/api/client_api_service.dart' show ClientsResponse;
import '../../services/sync/powersync_service.dart';
import '../../shared/providers/app_providers.dart' show
    assignedClientsProvider,
    onlineClientsProvider,
    assignedClientSearchQueryProvider,
    assignedClientPageProvider,
    onlineClientSearchQueryProvider,
    onlineClientPageProvider,
    isOnlineProvider,
    currentUserRoleProvider,
    assignedMunicipalitiesProvider,
    clientTouchpointsSyncProvider,
    myDayApiServiceProvider;

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
  Set<String> _addedClientIds = {}; // Track clients that have been added

  // Pagination state
  final int _itemsPerPage = 10;
  int _currentPage = 1;

  // Status tracking state
  Map<String, ClientStatus> _clientStatuses = {};
  bool _isLoadingStatuses = true;
  bool _hasStatusError = false;

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

      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 1; // Reset to first page on search
      });

      // Defer provider updates until after build cycle
      Future.microtask(() {
        if (!mounted) return;

        // Update the appropriate search query provider based on mode
        if (_clientFilter == 'assigned') {
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

      if (_clientFilter == 'assigned') {
        ref.read(assignedClientPageProvider.notifier).state = _currentPage;
        ref.invalidate(assignedClientsProvider);
      } else {
        // For 'all' mode, use online pagination providers
        ref.read(onlineClientPageProvider.notifier).state = _currentPage;
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
      if (_clientFilter == 'assigned') {
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
    // Hide loan released clients from the list
    return clients.where((client) => !client.loanReleased).toList();
  }

  Future<void> _loadClientStatuses() async {
    setState(() {
      _isLoadingStatuses = true;
      _hasStatusError = false;
    });

    try {
      final isOnline = ref.read(isOnlineProvider);
      final today = DateTime.now();

      if (isOnline) {
        // Use API when online
        await _loadStatusesFromAPI(today);
      } else {
        // Use PowerSync when offline
        await _loadStatusesFromPowerSync(today);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasStatusError = true;
          _isLoadingStatuses = false;
        });
        debugPrint('Error loading client statuses: $e');
      }
    }
  }

  Future<void> _loadStatusesFromAPI(DateTime today) async {
    try {
      final myDayApi = MyDayApiService();
      final todayClients = await myDayApi.fetchMyDayClients(today);

      final clientsAsync = _clientFilter == 'assigned'
          ? ref.read(assignedClientsProvider)
          : ref.read(onlineClientsProvider);

      final statuses = <String, ClientStatus>{};
      clientsAsync.when(
        data: (data) {
          final clients = data.items;
          for (final client in clients) {
            final inItinerary = todayClients.any((c) => c.clientId == client.id);
            // Only track inItinerary status, loanReleased is already available from client.loanReleased
            statuses[client.id!] = ClientStatus(
              inItinerary: inItinerary,
              loanReleased: client.loanReleased, // Keep for backward compatibility, but client.loanReleased is used
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      if (mounted) {
        setState(() {
          _clientStatuses = statuses;
          _isLoadingStatuses = false;
        });
      }
    } catch (e) {
      debugPrint('API status load failed, falling back to PowerSync: $e');
      await _loadStatusesFromPowerSync(today);
    }
  }

  Future<void> _loadStatusesFromPowerSync(DateTime today) async {
    try {
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final todayClients = await PowerSyncService.query('''
        SELECT client_id FROM itineraries
        WHERE scheduled_date = ?
      ''', [todayStr]);

      final inItineraryIds = todayClients.map((row) => row['client_id'] as String).toSet();

      final clientsAsync = _clientFilter == 'assigned'
          ? ref.read(assignedClientsProvider)
          : ref.read(onlineClientsProvider);

      final statuses = <String, ClientStatus>{};
      clientsAsync.when(
        data: (data) {
          final clients = data.items;
          for (final client in clients) {
            // Only track inItinerary status, loanReleased is already available from client.loanReleased
            statuses[client.id!] = ClientStatus(
              inItinerary: inItineraryIds.contains(client.id),
              loanReleased: client.loanReleased, // Keep for backward compatibility, but client.loanReleased is used
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      if (mounted) {
        setState(() {
          _clientStatuses = statuses;
          _isLoadingStatuses = false;
        });
      }
    } catch (e) {
      debugPrint('PowerSync status load failed: $e');
      if (mounted) {
        setState(() {
          _hasStatusError = true;
          _isLoadingStatuses = false;
        });
      }
    }
  }

  Future<void> _retryLoadStatuses() async {
    await _loadClientStatuses();
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

    // Get client status and touchpoint info for validation
    final status = _clientStatuses[client.id];
    final touchpointsAsync = ref.watch(clientTouchpointsSyncProvider);
    final touchpoints = touchpointsAsync.valueOrNull ?? [];
    final clientTouchpoints = touchpoints.where((t) => t.clientId == client.id).toList();
    final nextTouchpoint = clientTouchpoints.length;
    final nextType = nextTouchpoint < 7 ? TouchpointPattern.getType(nextTouchpoint + 1) : TouchpointType.visit;

    // Check if can add before proceeding
    if (!_canAddToItinerary(client, status, nextType)) {
      if (mounted) {
        final reason = _getDisableReason(client, status, nextType);
        HapticUtils.error();
        showToast(reason);
      }
      return;
    }

    setState(() {
      _addingClientIds.add(client.id!);
    });

    try {
      final myDayApiService = ref.read(myDayApiServiceProvider);
      // Default to today if no date is provided (ensure we always send a date to backend)
      final targetDate = customDate ?? widget.selectedDate ?? DateTime.now();

      debugPrint('ClientSelectorModal: _addClientToItinerary');
      debugPrint('ClientSelectorModal: widget.selectedDate = $widget.selectedDate');
      debugPrint('ClientSelectorModal: customDate = $customDate');
      debugPrint('ClientSelectorModal: targetDate = $targetDate');

      // Use my-day API for adding to itinerary (supports both today and custom dates)
      await myDayApiService.addToMyDay(
        client.id!,
        scheduledDate: targetDate,
        priority: 5,
      );

      if (mounted) {
        HapticUtils.success();
        showToast(customDate == null
            ? '${client.firstName} ${client.lastName} added to Today'
            : '${client.firstName} ${client.lastName} added to ${_formatDateShort(customDate)}');

        // Mark client as added (disable button, show "Added" status)
        setState(() {
          if (client.id != null) {
            _addedClientIds.add(client.id!);
          }
        });

        // Trigger parent refresh immediately
        widget.onClientAdded();

        // Invalidate todayItineraryProvider to refresh the itinerary
        ref.invalidate(todayItineraryProvider);
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

  String _getTouchpointOrdinal(int number) {
    if (number >= 11 && number <= 13) return 'th';
    switch (number % 10) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      case 4:
        return '4th';
      case 5:
        return '5th';
      case 6:
        return '6th';
      case 7:
        return '7th';
      default:
        return '${number}th';
    }
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddToItinerary(Client client, ClientStatus? status, TouchpointType nextType) {
    // Check loan released (client.loanReleased is already available from API data)
    if (client.loanReleased) return false;

    // Check already in today's itinerary (from _clientStatuses)
    if (status?.inItinerary == true) return false;

    // Check next touchpoint type (Caravan can only do Visit: 1, 4, 7)
    final userRole = ref.read(currentUserRoleProvider);
    if (userRole == UserRole.caravan && nextType == TouchpointType.call) {
      return false;
    }

    return true;
  }

  String _getDisableReason(Client client, ClientStatus? status, TouchpointType nextType) {
    // client.loanReleased is already available from API data
    if (client.loanReleased) return 'Loan released - cannot add';
    if (status?.inItinerary == true) return 'Already added today';

    final userRole = ref.read(currentUserRoleProvider);
    if (userRole == UserRole.caravan && nextType == TouchpointType.call) {
      return 'Next is Call - use Call feature';
    }

    return '';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch today's itinerary to filter out already-added clients
    final itineraryAsync = ref.watch(todayItineraryProvider);
    final today = DateTime.now();

    // Get existing client IDs from today's itinerary
    final existingClientIds = itineraryAsync.when(
      data: (items) {
        return items
            .where((item) => item.scheduledDate.year == today.year &&
                           item.scheduledDate.month == today.month &&
                           item.scheduledDate.day == today.day)
            .map((item) => item.clientId)
            .toSet();
      },
      loading: () => <String>{},
      error: (_, __) => <String>{},
    );

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

        // Filter out clients already in today's itinerary
        final filteredClients = clients.where((client) => !existingClientIds.contains(client.id)).toList();
        final displayableClients = _getDisplayableClients(filteredClients);

        // Load client statuses after clients are loaded
        if (_clientStatuses.isEmpty || _clientStatuses.length != clients.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isLoadingStatuses) {
              _loadClientStatuses();
            }
          });
        }

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
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
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
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d').format(widget.selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(LucideIcons.x, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterClients();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  // Filter toggle
                  if (widget.showAssignedFilter)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('Assigned', 'assigned'),
                          const SizedBox(width: 8),
                          _buildFilterChip('All Clients', 'all'),
                        ],
                      ),
                    ),
                  // Client count indicator
                  if (totalItems > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        'Showing ${displayableClients.length} of $totalItems clients',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  // Pagination controls
                  if (totalPages > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Previous page button
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft, size: 18),
                            onPressed: _currentPage > 1
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          // Page indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'Page $_currentPage of $totalPages',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          // Next page button
                          IconButton(
                            icon: const Icon(LucideIcons.chevronRight, size: 18),
                            onPressed: _currentPage < totalPages
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),
                  // Client list
                  Expanded(
                    child: _buildClientList(displayableClients, totalItems),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () {
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
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
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
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('EEEE, MMMM d').format(widget.selectedDate),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Search bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search clients...',
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  // Filter toggle
                  if (widget.showAssignedFilter)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('Assigned', 'assigned'),
                          const SizedBox(width: 8),
                          _buildFilterChip('All Clients', 'all'),
                        ],
                      ),
                    ),
                  // Client list skeleton (only the list shows skeleton)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        } else {
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

  Widget _buildClientList(List<Client> displayableClients, int totalItems) {
    // Show skeleton loading while fetching client statuses
    if (_isLoadingStatuses && !_hasStatusError) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5, // Show 5 skeleton cards
        itemBuilder: (context, index) => _buildClientSkeleton(),
      );
    }

    if (_hasStatusError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.orange.shade400),
            const SizedBox(height: 16),
            Text(
              'Failed to load client status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryLoadStatuses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

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
                      ? 'All clients have been added to today\'s itinerary'
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: displayableClients.length,
      itemBuilder: (context, index) {
        final client = displayableClients[index];
        final isAdding = _addingClientIds.contains(client.id);
        final status = _clientStatuses[client.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: client.clientType == ClientType.existing
                  ? Colors.green.shade100
                  : Colors.blue.shade100,
              child: Text(
                '${client.firstName[0]}${client.lastName.isNotEmpty ? client.lastName[0] : ''}',
                style: TextStyle(
                  color: client.clientType == ClientType.existing
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              '${client.firstName} ${client.lastName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.email != null && client.email!.isNotEmpty)
                  Text(
                    client.email!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    // Use client.loanReleased directly from client data
                    if (client.loanReleased)
                      _buildBadge('Loan Released', Colors.red, LucideIcons.ban),
                    // Keep the "Already added" badge from _clientStatuses
                    if (status?.inItinerary == true)
                      _buildBadge('Already added', Colors.orange, LucideIcons.calendarCheck),
                    // Touchpoint history badge uses ref.watch, so it updates reactively
                    _buildNextTouchpointBadge(client.id),
                  ],
                ),
              ],
            ),
            trailing: Icon(LucideIcons.chevronDown),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Touchpoint history preview
                    Text(
                      'Touchpoint History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action buttons row
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.calendar,
                            label: client.id != null && _addedClientIds.contains(client.id) ? 'Added' : 'Add to Today',
                            isPrimary: true,
                            isLoading: isAdding,
                            onTap: client.id != null && _addedClientIds.contains(client.id) ? null : () => _addClientToItinerary(client),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.calendarClock,
                            label: client.id != null && _addedClientIds.contains(client.id) ? 'Added' : 'Add with Date',
                            isPrimary: false,
                            isLoading: isAdding,
                            onTap: client.id != null && _addedClientIds.contains(client.id) ? null : () => _showDatePicker(client),
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
      },
    );
  }

  Widget _buildClientSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSkeletonCircle(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSkeletonLine(width: 120),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(width: 180),
                      const SizedBox(height: 4),
                      _buildSkeletonLine(width: 100),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildSkeletonButton()),
                const SizedBox(width: 8),
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildSkeletonLine({required double width}) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSkeletonButton() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildNextTouchpointBadge(String? clientId) {
    if (clientId == null) return const SizedBox.shrink();

    // Get touchpoints for this client
    final touchpointsAsync = ref.watch(clientTouchpointsSyncProvider);
    final touchpoints = touchpointsAsync.valueOrNull ?? [];
    final clientTouchpoints = touchpoints.where((t) => t.clientId == clientId).toList();
    final nextTouchpoint = clientTouchpoints.length;

    if (nextTouchpoint >= 7) return const SizedBox.shrink(); // All touchpoints done

    final nextType = TouchpointPattern.getType(nextTouchpoint + 1);
    final isCall = nextType == TouchpointType.call;

    return _buildBadge(
      'Next: ${_getTouchpointOrdinal(nextTouchpoint + 1)} ${nextType.name}',
      isCall ? Colors.orange : Colors.green,
      isCall ? LucideIcons.phone : LucideIcons.mapPin,
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

    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            else
              Icon(
                icon,
                size: 14,
                color: isDisabled
                    ? Colors.grey.shade500
                    : (isPrimary ? Colors.white : const Color(0xFF0F172A)),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLoading
                    ? Colors.grey.shade500
                    : isDisabled
                        ? Colors.grey.shade500
                        : isPrimary
                            ? Colors.white
                            : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
