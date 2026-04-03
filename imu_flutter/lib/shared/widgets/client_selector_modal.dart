import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/haptic_utils.dart';
import '../../core/models/user_role.dart';
import '../../features/clients/data/models/client_model.dart';
import '../../services/api/itinerary_api_service.dart';
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
  List<Client> _allClients = [];
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  Set<String> _addingClientIds = {};
  bool _isLoading = true;
  String? _error;
  String _clientFilter = 'assigned'; // 'assigned' or 'all'

  @override
  void initState() {
    super.initState();
    _loadClients();
    _searchController.addListener(_filterClients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            _clients = _allClients.where((client) {
              // Construct municipality ID from client's province and municipality
              final clientMunicipalityId = client.province != null && client.municipality != null
                  ? '${client.province}-${client.municipality}'
                  : null;
              return clientMunicipalityId != null && municipalityIds.contains(clientMunicipalityId);
            }).toList();
            _filterClients();
          },
          loading: () {
            _clients = _allClients; // Show all while loading
            _filterClients();
          },
          error: (_, __) {
            _clients = _allClients; // Show all on error
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

  Future<void> _addClientToItinerary(Client client, {DateTime? customDate}) async {
    if (client.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid client: missing ID'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate UUID format
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(client.id!)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid client ID format: ${client.id}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _addingClientIds.add(client.id!);
    });

    try {
      final itineraryApi = ItineraryApiService();
      final targetDate = customDate ?? widget.selectedDate;

      // Always use createItinerary to add to the itinerary system
      await itineraryApi.createItinerary(
        clientId: client.id!,
        scheduledDate: targetDate,
        status: 'pending',
        priority: 'normal',
      );

      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(customDate == null
                ? '${client.firstName} ${client.lastName} added to Today'
                : '${client.firstName} ${client.lastName} added to ${_formatDateShort(customDate)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

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

        // Check if it's the specific "already in itinerary" error
        String errorMessage = e.toString();
        if (errorMessage.contains('Client already in today\'s itinerary') ||
            errorMessage.contains('already in today\'s itinerary') ||
            errorMessage.contains('already has an itinerary for this date') ||
            errorMessage.contains('already in My Day')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${client.firstName} ${client.lastName} is already in the itinerary for this date'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add client: ${errorMessage}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

    if (_filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty ? 'No clients available' : 'No clients found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isEmpty
                  ? 'All clients have been added to today\'s itinerary'
                  : 'Try a different search term',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        final isAdding = _addingClientIds.contains(client.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Client info row
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: client.clientType == ClientType.existing
                          ? Colors.green.shade100
                          : Colors.blue.shade100,
                      child: Text(
                        '${client.firstName[0]}${client.lastName.isNotEmpty ? client.lastName[0] : ''}',
                        style: TextStyle(
                          color: client.clientType == ClientType.existing ? Colors.green.shade700 : Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${client.firstName} ${client.lastName}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          if (client.email != null && client.email!.isNotEmpty)
                            Text(
                              client.email!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          if (client.phone != null && client.phone!.isNotEmpty)
                            Text(
                              client.phone!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    ),
                    if (client.clientType != null)
                      Chip(
                        label: Text(
                          client.clientType!.name.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                        backgroundColor: client.clientType == ClientType.existing
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                  ],
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
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.shade200
              : isPrimary
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary ? const Color(0xFF0F172A) : Colors.grey.shade300,
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
                color: isPrimary ? Colors.white : const Color(0xFF0F172A),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isLoading
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
