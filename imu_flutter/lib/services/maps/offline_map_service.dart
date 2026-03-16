import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/logger.dart';

/// Cached map tile region
class CachedMapRegion {
  final String id;
  final String name;
  final int minZoom;
  final int maxZoom;
  final int x;
  final int y;
  final int width;
  final int height;
  final String localPath;
  final DateTime cachedAt;
  final DateTime? expiresAt;

  CachedMapRegion({
    required this.id,
    required this.name,
    required this.minZoom,
    required this.maxZoom,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.localPath,
    required this.cachedAt,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'localPath': localPath,
    'cachedAt': cachedAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
  };

  factory CachedMapRegion.fromJson(Map<String, dynamic> json) {
    return CachedMapRegion(
      id: json['id'] as String,
      name: json['name'] as String,
      minZoom: json['minZoom'] as int,
      maxZoom: json['maxZoom'] as int,
      x: json['x'] as int,
      y: json['y'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      localPath: json['localPath'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
    );
  }
}

/// Service for caching map tiles for offline use
class OfflineMapService {
  static const int _maxCacheSizeMB = 100;
  static const Duration _cacheExpiry = Duration(days: 7);

  final String _mapboxAccessToken;
  final String _cacheDirectory;
  final Map<String, CachedMapRegion> _cachedRegions = {};
  String? _basePath;

  OfflineMapService({
    required String mapboxAccessToken,
    String? cacheDirectory,
  })  : _mapboxAccessToken = mapboxAccessToken,
        _cacheDirectory = cacheDirectory ?? 'map_cache';

  /// Initialize cache directory
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _basePath = p.join(appDir.path, _cacheDirectory);

    final dir = Directory(_basePath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      logDebug('Created map cache directory: $_basePath');
    }

    await _loadCachedRegions();
  }

  /// Load cached regions from metadata file
  Future<void> _loadCachedRegions() async {
    if (_basePath == null) return;

    final metadataFile = File(p.join(_basePath!, 'regions_metadata.json'));
    if (await metadataFile.exists()) {
      try {
        final content = await metadataFile.readAsString();
        final List<dynamic> regions = jsonDecode(content);
        for (final region in regions) {
          final cached = CachedMapRegion.fromJson(region as Map<String, dynamic>);
          _cachedRegions[cached.id] = cached;
        }
        logDebug('Loaded ${_cachedRegions.length} cached regions');
      } catch (e) {
        logError('Failed to load cached regions metadata', e);
      }
    }
  }

  /// Save cached regions to metadata file
  Future<void> _saveCachedRegions() async {
    if (_basePath == null) return;

    final metadataFile = File(p.join(_basePath!, 'regions_metadata.json'));
    final regions = _cachedRegions.values.map((r) => r.toJson()).toList();
    await metadataFile.writeAsString(jsonEncode(regions));
  }

  /// Download and cache map tiles for a region
  Future<bool> cacheRegion({
    required String regionId,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required int minZoom,
    required int maxZoom,
    ProgressCallback? onProgress,
  }) async {
    try {
      if (_basePath == null) await initialize();

      // Calculate tile coordinates for all zoom levels
      int totalTiles = 0;
      int downloadedTiles = 0;

      for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
        final minTileX = _lonToTileX(minLng, zoom);
        final minTileY = _latToTileY(maxLat, zoom); // Note: Y is inverted
        final maxTileX = _lonToTileX(maxLng, zoom);
        final maxTileY = _latToTileY(minLat, zoom);

        totalTiles += ((maxTileX - minTileX + 1) * (maxTileY - minTileY + 1)).abs();
      }

      logDebug('Total tiles to download: $totalTiles');

      // Download tiles for each zoom level
      for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
        final minTileX = _lonToTileX(minLng, zoom);
        final minTileY = _latToTileY(maxLat, zoom);
        final maxTileX = _lonToTileX(maxLng, zoom);
        final maxTileY = _latToTileY(minLat, zoom);

        for (int x = min(0, minTileX); x <= max(minTileX, maxTileX); x++) {
          for (int y = min(0, minTileY); y <= max(minTileY, maxTileY); y++) {
            await _downloadTile(x, y, zoom, regionId);
            downloadedTiles++;
            onProgress?.call(downloadedTiles, totalTiles);
          }
        }
      }

      // Save region metadata
      final region = CachedMapRegion(
        id: regionId,
        name: regionId,
        minZoom: minZoom,
        maxZoom: maxZoom,
        x: _lonToTileX(minLng, minZoom),
        y: _latToTileY(maxLat, minZoom),
        width: (_lonToTileX(maxLng, minZoom) - _lonToTileX(minLng, minZoom) + 1).abs(),
        height: (_latToTileY(minLat, minZoom) - _latToTileY(maxLat, minZoom) + 1).abs(),
        localPath: _getRegionPath(regionId),
        cachedAt: DateTime.now(),
        expiresAt: DateTime.now().add(_cacheExpiry),
      );

      _cachedRegions[regionId] = region;
      await _saveCachedRegions();

      logDebug('Cached region: $regionId with $totalTiles tiles');
      return true;
    } catch (e) {
      logError('Failed to cache region', e);
      return false;
    }
  }

  /// Download a single map tile
  Future<void> _downloadTile(int x, int y, int zoom, String regionId) async {
    if (_basePath == null) return;

    final tileDir = Directory(p.join(_basePath!, regionId, '$zoom', '$x'));
    if (!await tileDir.exists()) {
      await tileDir.create(recursive: true);
    }

    final tilePath = p.join(tileDir.path, '$y.png');

    // Skip if already cached
    if (await File(tilePath).exists()) return;

    final url = 'https://api.mapbox.com/v4/mapbox.mapbox-streets-v11'
        '/$zoom/$x/$y@2x.png?access_token=$_mapboxAccessToken';

    // Note: Actual download requires http package
    // This is a placeholder for the download logic
    logDebug('Would download tile: $url');
  }

  /// Convert longitude to tile X coordinate
  int _lonToTileX(double lon, int zoom) {
    return ((lon + 180) / 360 * (1 << zoom)).floor();
  }

  /// Convert latitude to tile Y coordinate
  int _latToTileY(double lat, int zoom) {
    final latRad = lat * pi / 180;
    return ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * (1 << zoom))
        .floor();
  }

  /// Get local path for a cached region
  String _getRegionPath(String regionId) {
    if (_basePath == null) return '';
    return p.join(_basePath!, regionId);
  }

  /// Get local tile URL for offline use
  String? getLocalTileUrl(String regionId, int x, int y, int zoom) {
    if (_basePath == null) return null;
    return 'file://${_basePath!}/$regionId/$zoom/$x/$y.png';
  }

  /// Check if a region is cached
  bool isRegionCached(String regionId) {
    return _cachedRegions.containsKey(regionId);
  }

  /// Get cached region
  CachedMapRegion? getCachedRegion(String regionId) {
    return _cachedRegions[regionId];
  }

  /// Get all cached regions
  List<CachedMapRegion> getAllCachedRegions() {
    return _cachedRegions.values.toList();
  }

  /// Delete a cached region
  Future<bool> deleteCachedRegion(String regionId) async {
    try {
      if (_basePath == null) return false;

      final regionDir = Directory(_getRegionPath(regionId));
      if (await regionDir.exists()) {
        await regionDir.delete(recursive: true);
      }

      _cachedRegions.remove(regionId);
      await _saveCachedRegions();

      logDebug('Deleted cached region: $regionId');
      return true;
    } catch (e) {
      logError('Failed to delete cached region', e);
      return false;
    }
  }

  /// Clear all cached regions
  Future<void> clearCache() async {
    if (_basePath == null) return;

    final dir = Directory(_basePath!);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    _cachedRegions.clear();
    logDebug('Cleared all map cache');
  }

  /// Get cache size in MB
  Future<double> getCacheSizeMB() async {
    if (_basePath == null) return 0;

    final dir = Directory(_basePath!);
    if (!await dir.exists()) return 0;

    int totalBytes = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }

    return totalBytes / (1024 * 1024);
  }

  /// Clean expired cache regions
  Future<int> cleanExpiredCache() async {
    int cleaned = 0;
    final now = DateTime.now();

    final expiredRegions = _cachedRegions.values
        .where((r) => r.expiresAt != null && r.expiresAt!.isBefore(now))
        .toList();

    for (final region in expiredRegions) {
      if (await deleteCachedRegion(region.id)) {
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logDebug('Cleaned $cleaned expired cache regions');
    }

    return cleaned;
  }
}

typedef ProgressCallback = void Function(int current, int total);

/// Provider for offline map service
final offlineMapServiceProvider = Provider<OfflineMapService?>((ref) {
  // TODO: Get Mapbox token from environment
  const token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  if (token.isEmpty) return null;

  return OfflineMapService(mapboxAccessToken: token);
});
