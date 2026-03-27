import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Map configuration for Mapbox and location services
class MapConfig {
  MapConfig._();

  static late String _mapboxAccessToken;
  static late String _mapboxStyleUrl;
  static late double _defaultZoom;
  static late double _minZoom;
  static late double _maxZoom;
  static late bool _enableClustering;
  static late int _clusterRadius;
  static late bool _offlineModeEnabled;

  /// Initialize map configuration from environment file
  static Future<void> initialize({String environment = 'dev'}) async {
    final envFile = environment == 'prod' ? '.env.prod' : '.env.dev';

    try {
      await dotenv.load(fileName: envFile);
    } catch (e) {
      debugPrint('Warning: Could not load $envFile: $e');
    }

    _mapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ??
        dotenv.env['MAPBOX_PUBLIC_TOKEN'] ??
        const String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue: '');
    _mapboxStyleUrl = dotenv.env['MAPBOX_STYLE_URL'] ??
        'mapbox://styles/mapbox/streets-v12';
    _defaultZoom = double.tryParse(dotenv.env['MAP_DEFAULT_ZOOM'] ?? '15.0') ?? 15.0;
    _minZoom = double.tryParse(dotenv.env['MAP_MIN_ZOOM'] ?? '10.0') ?? 10.0;
    _maxZoom = double.tryParse(dotenv.env['MAP_MAX_ZOOM'] ?? '20.0') ?? 20.0;
    _enableClustering = dotenv.env['MAP_ENABLE_CLUSTERING'] == 'true';
    _clusterRadius = int.tryParse(dotenv.env['MAP_CLUSTER_RADIUS'] ?? '50') ?? 50;
    _offlineModeEnabled = dotenv.env['MAP_OFFLINE_ENABLED'] == 'true';

    debugPrint('MapConfig initialized:');
    debugPrint('  Mapbox Token: ${_mapboxAccessToken.isNotEmpty ? "Set" : "Not set"}');
    debugPrint('  Style URL: $_mapboxStyleUrl');
    debugPrint('  Offline Enabled: $_offlineModeEnabled');
  }

  // Getters

  /// Mapbox public access token
  static String get mapboxAccessToken => _mapboxAccessToken;

  /// Mapbox style URL
  static String get mapboxStyleUrl => _mapboxStyleUrl;

  /// Default zoom level for map views
  static double get defaultZoom => _defaultZoom;

  /// Minimum zoom level
  static double get minZoom => _minZoom;

  /// Maximum zoom level
  static double get maxZoom => _maxZoom;

  /// Whether marker clustering is enabled
  static bool get enableClustering => _enableClustering;

  /// Cluster radius in pixels
  static int get clusterRadius => _clusterRadius;

  /// Whether offline map mode is enabled
  static bool get offlineModeEnabled => _offlineModeEnabled;

  /// Check if Mapbox is properly configured
  static bool get isConfigured => _mapboxAccessToken.isNotEmpty;

  /// Get Mapbox style URL with access token
  static String getStyleUrl() {
    return '$_mapboxStyleUrl?access_token=$_mapboxAccessToken';
  }
}

/// Touchpoint status for map markers
enum TouchpointStatus {
  none(0, 'Not Started', 0xFF9E9E9E), // Grey
  inProgress(1, 'In Progress', 0xFFFFA726), // Orange
  completed(2, 'Completed', 0xFF66BB6A); // Green

  final int value;
  final String label;
  final int color;

  const TouchpointStatus(this.value, this.label, this.color);

  static TouchpointStatus fromCompletedCount(int count) {
    if (count == 0) return TouchpointStatus.none;
    if (count >= 7) return TouchpointStatus.completed;
    return TouchpointStatus.inProgress;
  }
}

/// Map marker data for client locations
class ClientMapMarker {
  final String clientId;
  final String clientName;
  final double latitude;
  final double longitude;
  final TouchpointStatus status;
  final int completedTouchpoints;
  final String? address;

  ClientMapMarker({
    required this.clientId,
    required this.clientName,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.completedTouchpoints,
    this.address,
  });

  /// Create marker from client
  factory ClientMapMarker.fromClient(
    dynamic client, {
    Address? address,
  }) {
    final primaryAddress = address ?? (client.addresses?.isNotEmpty == true
        ? client.addresses!.first
        : null);

    return ClientMapMarker(
      clientId: client.id ?? '',
      clientName: client.fullName ?? 'Unknown',
      latitude: primaryAddress?.latitude ?? 0.0,
      longitude: primaryAddress?.longitude ?? 0.0,
      status: TouchpointStatus.fromCompletedCount(
        client.completedTouchpoints ?? 0,
      ),
      completedTouchpoints: client.completedTouchpoints ?? 0,
      address: primaryAddress?.fullAddress,
    );
  }

  /// Check if marker has valid coordinates
  bool get hasValidLocation =>
      latitude != 0.0 && longitude != 0.0;

  Map<String, dynamic> toJson() => {
        'clientId': clientId,
        'clientName': clientName,
        'latitude': latitude,
        'longitude': longitude,
        'status': status.value,
        'completedTouchpoints': completedTouchpoints,
        'address': address,
      };
}

/// Address model for map compatibility
class Address {
  final String? id;
  final String? street;
  final String? barangay;
  final String? city;
  final String? province;
  final bool? isPrimary;
  final double? latitude;
  final double? longitude;

  Address({
    this.id,
    this.street,
    this.barangay,
    this.city,
    this.province,
    this.isPrimary,
    this.latitude,
    this.longitude,
  });

  String? get fullAddress {
    final parts = <String>[
      if (street != null && street!.isNotEmpty) street!,
      if (barangay != null && barangay!.isNotEmpty) barangay!,
      if (city != null && city!.isNotEmpty) city!,
      if (province != null && province!.isNotEmpty) province!,
    ];
    return parts.isNotEmpty ? parts.join(', ') : null;
  }
}
