import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/config/map_config.dart';
import '../../../services/maps/interactive_map_service.dart';
import '../../../services/maps/map_service.dart';
import '../../../core/utils/haptic_utils.dart';
import '../../../core/utils/debounce_utils.dart';
import '../../../shared/utils/loading_helper.dart';

/// Provider for map service
final mapServiceProvider = Provider<InteractiveMapService>((ref) {
  final service = InteractiveMapService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Client map view widget
class ClientMapView extends ConsumerStatefulWidget {
  final List<dynamic> clients;
  final String? selectedClientId;
  final Function(String)? onClientTap;
  final bool showControls;
  final bool showSearch;
  final MapViewMode initialMode;

  const ClientMapView({
    super.key,
    required this.clients,
    this.selectedClientId,
    this.onClientTap,
    this.showControls = true,
    this.showSearch = true,
    this.initialMode = MapViewMode.allClients,
  });

  @override
  ConsumerState<ClientMapView> createState() => _ClientMapViewState();
}

class _ClientMapViewState extends ConsumerState<ClientMapView> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final TextEditingController _searchController = TextEditingController();
  final _searchDebounce = Debounce(milliseconds: 300);

  MapViewMode _currentMode = MapViewMode.allClients;
  MapFilters _filters = const MapFilters();
  Position? _currentPosition;
  bool _isLoading = true;
  String? _selectedClientId;
  List<ClientMapMarker> _filteredMarkers = [];

  StreamSubscription? _markersSubscription;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _selectedClientId = widget.selectedClientId;
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      await LoadingHelper.withLoading(
        ref: ref,
        message: 'Loading map...',
        operation: () async {
          final mapService = ref.read(mapServiceProvider);
          await mapService.initialize();

          // Update markers with client data
          mapService.updateMarkers(widget.clients);
          mapService.setViewMode(_currentMode);

          // Listen to marker updates
          _markersSubscription = mapService.markersStream.listen((markers) {
            if (mounted) {
              setState(() {
                _filteredMarkers = markers;
                _updateMarkers(markers);
                _isLoading = false;
              });
            }
          });

          // Listen to location updates
          _locationSubscription = mapService.userLocationStream.listen((position) {
            if (position != null && mounted) {
              setState(() {
                _currentPosition = position;
              });
              _centerMapOnUser();
            }
          });
        },
      );
    } catch (e) {
      // Still hide loading even if there's an error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMarkers(List<ClientMapMarker> markers) {
    final Set<Marker> newMarkers = {};

    for (final markerData in markers) {
      final marker = Marker(
        markerId: MarkerId(markerData.clientId),
        position: LatLng(markerData.latitude, markerData.longitude),
        infoWindow: InfoWindow(
          title: markerData.clientName,
          snippet:
              '${markerData.completedTouchpoints}/7 Touchpoints\n${markerData.address ?? ""}',
          onTap: () {
            HapticUtils.lightImpact();
            widget.onClientTap?.call(markerData.clientId);
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerColor(markerData.status),
        ),
        onTap: () {
          HapticUtils.lightImpact();
          setState(() {
            _selectedClientId = markerData.clientId;
          });
          widget.onClientTap?.call(markerData.clientId);
        },
      );

      newMarkers.add(marker);
    }

    // Add user location marker
    if (_currentPosition != null) {
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
      newMarkers.add(userMarker);
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  double _getMarkerColor(TouchpointStatus status) {
    switch (status) {
      case TouchpointStatus.completed:
        return BitmapDescriptor.hueGreen;
      case TouchpointStatus.inProgress:
        return BitmapDescriptor.hueOrange;
      case TouchpointStatus.none:
        return BitmapDescriptor.hueRed;
    }
  }

  Future<void> _centerMapOnUser() async {
    if (_currentPosition == null) return;

    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        ),
        MapConfig.defaultZoom,
      ),
    );
  }

  Future<void> _centerMapOnBounds() async {
    if (_filteredMarkers.isEmpty) return;

    final controller = await _mapController.future;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _filteredMarkers
            .map((m) => m.latitude)
            .reduce((a, b) => a < b ? a : b),
        _filteredMarkers
            .map((m) => m.longitude)
            .reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        _filteredMarkers
            .map((m) => m.latitude)
            .reduce((a, b) => a > b ? a : b),
        _filteredMarkers
            .map((m) => m.longitude)
            .reduce((a, b) => a > b ? a : b),
      ),
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _showFilterBottomSheet() {
    HapticUtils.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MapFilterBottomSheet(
        filters: _filters,
        onFiltersChanged: (newFilters) {
          setState(() {
            _filters = newFilters;
          });
          ref.read(mapServiceProvider).updateFilters(newFilters);
        },
      ),
    );
  }

  void _showViewModeBottomSheet() {
    HapticUtils.lightImpact();
    showModalBottomSheet(
      context: context,
      builder: (context) => _ViewModeBottomSheet(
        currentMode: _currentMode,
        onModeSelected: (mode) {
          HapticUtils.lightImpact();
          setState(() {
            _currentMode = mode;
          });
          ref.read(mapServiceProvider).setViewMode(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      ref.read(mapServiceProvider).updateMarkers(widget.clients);
      return;
    }

    final mapService = ref.read(mapServiceProvider);
    final results = mapService.searchByAddress(query);
    // Update markers with search results
  }

  @override
  void didUpdateWidget(ClientMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clients != oldWidget.clients) {
      ref.read(mapServiceProvider).updateMarkers(widget.clients);
    }
  }

  @override
  void dispose() {
    _markersSubscription?.cancel();
    _locationSubscription?.cancel();
    _searchController.dispose();
    _searchDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MapConfig.isConfigured) {
      return _buildPlaceholder();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition?.latitude ?? 14.5995,
                _currentPosition?.longitude ?? 120.9842,
              ),
              zoom: MapConfig.defaultZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController.complete(controller);
              if (_filteredMarkers.isNotEmpty) {
                _centerMapOnBounds();
              }
            },
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Search bar
          if (widget.showSearch)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _SearchBar(
                controller: _searchController,
                onSearch: (query) => _searchDebounce.run(() => _performSearch(query)),
              ),
            ),

          // Map controls
          if (widget.showControls)
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapControlButton(
                    icon: Icons.filter_list,
                    onTap: _showFilterBottomSheet,
                    tooltip: 'Filter',
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.map,
                    onTap: _showViewModeBottomSheet,
                    tooltip: 'View Mode',
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.my_location,
                    onTap: _centerMapOnUser,
                    tooltip: 'My Location',
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.fit_screen,
                    onTap: _centerMapOnBounds,
                    tooltip: 'Fit All',
                  ),
                ],
              ),
            ),

          // Statistics panel
          Positioned(
            left: 16,
            bottom: 16,
            child: _StatisticsPanel(
              markers: _filteredMarkers,
              totalClients: widget.clients.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Map Not Configured',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please add your Mapbox access token to the .env file',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;

  const _SearchBar({
    required this.controller,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search clients or addresses...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller.clear();
                    onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: onSearch,
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _MapControlButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Icon(icon),
          ),
        ),
      ),
    );
  }
}

class _StatisticsPanel extends StatelessWidget {
  final List<ClientMapMarker> markers;
  final int totalClients;

  const _StatisticsPanel({
    required this.markers,
    required this.totalClients,
  });

  @override
  Widget build(BuildContext context) {
    final completed = markers.where((m) => m.status == TouchpointStatus.completed).length;
    final inProgress = markers.where((m) => m.status == TouchpointStatus.inProgress).length;
    final notStarted = markers.where((m) => m.status == TouchpointStatus.none).length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Showing ${markers.length} of $totalClients',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatDot(color: Colors.green, count: completed),
              const SizedBox(width: 8),
              _StatDot(color: Colors.orange, count: inProgress),
              const SizedBox(width: 8),
              _StatDot(color: Colors.red, count: notStarted),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;
  final int count;

  const _StatDot({required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _MapFilterBottomSheet extends StatefulWidget {
  final MapFilters filters;
  final Function(MapFilters) onFiltersChanged;

  const _MapFilterBottomSheet({
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  State<_MapFilterBottomSheet> createState() => _MapFilterBottomSheetState();
}

class _MapFilterBottomSheetState extends State<_MapFilterBottomSheet> {
  late MapFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Clients',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('Touchpoint Status'),
          CheckboxListTile(
            title: const Text('Completed'),
            value: _filters.showCompleted,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(showCompleted: value ?? true);
              });
              widget.onFiltersChanged(_filters);
            },
          ),
          CheckboxListTile(
            title: const Text('In Progress'),
            value: _filters.showInProgress,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(showInProgress: value ?? true);
              });
              widget.onFiltersChanged(_filters);
            },
          ),
          CheckboxListTile(
            title: const Text('Not Started'),
            value: _filters.showNotStarted,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(showNotStarted: value ?? true);
              });
              widget.onFiltersChanged(_filters);
            },
          ),
        ],
      ),
    );
  }
}

class _ViewModeBottomSheet extends StatelessWidget {
  final MapViewMode currentMode;
  final Function(MapViewMode) onModeSelected;

  const _ViewModeBottomSheet({
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View Mode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _ViewModeTile(
            icon: Icons.map,
            title: 'All Clients',
            mode: MapViewMode.allClients,
            currentMode: currentMode,
            onTap: onModeSelected,
          ),
          _ViewModeTile(
            icon: Icons.today,
            title: 'Today\'s Itinerary',
            mode: MapViewMode.todayClients,
            currentMode: currentMode,
            onTap: onModeSelected,
          ),
          _ViewModeTile(
            icon: Icons.near_me,
            title: 'Nearby',
            mode: MapViewMode.nearbyClients,
            currentMode: currentMode,
            onTap: onModeSelected,
          ),
          _ViewModeTile(
            icon: Icons.route,
            title: 'Route View',
            mode: MapViewMode.routeView,
            currentMode: currentMode,
            onTap: onModeSelected,
          ),
        ],
      ),
    );
  }
}

class _ViewModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final MapViewMode mode;
  final MapViewMode currentMode;
  final Function(MapViewMode) onTap;

  const _ViewModeTile({
    required this.icon,
    required this.title,
    required this.mode,
    required this.currentMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => onTap(mode),
    );
  }
}
