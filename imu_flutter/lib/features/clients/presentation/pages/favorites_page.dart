// Favorites Page - Matches Clients Page exactly but shows only favorited clients
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
import '../../../../services/api/itinerary_api_service.dart' show todayItineraryProvider;
import '../../../../shared/providers/app_providers.dart' show
    myDayApiServiceProvider,
    todayItineraryProvider;
import '../../../../shared/widgets/client/touchpoint_progress_badge.dart';
import '../../../../shared/widgets/client/touchpoint_status_badge.dart';
import '../../../../shared/widgets/client/client_status_badge.dart';
import '../../../../shared/widgets/client/client_list_tile.dart';
import '../../../../shared/widgets/skeletons/client_skeleton.dart';
import '../../data/providers/client_favorites_provider.dart';
import '../../data/models/client_model.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  final _searchController = TextEditingController();
  final _searchDebounce = Debounce(milliseconds: 300);
  String _searchQuery = '';

  // Optimistic set of client IDs scheduled today
  final Set<String> _scheduledTodayIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce.run(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    HapticUtils.lightImpact();
    if (mounted) {
      AppNotification.showWarning(
        context,
        'Refreshing favorites...',
        duration: const Duration(seconds: 3),
      );
    }
    // Invalidate the favorites provider to trigger refresh
    ref.invalidate(favoritedClientListProvider);
    if (mounted) {
      AppNotification.showSuccess(
        context,
        'Favorites refreshed',
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final starredAsync = ref.watch(favoritedClientListProvider);

    return starredAsync.when(
      data: (clients) {
        // Filter clients based on search query
        final filteredClients = _searchQuery.isEmpty
            ? clients
            : clients.where((client) =>
                client.fullName.toLowerCase().contains(_searchQuery) ||
                (client.municipality?.toLowerCase().contains(_searchQuery) ?? false)).toList();

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
                              context.pop();
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
                                  'Back',
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
                            'Favorites',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredClients.length} clients',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Description
                      if (clients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.star,
                                size: 14,
                                color: Colors.amber.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Tap the star on any client card to add them to your favorites',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
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
                if (clients.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search favorites...',
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

                // Client list
                Expanded(
                  child: filteredClients.isEmpty
                      ? _buildEmptyState(clients.isEmpty)
                      : RefreshIndicator(
                          onRefresh: () async => _handleRefresh(),
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 17),
                            itemCount: filteredClients.length,
                            itemBuilder: (context, index) {
                              final client = filteredClients[index];
                              return _buildClientTile(client);
                            },
                          ),
                        ),
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
              // Header (always visible)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: const Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Favorites',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 80),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Expanded(child: ClientListSkeleton(itemCount: 7)),
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
              const Text(
                'Failed to load favorites',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
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
                onPressed: () => ref.invalidate(favoritedClientListProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noFavorites) {
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
              noFavorites ? LucideIcons.star : LucideIcons.search,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            noFavorites ? 'No favorites yet' : 'No favorites found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noFavorites
                ? 'Tap the star on any client card to add them to your favorites'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClientTile(Client client) {
    // Check if client is in today's itinerary
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
        loading: () {},
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

  Future<void> _addClientToItinerary(Client client, {bool useDatePicker = false}) async {
    DateTime? scheduledDate;

    if (useDatePicker) {
      final DateTime now = DateTime.now();
      scheduledDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: now.add(const Duration(days: 30)),
      );

      if (scheduledDate == null) return;
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
          } else {
            showToast('Added to itinerary for ${DateFormat('MMM dd').format(scheduledDate)}');
          }
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

  Future<void> _addClientToToday(Client client) async {
    await _addClientToItinerary(client, useDatePicker: false);
  }

  Future<void> _showDatePickerForClient(Client client) async {
    await _addClientToItinerary(client, useDatePicker: true);
  }
}
