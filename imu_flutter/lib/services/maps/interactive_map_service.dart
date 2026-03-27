import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/config/map_config.dart';
import '../location/geolocation_service.dart';

/// Map view mode
enum MapViewMode {
  allClients,
  todayClients,
  nearbyClients,
  routeView,
}

/// Map filter options
class MapFilters {
  final bool showCompleted;
  final bool showInProgress;
  final bool showNotStarted;
  final Set<ProductType>? productTypes;
  final Set<ClientType>? clientTypes;
  final double? maxDistanceKm;
  final String? municipalityCode;

  const MapFilters({
    this.showCompleted = true,
    this.showInProgress = true,
    this.showNotStarted = true,
    this.productTypes,
    this.clientTypes,
    this.maxDistanceKm,
    this.municipalityCode,
  });

  MapFilters copyWith({
    bool? showCompleted,
    bool? showInProgress,
    bool? showNotStarted,
    Set<ProductType>? productTypes,
    Set<ClientType>? clientTypes,
    double? maxDistanceKm,
    String? municipalityCode,
  }) {
    return MapFilters(
      showCompleted: showCompleted ?? this.showCompleted,
      showInProgress: showInProgress ?? this.showInProgress,
      showNotStarted: showNotStarted ?? this.showNotStarted,
      productTypes: productTypes ?? this.productTypes,
      clientTypes: clientTypes ?? this.clientTypes,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      municipalityCode: municipalityCode ?? this.municipalityCode,
    );
  }
}

/// Product type enum (matching client model)
enum ProductType {
  sssPensioner,
  gsisPensioner,
  private,
}

/// Client type enum
enum ClientType {
  potential,
  existing,
}

/// Interactive map service for client location management
class InteractiveMapService {
  static final InteractiveMapService _instance =
      InteractiveMapService._internal();
  factory InteractiveMapService() => _instance;
  InteractiveMapService._internal();

  final GeolocationService _geoService = GeolocationService();
  final StreamController<List<ClientMapMarker>> _markersController =
      StreamController<List<ClientMapMarker>>.broadcast();
  final StreamController<Position?> _userLocationController =
      StreamController<Position?>.broadcast();

  List<ClientMapMarker> _currentMarkers = [];
  Position? _currentUserLocation;
  MapViewMode _viewMode = MapViewMode.allClients;
  MapFilters _filters = const MapFilters();

  // Streams
  Stream<List<ClientMapMarker>> get markersStream => _markersController.stream;
  Stream<Position?> get userLocationStream => _userLocationController.stream;

  // Getters
  List<ClientMapMarker> get currentMarkers => _currentMarkers;
  Position? get currentUserLocation => _currentUserLocation;
  MapViewMode get viewMode => _viewMode;
  MapFilters get filters => _filters;

  /// Initialize map service
  Future<void> initialize() async {
    // Start tracking user location
    _startLocationTracking();
  }

  /// Start tracking user location
  void _startLocationTracking() {
    GeolocationService().startLocationStream().listen(
      (position) {
        _currentUserLocation = position;
        _userLocationController.add(position);
        _updateFilteredMarkers();
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  /// Update markers with new client data
  void updateMarkers(List<dynamic> clients) {
    _currentMarkers = clients
        .map((client) => ClientMapMarker.fromClient(client))
        .where((marker) => marker.hasValidLocation)
        .toList();

    _updateFilteredMarkers();
  }

  /// Set current view mode
  void setViewMode(MapViewMode mode) {
    _viewMode = mode;
    _updateFilteredMarkers();
  }

  /// Update filters
  void updateFilters(MapFilters filters) {
    _filters = filters;
    _updateFilteredMarkers();
  }

  /// Update filtered markers based on current mode and filters
  void _updateFilteredMarkers() {
    var filtered = List<ClientMapMarker>.from(_currentMarkers);

    // Apply view mode
    switch (_viewMode) {
      case MapViewMode.allClients:
        // Show all clients
        break;
      case MapViewMode.todayClients:
        // Filter by today's itinerary (would need date comparison)
        filtered = filtered.where((marker) {
          // TODO: Implement today's itinerary filtering
          return true;
        }).toList();
        break;
      case MapViewMode.nearbyClients:
        if (_currentUserLocation != null && _filters.maxDistanceKm != null) {
          filtered = filtered.where((marker) {
            final distance = GeolocationService().calculateDistanceInKm(
                  _currentUserLocation!.latitude,
                  _currentUserLocation!.longitude,
                  marker.latitude,
                  marker.longitude,
                );
            return distance <= _filters.maxDistanceKm!;
          }).toList();
        }
        break;
      case MapViewMode.routeView:
        // Sort by distance from user
        if (_currentUserLocation != null) {
          filtered.sort((a, b) {
            final distA = GeolocationService().calculateDistanceInKm(
                  _currentUserLocation!.latitude,
                  _currentUserLocation!.longitude,
                  a.latitude,
                  a.longitude,
                );
            final distB = GeolocationService().calculateDistanceInKm(
                  _currentUserLocation!.latitude,
                  _currentUserLocation!.longitude,
                  b.latitude,
                  b.longitude,
                );
            return distA.compareTo(distB);
          });
        }
        break;
    }

    // Apply status filters
    filtered = filtered.where((marker) {
      switch (marker.status) {
        case TouchpointStatus.completed:
          return _filters.showCompleted;
        case TouchpointStatus.inProgress:
          return _filters.showInProgress;
        case TouchpointStatus.none:
          return _filters.showNotStarted;
      }
    }).toList();

    _markersController.add(filtered);
  }

  /// Get clients sorted by distance from current location
  List<ClientMapMarker> getClientsSortedByDistance({
    Position? from,
    int limit = 20,
  }) {
    final location = from ?? _currentUserLocation;
    if (location == null) return _currentMarkers;

    final withDistance = _currentMarkers.map((marker) {
      final distance = GeolocationService().calculateDistanceInKm(
            location.latitude,
            location.longitude,
            marker.latitude,
            marker.longitude,
          );
      return MapEntry(marker, distance);
    }).toList();

    withDistance.sort((a, b) => a.value.compareTo(b.value));

    return withDistance
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  /// Get nearby clients within radius
  List<ClientMapMarker> getNearbyClients({
    Position? center,
    double radiusKm = 5.0,
  }) {
    final location = center ?? _currentUserLocation;
    if (location == null) return [];

    return _currentMarkers.where((marker) {
      final distance = GeolocationService().calculateDistanceInKm(
            location.latitude,
            location.longitude,
            marker.latitude,
            marker.longitude,
          );
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate route between multiple points (returns ordered list)
  List<ClientMapMarker> calculateOptimalRoute({
    required List<ClientMapMarker> clients,
    Position? startFrom,
  }) {
    if (clients.isEmpty) return clients;

    final location = startFrom ?? _currentUserLocation;
    final List<ClientMapMarker> route = [];
    final Set<String> visited = {};

    Position currentPos = location ??
        Position(
          latitude: clients.first.latitude,
          longitude: clients.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );

    // Nearest neighbor algorithm
    while (visited.length < clients.length) {
      ClientMapMarker? nearest;
      double minDistance = double.infinity;

      for (final client in clients) {
        if (visited.contains(client.clientId)) continue;

        final distance = GeolocationService().calculateDistanceInKm(
              currentPos.latitude,
              currentPos.longitude,
              client.latitude,
              client.longitude,
            );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = client;
        }
      }

      if (nearest != null) {
        route.add(nearest);
        visited.add(nearest.clientId);
        currentPos = Position(
          latitude: nearest.latitude,
          longitude: nearest.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        break;
      }
    }

    return route;
  }

  /// Get distance to client
  double? getDistanceToClient(String clientId) {
    final marker = _currentMarkers.firstWhere(
      (m) => m.clientId == clientId,
      orElse: () => _currentMarkers.first,
    );

    if (_currentUserLocation == null || !marker.hasValidLocation) {
      return null;
    }

    return GeolocationService().calculateDistanceInKm(
      _currentUserLocation!.latitude,
      _currentUserLocation!.longitude,
      marker.latitude,
      marker.longitude,
    );
  }

  /// Search clients by address
  List<ClientMapMarker> searchByAddress(String query) {
    final lowerQuery = query.toLowerCase();
    return _currentMarkers.where((marker) {
      return marker.address?.toLowerCase().contains(lowerQuery) == true ||
          marker.clientName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get statistics for current markers
  Map<String, int> getStatistics() {
    return {
      'total': _currentMarkers.length,
      'completed': _currentMarkers
          .where((m) => m.status == TouchpointStatus.completed)
          .length,
      'inProgress': _currentMarkers
          .where((m) => m.status == TouchpointStatus.inProgress)
          .length,
      'notStarted': _currentMarkers
          .where((m) => m.status == TouchpointStatus.none)
          .length,
    };
  }

  /// Dispose resources
  void dispose() {
    _markersController.close();
    _userLocationController.close();
  }
}
