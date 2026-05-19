import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/my_day_api_service.dart';
import '../sync/powersync_service.dart';

const double _kGeofenceRadius = 400.0; // meters
const Duration _kCooldown = Duration(hours: 16);

// ±0.005° ≈ ~550m — bounding-box pre-filter before precise distance check
const double _kBoundingBoxDelta = 0.005;

const String _kCooldownPrefix = 'geofence_cooldown_';
const String _kChannelId = 'geofencing_proximity';
const String _kChannelName = 'Nearby Clients';

// Top-level function required by flutter_local_notifications
@pragma('vm:entry-point')
void _onGeofenceNotificationResponse(NotificationResponse response) {
  GeofencingService._instance?._handleResponse(response);
}

class GeofencingService {
  // Singleton reference for the top-level callback
  static GeofencingService? _instance;

  final FlutterLocalNotificationsPlugin _plugin;
  final MyDayApiService _myDay;

  StreamSubscription<Position>? _positionSub;
  bool _initialized = false;

  GeofencingService({
    FlutterLocalNotificationsPlugin? plugin,
    MyDayApiService? myDay,
  })  : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _myDay = myDay ?? MyDayApiService() {
    _instance = this;
  }

  /// Initialize notifications channel and start the GPS stream.
  /// Safe to call multiple times — no-ops after first call.
  Future<void> init() async {
    if (_initialized) return;

    // Set up flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onGeofenceNotificationResponse,
    );

    // Create the Android notification channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          importance: Importance.high,
          enableVibration: true,
        ));

    // Request notification permission (Android 13+)
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }

    // Check location permission before starting stream
    final locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied ||
        locPerm == LocationPermission.deniedForever) {
      debugPrint('[GeofencingService] Location permission not granted — stream not started');
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      _onPositionUpdate,
      onError: (e) => debugPrint('[GeofencingService] Stream error: $e'),
    );

    _initialized = true;
    debugPrint('[GeofencingService] Initialized — proximity monitoring active');
  }

  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    _initialized = false;
    if (_instance == this) _instance = null;
  }

  Future<void> _onPositionUpdate(Position position) async {
    try {
      final db = await PowerSyncService.database;
      final lat = position.latitude;
      final lng = position.longitude;

      final rows = await db.getAll(
        '''SELECT id, first_name, last_name, middle_name,
                  full_address, latitude, longitude
           FROM clients
           WHERE (loan_released IS NULL OR loan_released = 0)
             AND latitude  IS NOT NULL
             AND longitude IS NOT NULL
             AND latitude  BETWEEN ? AND ?
             AND longitude BETWEEN ? AND ?
             AND EXISTS (
               SELECT 1 FROM user_locations ul
               WHERE ul.province    = province
                 AND ul.municipality = municipality
                 AND ul.deleted_at  IS NULL
             )''',
        [
          lat - _kBoundingBoxDelta,
          lat + _kBoundingBoxDelta,
          lng - _kBoundingBoxDelta,
          lng + _kBoundingBoxDelta,
        ],
      );

      await processNearbyClients(
        agentLat: lat,
        agentLng: lng,
        clientRows: rows,
      );
    } catch (e) {
      debugPrint('[GeofencingService] Error on position update: $e');
    }
  }

  /// Core proximity logic — exposed for testing without mocking GPS stream.
  @visibleForTesting
  Future<void> processNearbyClients({
    required double agentLat,
    required double agentLng,
    required List<Map<String, dynamic>> clientRows,
  }) async {
    for (final row in clientRows) {
      final clientLat = (row['latitude'] as num?)?.toDouble();
      final clientLng = (row['longitude'] as num?)?.toDouble();
      if (clientLat == null || clientLng == null) continue;

      final distance = Geolocator.distanceBetween(
          agentLat, agentLng, clientLat, clientLng);
      if (distance > _kGeofenceRadius) continue;

      final clientId = row['id'] as String? ?? '';
      if (clientId.isEmpty) continue;

      if (!await isCooldownExpired(clientId)) continue;

      // Write cooldown BEFORE firing so lingering in the area doesn't re-trigger
      await writeCooldown(clientId);

      final firstName = (row['first_name'] as String?) ?? '';
      final middleName = (row['middle_name'] as String?) ?? '';
      final lastName = (row['last_name'] as String?) ?? '';
      final fullName = [firstName, middleName, lastName]
          .where((s) => s.isNotEmpty)
          .join(' ');
      final address = (row['full_address'] as String?) ?? '';

      await _showNotification(
        clientId: clientId,
        clientName: fullName,
        address: address,
        distanceMeters: distance.round(),
        clientLat: clientLat,
        clientLng: clientLng,
      );
    }
  }

  /// Returns true if the 16-hour cooldown has elapsed (or never started).
  @visibleForTesting
  Future<bool> isCooldownExpired(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('$_kCooldownPrefix$clientId');
    if (stored == null) return true;
    final elapsed = DateTime.now().millisecondsSinceEpoch - stored;
    return elapsed >= _kCooldown.inMilliseconds;
  }

  /// Stamps the current time as the cooldown start for a client.
  @visibleForTesting
  Future<void> writeCooldown(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '$_kCooldownPrefix$clientId', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _showNotification({
    required String clientId,
    required String clientName,
    required String address,
    required int distanceMeters,
    required double clientLat,
    required double clientLng,
  }) async {
    final notifId = clientId.hashCode.abs();
    final payload = jsonEncode({
      'client_id': clientId,
      'lat': clientLat,
      'lng': clientLng,
      'name': clientName,
    });

    final androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      importance: Importance.high,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction(
          'navigate',
          'Navigate Now',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'itinerary',
          'Add to Itinerary',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      notifId,
      'You are near $clientName',
      '$address · ${distanceMeters}m away',
      NotificationDetails(android: androidDetails),
      payload: payload,
    );

    debugPrint('[GeofencingService] Notification: $clientName (${distanceMeters}m)');
  }

  void _handleResponse(NotificationResponse response) {
    final payloadStr = response.payload;
    if (payloadStr == null) return;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final clientId = data['client_id'] as String?;
    final clientLat = (data['lat'] as num?)?.toDouble();
    final clientLng = (data['lng'] as num?)?.toDouble();
    final clientName = (data['name'] as String?) ?? '';

    if (clientId == null) return;

    final actionId = response.actionId;

    // Run async operations without blocking the callback
    _handleAction(
      actionId: actionId,
      clientId: clientId,
      clientLat: clientLat,
      clientLng: clientLng,
      clientName: clientName,
    );
  }

  Future<void> _handleAction({
    required String? actionId,
    required String clientId,
    required double? clientLat,
    required double? clientLng,
    required String clientName,
  }) async {
    try {
      switch (actionId) {
        case 'navigate':
          if (clientLat != null && clientLng != null) {
            final uri = Uri.parse(
                'geo:$clientLat,$clientLng?q=$clientLat,$clientLng(${Uri.encodeComponent(clientName)})');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
          }
          await _myDay.addToMyDay(clientId);
          break;
        case 'itinerary':
          await _myDay.addToMyDay(clientId);
          break;
        case 'dismiss':
        default:
          // Cooldown was written at notification fire time — nothing else needed
          break;
      }
    } catch (e) {
      debugPrint('[GeofencingService] Error handling action $actionId: $e');
    }
  }
}

final geofencingServiceProvider = Provider<GeofencingService>((ref) {
  final service = GeofencingService();
  ref.onDispose(service.dispose);
  return service;
});
