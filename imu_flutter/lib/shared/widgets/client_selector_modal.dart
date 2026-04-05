import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../app.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/utils/debounce_utils.dart';
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../models/client_status.dart';
import '../../services/api/my_day_api_service.dart';
import '../../services/api/itinerary_api_service.dart';
import '../../services/api/api_exception.dart';
import '../../services/sync/powersync_service.dart';
import '../../shared/providers/app_providers.dart';

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
  List<Client> _allClients = [];
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Set<String> _addingClientIds = {};
  bool _isLoading = true;
  String? _error;
  String _clientFilter = 'assigned'; // 'assigned' or 'all'

  // NEW: Status tracking state
  Map<String, ClientStatus> _clientStatuses = {};
  bool _isLoadingStatuses = true;
  bool _hasStatusError = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_onSearchChanged);
    _loadClientStatuses(); // NEW: Load status information
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce.run(_filterClients);
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Wait for clients to be loaded
      List<Client> clients = [];
      int retries = 0;

      while (clients.isEmpty && retries < 10) {
        final clientsAsync = ref.read(clientsProvider);

        clientsAsync.when(
          data: (data) {
            clients = data;
          },
          loading: () {
            // Still loading, wait a bit
          },
          error: (error, _) {
            if (mounted) {
              setState(() {
                _error = error.toString();
                _isLoading = false;
              });
            }
            return;
          },
        );

        if (clients.isEmpty) {
          await Future.delayed(const Duration(milliseconds: 200));
          retries++;
        } else {
          break;
        }
      }

      // Get today's itinerary to filter out already added clients
      final itineraryAsync = ref.read(todayItineraryProvider);
      final today = DateTime.now();

      Set<String> existingClientIds = {};
      itineraryAsync.when(
        data: (items) {
          existingClientIds = items
              .where((item) => item.scheduledDate.year == today.year &&
                             item.scheduledDate.month == today.month &&
                             item.scheduledDate.day == today.day)
              .map((item) => item.clientId)
              .toSet();
        },
        loading: () {},
        error: (_, __) {},
      );

      // Filter out clients already in today's itinerary
      _allClients = clients.where((client) => !existingClientIds.contains(client.id)).toList();

      // Apply filter (assigned vs all)
      _applyClientFilter();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyClientFilter() {
    if (_clientFilter == 'all') {
      _clients = _allClients;
    } else {
      // For 'assigned', filter by assigned municipalities
      final userRole = ref.read(currentUserRoleProvider);
      final shouldFilterByArea = switch (userRole) {
        UserRole.admin || UserRole.assistantAreaManager => false,
        UserRole.areaManager || UserRole.caravan || UserRole.tele => true,
      };

      if (shouldFilterByArea) {
        // Get assigned municipalities and filter clients
        final assignedMunicipalitiesAsync = ref.watch(assignedMunicipalitiesProvider);
        assignedMunicipalitiesAsync.when(
          data: (municipalityIds) {
            if (municipalityIds.isEmpty) {
              // User has no assigned municipalities - show no clients
              _clients = [];
            } else {
              _clients = _allClients.where((client) {
                // Construct municipality ID from client's province and municipality
                final clientMunicipalityId = client.province != null && client.municipality != null
                    ? '${client.province}-${client.municipality}'
                    : null;
                return clientMunicipalityId != null && municipalityIds.contains(clientMunicipalityId);
              }).toList();
            }
            _filterClients();
          },
          loading: () {
            // While loading assigned areas, show no clients (not all clients)
            _clients = [];
            _filterClients();
          },
          error: (_, __) {
            // On error loading assigned areas, show no clients (not all clients)
            _clients = [];
            _filterClients();
          },
        );
        return;
      } else {
        // Admin and Assistant Area Manager see all clients
        _clients = _allClients;
      }
    }
    _filterClients(); // Apply search filter
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredClients = _clients;
      } else {
        _filteredClients = _clients.where((client) {
          final fullName = '${client.firstName} ${client.lastName} ${client.middleName ?? ''}'.toLowerCase();
          final email = (client.email ?? '').toLowerCase();
          return fullName.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  List<Client> get _displayableClients {
    // Hide loan released clients from the list
    return _filteredClients.where((client) => !client.loanReleased).toList();
  }

  Future<void> _loadClientStatuses() async {
    if (_clients.isEmpty) return; // Wait for clients to load first

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

      final statuses = <String, ClientStatus>{};
      for (final client in _clients) {
        final inItinerary = todayClients.any((c) => c.clientId == client.id);
        statuses[client.id!] = ClientStatus(
          inItinerary: inItinerary,
          loanReleased: client.loanReleased,
        );
      }

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

      final statuses = <String, ClientStatus>{};
      for (final client in _clients) {
        statuses[client.id!] = ClientStatus(
          inItinerary: inItineraryIds.contains(client.id),
          loanReleased: client.loanReleased,
        );
      }

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
        // Use top-positioned toast instead of bottom SnackBar
        showToast('Invalid client: missing ID');
      }
      return;
    }

    // Validate UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(client.id!)) {
      if (mounted) {
        // Use top-positioned toast instead of bottom SnackBar
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

    // NEW: Check if can add before proceeding
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
      final myDayApi = MyDayApiService();
      final targetDate = customDate ?? widget.selectedDate;

      // Use my-day API for adding to itinerary (supports both today and custom dates)
      await myDayApi.addToMyDay(
        client.id!,
        scheduledDate: targetDate,
        priority: 5,
      );

      if (mounted) {
        HapticUtils.success();
        // Use top-positioned toast instead of bottom SnackBar
        showToast(customDate == null
            ? '${client.firstName} ${client.lastName} added to Today'
            : '${client.firstName} ${client.lastName} added to ${_formatDateShort(customDate)}');

        // Remove client from list
        setState(() {
          _clients.remove(client);
          _filterClients();
        });

        // Close modal immediately
        if (mounted) Navigator.pop(context);

        // Trigger parent refresh after modal closes
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onClientAdded();
        });
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

        // Use top-positioned toast instead of bottom SnackBar
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
    // Check loan released
    if (client.loanReleased) return false;

    // Check already in today's itinerary
    if (status?.inItinerary == true) return false;

    // Check next touchpoint type (Caravan can only do Visit: 1, 4, 7)
    final userRole = ref.read(currentUserRoleProvider);
    if (userRole == UserRole.caravan && nextType == TouchpointType.call) {
      return false;
    }

    return true;
  }

  String _getDisableReason(Client client, ClientStatus? status, TouchpointType nextType) {
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
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
            // Client list
            Expanded(
              child: _buildClientList(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientList(ScrollController? scrollController) {
    // Show skeleton loading while fetching client statuses
    if (_isLoadingStatuses && !_hasStatusError) {
      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 5, // Show 5 skeleton cards
        itemBuilder: (context, index) => _buildClientSkeleton(),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertCircle, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text('Failed to load clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadClients,
              child: const Text('Retry'),
            ),
          ],
        ),
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

    if (_displayableClients.isEmpty) {
      // Check if user has no assigned municipalities
      final userRole = ref.read(currentUserRoleProvider);
      final shouldFilterByArea = switch (userRole) {
        UserRole.admin || UserRole.assistantAreaManager => false,
        UserRole.areaManager || UserRole.caravan || UserRole.tele => true,
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
                  : (_searchController.text.isEmpty ? 'No clients available' : 'No clients found'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              hasNoAssignedLocations
                  ? 'You have no assigned locations. Please contact your administrator to assign areas to you.'
                  : (_searchController.text.isEmpty
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
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _displayableClients.length,
      itemBuilder: (context, index) {
        final client = _displayableClients[index];
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
                    if (status?.loanReleased == true)
                      _buildBadge('Loan Released', Colors.red, LucideIcons.ban),
                    if (status?.inItinerary == true)
                      _buildBadge('Already added', Colors.orange, LucideIcons.calendarCheck),
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
                            label: 'Add to Today',
                            isPrimary: true,
                            isLoading: isAdding,
                            onTap: () => _addClientToItinerary(client),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: LucideIcons.calendarClock,
                            label: 'Add with Date',
                            isPrimary: false,
                            isLoading: isAdding,
                            onTap: () => _showDatePicker(client),
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
    String? reason, // NEW: Disable reason
  }) {
    final isDisabled = onTap == null && !isLoading;

    return InkWell(
      onTap: isDisabled
          ? () {
              // Show reason toast when clicking disabled button
              if (reason != null && mounted) {
                showToast(reason);
                HapticUtils.error();
              }
            }
          : onTap,
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
